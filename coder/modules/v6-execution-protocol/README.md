# v6+ Execution Protocol (Module)

独立 module of coder skill v7.0+。v6.0+ 执行流程完整协议（state / delivery / 断点续跑 / adaptive / memory 自动沉淀）。

## 用途

- `high` 加载（第一次进 v6 Phase / 协议不清时）
- 13 Phase 完整协议 + state schema + Hook 清单 + Adaptive control + Memory 自动沉淀协议

## 内容

- `SKILL.md`：完整协议（~3500 tokens）

## 涵盖

- 13 Phase 流水线（-1 / 0 / 0.5 / 0.6 / 1 / 2 / 2.5 / 3 / 4 / 4.5 / 5 / 6 / 7）
- state.json schema（持久化 + 断点续跑）
- delivery-schema 7 字段 + 7 校验规则
- 14 Hook 强制清单（v6.0 + v6.1）
- Adaptive control（drift ≥ 0.4 触发）
- Memory MCP 自动沉淀（Phase 0.5 / 5 / drift）

## 框架映射

- 12-Factor: IV (backing services), IX (disposability), XI (logs)

## 加载策略

`load_priority: high` — 每次新 spec 启动加载（~3500 tokens 成本）。

## 与其他 module 的关系

- 引用 [`hard-constraints`](../hard-constraints/) + [`anti-patterns`](../anti-patterns/)（always 加载）
- 被 Phase 协议 modules 引用（on-demand）
