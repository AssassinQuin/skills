# Skill Evolver

Skill self-evolution framework. Based on [SkillEvolver paper](https://arxiv.org/abs/2605.10500). Command-driven + script-enforced + progressive disclosure + dual-path + deployment grounding audit. v6: paradigm shift from document-style → command-driven, script-enforced invocation.

## Trigger

进化 X skill、审计 X、评估 X 质量、进化 skill-evolver、优化所有 skills、查看进化历史、重写 skill、优化 X 痛点 Y、验证 X skill

## Quick Start

```
/skill-evolver 进化 coder skill
/skill-evolver 审计 web-research 的质量
/skill-evolver 评估 storytelling 评分
/skill-evolver 优化 brainstorm，痛点是产出太发散
```

## Workflow

1. **Command Entry** — Parse intent: evolve / audit / evaluate / rewrite
2. **Value Anchoring** — Score current state, identify pain points
3. **Phase Execution** — Bash-enforced phases via `scripts/evolve.sh` with user confirmation gates
4. **Evolution Comparison** — Before/after metrics display (scores, pain point regression)
5. **Deployment** — Mandatory pain point regression test before merge

## Directory Structure

```
SKILL.md                        # Core instructions
references/
  evolution-strategies.md       # Strategy library for common skill issues
  origin-paper.md               # SkillEvolver paper summary
  failure-modes.md              # FM1-FM7 failure mode diagnostics
  modules/                      # Modular evolution components
scripts/
  evolve.sh                     # Bash-enforced phase execution
```

## Evolution Strategies

The framework includes strategies for: structure optimization, trigger precision, progressive disclosure, failure mode prevention, and output contract tightening.

## See Also

- darwin-skill — Rubric-based evaluation (8 dimensions, 100 points)
- skill-creator — Manual skill creation
- coder — Example of an evolved skill (score 9.0/10)
