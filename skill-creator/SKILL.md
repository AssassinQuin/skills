---
name: skill-creator
description: "Create, update, or validate AI skills (SKILL.md + supporting files). Trigger when user says: create skill, new skill, 写个 skill, 创建 skill, skill 模板, 新建 skill, update skill, edit skill, modify skill, skill-creator, init skill, validate skill. Generates complete skill directory with SKILL.md, README.md, agents/ config, and references/"
---

# Skill Creator

Command-driven skill factory with sub-agent orchestration and enforced validation.

## Decision Table

| Intent | Mode | Path |
|--------|------|------|
| "创建/new skill" | CREATE | init → draft → validate → package |
| "更新/update skill" | EDIT | load → edit → validate → package |
| "验证/validate skill" | CHECK | validate only |
| "打包/package skill" | PACKAGE | validate → package |

## Sub-Agents

| Role | Model | Task |
|------|-------|------|
| architect | haiku | Directory structure planning, naming, frontmatter generation |
| writer | sonnet | SKILL.md content, README.md, references/ content |
| validator | haiku | quick_validate.py execution, structure completeness check |

## Standard Directory Template

Every new skill MUST follow this structure:

```
{skill-name}/
├── SKILL.md                    # Core instructions (required)
├── README.md                   # User docs: trigger, workflow, structure
├── agents/
│   └── claude-code.yaml        # Sub-agent orchestration config
├── references/                 # Detailed guides loaded on demand
├── scripts/                    # Automation scripts (if needed)
└── evals/                      # Quality checklists (optional)
```

For detailed anatomy and progressive disclosure patterns, read `references/directory-guide.md`.

## Phase Flow

### Phase 1: Initialize (MUST run script)

```bash
scripts/init_skill.py <skill-name> --path <output-dir>
```

Output: directory with SKILL.md template, README.md template, agents/ template.

After initialization, customize based on the user's requirement. If skill already exists, skip to Phase 2.

### Phase 2: Draft

1. **Gather requirements** — Ask user for: purpose, trigger scenarios, key workflow steps. Max 3 questions per round.
2. **Plan resources** — Identify which of references/, scripts/, evals/ are needed. See `references/directory-guide.md` for guidance.
3. **Write SKILL.md** — Lean body (<200 lines). Push detailed content to references/. Follow principles below.
4. **Write README.md** — Trigger words, quick start, workflow overview, directory structure, related skills.
5. **Write agents/claude-code.yaml** — Define sub-agent roles if the skill uses agents. Follow `references/directory-guide.md` agent config format.

Assign to sub-agents:
- **architect** (haiku): frontmatter, directory layout, agents/ config
- **writer** (sonnet): SKILL.md body, README.md, references/ content

### Phase 3: Validate (MUST run script)

```bash
scripts/quick_validate.py <skill-path>
```

If validation fails: fix reported errors, re-run. Do NOT proceed to Phase 4 until validation passes.

Then run **structural completeness check**:
- [ ] SKILL.md has name + description in frontmatter
- [ ] README.md exists with trigger + workflow sections
- [ ] agents/claude-code.yaml exists (or skill genuinely needs no sub-agents)
- [ ] references/ files referenced from SKILL.md actually exist
- [ ] No TODO placeholders remain

### Phase 4: Package (MUST run script, only when requested)

```bash
scripts/package_skill.py <skill-path> [output-dir]
```

Outputs distributable `.skill` file.

## Core Principles

**Concise is Key** — Context window is shared. Only add what Claude doesn't already know. Challenge each line: "Does this justify its token cost?"

**Degrees of Freedom** — High freedom (text instructions) for flexible tasks. Low freedom (scripts) for fragile, consistency-critical operations.

**Progressive Disclosure** — SKILL.md = trigger + core workflow. references/ = details loaded on demand. Three levels: metadata → SKILL.md body → references/.

For detailed guidance on these principles with examples, read `references/directory-guide.md`.

## SKILL.md Writing Rules

**Frontmatter**: `name` + `description` only. Description MUST include what the skill does AND when to use it (trigger scenarios). This is the primary triggering mechanism — "when to use" info goes here, not in the body.

**Body**: Imperative/infinitive form. No "About" or "Introduction" sections — jump straight to the decision table or workflow.

**References**: If SKILL.md approaches 200 lines, split content. Move detailed guides to references/. Reference them with: `See references/{file}.md for {purpose}.`

## Constraints

1. Scripts MUST be called via Bash — no manual equivalent for init/validate/package
2. Sub-agent model assignment follows R5.1: haiku for deterministic, sonnet for creative/reasoning, opus for strategic
3. No duplicate information across SKILL.md and references/ — each fact lives in one place
4. Every generated skill MUST include README.md — this is user documentation, not AI context
5. Frontmatter description is the trigger — invest in writing it well
