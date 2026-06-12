# Directory Guide

Detailed anatomy, progressive disclosure patterns, and agent config format. Read when designing a new skill's structure.

## Anatomy

### SKILL.md (required)

- **Frontmatter** (YAML): `name` + `description` (required). Description is the primary trigger — include what the skill does AND specific "when to use" scenarios.
- **Body** (Markdown): Instructions for executing the skill. Only loaded AFTER triggering.

### README.md (required)

User-facing documentation. Every skill MUST have one. Contains:
- What the skill does (1-2 sentences)
- Trigger words
- Quick start examples (2-3 prompts)
- Workflow overview
- Directory structure
- Related skills

### agents/claude-code.yaml (recommended)

Sub-agent orchestration config. Format:

```yaml
interface:
  display_name: "Skill Name"
  short_description: "One-line description"
  trigger_words: ["trigger1", "trigger2"]
  default_prompt: "Use $skill-name to ..."

agents:
  - role: "role-name"
    model: "haiku|sonnet|opus"
    description: "What this agent does"

workflow:
  - step: "step-name"
    agent: "role-name"  # or null for main agent
    output: "what this step produces"
```

Model assignment: haiku for deterministic/fast tasks, sonnet for standard reasoning, opus for strategic decisions.

### references/ (as needed)

Documentation loaded on demand. Use when:
- SKILL.md approaches 200 lines
- Content varies by scenario (e.g., per-language guides)
- Detailed API docs, schemas, or policies

Rules:
- Keep one level deep from SKILL.md
- Files > 100 lines: add table of contents at top
- Reference from SKILL.md: `See references/{file}.md for {purpose}.`

### scripts/ (as needed)

Executable code for deterministic reliability. Use when:
- Same code is rewritten repeatedly across invocations
- Operations are fragile and need consistency
- Validation or scaffolding tasks

### evals/ (optional)

Quality checklists and evaluation rubrics. Use when:
- Skill output quality needs consistent verification
- Multiple evaluation criteria exist
- Scoring rubric helps calibrate output quality

### assets/ (optional)

Files used in output (templates, images, fonts). Not loaded into context — used directly in produced artifacts.

## Progressive Disclosure Patterns

### Pattern 1: High-level guide with references

```
SKILL.md (overview + core workflow)
└── references/
    ├── advanced-feature-A.md
    ├── advanced-feature-B.md
    └── api-reference.md
```

### Pattern 2: Multi-domain organization

```
SKILL.md (overview + domain selection)
└── references/
    ├── domain-a.md
    ├── domain-b.md
    └── domain-c.md
```

### Pattern 3: Conditional details

```markdown
## Basic usage
[basic instructions]

**For advanced feature X**: See references/feature-x.md
**For framework Y**: See references/framework-y.md
```

## Anti-patterns

- **Do not** duplicate information across SKILL.md and references/
- **Do not** create deeply nested references (>1 level from SKILL.md)
- **Do not** add "About" or "Introduction" sections — jump to workflow
- **Do not** include verbose examples in SKILL.md — put them in references/
- **Do not** leave TODO placeholders in production skills
