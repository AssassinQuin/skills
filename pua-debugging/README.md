# PUA Debugging (职场 PUA 式调试)

Forces exhaustive problem-solving using corporate PUA rhetoric and structured debugging methodology. When tasks fail 2+ times, activates escalating pressure to break through stuck patterns.

## Trigger

卡住了、stuck、失败 2 次、搞不定、反复出错、pua-debugging、再试试

## Quick Start

```
/pua-debugging 这个 bug 搞了两次还没修好
/pua-debugging 部署又失败了，卡住了
```

## Three Iron Rules

1. **禁止甩锅** — 不准说"环境问题""别人的代码"，先从自己能控制的部分排查
2. **禁止投降** — 不准说"搞不定""建议换方案"，除非穷尽所有路径
3. **禁止假装努力** — 不准只改表面的东西然后说"应该好了"

## Workflow

1. **闻味道 (Smell)** — Diagnose the stuck pattern (repetition? tunnel vision? wrong level?)
2. **揪头发 (Pull Up)** — Elevate perspective, zoom out to system level
3. **照镜子 (Mirror)** — Self-check: what assumptions am I making?
4. **执行新方案 (Execute)** — Try the new approach with verification

## Proactivity Levels

| Level | Behavior | Example |
|-------|----------|---------|
| 0 | Reactive | Waits for user to suggest solutions |
| 1 | Active | Proposes solutions after analyzing |
| 2 | Preemptive | Anticipates failure modes before they happen |
| 3 | Obsessive | Verifies every assumption, every edge case |

## Pressure Escalation

After each failed attempt, pressure increases. The rhetoric shifts from encouraging → challenging → direct confrontation. The goal is to break through cognitive ruts, not to demoralize.

## Directory Structure

```
SKILL.md                    # Core instructions
agents/
  claude-code.yaml          # Sub-agent orchestration config
```

## See Also

- diagnose — Systematic diagnosis skill
- coder — General coding with verification loops
