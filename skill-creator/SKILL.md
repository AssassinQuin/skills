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
├── agents/                     # Sub-agent orchestration (when needed)
│   ├── claude-code.yaml        # Role declarations + workflow
│   └── {role}.md               # Per-agent prompt templates (when needed)
├── references/                 # Detailed guides loaded on demand
├── scripts/                    # Automation scripts (if needed)
└── evals/                      # Quality checklists (optional)
```

For detailed anatomy and progressive disclosure patterns, read `references/directory-guide.md`.

## 子 Agent 使用规范（重要）

### 何时需要 agents/

**需要**（必须 skill-local）：
- skill 有专用的、不共享的 subagent_type（如 `scout-*` / `dim-*`）
- skill 引用的 subagent_type 在 `~/.claude/agents/` 中不存在
- 多个 skill-local agent 协作（编排器 + 维度 agent 模式）

**不需要**（用全局或内置即可）：
- 只用 Claude Code 内置 subagent_type（`Explore` / `general-purpose`）
- 只用通用 personal agent（`coder` / `oracle` / `researcher` / `reviewer` / `explorer` / `Plan` 已在 `~/.claude/agents/`）
- skill 本身不 spawn 子 agent

### agents/ 目录结构

```
{skill}/agents/
├── claude-code.yaml          # 必需：声明所有 role + workflow
├── {role-1}.md               # 可选：每个 role 的详细 prompt 模板
├── {role-2}.md
└── ...
```

### claude-code.yaml 格式

```yaml
interface:
  display_name: "Skill Name"
  short_description: "One-line description"
  trigger_words: ["关键词1", "关键词2"]
  default_prompt: "Use {skill} to ..."

agents:
  - role: {role-name}                    # 必须与 SKILL.md 中的 subagent_type 一致
    model: haiku|sonnet|opus              # R5.1：禁止省略 model
    description: |                        # 一句话说明职责
      该 agent 的任务描述...

workflow:
  - step: {step-name}
    agent: {role-name}|null              # null = 主 agent 执行
    output: "该步骤的输出"

scripts:
  enforce: "scripts/{script}.sh"          # 可选
```

### SKILL.md 中调用子 agent

**用 `Agent` 工具**（不是 `TaskCreate`）：

```
Agent(
  subagent_type="{role-name}",     # 来自 agents/claude-code.yaml 的 role
  model="sonnet",                  # R5.1：显式指定，不省略
  description="任务描述",
  prompt="详细指令..."
)
```

**禁止**：
- ❌ 用 `TaskCreate(...)` 试图启动子 agent（TaskCreate 只是任务列表管理）
- ❌ 在 SKILL.md 引用不存在的 subagent_type（必须先在 agents/ 中定义）
- ❌ 省略 model 参数（违反 R5.1）

### 决策流程：何时创建 skill-local agents/

```
skill 需要 spawn 子 agent？
├── 否 → 不创建 agents/
└── 是 → subagent_type 已在 ~/.claude/agents/ 或 Claude 内置？
    ├── 是（如 Explore / general-purpose / oracle）→ 直接用，不创建 skill-local
    └── 否（专用 role 如 scout-gh / dim-world）→ 创建 skill-local agents/
        ├── agents/claude-code.yaml（声明 role + model + workflow）
        └── agents/{role}.md（详细 prompt 模板，可选但推荐）
```

### 参考实例

- `novel-distill/agents/`：6 个 dim-*.md + claude-code.yaml，编排器 + 维度并行模式
- `skill-search/agents/`：5 个 scout-*.md + claude-code.yaml，5 子 agent 并行 Scout 模式
- `skill-creator/agents/`：claude-code.yaml 声明 architect/writer/validator（用全局通用 role）

## Phase Flow

### Phase 1: Initialize (MUST run script)

```bash
scripts/init_skill.py <skill-name> --path <output-dir>
```

Output: directory with SKILL.md template, README.md template, agents/ template.

After initialization, customize based on the user's requirement. If skill already exists, skip to Phase 2.

### Phase 2: Draft

1. **Gather requirements** — Ask user for: purpose, trigger scenarios, key workflow steps. Max 3 questions per round.
2. **Plan resources** — Identify which of references/, scripts/, evals/, agents/ are needed. See "子 Agent 使用规范" above + `references/directory-guide.md`.
3. **Write SKILL.md** — Lean body (<200 lines). Push detailed content to references/. Follow principles below.
4. **Write README.md** — Trigger words, quick start, workflow overview, directory structure, related skills.
5. **Write agents/claude-code.yaml** (when skill uses sub-agents) — Define sub-agent roles. Follow "子 Agent 使用规范" above.

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
- [ ] If SKILL.md references subagent_type → agents/claude-code.yaml exists with matching role
- [ ] agents/claude-code.yaml 中每个 role 有对应 .md 模板 OR 全局 ~/.claude/agents/ 中存在
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
4. SKILL.md 引用的 subagent_type 必须在 agents/claude-code.yaml 中声明，或在 `~/.claude/agents/` 全局存在，或为 Claude 内置（`Explore`/`general-purpose`）
5. No duplicate information across SKILL.md and references/ — each fact lives in one place
6. Every generated skill MUST include README.md — this is user documentation, not AI context
7. Frontmatter description is the trigger — invest in writing it well
