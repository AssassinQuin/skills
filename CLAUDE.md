# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A unified AI skill library. 28 skills distributed via directory-level symlinks to 6 tool directories (Claude, OpenCode, Trae, Cursor, Agents, opencode). No build system, no tests, no CI. Skills are Markdown files consumed by AI tools at runtime.

## Skill Structure

Every skill lives in `<skill-name>/SKILL.md` with YAML frontmatter (required: `name`, `description`) plus Markdown body. Optional dirs: `references/`, `scripts/`.

Frontmatter fields: `name`, `description`, `allowed-tools`, `license`, `hidden`, `user-invocable`, `hooks`, `metadata.version`.

Languages: mostly English, some Chinese (programmer, huashu-nuwa, pua-debugging), traditional Chinese (storytelling).

## Distribution (Directory-Level Symlinks)

Each tool's skills directory symlinks directly to this repo. Adding/removing a skill here auto-syncs all tools.

```bash
# Re-initialize all symlinks
for dir in ~/.trae/skills ~/.config/opencode/skills ~/.opencode/skills ~/.claude/skills ~/.agents/skills ~/.cursor/skills; do
  rm -rf "$dir" && ln -s /Users/ganjie/skills "$dir"
done
```

## Nested Git Repos

Three skills are nested git repos (NOT submodules) — changes inside them require separate git operations from within their directories:

- `planning-with-files/` — branch: master, upstream: OthmanAdi/planning-with-files
- `darwin-skill/` — branch: master, upstream: alchaincyf/darwin-skill
- `humanizer/` — branch: main, upstream: blader/humanizer

Update pattern for nested repos:
```bash
cd <skill-dir> && git fetch upstream && git merge upstream/<branch> && git push origin <branch>
```

Other upstream skills (skill-seekers, huashu-nuwa, storytelling, prose-craft) are manually synced — upstream structures are incompatible, only SKILL.md is carried over.

## Key Architecture Patterns

- **Memory skill** (`memory/`): Cross-skill memory API with MCP tools (`memory_memory_*`). Three-tier isolation: project/shared/global. Must be loaded before calling any memory MCP tool.
- **Programmer skill** (`programmer/`): Multi-phase coding engine with specialized agents (@explorer, @librarian, @fixer, @oracle, @designer). Governance via 4-document review system.
- **Darwin skill** (`darwin-skill/`): 8-dimension rubric for evaluating and hill-climbing optimization of SKILL.md files.
- **Huashu-nuwa** (`huashu-nuwa/`): Generates perspective skills from research. Contains 8 example sub-skills in `examples/`.

## Docker / MCP Servers

`dockerfile/` contains Docker configs for MCP servers: `searxng-mcp`, `github-mcp-server`, `one-search-mcp`.

## Git Notes

- `AGENTS.md` is excluded from git (contains local paths) via `.gitignore`
- `web-research/data/` is excluded (local research artifacts)
- `huashu-nuwa/` is 18M+ (contains images), not a nested repo
