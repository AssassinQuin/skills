# Skill Creator

Guide for creating effective AI skills (SKILL.md files). Covers skill anatomy, progressive disclosure, degrees of freedom, and validation. Includes scripts for scaffolding and packaging.

## Trigger

创建 skill、create skill、新建 skill、skill-creator、skill 模板

## Quick Start

```
/skill-creator 创建一个新的代码审查 skill
/skill-creator 我想做一个自动化部署的 skill
```

## Workflow

1. **Understand Intent** — What should the skill do? When should it trigger?
2. **Quick Start or Advanced** — Auto-detect complexity, offer appropriate template
3. **Progressive Disclosure** — Structure information in layers (trigger → core → details)
4. **Validation** — Use `scripts/quick_validate.py` to check quality
5. **Packaging** — Use `scripts/package_skill.py` for distribution

## Key Principles

### Concise is Key
Every token in SKILL.md costs context window space. Cut ruthlessly.

### Degrees of Freedom
Set appropriate constraints — too few = unpredictable behavior, too many = rigid and fragile.

### Progressive Disclosure
Layer information: trigger conditions first, core behavior second, edge cases last.

## Directory Structure

```
SKILL.md                    # Core instructions
references/
  workflows.md              # Common skill workflow patterns
  output-patterns.md        # Output format patterns
scripts/
  init_skill.py             # Scaffold a new skill directory
  package_skill.py          # Package skill for distribution
  quick_validate.py         # Validate SKILL.md quality
```

## See Also

- skill-evolver — Evolve existing skills
- darwin-skill — Evaluate skill quality with rubric
- huashu-nuwa — Distill expert thinking into skills
