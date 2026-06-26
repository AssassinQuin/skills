# Coder-Metadata

**Phase 1 元数据 + 架构 + Deepening Opportunities**（含合并的 S.U.P.E.R check）。3 路并发：explorer + get_architecture + researcher。

## Trigger

- 进入 coder 流水线 Phase 1（spec + reuse 已生成）
- 需要项目语言/框架/arch_pattern 元数据
- 需要 S.U.P.E.R 模块健康分热图

## Quick Start

```
/coder-metadata 扫描当前项目
```

## Workflow

1. explorer(haiku) 7 维扫描 + deepening candidates 识别
2. orchestrator 直调 codebase-memory-mcp.get_architecture
3. researcher(sonnet) 触发式查 unknown framework
4. orchestrator 合并 + S.U.P.E.R 评分（v7.2 合并自 phase-1-super-check）
5. 传 metadata + 热图给 Phase 3 oracle

## Directory Structure

```
SKILL.md（含 S.U.P.E.R check 合并章节）/ scripts/explorer-runner / README.md
```

## Output Format

```
.coder-metadata.yaml（7 维 + deepening_candidates + S.U.P.E.R 热图）
```

## See Also

coder-spec / coder-reuse / coder-design (Phase 3 消费 metadata) / codebase-memory-mcp（MCP 集成）/ coder (主 router)
