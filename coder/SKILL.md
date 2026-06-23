---
name: coder
description: >
  多语言编码元 skill（router + 7 Phase 流水线 + parallel subagents + 5 MCP 集成）。


  显式 trigger：写代码、实现、重构、修复、修改、coder、编码、开发、debug、新增、
  审计代码、review diff、add feature、implement、build、fix。
  隐式 trigger："修这个 bug" / "加个 X 功能" / "重构这块" / "这块代码不对" /
  "为什么 X 报错" / "改下 X"。

  不触发：纯问答、解释、分析、调研（用 web-research / researcher）、人物思维（用 huashu-nuwa）。

  架构（v5.0）：本 skill 是 router，按 7 Phase 流水线编排 + parallel subagents；
  语言知识在 memory MCP（不在 references）。
metadata:
  version: "5.0"
  skill_type: execution
  agent_compatible: true
  previous_version: "3.2"
  design_doc: ".deepen/20260622-v5.0/design.md"
---

# Coder v5.0 — Router + Parallel Subagents

> v3.2 → v5.0 推倒重做。完整设计见 [`design.md`](.deepen/20260622-v5.0/design.md)。
> v3.2 备份在 [`snapshots/SKILL-v3.2.md.bak`](snapshots/SKILL-v3.2.md.bak)。

**核心形态**：SKILL.md 是路由表（本文件），细节全在 `references/`（progressive disclosure）。
语言约束 / 踩坑 / 经验**不在文件**，全在 memory MCP（详见 §5）。

---

## 1. 何时触发 / 何时不触发

**触发**：见 frontmatter `description`。

**退出条件**：

| 条件 | 行为 |
|---|---|
| 无匹配语言且目标文件无法确定 | 退出，使用通用编码 |
| 纯文档任务 | 退出，使用文档 skill |
| 非 coding 任务 | 退出，使用通用能力 |

---

## 2. 7 Phase 路由表（核心）

| Phase | 名字 | 执行者 | 输入 | 输出 | 下一 Phase | **前置 gate**（MUST） |
|---|---|---|---|---|---|---|
| 0 | 需求捕获 | orchestrator（内联）| 用户请求 | 意图 + 验收 checklist | 1 | AskUserQuestion 或用户已明确意图 |
| 1 | 元数据 + 架构 | 🌟 **3 路并发**: explorer(haiku) + get_architecture(orch) + researcher(sonnet, 触发式) | 意图 | metadata + S.U.P.E.R 热图 | 2 | **codebase-memory-mcp.get_architecture 必须触发**（失败需显式标记 fallback） |
| 2 | 语言路由 | orchestrator（内联）| metadata | spawn `{lang}-coder` | 3 或 4 | Phase 1 产出已记录（不能"我熟悉"跳过） |
| 3 | 设计方案 | 🌟 **N oracle 并发**（2-4，按复杂度，仅复杂任务）| metadata + 热图 | 2-4 方案 + 推荐 | 4 | 复杂度评估（见 §2.1） |
| 4 | 执行 | `{lang}-coder`（sonnet，可多语言并发）| 方案 + memory 注入 | diff + drift 遥测 | 5 | **MUST spawn 子 agent**（orchestrator 不允许直接编码，唯一例外见 §2.2） |
| 5 | 验证 | 🌟 **3 reviewer 并发**: 正确性 / S.U.P.E.R / 安全 | diff + checklist | 审查报告 | 6 | **至少 1 个 reviewer 子 agent**（自审只在 reviewer 全失败时降级，必须显式标注 ⚠️） |
| 6 | 持久化 | orchestrator（内联）| 全部产出 | memory + MASTER.md + 索引 | — | — |

**Phase 详执行协议**：见 [`references/phase-{N}-*.md`](references/)。

**简单任务跳过 Phase 3**：改动 <3 文件 / 无 public API 变更 / 无跨模块影响 / 无新依赖。

### 2.1 复杂度评估（决定是否跳过 Phase 3）

任务**任一**条件命中 → 走 Phase 3：
- 改动 ≥3 文件
- public API / CLI 接口变更
- 跨模块影响（service + store + 命令层联动）
- 引入新依赖
- 用户表达含"重构""统一""架构调整"

全部不命中 → 跳过 Phase 3，**但仍必须**走 Phase 4 spawn + Phase 5 reviewer。

### 2.2 Phase 4 唯一允许 orchestrator 直接编码的情况

仅当满足**全部**条件：
- 改动 **1 个文件**
- 改动 **<20 行**
- 不涉及第三方库语法
- 无 public API 变更

任一不满足 → MUST spawn `{lang}-coder` 子 agent。

orchestrator 直接编码时必须在 **Edit 调用前的文本里即时**标注 `⚠️ orchestrator_direct_coding` + 依据本节哪条（**不能事后在最终汇报里补**）。R12 在 skill 执行层面的体现。

---

## 3. 语言路由（Phase 2 细则）

| 信号 | 路由 |
|---|---|
| 目标文件 `.go` 或项目含 `go.mod` | → [`agents/go-coder.md`](agents/go-coder.md) |
| 目标文件 `.py` 或项目含 `pyproject.toml`/`setup.py`/`requirements.txt` | → [`agents/python-coder.md`](agents/python-coder.md) |
| `.ts`/`.tsx`/`.js` | 暂无 agent，回退通用 + 提示扩展 |
| `.rs` | 暂无 agent，回退通用 + 提示扩展 |
| 三层未匹配 | 退出 |

**spawn `{lang}-coder` 前**：orchestrator 必调 `memory_search(tags=["coding-{lang}-*"])`
注入语言上下文。若返回空 → 触发 seed 流程（§5 + [`references/memory-tier-strategy.md`](references/memory-tier-strategy.md)）。

### 3.1 MCP 触发条件表（MUST / SHOULD / OPTIONAL）

避免"我熟悉所以不用查"的偷懒——MCP 触发是**条件驱动**，不是"感觉驱动"。

| MCP | 何时 MUST 触发 | 何时 SHOULD 触发 | 何时 OPTIONAL |
|---|---|---|---|
| **codebase-memory-mcp** (`get_architecture` / `search_graph`) | 任何**多文件改动前**（Phase 1）；service/store 有方法可能复用时 | 改动 1 文件但牵涉调用方追踪 | 单文件 <20 行改动 |
| **context7** (library docs) | 使用**第三方库 API 不确定**时（如 Typer 参数类型、Pydantic Field 行为）；写新库集成代码 | 用了库但 API 是常用部分 | 纯 stdlib 代码 |
| **context-mode** (`ctx_batch_execute`/`ctx_execute`) | 命令输出 >20 行；读 >1 个大文件；批量 grep | 单文件 Read | 短输出观察 |
| **github MCP** | 任务涉及 PR/issue/上游 | 查 CI 状态 | 纯本地 |
| **memory MCP** (`memory_search`) | spawn 子 agent 前（注入语言 context）；Phase 6 写决策 | 涉及历史决策追溯 | — |

**Anti-pattern**："我熟悉这个项目/库"**不构成**跳过 MCP 的理由。本次执行（2026-06-22）正是因为以"熟悉 fcli"为由跳过 codebase-memory-mcp，导致漏掉 service.get_history 已存在，返工一次。

**判断规则**：触发条件是**任务属性**（改动范围/库确定性/输出规模），不是 orchestrator 的自信程度。

---

## 4. 硬约束（13 条摘要）

| # | 约束 | 出处 |
|---|---|---|
| 1 | 意图不清必问（Phase 0） | R1 + R4 |
| 2 | 子 agent 必须显式指定 model（R5.1） | R5.1 |
| 3 | token 预算硬性（主上下文 ≤30k + ctx_index 长文件） | R6 |
| 4 | 暴露冲突不折中（R7） | R7 |
| 5 | 先读再写（R8） | R8 |
| 6 | 测试验证意图（R9） | R9 |
| 7 | 长任务检查点（R10） | R10 |
| 8 | 惯例优先于新颖（R11） | R11 |
| 9 | 失败显性化（R12） | R12 |
| 10 | 外科手术式修改（R3） | R3 |
| 11 | 简洁优先（R2） | R2 |
| 12 | 编码前先思考（R1） | R1 |
| 13 | **Edit 前 grep 同类模式**（防"只修一处"漏修） | R8 扩展，见 §11.7 |

**完整版**（含检查命令 + 例子）：[`references/hard-constraints.md`](references/hard-constraints.md)。

---

## 5. 语言知识在 memory MCP（v5.0 核心决策）

**不存 references 文件**。语言约束 / 踩坑 / 经验全部在 memory MCP。

| tag | tier | 用途 |
|---|---|---|
| `coding-{lang}-convention` / `-trap` / `-tooling` / `-verification` | 共享级 | 跨项目通用知识 |
| `coding-{lang}-gotcha` | 项目级 | 项目专属坑（子 agent 可写）|
| `coding-super-decay` | 共享级 | S.U.P.E.R 衰减记录 |
| `coding-audit-finding` | 项目级 | reviewer 发现（子 agent 可写）|
| `coding-user-pref` | 全局级 | 用户偏好 |

**写入权限**：子 agent 只能写项目级；共享/全局级必须 orchestrator + 🔒 用户确认。
**首次使用 memory 为空**：orchestrator 检测 → AskUserQuestion（是 / 这次否 / 永不问）→
用户选"是"才跑 `scripts/seed-memory.py`。详见 [`memory-tier-strategy.md`](references/memory-tier-strategy.md)。

---

## 6. 汇报（强制字段）

```markdown
## 改动摘要
- 语言: {lang} | 文件数: {N} | 类型: {类型} | 风险: {等级}

## 并发产出
- Phase 1: explorer + get_architecture + researcher → {N}/3 成功
- Phase 3: {N} oracle 并发 → 选定方案 {X}
- Phase 5: 3 reviewer 并发 → 🔴{N}/🟡{N}/🟢{N}

## MCP 调用
- codebase-memory-mcp / context-mode / memory / github / context7: {触发列表}

## 硬约束执行检查（§4 的 13 条）
- [✓/✗] 1-13

## drift_score（若触发 adaptive control）
- {file_overrun}/{loc_overrun}/{unplanned_deps}/{super_decay} → drift = {0.X}
- 决策: 继续 / warning / 重新分解 / 回 Phase 0

## 文件列表 + 验证结果
- path/to/file: {改动} | lint: PASS | type: PASS | test: {M}P/{K}F
```

---

## 7. references 索引（progressive disclosure）

| 文件 | 何时加载 |
|---|---|
| [`phase-0-intent-capture.md`](references/phase-0-intent-capture.md) | Phase 0 触发 AskUserQuestion |
| [`phase-1-metadata-scan.md`](references/phase-1-metadata-scan.md) | Phase 1 开始 |
| [`phase-1-super-check.md`](references/phase-1-super-check.md) | Phase 1 S.U.P.E.R 评分 |
| [`phase-3-design-options.md`](references/phase-3-design-options.md) | Phase 3 复杂任务 |
| [`phase-4-execution-protocol.md`](references/phase-4-execution-protocol.md) | Phase 4 spawn 子 agent |
| [`phase-5-verification.md`](references/phase-5-verification.md) | Phase 5 spawn reviewer |
| [`phase-6-persistence.md`](references/phase-6-persistence.md) | Phase 6 持久化 |
| [`codebase-memory-mcp.md`](references/codebase-memory-mcp.md) | 任 Phase 调 codebase-memory-mcp |
| [`context-mode-integration.md`](references/context-mode-integration.md) | 子 agent 读大文件 / 批量命令 |
| [`memory-tier-strategy.md`](references/memory-tier-strategy.md) | Phase 6 写 memory |
| [`github-integration.md`](references/github-integration.md) | 任务涉及 issue/PR/上游 |
| [`context7-integration.md`](references/context7-integration.md) | 子 agent 写库代码 |
| [`adaptive-control.md`](references/adaptive-control.md) | Phase 4 drift ≥ 0.2 |
| [`hard-constraints.md`](references/hard-constraints.md) | **永远加载**（orchestrator + 所有子 agent） |

---

## 8. 降级策略（失败显性化，符合硬约束 #9）

| 场景 | 降级 | 标注 |
|---|---|---|
| memory MCP 不可用 | 子 agent 裸跑（不回退 legacy）| ⚠️ 无语言经验注入 |
| codebase-memory-mcp 不可用 | grep/glob/Read | ⚠️ 影响分析可能不全 |
| context-mode 不可用 | Read（可能爆 context）| ⚠️ token 成本增加 |
| oracle 并发失败 ≥50% | 串行 1 oracle | ⚠️ 方案多样性降低 |
| reviewer 并发失败 | orchestrator 自审 | ⚠️ 审查深度降低 |
| drift ≥ 0.4 | spawn oracle 重新分解 | 🔒 用户确认新计划 |
| **orchestrator 借口"熟悉项目"跳过 Phase 1 扫描** | **不允许降级**——必须跑 codebase-memory-mcp.get_architecture，失败也必须显式标记 fallback | 🔒 严禁静默跳过 |
| **orchestrator 借口"任务简单"直接编码（违反 §2.2）** | **不允许降级**——必须 spawn 子 agent；唯一例外见 §2.2 全部条件 | 🔒 严禁静默跳过 |
| **Phase 5 reviewer 简化为"自审 + 跑测试"** | 必须至少 spawn 1 个 reviewer 子 agent（正确性维度）；自审只在全部 reviewer 失败时降级 | 🔒 严禁静默简化 |

**绝不静默降级**（R12）。本次执行（fcli 命令重构 2026-06-22）的三大偏离都属于"静默降级"，已加入 §11 Anti-pattern。

---

## 9. 新语言扩展协议

新增语言（TypeScript / Rust / Java）按此协议：

1. 在 `agents/` 新建 `{lang}-coder.md`（参考 `go-coder.md`）
2. 在 `references/legacy/` 提供 4 个种子文件（`{lang}-conventions/traps/tooling/verification.md`）
3. 跑 `scripts/seed-memory.py --lang={lang}` seed 到 memory MCP
4. 在本文件 §3 语言路由表加对应行

缺任一步骤 → 该语言不可用，§3 路由退出"未匹配"。

---

## 10. 相关文件

- 编码子 agent：[`agents/go-coder.md`](agents/go-coder.md) / [`agents/python-coder.md`](agents/python-coder.md)
- 全局子 agent（被本 skill 复用）：`agents/explorer.md` / `agents/oracle.md` / `agents/reviewer.md` / `agents/researcher.md`
- 14 个 references：见 §7
- v3.2 语言 references（待 seed）：`references/legacy/`
- 完整设计文档：[`.deepen/20260622-v5.0/design.md`](.deepen/20260622-v5.0/design.md)（716 行）
- v3.2 SKILL.md 备份：[`snapshots/SKILL-v3.2.md.bak`](snapshots/SKILL-v3.2.md.bak)

---

## 11. Anti-pattern（从历次执行偏离中提炼）

以下反例全部来自真实执行，下次遇到类似情境**必须**识别并拒绝。

### 11.1 "我熟悉项目" → 跳过 Phase 1 扫描

**案例**（fcli 命令重构 2026-06-22）：orchestrator 在 fcli 项目里工作过几小时，判定"已熟悉"，跳过 codebase-memory-mcp.get_architecture，直接手动 grep。

**直接损失**：漏掉 `GoldReserveService.get_history` 方法已存在，gold history 第一次 Edit 用 `container.gold_reserve_store` 直接访问，Pyright 报错后返工。

**正确做法**：`get_architecture` 是**依赖发现**工具，不是"熟悉度检查"。即使昨天刚改过这个项目，今天仍必须跑——代码可能已被别的 session 改动，依赖图可能已变。

### 11.2 "任务简单" → orchestrator 直接编码

**案例**（同上）：判定"命令重构不算复杂"，orchestrator 直接 Edit 5 个命令文件 + 2 个测试，完全没 spawn python-coder。

**直接损失**：主上下文被 9 个文件的代码 diff 污染（本会话已经做过多次重构，上下文压力极大）；gpr 子命令 `-h` 被截获的 UX 问题没被独立 reviewer 发现。

**正确做法**：按 §2.2 判定——5 个命令文件改动不满足"1 个文件 + <20 行"，MUST spawn 子 agent。

### 11.3 "测试过就算验证通过" → 简化 Phase 5

**案例**（同上）：Phase 5 只跑了 `pytest + ruff + 命令 help`，没 spawn reviewer 子 agent。

**直接损失**：UX 层面的问题（`fcli gpr compare -h` 输出根 help 而非子命令 help）在自审中被忽略，最后用户用才发现。

**正确做法**：Phase 5 至少 spawn 1 个 reviewer 子 agent（正确性维度）。自审只在全部 reviewer 失败时降级，必须显式标注 ⚠️。

### 11.4 "靠记忆写第三方库代码"

**案例**（同上）：Typer 的 `list_rates` 函数命名会生成 `list-rates` 命令，需要显式 `name="list"`——orchestrator 靠记忆写错，返工一次。

**直接损失**：1 次返工 + 主上下文多消耗一次 Edit。

**正确做法**：涉及 Typer/Pydantic/aiohttp 等第三方库 API 不确定时，MUST 触发 context7（见 §3.1）。

### 11.5 "汇报时只写完成的"

**案例**（同上）：Phase 5 汇报写"103 passed + ruff clean"，但没显式标注"0 子 agent spawn / 0 reviewer / 2 MCP 跳过"。

**正确做法**：汇报（§6）的"并发产出"和"MCP 调用"字段必须如实列出，偏离协议必须显式标注（不能只写成功的）。这是 R12（失败显性化）在 skill 执行层面的体现。

### 11.6 "简单任务滑坡" → 逐项跳协议

**案例**（fcli 三连修复 2026-06-23）：一次会话连修 3 个 bug（159xxx fund name / gold history rich 渲染 / WGC URL 错误）。每处单独看都"简单"——1 行 / 18 行 / 12 行——于是滑坡：
- 第 1 处：spawn 了 reviewer ✅
- 第 2 处：1 行改动，跳 reviewer ❌
- 第 3 处：18 行 + 真实验证通过，跳 reviewer ❌
- 三处都没调 `memory_search`、都没写 Phase 6 memory、`⚠️ orchestrator_direct_coding` 全部事后在汇报里补

**直接损失**：协议偏离没被即时拦截，最终一次性总结时已经晚了。元层面问题是**"任务看起来简单 → 放松警惕"**——简单的任务恰恰最容易让人跳协议。

**正确做法**：
- **简单的任务更**需要严格走协议——因为容易放松警惕。把"看起来简单"当作**加强**协议执行的信号，而非放松。
- 每次 Edit 前自问：这一处是否触发了 §2.2 / Phase 5 reviewer / memory_search 任一项？触发就必须做。
- 一次会话连续修多个 bug 时，**每个 bug 都重做 Phase 1**（哪怕只是 grep 一次外部依赖），不能"我熟悉了"。

### 11.7 "Edit 前没排查同类模式" → 只修一处

**案例**（fcli 三连修复 2026-06-23）：修 `gold_presenter.py:217` 的 `curr["date"]` 渲染 bug（rich 15.0 不自动 `str()` date 对象），只改了这一处，没 grep 其他 `*_presenter.py` 是否有同样的 `date` 对象直传 `rich.table.add_row` 模式。

**直接损失**：可能漏修同类 bug（fund_presenter / gpr_presenter 等若有同样模式，用户下次又会遇到）。

**正确做法**：**Edit 前 grep 同类模式**（硬约束 #13）。具体执行：
- 修渲染 bug → `grep -rn 'add_row.*date\|\[.date.\]' fcli/utils/`
- 修 URL 构造 → grep 调用方
- 修字段名 → grep 全部引用

只多花一次 grep，避免漏修 + 下一轮返工。这是 R8（先读再写）在"横向排查"维度的扩展。
