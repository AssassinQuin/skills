# Coder-Archive

**Phase 7 归档**（含 post-mortem + handoff 段）。orchestrator 收尾：signature 终验 + archive.md 生成 + state 清除 + memory MCP 沉淀 + MASTER.md 索引。

## Trigger

- Phase 6 delivery-checklist 已签字
- 全流程收尾归档

## Quick Start

```
（自动触发，不需要用户调用）
```

## Workflow

1. signature-guard verify（检查所有必签 Phase）
2. 生成 archive.md（含 handoff + post-mortem 段）
3. mv specs-active/{ts}-{slug}/ archive/
4. 清除 current.json
5. 更新 MASTER.md 索引
6. memory MCP 写关键决策（shared tag）

## Directory Structure

```
SKILL.md / README.md
```

## Output Format

```
archive.md（Phase 历史 + handoff + post-mortem）
```

## See Also

coder-persist (Phase 6 前驱) / mattpocock handoff (灵感来源) / coder (主 router)
