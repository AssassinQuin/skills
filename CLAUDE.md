# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A unified AI skill library. 50 skills distributed via directory-level symlinks to 7 tool directories (Claude, OpenCode, Trae, Cursor, Agents, opencode, cc-switch). No build system, no tests, no CI. Skills are Markdown files consumed by AI tools at runtime. Includes 13 skills from mattpocock/skills (hidden by default).

## Skill Structure

Every skill lives in `<skill-name>/SKILL.md` with YAML frontmatter (required: `name`, `description`) plus Markdown body.

Frontmatter fields: `name`, `description`, `allowed-tools`, `license`, `hidden`, `user-invocable`, `hooks`, `metadata.version`.

Languages: mostly English, some Chinese (huashu-nuwa, pua-debugging), traditional Chinese (storytelling).

### Standard Directory Layout

```
<skill-name>/
├── SKILL.md                    # Core instructions (AI consumed, required)
├── README.md                   # User docs: what it does, triggers, workflow, structure
├── references/                 # Reference knowledge loaded by the skill
├── scripts/                    # Automation scripts (shell, python, etc.)
├── examples/                   # Example inputs/outputs (optional)
└── evals/                      # Quality checklists and evaluation rubrics (optional)
```

- **README.md** — User-facing documentation. What the skill does, trigger words, quick start, workflow overview, directory structure, and related skills.

### Global Subagents (`skills/agents/`)

Subagents are Claude Code-level infrastructure, **decoupled from skills**. All subagent definitions live in `skills/agents/` and are symlinked to `~/.claude/agents/` via `scripts/setup-agents.sh`. Skills reference these global subagents by name in their SKILL.md but do **not** own or define them.

This follows the official Claude Code design: subagents live at `~/.claude/agents/` (user-level) or `.claude/agents/` (project-level), independent from `~/.claude/skills/`. See [Subagents docs](https://docs.claude.com/en/docs/claude-code/sub-agents).

| Subagent | Model | Used by |
|----------|-------|---------|
| brainstorm-collider | sonnet | brainstorm |
| evolver-auditor | opus | skill-evolver |
| evolver-explorer | sonnet | skill-evolver |
| explorer | haiku | programmer, coder (v5.0 Phase 1) |
| oracle | opus | programmer, darwin-skill, coder (v5.0 Phase 3) |
| researcher | sonnet | web-research, huashu-nuwa, coder (v5.0 Phase 1 触发式) |
| reviewer | sonnet | darwin-skill, code-review, fin-code-review |
| correctness-reviewer | sonnet | coder (v6.1 Phase 5 正确性维度) |
| project-reviewer | sonnet | coder (v6.1 Phase 5 S.U.P.E.R + 惯例维度) |
| security-reviewer | sonnet | coder (v6.1 Phase 5 安全维度) |
| test-strategist | sonnet | coder (v6.1 Phase 3 test-plan) |

## Distribution (Directory-Level Symlinks)

Each tool's skills directory symlinks directly to this repo. Adding/removing a skill here auto-syncs all tools.

```bash
# Re-initialize all symlinks (skill 分发 + agent 注册)
for dir in ~/.trae/skills ~/.config/opencode/skills ~/.opencode/skills ~/.claude/skills ~/.agents/skills ~/.cursor/skills ~/.cc-switch/skills; do
  rm -rf "$dir" && ln -s /Users/ganjie/skills "$dir"
done
bash ~/.claude/skills/scripts/setup-agents.sh   # 注册 skill agents → ~/.claude/agents/
```

## cc-switch Integration (2026-06-25)

`~/.cc-switch/skills/` was migrated from a real directory (cc-switch's own skill store) to a symlink → `/Users/ganjie/skills`. To prevent the cc-switch GUI from auto-syncing over the symlink, `~/.cc-switch/settings.json` was modified:

- `skillSyncMethod`: `auto` → `manual`
- `skillStorageLocation`: `cc_switch` → `external`

Backup before migration: `~/.cc-switch-backup-20260625-115628.tar.gz` (42M). Rollback: `cd ~/.cc-switch && tar xzf ~/cc-switch-backup-*.tar.gz && rm ~/.cc-switch/skills`.

## Nested Git Repos

Four skills are nested git repos (NOT submodules) — changes inside each require separate git operations from within their directories:

- `humanizer/` — branch: main, upstream: blader/humanizer
- `darwin-skill/` — branch: main, upstream: alchaincyf/darwin-skill (migrated from cc-switch on 2026-06-25)
- `planning-with-files/` — migrated from cc-switch on 2026-06-25 (GitHub clone)
- `skill-audit-skills/` — added 2026-06-25, upstream: LeeFeee/skill-audit-skills

Update pattern for nested repos:
```bash
cd <skill-dir> && git fetch upstream && git merge upstream/<branch> && git push origin <branch>
```

Other upstream skills (skill-seekers, huashu-nuwa, storytelling, prose-craft) are manually synced — upstream structures are incompatible, only SKILL.md is carried over.

## Key Architecture Patterns

- **Memory skill** (`memory/`): Cross-skill memory API with MCP tools (`memory_memory_*`). Three-tier isolation: project/shared/global. Must be loaded before calling any memory MCP tool.
- **Coder** (`coder/`): Multi-language coding meta-skill — router + 7 Phase pipeline + parallel subagents. **v5.0 (2026-06-22)**：progressive disclosure + parallel subagents (Phase 1/3/5) + orchestrator-as-router. Language knowledge lives in **memory MCP** (not `references/` files). SKILL.md ≤200 行 router,14 个 references 按需加载。skill-evolver STRUCTURAL_SCORE：8.1 vs v3.2 的 6.1。完整设计见 `coder/.deepen/20260622-v5.0/design.md`。v3.2 文件归档到 `coder/references/legacy/` 待 seed。
- **Skill Evolver** (`skill-evolver/`): Evolution framework for SKILL.md optimization. Based on [darwin-skill](https://github.com/alchaincyf/darwin-skill) rubric concepts. Includes FM1-FM7 failure mode diagnostics in `references/failure-modes.md`.

## mattpocock/skills (6 hidden, 5 visible)

11 skills sourced from [mattpocock/skills](https://github.com/mattpocock/skills) (104k stars). Visible: tdd, diagnose, handoff, to-prd, to-issues. Hidden: grill-with-docs, improve-codebase-architecture, prototype, triage, git-guardrails-claude-code, agent-browser. Hidden skills can still be invoked but don't clutter the skill list.
- **Huashu-nuwa** (`huashu-nuwa/`): Generates perspective skills from research. Contains 8 example sub-skills in `examples/`.

## Docker / MCP Servers

`dockerfile/` contains Docker configs for MCP servers: `searxng-mcp`, `github-mcp-server`, `one-search-mcp`.

## Sub-Agent MCP Precheck

Subagent 使用运行时降级处理 MCP 工具不可用（v2 协议），不再强制父 agent 预检。每个 agent body 末尾有降级表，工具失败时自动沿链切换。详见 `~/.claude/agents/MCP-PRECHECK.md`。

## Git Notes

- `AGENTS.md` is excluded from git (contains local paths) via `.gitignore`
- `web-research/data/` is excluded (local research artifacts)
- `huashu-nuwa/` is 18M+ (contains images), not a nested repo
