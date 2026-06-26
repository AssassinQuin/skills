# Phase 4: Execution Protocol (Module)

独立 module of coder skill v7.0+。负责执行（vertical tracer-bullet slice 分组 + lang-coder spawn）。

## 用途

- Phase 4 子流程：按 user behavior 分组 spawn 多个 lang-coder-project
- 反 horizontal slicing（来自 tdd）

## 内容

- `SKILL.md`：完整 Phase 4 协议（~1800 tokens）
- `scripts/group-vertical-slices.py`：从文件改动 + behaviors 推 slice 分组
- `assets/`：lang-coder prompt 模板占位

## 独立使用

```bash
python3 scripts/group-vertical-slices.py \
    --files-changed src/auth/login.py,src/auth/api.py,tests/test_login.py \
    --user-behaviors "用户能登录,用户错密码失败"
```

输出示例：
```
## Slice 1: 用户能登录 [AFK]
  Layers: logic + api + tests
  Files: src/auth/login.py, src/auth/api.py, tests/test_login.py
```

## 核心原则

- **vertical slice**：贯穿所有层（schema + API + logic + tests），独立 demoable
- **HITL vs AFK**：能 AFK（自动 merge）的不要标 HITL
- **上限 5 个 slice 并发**：防 token 爆炸

## 框架映射

- SOLID: SRP（vertical slice = 单一 user behavior）
- 12-Factor: I (codebase), VII (port binding)

## 子 agent

spawn `{lang}-coder-project` × N（按 slice 分组），每个返回 `delivery-schema.yaml`。

## 上游 / 下游

- 上游：[`phase-3-design-options`](../phase-3-design-options/) / [`phase-2.5-prototype`](../phase-2.5-prototype/)
- 下游：[`phase-4.5-delivery-validation`](../phase-4.5-delivery-validation/)
