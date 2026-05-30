# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A unified AI skill library. 34 skills distributed via directory-level symlinks to 6 tool directories (Claude, OpenCode, Trae, Cursor, Agents, opencode). No build system, no tests, no CI. Skills are Markdown files consumed by AI tools at runtime. Includes 13 skills from mattpocock/skills (hidden by default).

## Skill Structure

Every skill lives in `<skill-name>/SKILL.md` with YAML frontmatter (required: `name`, `description`) plus Markdown body. Optional dirs: `references/`, `scripts/`.

Frontmatter fields: `name`, `description`, `allowed-tools`, `license`, `hidden`, `user-invocable`, `hooks`, `metadata.version`.

Languages: mostly English, some Chinese (huashu-nuwa, pua-debugging), traditional Chinese (storytelling).

## Distribution (Directory-Level Symlinks)

Each tool's skills directory symlinks directly to this repo. Adding/removing a skill here auto-syncs all tools.

```bash
# Re-initialize all symlinks
for dir in ~/.trae/skills ~/.config/opencode/skills ~/.opencode/skills ~/.claude/skills ~/.agents/skills ~/.cursor/skills; do
  rm -rf "$dir" && ln -s /Users/ganjie/skills "$dir"
done
```

## Nested Git Repos

Two skills are nested git repos (NOT submodules) — changes inside them require separate git operations from within their directories:

- `planning-with-files/` — branch: master, upstream: OthmanAdi/planning-with-files
- `humanizer/` — branch: main, upstream: blader/humanizer

Update pattern for nested repos:
```bash
cd <skill-dir> && git fetch upstream && git merge upstream/<branch> && git push origin <branch>
```

Other upstream skills (skill-seekers, huashu-nuwa, storytelling, prose-craft) are manually synced — upstream structures are incompatible, only SKILL.md is carried over.

## Key Architecture Patterns

- **Memory skill** (`memory/`): Cross-skill memory API with MCP tools (`memory_memory_*`). Three-tier isolation: project/shared/global. Must be loaded before calling any memory MCP tool.
- **Skill Evolver** (`skill-evolver/`): Evolution framework for SKILL.md optimization. Based on [darwin-skill](https://github.com/alchaincyf/darwin-skill) rubric concepts. Includes FM1-FM7 failure mode diagnostics in `references/failure-modes.md`.

## mattpocock/skills (6 hidden, 6 visible)

12 skills sourced from [mattpocock/skills](https://github.com/mattpocock/skills) (104k stars). Visible: tdd, diagnose, caveman, handoff, to-prd, to-issues. Hidden: grill-with-docs, improve-codebase-architecture, prototype, triage, git-guardrails-claude-code, agent-browser. Hidden skills can still be invoked but don't clutter the skill list.
- **Huashu-nuwa** (`huashu-nuwa/`): Generates perspective skills from research. Contains 8 example sub-skills in `examples/`.

## Docker / MCP Servers

`dockerfile/` contains Docker configs for MCP servers: `searxng-mcp`, `github-mcp-server`, `one-search-mcp`.

## Git Notes

- `AGENTS.md` is excluded from git (contains local paths) via `.gitignore`
- `web-research/data/` is excluded (local research artifacts)
- `huashu-nuwa/` is 18M+ (contains images), not a nested repo
