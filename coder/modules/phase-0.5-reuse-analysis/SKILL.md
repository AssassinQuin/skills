---
phase: 0.5
name: phase-0.5-reuse-analysis
description: Phase 0.5 复用 + 替代分析。explorer 项目内扫描 + researcher 外部调研 + oracle 决策。
source: ".deepen/20260625-execution-flow/design.md §3"
status: active
tokens_estimate: 1200
load_priority: on-demand
load_when: "进入 Phase 0.5"
keywords: reuse report explorer researcher oracle internal external alternatives
domain: coding
subdomain: phase
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  solid:
    - Don't Repeat Yourself（DRY）
  notes: "DRY 原则 + 复用优于自造"
---

# Phase 0.5: 复用 + 替代分析（v6.0 新增）

> **加载时机**：Phase 0 用户选了 Phase 0.5（推荐）。
> **目的**：避免重复造轮子 + 用现成的更好实现。

## 3 个 subagent 并发

| Subagent | model | 任务 | 输出文件 |
|---|---|---|---|
| `explorer` | haiku | 在本 codebase 找同类实现 | `reuse-internal.md` |
| `researcher` | sonnet | 在 GitHub / PyPI / pkg.go.dev / npm 找现成方案 | `reuse-external.md` |
| `oracle` | opus | 评估"复用 vs 自造 vs 替代" | `reuse-decision.md` |

3 个 agent 在**一条消息里并发 spawn**（Claude Code 自动并行）。

## 1. explorer 任务（haiku）

**输入**：
- spec.md（用户需求）
- codebase 路径

**任务**：
1. 调 `codebase-memory-mcp.search_graph` 找语义相关函数 / 类
2. 调 `codebase-memory-mcp.get_architecture` 看模块结构
3. grep 同类关键词（spec 提取的）

**输出**（reuse-internal.md）：
```markdown
## 项目内可复用（explorer）

| 现有代码 | 复用方式 | 改动量 | 风险 |
|---|---|---|---|
| `auth/login.py:42 LoginService` | 直接用 | 0 | low |
| `utils/validator.py:email` | 扩展 | +5 行 | low |
| `db/transaction.py:with_tx` | 已用 | 0 | low |

## 看起来相关但不该用
- `legacy/auth.py:LoginService`（deprecated，勿用）
- 理由：spec.md 要求"不复用 legacy 模块"
```

## 2. researcher 任务（sonnet）

**输入**：
- spec.md
- 项目语言 / 框架

**任务**：
1. WebSearch / GitHub MCP 搜索同类库
2. 评估文档质量 + 维护活跃度
3. 评估集成成本

**输出**（reuse-external.md）：
```markdown
## 外部现成方案（researcher）

| 库 / 项目 | 优势 | 劣势 | 集成成本 | 维护活跃度 |
|---|---|---|---|---|
| `fastapi-login` | 开箱即用 | 灵活性差 | 1h | 中（半年没更新） |
| `authlib` | 标准协议 | 学习曲线 | 3h | 高（活跃） |
| `fastapi-users` | 完整用户系统 | 过度工程 | 5h | 高 |

## 推荐 Top 2
1. **authlib**：标准协议，长期收益高
2. **fastapi-login**：快速集成但维护风险
```

## 3. oracle 任务（opus）

**输入**：
- spec.md
- reuse-internal.md
- reuse-external.md

**任务**：决策"复用 / 自造 / 替代"。

**输出**（reuse-decision.md）：
```markdown
## 决策（oracle）

**推荐**：复用 `LoginService` + 扩展 validator（不引入新依赖）

**理由**：
1. 项目内 LoginService 已存在，0 集成成本
2. 外部库灵活性差，不匹配本项目 N 个定制需求
3. 扩展 validator 比 import authlib 轻

## 反例（用户应避免）
- ❌ 重新写一个 LoginService（重复造轮子）
- ❌ 引入 fastapi-login（违反 spec 的"无新依赖"）
- ❌ 用 legacy/auth.py（deprecated）

## Phase 3 设计需考虑
- LoginService 现有方法是否够用（如不够需扩展）
- validator 扩展点的接口稳定性

## 用户确认
[ ] 同意推荐方案
[ ] 改用：____
```

## 整合到 reuse-report.md

orchestrator 把 3 个 subagent 输出合并：

```
.claude/coder-state/specs-active/{ts}-{slug}/reuse-report.md
```

文件结构：
- §1 项目内可复用（explorer）
- §2 外部现成方案（researcher）
- §3 决策（oracle）

## 用户确认

AskUserQuestion：
```
{
  question: "Phase 0.5 复用决策，你的选择？",
  options: [
    "(推荐) 复用 LoginService + 扩展 validator",
    "引入 authlib（外部库）",
    "自造（不推荐）",
    "查看完整 reuse-report"
  ]
}
```

用户选 → 写入 state.json `phases["Phase 0.5"].reuse_decision`。

## 退出条件

Phase 0.5 → Phase 1：
- ✅ reuse-report.md 已生成
- ✅ 用户已选决策
- ✅ state.json 已记录

## 跳过场景

用户在 Phase 0 没选 Phase 0.5 → 跳过，直接 Phase 1。
但 Phase 1 的 explorer 仍会做基础复用扫描（不带决策）。

## Anti-pattern

### ❌ explorer 没用 codebase-memory-mcp

直接 grep 而非调 `search_graph` → 漏同类模式（§11.1 反例）。

### ❌ oracle 决策没说理由

只说"推荐 X" 不给理由 → 用户无法判断 → AskUserQuestion 卡住。

### ❌ researcher 找了一堆但不评估

列出 10 个库但不分 Top 2 → 用户选择困难。

## 引用

- 设计：[`.deepen/20260625-execution-flow/design.md`](../.deepen/20260625-execution-flow/design.md) §3 Phase 0.5
- 上游：[`phase-0-intent-capture.md`](phase-0-intent-capture.md)
- 下游：[`phase-1-metadata-scan.md`](phase-1-metadata-scan.md)
- 子 agent 配置：[`agents/explorer.md`](../agents/explorer.md) / [`agents/researcher.md`](../agents/researcher.md) / [`agents/oracle.md`](../agents/oracle.md)
