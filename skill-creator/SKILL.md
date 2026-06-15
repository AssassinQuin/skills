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
├── references/                 # Detailed guides loaded on demand
├── scripts/                    # Automation scripts (if needed)
└── evals/                      # Quality checklists (optional)
```

For detailed anatomy and progressive disclosure patterns, read `references/directory-guide.md`.

## 子 Agent 使用规范（重要）

Subagent 是**全局基础设施**，不属于任何 skill。所有 subagent 定义集中在仓库根 `skills/agents/`，通过 `scripts/setup-agents.sh` symlink 到 `~/.claude/agents/`。Skill 只**引用**全局 subagent，不 own、不在 skill 目录创建 `agents/`。

### 现有全局 subagent

| Subagent | Model | 典型用途 |
|----------|-------|---------|
| `brainstorm-collider` | sonnet | 创意碰撞（brainstorm 用） |
| `evolver-auditor` | opus | skill 质量审计 |
| `evolver-explorer` | sonnet | skill 进化探索 |
| `explorer` | haiku | 项目扫描、文件搜索 |
| `oracle` | opus | 战略分析、任务拆解、架构规划 |
| `researcher` | sonnet | 外部调研、文档检索 |
| `reviewer` | sonnet | 代码审查、质量审计、报告写作 |

加 Claude 内置：`Explore` / `general-purpose`。

### 调用方式

```
Agent(
  subagent_type="oracle",        # 必须在上表或 Claude 内置中
  model="opus",                  # R5.1：显式指定，禁止省略
  description="任务描述",
  prompt="详细指令..."
)
```

**禁止**：
- ❌ 在 skill 目录创建 `agents/`（违反全局基础设施原则）
- ❌ 引用 `skills/agents/` 表外的 subagent_type（先在仓库根 `skills/agents/` 新增定义）
- ❌ 用 `TaskCreate(...)` 启动子 agent（TaskCreate 只是任务列表管理）
- ❌ 省略 model 参数（违反 R5.1）

## Phase Flow

### Phase 1: Initialize (MUST run script)

```bash
scripts/init_skill.py <skill-name> --path <output-dir>
```

Output: directory with SKILL.md template, README.md template, agents/ template.

After initialization, customize based on the user's requirement. If skill already exists, skip to Phase 2.

### Phase 2: Draft

1. **Gather requirements** — Ask user for: purpose, trigger scenarios, key workflow steps. Max 3 questions per round.
2. **Plan resources** — Identify which of references/, scripts/, evals/ are needed. See "子 Agent 使用规范" above for sub-agent usage.
3. **Write SKILL.md** — Lean body (<200 lines). Push detailed content to references/. Follow principles below.
4. **Write README.md** — Trigger words, quick start, workflow overview, directory structure, related skills.

Assign to sub-agents:
- **architect** (haiku): frontmatter, directory layout
- **writer** (sonnet): SKILL.md body, README.md, references/ content

### Phase 3: Validate (MUST run script)

```bash
scripts/quick_validate.py <skill-path>
```

If validation fails: fix reported errors, re-run. Do NOT proceed to Phase 4 until validation passes.

Then run **structural completeness check**:
- [ ] SKILL.md has name + description in frontmatter
- [ ] README.md exists with trigger + workflow sections
- [ ] SKILL.md 中引用的所有 subagent_type 都在上表全局清单或 Claude 内置（`Explore` / `general-purpose`）中
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
2. Sub-agent model assignment follows R5.1: haiku for deterministic, sonnet for creative/reasoning, opus for strategic. **禁止省略 model**
3. Sub-agent 调用用 `Agent` 工具，**不是** `TaskCreate`（TaskCreate 只是任务列表管理）
4. SKILL.md 引用的 subagent_type 必须在 `skills/agents/` 全局清单中存在，或为 Claude 内置（`Explore`/`general-purpose`）。**禁止**在 skill 目录创建 `agents/`。
5. No duplicate information across SKILL.md and references/ — each fact lives in one place
6. Every generated skill MUST include README.md — this is user documentation, not AI context
7. Frontmatter description is the trigger — invest in writing it well
