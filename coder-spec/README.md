# Coder-Spec

**Phase 0 需求确认协议**。多轮 AskUserQuestion 把模糊需求收敛为 spec.md + 验收 + Phase 选择 + 用户签字。

## Trigger

- `写个 X` / `add feature` / `实现 X` / `refactor Y` 且需求未确认
- 进入 coder 流水线 Phase 0
- 含 "需求不清" / "改 bug 但没复现" 的任务

## Quick Start

```
/coder-spec 给 CLI 加一个 --json 输出参数
```

## Workflow

1. 多轮 AskUserQuestion（输入/输出/边界/验收）
2. 生成 spec.md（spec-template.md）
3. spec-guard hook 校验
4. 复杂度评估 → Phase 选择（用户在 checklist 签字）
5. signature-guard 记录签字
6. 进入 Phase 0.5 / 0.6 / 1

## Directory Structure

```
SKILL.md / assets/spec-template.md / scripts/{spec-guard,signature-guard,spec-template-render} / README.md
```

## Output Format

```
spec.md（输入/输出/验收/边界/Phase 选择）+ user-signature.json
```

## See Also

coder-reuse (Phase 0.5) / coder-debug (Phase 0.6) / coder-metadata (Phase 1) / coder-constraints (硬约束 #1) / coder (主 router)
