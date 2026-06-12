# Web Research

Multi-source parallel research. Local-first → 6-angle brainstorm → parallel agent search (sonnet) → inspiration mining → synthesis report. Output: `{skill_dir}/data/{date}-{slug}/`.

## Trigger

调研、研究、搜索研究、web research、对比分析、方案选型、文献、literature review、deep dive

## Quick Start

```
/web-research 调研 Rust vs Go 在微服务场景的优劣
/web-research 研究 RAG 最新进展和主流方案
/web-research 对比分析 Three.js vs Babylon.js 选型
```

## Workflow

1. **Phase 0: Quick Judgment** — Is deep research needed? Skip if answer is local.
2. **Phase 1: Local-First** — Grep existing knowledge base before hitting the web.
3. **Phase 2: Structured Brainstorm** — 6-angle search theme generation → user confirmation.
4. **Phase 3: Parallel Search** — MCP cache (zero tokens) → multi-source parallel agents.
5. **Phase 4: Inspiration Mining** — Sonnet agents follow up on ≥2 high-value findings.
6. **Phase 5: Synthesis** — Structured report → saved to `data/{date}-{slug}/`.

## Directory Structure

```
SKILL.md                    # Core instructions
references/
  agent-prompt.md           # Sub-agent prompt templates
  tool-specs.md             # MCP tool capability specs
scripts/
  mcp-probe.sh              # MCP server availability check
data/                       # Research output (gitignored)
agents/
  claude-code.yaml          # Sub-agent orchestration config
```

## Output Format

Research artifacts are saved to `data/{YYYY-MM-DD}-{slug}/` with structured findings, sources, and synthesis.

## See Also

- brainstorm — Pure brainstorming without web search
- citation-sourcing — Source verification
- huashu-nuwa — Distill research into skills
