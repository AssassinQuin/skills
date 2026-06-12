# Neat Freak

End-of-session knowledge cleanup with OCD-level rigor. Reconciles project docs (CLAUDE.md, README.md, docs/) and agent memory against the current code state so nothing rots.

## Trigger

sync up、tidy up docs、update memory、clean up docs、/sync、/neat、同步一下、整理文档、整理一下、更新记忆、梳理一下、收尾、这个阶段做完了、新人能直接上手

## Quick Start

```
/neat-freak 同步一下
/neat-freak 整理文档，新人要能直接上手
/neat-freak 这个阶段做完了，收尾
```

## Workflow

1. **Inventory** — Mechanical enumeration of all docs, memory, and config files (mandatory, cannot skip)
2. **Change Detection** — Build a change impact matrix: what code changed → what docs/memory are stale
3. **Execute Updates** — Edit files with tools, not just describe changes
4. **Self-Check** — Run through checklist item by item
5. **Change Summary** — Report what was updated, what was already current, what was deleted

## Three Knowledge Types

| Type | Audience | Examples |
|------|----------|----------|
| **Code Docs** | Future developers | CLAUDE.md, README.md, inline comments |
| **Agent Memory** | Future AI sessions | Project memories, feedback, references |
| **User Docs** | Humans | Architecture docs, ADRs, onboarding guides |

## Directory Structure

```
SKILL.md                    # Core instructions
references/
  sync-matrix.md            # Change impact matrix template
  agent-paths.md            # Agent memory path mapping
```

## See Also

- memory — Memory storage and retrieval
- handoff — Session handoff to another developer/agent
