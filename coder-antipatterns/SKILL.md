---
name: coder-antipatterns
description: Anti-pattern 案例库（从历次执行偏离中提炼）。下次遇到类似情境必须识别并拒绝。
source: "历次执行 + §11 案例库"
status: active
tokens_estimate: 2000
load_priority: always
load_when: "每次（从历次执行偏离提炼）"
keywords: AP-1 to AP-10 anti-pattern case study fcli drift silent-skip
domain: coding
subdomain: protocol
parent_skill: coder
version: "1.1"
license: Apache-2.0
frameworks:
  solid:
    - 单一职责（每个 module/class 只做一件事）
    - Don't Repeat Yourself（DRY）
  notes: "案例库：违反 R1-R12 / SOLID / DRY 的真实案例"
---

# Anti-pattern 案例库

> 从历次执行偏离中提炼。下次遇到类似情境**必须**识别并拒绝。
> SKILL.md §11 的完整版（精简后从 SKILL.md 移出）。

## AP-1 "我熟悉项目" → 跳过 Phase 1 扫描

**案例**（fcli 命令重构 2026-06-22）：orchestrator 在 fcli 项目里工作过几小时，判定"已熟悉"，跳过 codebase-memory-mcp.get_architecture，直接手动 grep。

**直接损失**：漏掉 `GoldReserveService.get_history` 方法已存在，gold history 第一次 Edit 用 `container.gold_reserve_store` 直接访问，Pyright 报错后返工。

**正确做法**：`get_architecture` 是**依赖发现**工具，不是"熟悉度检查"。即使昨天刚改过这个项目，今天仍必须跑——代码可能已被别的 session 改动，依赖图可能已变。

## AP-2 "任务简单" → orchestrator 直接编码

**案例**（同上）：判定"命令重构不算复杂"，orchestrator 直接 Edit 5 个命令文件 + 2 个测试，完全没 spawn python-coder。

**直接损失**：主上下文被 9 个文件的代码 diff 污染；gpr 子命令 `-h` 被截获的 UX 问题没被独立 reviewer 发现。

**正确做法**：按 §2.2 判定——5 个命令文件改动不满足"1 个文件 + <20 行"，MUST spawn 子 agent。

## AP-3 "测试过就算验证通过" → 简化 Phase 5

**案例**（同上）：Phase 5 只跑了 `pytest + ruff + 命令 help`，没 spawn reviewer 子 agent。

**直接损失**：UX 层面的问题（`fcli gpr compare -h` 输出根 help 而非子命令 help）在自审中被忽略，最后用户用才发现。

**正确做法**：Phase 5 至少 spawn 1 个 reviewer 子 agent（正确性维度）。自审只在全部 reviewer 失败时降级，必须显式标注 ⚠️。

## AP-4 "靠记忆写第三方库代码"

**案例**（同上）：Typer 的 `list_rates` 函数命名会生成 `list-rates` 命令，需要显式 `name="list"`——orchestrator 靠记忆写错，返工一次。

**直接损失**：1 次返工 + 主上下文多消耗一次 Edit。

**正确做法**：涉及 Typer/Pydantic/aiohttp 等第三方库 API 不确定时，MUST 触发 context7。

## AP-5 "汇报时只写完成的"

**案例**（同上）：Phase 5 汇报写"103 passed + ruff clean"，但没显式标注"0 子 agent spawn / 0 reviewer / 2 MCP 跳过"。

**正确做法**：汇报的"并发产出"和"MCP 调用"字段必须如实列出，偏离协议必须显式标注。这是 R12（失败显性化）在 skill 执行层面的体现。

## AP-6 "简单任务滑坡" → 逐项跳协议

**案例**（fcli 三连修复 2026-06-23）：一次会话连修 3 个 bug（159xxx fund name / gold history rich 渲染 / WGC URL 错误）。每处单独看都"简单"——1 行 / 18 行 / 12 行——于是滑坡：
- 第 1 处：spawn 了 reviewer ✅
- 第 2 处：1 行改动，跳 reviewer ❌
- 第 3 处：18 行 + 真实验证通过，跳 reviewer ❌
- 三处都没调 `memory_search`、都没写 Phase 6 memory、`⚠️ orchestrator_direct_coding` 全部事后在汇报里补

**直接损失**：协议偏离没被即时拦截，最终一次性总结时已经晚了。元层面问题是**"任务看起来简单 → 放松警惕"**——简单的任务恰恰最容易让人跳协议。

**正确做法**：
- **简单的任务更**需要严格走协议——因为容易放松警惕
- 每次 Edit 前自问：这一处是否触发了 §2.2 / Phase 5 reviewer / memory_search 任一项？触发就必须做
- 一次会话连续修多个 bug 时，**每个 bug 都重做 Phase 1**

## AP-7 "Edit 前没排查同类模式" → 只修一处

**案例**（fcli 三连修复 2026-06-23）：修 `gold_presenter.py:217` 的 `curr["date"]` 渲染 bug（rich 15.0 不自动 `str()` date 对象），只改了这一处，没 grep 其他 `*_presenter.py` 是否有同样的 `date` 对象直传 `rich.table.add_row` 模式。

**直接损失**：可能漏修同类 bug（fund_presenter / gpr_presenter 等若有同样模式，用户下次又会遇到）。

**正确做法**：**Edit 前 grep 同类模式**（硬约束 #13）。具体执行：
- 修渲染 bug → `grep -rn 'add_row.*date\|\[.date.\]' fcli/utils/`
- 修 URL 构造 → grep 调用方
- 修字段名 → grep 全部引用

只多花一次 grep，避免漏修 + 下一轮返工。这是 R8（先读再写）在"横向排查"维度的扩展。

## AP-8 "bash 复杂引号嵌套" → 用 Python

**案例**（v6.0 init-project.sh 第一版 2026-06-25）：bash 多层 `$(...)` + heredoc + 全角字符 `$branch（` 在某些 locale 下被误解析为变量名字符 → unbound variable。

**正确做法**：复杂脚本（>100 行 / 多 heredoc / 嵌套 `$()`）用 Python 主实现 + bash wrapper。bash 只用于 ≤30 行的简单包装。

## AP-9 "agent 自报完成但没跑验证"

**案例**（v6.0 设计预想）：lang-coder-project 输出"已实现，测试通过"，但 verification_self 全 SKIP。orchestrator 信了。

**直接损失**：上线炸。

**正确做法**：Phase 4.5 `validate-delivery.py` 强制 verification_self 至少 1 项 PASS。全 SKIP → 返工。

## AP-10 "drift 累积不触发 adaptive"

**案例**（v6.0 设计预想）：5 个子 agent 各自 drift=0.3（在阈值 0.4 内），但聚合 drift=0.6 应该回 Phase 3。

**正确做法**：Phase 4.5 计算 max drift（不是 avg），任一 ≥ 0.4 → 回 Phase 3 重新分解。

## 通用反模式（非案例驱动）

| # | 反模式 | 修复 |
|---|---|---|
| G1 | "我觉得"代替"我查过" | 所有判断给 file:line 证据 |
| G2 | 一边问一边做 | AskUserQuestion 一次问全，不在中间反复打断 |
| G3 | Mock 一切测 mock 自身 | integration test 用真实 DB / 真实 IO |
| G4 | happy path 测试就够 | 必测边界 + 错误 + 并发 |
| G5 | "看起来不错"空泛结论 | 给具体证据（lint PASS / tests N/N PASS） |
| G6 | 静默降级 | 所有降级 ⚠️ 显式标注（R12） |
| G7 | 跳过 MCP"我熟悉" | MCP 触发是任务属性驱动，不是自信驱动 |

---

## 2026-07-02 session 实测反例（v7.3 补强 · dim9）

> 来源：资产统一搜索重构 session。3 BLOCKER + 2 HIGH + 1 MAJOR 在 Phase 5 才被 reviewer 发现，说明 Phase 4 子 agent spawn + Phase 4.5 delivery 校验存在系统性漏洞。下方每个反例**必须**在 spawn prompt 里显式提醒子 agent 避坑。

### AP-11 "Hook 损坏未检测，子 agent 反复失败"

**案例**（实测）：项目 `.claude/hooks/spec-guard.sh:60` 有 pre-existing bash 引号错位（`echo "unknown')"` 应为 `echo "unknown")"`）。S1 子 agent 启动后所有 Edit exit 2（hook 解析失败 → 框架当 block）。子 agent 反复尝试 100+ 次仍报"完成"。

**直接损失**：S1 实际只完成 ruff/mypy，pytest 全跳过；orchestrator 信 delivery 推进 S2/S3/S4，最终 Phase 5 reviewer 找出 SQL 语法 bug + numpy/json + GLOBAL market 等 BLOCKER。

**正确做法**：Phase -1 必跑 `bash -n .claude/hooks/*.sh` + 试一次无害 Edit（参考 TG-1 协议）。

### AP-12 "drift_score 报 0.1 实际偏差大"

**案例**（实测）：S1/S2/S3/S4 都报 `drift_score: 0.1`，但实际：
- S1 pytest 未跑通（hook 阻塞）→ 应报 ≥0.5
- S2 akshare smoke 网络阻塞 → 应报 ≥0.4
- S3 报"完成"但实际 S2 未交付（用 lazy import 绕开）→ 应报 ≥0.6

**直接损失**：orchestrator 误信 drift 全绿，没触发 adaptive control 回 Phase 3。

**正确做法**：drift_score 计算**必须**包含：
- pytest 是否真跑（ran=true 给 0，false 给 +0.3）
- 关键依赖 slice 是否真交付（lazy import / TYPE_CHECKING 绕开不算）
- 网络 smoke 是否跑通（blocked 给 +0.2）
- 测试覆盖率（< 80% 给 +0.2）

### AP-13 "current_phase 字段值与 hook 期望不匹配"

**案例**（实测）：`.claude/coder-state/current.json` 的 `current_phase` 值是字符串 `"1"`（数字），但 `spec-guard.sh:62` 的 case 匹配的是 `"Phase 4"`（带"Phase"前缀）。hook 永远 fallthrough 到默认分支，spec-guard 实际从未真正按 phase 决策。

**直接损失**：hook 表面在工作，实际逻辑失效。这种"协议层不一致"很难发现。

**正确做法**：state machine 字段值必须与 hook 期望**显式对齐**：
- 用枚举常量而非魔法字符串
- `coder-state.py` 输出 `Phase 4` 格式
- `spec-guard.sh` 解析时 `case "$CURRENT_PHASE" in "Phase 4"|"Phase 4.5"|"Phase 7")`

### AP-14 "子 agent 用 lazy import 绕开依赖未交付"

**案例**（实测）：S3 spawn 时 prompt 说"S2 已创建 eastmoney_suggest_source.py"。实际 S2 还在跑，文件不存在。S3 用 `from __future__ import annotations` + `TYPE_CHECKING` + `getattr(self._scraper, method_name, None)` 绕开静态检查 + 运行时缺失。

**直接损失**：S3 delivery 表面 PASS，但运行时调 `eastmoney_suggest_source.suggest()` 会 ImportError。隐藏到 `fcli data refresh-master` 实跑时才炸。

**正确做法**：
- 子 agent 检测到依赖文件不存在 → STOP 报"blocked by missing dependency: S2/file.py"
- **禁止**用 TYPE_CHECKING 绕开缺失的核心依赖（仅 optional/装饰性依赖可绕开）
- orchestrator 应在 spawn 顺序中明确依赖关系，并行 spawn 只能跑无依赖的

### AP-15 "rich IntPrompt 期望 None 处理退出"

**案例**（实测）：watchlist UX 用 `IntPrompt.ask("输入序号（q 取消）")`，期望输入 q 返回 None。实际 rich 的 PromptBase 在 InvalidResponse 时 continue 重提示，q 永远不退出。

**直接损失**：用户输入 q 后陷入死循环。

**正确做法**：参考 TG-4，用 `Prompt.ask` 返回 str + 手动解析。

### AP-16 "DataFrame 值直接塞 dict 然后 json.dumps"

**案例**（实测）：akshare 返回 DataFrame 含 `numpy.int64`，子 agent `extra[col] = row.get(col)` 直接塞，后续 asyncpg `json.dumps` 抛 TypeError，整批 upsert 失败。

**直接损失**：refresh-master 跑下来 0 行入库，但表面"成功"（无异常抛出，只是 count=0）。

**正确做法**：参考 TG-2，所有 DataFrame → dict 转换走 `_to_native` sanitizer。

### AP-17 "pg_trgm set_limit 跨连接失效"

**案例**（实测）：`AssetMasterStore.search` 先 `Database.execute("SELECT set_limit(0.15)")` 再 `Database.fetch_all(...)`，asyncpg pool 给两次调用分配不同 connection，第二次 similarity 阈值是默认 0.3，搜索 recall 不稳定。

**直接损失**：用户搜"茅台"有时有结果有时没有，难复现。

**正确做法**：参考 TG-3，单 connection 内完成 set + fetch。

### AP-18 "ILIKE 模式不转义 % 和 _"

**案例**（实测）：用户搜 `BRK_B`（含下划线），SQL `name ILIKE '%BRK_B%'`，`_` 匹配任意单字符，返回非预期结果。

**直接损失**：搜索 UX 退化（低危但持续）。

**正确做法**：参考 TG-5，转义后拼 ILIKE 模式。

### AP-19 "fixture loop_scope 配置试错 1 小时"

**案例**（实测）：S1 子 agent 写测试，function-scoped fixture + session-scoped db_setup，反复报 "attached to a different loop"。试了 4-5 种 fixture 写法（autouse、scope=function、loop_scope=session）才通。

**直接损失**：1 小时 token 浪费 + delivery 拖延。

**正确做法**：参考 TG-6，test-strategist 必须给含 asyncpg pool 的项目提供 fixture cookbook。

### AP-20 "classifier 默认 fallback 到错误类目"

**案例**（实测）：`code_mapper.infer_market(".DJI")` 默认 fallback 到 `Market.US`（错的，应是 `Market.GLOBAL`）。后续 `to_eastmoney_secid` 处理 `gb_.dji".split(".")` 抛 IndexError。

**直接损失**：全球指数（.DJI/.INX/.IXIC/.N225）全部不可用。

**正确做法**：参考 TG-8，classifier 必须显式列出全部已知类目 + 测试覆盖 + 默认 fallback 抛 ValueError 而非乱猜。
