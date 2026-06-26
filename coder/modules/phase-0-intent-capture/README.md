# Phase 0: Intent Capture (Module)

独立 module of coder skill v7.0+。负责需求确认（多轮 AskUserQuestion + spec.md + 用户签字）。

## 用途

- Phase 0 子流程：把用户请求转成可签字的 spec.md
- 强制"用户主导"——spec 没确认不开干

## 内容

- `SKILL.md`：完整 Phase 0 协议（~1800 tokens）
- `scripts/gen-spec.py`：spec.md 渲染器（从 AskUserQuestion 答案 + 用户输入）
- `assets/spec-template.md`：spec.md 模板（11 必填字段）

## 独立使用

```bash
python3 scripts/gen-spec.py \
    --slug "add-login" \
    --user-input "加个登录功能" \
    --restated "实现 user login，复用 LoginService" \
    --acceptance "功能能跑,测试 80%" \
    --phase-0_5 yes --phase-3 yes --phase-4_5 no --phase-7 yes \
    --budget 120
```

## 输入 / 输出

| 输入 | 来源 |
|---|---|
| 用户原话 | 用户消息 |
| 复述 | orchestrator 0.1 |
| acceptance / phase / budget | AskUserQuestion 0.2 |

| 输出 | 路径 |
|---|---|
| spec.md | `.claude/coder-state/specs-active/{ts}-{slug}/spec.md` |
| user_signed_hash | state.json `phases["Phase 0"].user_signed_hash` |

## 框架映射

- 12-Factor: XI (logs) - spec.md 是审计日志一部分
- Lean: 需求清晰度 = 减少返工

## 上游 / 下游

- 上游：用户消息
- 下游：[`phase-0.5-reuse-analysis`](../phase-0.5-reuse-analysis/) 或 [`phase-1-metadata-scan`](../phase-1-metadata-scan/)
