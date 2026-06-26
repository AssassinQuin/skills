---
phase: 6
name: phase-6-persistence
description: Phase 6 持久化 — 3 层记忆（memory MCP + MASTER.md + codebase-memory-mcp 增量索引）+ 经验提炼流程。
source: "design.md §5.7 + §7.3"
status: skeleton
tokens_estimate: 1000
load_priority: on-demand
load_when: "进入 Phase 6"
keywords: memory MCP write delivery-checklist handoff view user signature archive
domain: coding
subdomain: phase
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  twelve_factor:
    - XI. Logs - 当作事件流
  notes: "handoff + 交付清单 + memory 沉淀"
---

# Phase 6: 持久化（orchestrator 内联）

> **加载时机**：Phase 5 验证通过后。

## 3 层记忆

### 1. memory MCP（按 tag + tier）

按 `memory-tier-strategy.md` 的 tag 表写入。子 agent 写项目级；
共享/全局级必须 orchestrator + 🔒 用户确认（Q8）。

### 2. MASTER.md 跨 session 进度（项目根 + gitignore，Q3）

```markdown
# Coder Progress — {project}

## Current Task
- [ ] task N: {description} — in_progress

## Completed
- [x] task N-1: {description} — 2026-06-22

## Blocked
- [ ] task X: blocked by {reason}

## Notes
- {key decisions}
```

### 3. codebase-memory-mcp 增量索引

若 `codebase_indexed=true`：触发 `index_repository`（incremental 模式）。
失败 → ⚠️ 不阻塞。

## 经验提炼流程（写回 memory）

每次 coder 跑完，orchestrator 判断是否发现新经验：

| 触发 | 内容 | tag | tier | 用户确认? |
|---|---|---|---|---|
| 新坑（未在 memory 中） | "踩坑: {描述}。正确做法: {做法}" | `coding-{lang}-gotcha` | 项目级 | 否 |
| 通用坑（跨项目） | 提议升级 | `coding-{lang}-trap` | 共享级 | 🔒 是 |
| 新 convention | "发现: {语言} 中 {模式}" | `coding-{lang}-convention` | 共享级 | 🔒 是 |
| 工具链发现 | "环境: {工具} 关键命令" | `coding-{lang}-tooling` | 共享级 | 🔒 是 |
| 审计发现 | "审计: {代码类型} 常见问题" | `coding-audit-finding` | 项目级 | 否 |
| S.U.P.E.R 衰减 | "{模块} 从 X → Y 因 {原因}" | `coding-super-decay` | 共享级 | 🔒 是 |
| 用户反馈偏好 | "用户偏好 {X}" | `coding-user-pref` | 全局级 | 🔒 是 |

## 去重（避免冗余）

写共享级前先 `memory_search`：
- semantic 相似度 ≥0.85 → 视为重复，跳过或合并
- 同 tag 已有 ≥10 条相似 → 提示用户清理

## 汇报（强制）

经验总结**不可跳过**（即使无新经验也输出"本次无新经验"确认 — v3.2 继承）。

## 失败场景

| 场景 | 行为 |
|---|---|
| memory MCP 不可用 | 标 ⚠️ + 跳过写入 + 汇报"经验未持久化" |
| MASTER.md 写失败 | 标 ⚠️ + 继续（不阻塞）|
| codebase-memory-mcp 索引失败 | 标 ⚠️ + 不重试（用户可手动跑）|

## TODO（待 step 2 扩充）

- [ ] MASTER.md 模板的完整字段
- [ ] 经验去重的具体阈值
- [ ] 跨 session 续传流程（/clear 后如何 lookup）

## 引用

- design.md §5.7 + §7.3
- `memory-tier-strategy.md`（tag + tier 完整表）
- `codebase-memory-mcp.md`（增量索引）
