# Phase 4.5: Delivery Validation (Module)

独立 module of coder skill v7.0+。负责子 agent delivery 校验。

## 用途

- Phase 4.5 子流程：所有子 agent delivery 跑 `validate-delivery.py`
- 7 条规则强制（字段齐全 / files vs git diff / drift / verification / deps / caveats / focus_areas）

## 内容

- `SKILL.md`：完整 Phase 4.5 协议（~1200 tokens）
- `scripts/validate-delivery.py`：delivery YAML 校验器
- `assets/delivery-schema.yaml`：delivery 标准格式（v6.2 加 slice 字段）

## 独立使用

```bash
python3 scripts/validate-delivery.py agent-output.md \
    --git-diff \
    --allowed-deps "authlib,redis"
```

## 7 条校验规则

| # | 规则 | 失败 |
|---|---|---|
| 1 | 必填字段齐全 | BLOCK |
| 2 | files_changed 与 git diff 一致 | BLOCK |
| 3 | drift_score < 0.4 | BLOCK → 回 Phase 3 |
| 4 | verification_self ≥ 1 PASS | BLOCK |
| 5 | new_dependencies ⊆ spec.allowed_deps | BLOCK |
| 6 | known_caveats < 5 | WARN |
| 7 | handoff.to_reviewer.focus_areas ≥ 1 | BLOCK |

## 触发 adaptive control

drift_score ≥ 0.4 → 不返工子 agent，回 Phase 3 让 oracle 重新分解。

## 上游 / 下游

- 上游：[`phase-4-execution-protocol`](../phase-4-execution-protocol/)
- 下游：[`phase-5-verification`](../phase-5-verification/)
