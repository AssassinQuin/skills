# Coder-Persist

**Phase 6 持久化** — 3 层记忆（memory MCP + MASTER.md + codebase-memory-mcp 增量索引）+ 经验提炼流程。

## Trigger

- Phase 5 review 已签字
- 需要把本次任务经验沉淀到 memory + MASTER.md

## Quick Start

```
（自动触发，不需要用户调用）
```

## Workflow

1. memory MCP 写关键决策（shared tier）+ gotcha（project tier）
2. MASTER.md 追加本次 task 索引
3. codebase-memory-mcp 增量索引 diff
4. 生成 delivery-checklist.md
5. 用户在 checklist 签字 → 进 Phase 7

## Directory Structure

```
SKILL.md / assets/{delivery-checklist,archive-template}.md / scripts/{master-update,memory-writer} / README.md
```

## Output Format

```
delivery-checklist.md（含 handoff 段）+ memory MCP entries + MASTER.md 更新
```

## See Also

coder-verify (Phase 5 前驱) / coder-archive (Phase 7 后继) / coder (主 router)
