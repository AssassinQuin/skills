# Coder-Adaptive

**Adaptive Control** — drift_score 公式 + 决策表 + oracle 重新分解触发条件。

## Trigger

- Phase 4.5 delivery 校验时 drift ≥ 0.4
- 子 agent 实际改动严重偏离估算
- 需要重新分解任务

## Quick Start

```
（自动触发，drift ≥ 0.4 时）
```

## Workflow

1. drift_score = f(file_overrun, loc_overrun, unplanned_deps, super_decay)
2. drift < 0.2 → 接受 delivery
3. 0.2 ≤ drift < 0.4 → 警告但接受
4. drift ≥ 0.4 → spawn oracle 重新分解 + 🔒 用户确认新计划

## Directory Structure

```
SKILL.md / scripts/drift-compute.py / README.md
```

## Output Format

```
drift 报告 + 重分解决策（PASS / WARN / RECOMPOSE）
```

## See Also

coder-execute (Phase 4 触发源) / coder-deliver (Phase 4.5 触发源) / coder-design (重分解时复用) / coder (主 router)
