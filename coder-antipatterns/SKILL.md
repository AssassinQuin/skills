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
