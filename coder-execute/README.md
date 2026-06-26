# Coder-Execute

**Phase 4 执行协议** — vertical tracer-bullet slice 分组 + {lang}-coder spawn + memory 注入 + MCP 4 触达点 + drift 遥测 + v7.1 [3,5] 上限 + model 显式。

## Trigger

- Phase 3 design 已选定（或简单任务从 Phase 2 直入）
- 需要 spawn 编码子 agent 写代码
- 改动覆盖多文件 / 多语言

## Quick Start

```
/coder-execute 按设计实现登录 slice
```

## Workflow

1. 按 vertical slice 分组（每 slice 完整 user 行为）
2. spawn 前 memory_search 注入语言上下文
3. 并发 spawn 3-5 个 {lang}-coder-project(sonnet)
4. 每个子 agent 返回 delivery-schema + drift 遥测
5. drift ≥ 0.4 触发 coder-adaptive 重分解

## Directory Structure

```
SKILL.md / assets/delivery-schema.yaml / scripts/{drift-compute,task-progress-guard} / README.md
```

## Output Format

```
diff + delivery-schema per agent（含 slice 元数据 + drift 遥测）
```

## See Also

coder-design (Phase 3 前驱) / coder-deliver (Phase 4.5 后继) / coder-adaptive (drift 触发) / coder-constraints (#14 并发 [3,5]) / coder (主 router)
