# Memory

Cross-skill memory API with MCP tools (`memory_memory_*`). Three-tier isolation: project / shared / global. Provides structured storage with tags, scope, type, and lifecycle management.

## Trigger

save to memory、保存记忆、提取记忆、recall、remember、记忆、会话结束

## Quick Start

```
/memory 保存这个项目的 API 认证方案到项目记忆
/memory 提取关于 Redis 集群配置的经验
/memory 清理过期的项目记忆
```

## Key Concepts

### Three-Tier Isolation

| Scope | Location | Use Case |
|-------|----------|----------|
| **Project** | `.claude/memory/` | Project-specific knowledge (APIs, conventions) |
| **Shared** | `~/.claude/shared-memory/` | Cross-project knowledge (tool patterns, preferences) |
| **Global** | `~/.claude/global-memory/` | Universal knowledge (principles, workflows) |

### Tag System v2

Every memory entry requires:
- **Scope** (required): project | shared | global
- **Type** (required): fact | decision | pattern | error | preference
- **Lifecycle** (optional): active | deprecated | archived

### Cross-Skill API

Other skills can use memory MCP tools (`memory_memory_*`) to store and retrieve knowledge. Memory must be loaded before any MCP tool call.

## Workflow

1. **Gate Check** — Validate request is memory-worthy (not ephemeral, not derivable from code)
2. **Trigger Routing** — save / recall / cleanup / conflict resolution
3. **Storage** — Write with structured format (tags, scope, type)
4. **Retrieval** — Search with scope filtering

## Directory Structure

```
SKILL.md                    # Core instructions
references/
  mcp-tools.md              # MCP tool reference (memory_memory_*)
  installation.md           # MCP server setup guide
```

## MCP Tools

Requires the memory MCP server to be running. Tools include: `memory_store`, `memory_search`, `memory_list`, `memory_delete`, `memory_update`, `memory_graph`, `memory_harvest`, `memory_cleanup`, `memory_health`, `memory_quality`.

## See Also

- neat-freak — Session-end knowledge reconciliation
- coder — Uses memory for experience persistence
