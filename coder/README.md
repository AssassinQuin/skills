# Coder

Multi-language coding meta-skill. Auto-detects project language → probes toolchain → loads context → orchestrates skill chain → executes → reviews → deep audit → persists experience.

## Trigger

写代码、实现、重构、修复、修改、coder、编码、开发、debug、新增、审计代码、review diff

## Quick Start

```
/coder 实现一个 HTTP 中间件
/coder review 这个 diff
/coder 重构 payment 模块，拆分出 billing 子包
```

## Workflow

1. **Language Detection** — Detect Go, Python, or other via project files (`go.mod`, `pyproject.toml`, etc.)
2. **Context Loading** — Load language-specific conventions from `references/`
3. **Orchestration Decision** — Determine path: understand → plan → execute → audit
4. **Execution** — Edit code with verification loops per language
5. **Deep Audit** — Protocol-based code review via `code-audit-protocol.md`
6. **Experience Persist** — Save patterns to project memory

## Directory Structure

```
SKILL.md                    # Core instructions (AI consumed)
references/
  go-conventions.md         # Go naming, error handling, concurrency patterns
  go-editing-traps.md       # Common Go editing pitfalls
  go-gopls-strategy.md      # gopls integration strategy
  go-verification-loop.md   # Go-specific test/verify cycle
  python-conventions.md     # Python style and patterns
  python-editing-rules.md   # Python editing constraints
  python-tooling.md         # Python toolchain (pytest, ruff, mypy)
  python-verification-loop.md
  core-protocols.md         # Shared execution protocols
  code-audit-protocol.md    # Deep audit checklist
```

## See Also

- skill-evolver — Evolve this skill
- darwin-skill — Evaluate skill quality
- code-review — Lighter-weight review workflow
