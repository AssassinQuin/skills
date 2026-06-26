---
phase: 0
name: phase-0-intent-capture
description: Phase 0 需求确认协议（v6.0 强化版）。多轮 AskUserQuestion + spec.md 生成 + 用户签字。
source: ".deepen/20260625-execution-flow/design.md §3"
status: active
tokens_estimate: 1800
load_priority: on-demand
load_when: "进入 Phase 0"
keywords: multi-turn AskUserQuestion spec.md user signature acceptance checklist phase selection budget
domain: coding
subdomain: phase
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  twelve_factor:
    - XI. Logs - 当作事件流
  notes: "需求清晰度 = 减少返工（Lean）"
---

# Phase 0: 需求确认（v6.0 强化版）

> v5.0 单轮意图捕获 → v6.0 多轮追问 + spec.md 生成 + 用户签字。
> 这是"用户主导"的第一个体现：**spec 没确认不开干**。
> **加载时机**：orchestrator 进入 Phase 0（每次新 spec 启动）。

## 0.0 前置检查

读 `.claude/coder-state/current.json`：
- 存在 → AskUserQuestion: 续跑 / 查看进度 / 重新开始 / 永不问
- 不存在 → 跑 `bash scripts/coder-state.sh init --slug {slug}`

## 子步骤

### 0.1 意图捕获 + 复述

orchestrator 把用户原始请求**一句话复述** + 关键词提取：

```
用户原话：{verbatim}
Agent 复述：{one-sentence summary}
关键词：{comma-separated}
```

AskUserQuestion：**"我理解对了吗？"**
- ✅ 确认
- ✏️ 修改（用户重新描述）
- ❌ 完全不对（用户重新讲）

不通过则循环 0.1，直到用户确认。

### 0.2 多轮追问（一次 AskUserQuestion 4 个并行问题）

```
AskUserQuestion([
  {
    question: "这个需求的优先级？",
    header: "Priority",
    options: [
      "must（阻塞业务）",
      "nice-to-have（优化体验）",
      "experiment（验证想法）"
    ]
  },
  {
    question: "验收 checklist？",
    header: "Acceptance",
    multiSelect: true,
    options: [
      "功能 X 能跑（演示通过）",
      "测试覆盖 Y（≥N 个新 test）",
      "文档更新 Z",
      "类型检查 PASS",
      "lint PASS",
      "无新依赖（除非显式允许）"
    ]
  },
  {
    question: "时间预算？",
    header: "Budget",
    options: [
      "30 分钟（小修）",
      "2 小时（中等）",
      "半天+（大改）",
      "不确定（让 agent 估）"
    ]
  },
  {
    question: "哪些 Phase 必跑？",
    header: "Phases",
    multiSelect: true,
    options: [
      "(推荐) Phase 0.5 复用 + 替代分析",
      "(推荐) Phase 3 设计方案 + test-plan",
      "(可选) Phase 4.5 子 agent 交付检查",
      "(必跑) Phase 5 reviewer + test",
      "(可选) Phase 7 归档"
    ]
  }
])
```

### 0.2b Module Sketch 追问（v6.2 新增，from to-prd）

orchestrator 在 spec.md 生成前，基于 0.1 复述 + 0.2 用户回答，提出 **module 划分候选**：

```
AskUserQuestion({
  question: "我建议的 module 划分（每个 module 是 deep module 候选 = 简单接口 + 大功能 + 可测）",
  options: [
    "同意建议的 module 划分",
    "拆更细（我觉得 X module 太大）",
    "合并（X 和 Y 应该是一个 module）",
    "重新规划（让 oracle 在 Phase 0.5/3 重新做）"
  ]
})
```

deep module 候选清单（orchestrator 推断）：
- `LoginService`：接口 2 method / 封装 auth+session+audit / 可 mock
- `LoginValidator`：可能太浅，考虑合并到 LoginService

用户确认后写入 spec.md `Module Sketch` 段。

### 0.3 生成 spec.md

按 [`templates/spec.md.template`](../templates/spec.md.template) 渲染，写到：
```
.claude/coder-state/specs-active/{ts}-{slug}/spec.md
```

字段填充规则：
- `USER_RAW_INPUT`: 用户原始请求（verbatim）
- `AGENT_RESTATED`: agent 复述（已 0.1 确认）
- `ACCEPTANCE_CHECKLIST`: 0.2 Q2 用户选 + agent 补充的明确验收点
- `PHASE_0_5/3/4_5/7`: 0.2 Q4 用户选 → ✅ / ❌
- `BUDGET_MINUTES`: 0.2 Q3 解析（"30 分钟" → 30）
- `AUTO_PHASES`: `["Phase 1", "Phase 2"]`（这些不需要签字，自动跑）
- `ALLOWED_DEPS`: 默认空（除非用户在 0.2 显式列）
- `OUT_OF_SCOPE`: agent 推断 + 用户确认（"不动 X / 不引 Y / 不改 Z"）

### 0.4 用户签字 + 状态持久化

```
USER_HASH=$(echo "$USER|$TS|$(cat spec.md)" | sha256sum | cut -c1-16)

# 写入 spec.md 末尾
# 写入 state.json
bash scripts/coder-state.sh update-phase "Phase 0" completed
```

state.json 自动推进 `current_phase` 到下一个（Phase 0.5 或 Phase 1）。

## AskUserQuestion 高频反模式

### ❌ 一次问太多

AskUserQuestion 上限 4 个问题。超过用户疲劳。

### ❌ 用开放式问题

❌ "你想怎么做？" → 用户负担重
✅ 选择题 + "Other" 兜底

### ❌ 中间反复打断

Phase 0 一次问全，后续 Phase 1/2 自动跑（除非 spec 里选了"必须签字"）。

## spec.md 必填字段（agent 渲染时核对）

| 字段 | 来源 | 缺省 |
|---|---|---|
| `USER_RAW_INPUT` | 0.0 verbatim | 必填 |
| `AGENT_RESTATED` | 0.1 复述 | 必填 |
| `ACCEPTANCE_CHECKLIST` | 0.2 Q2 | 必填 |
| `PHASE_*` | 0.2 Q4 | ✅/❌ |
| `BUDGET_MINUTES` | 0.2 Q3 | 必填 |
| `AUTO_PHASES` | 默认 `[Phase 1, Phase 2]` | — |
| `ALLOWED_DEPS` | 0.2 用户列 | `（无）` |
| `OUT_OF_SCOPE` | agent 推断 + 确认 | 必填 |
| `USER_HASH` | sha256 | 必填 |

## 与 v5.0 的差异

| 维度 | v5.0 | v6.0 |
|---|---|---|
| 意图确认 | 单轮 | 多轮 + 复述 |
| spec.md | 不生成 | 强制生成 + 用户签字 |
| Phase 选择 | 全跑 | 用户选 |
| 时间预算 | 无 | 显式 |
| 允许依赖 | 无 | 显式 allowlist |
| Phase 跳过 | "简单任务"模糊判断 | spec 明确列出 |

## 退出条件

Phase 0 → Phase 0.5 / Phase 1（按用户选择）：
- ✅ spec.md 已生成（必填字段齐全）
- ✅ state.json `phases["Phase 0"] = completed`
- ✅ `user_signed_hash` 已记录
- ✅ 用户在 AskUserQuestion 里点了"确认"

任何缺项 → 留在 Phase 0，不允许进 Phase 1。

## 引用

- 设计：[`.deepen/20260625-execution-flow/design.md`](../.deepen/20260625-execution-flow/design.md) §3 Phase 0
- spec 模板：[`templates/spec.md.template`](../templates/spec.md.template)
- state 管理：[`scripts/coder-state.sh`](../scripts/coder-state.sh)
- 下游：[`phase-1-metadata-scan.md`](phase-1-metadata-scan.md)
