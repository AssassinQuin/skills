---
phase: 4
name: phase-4-execution-protocol
description: Phase 4 执行协议 — {lang}-coder spawn + memory 注入 + MCP 4 触达点 + drift 遥测 schema。
source: "design.md §5.5 + §6 + §10"
status: skeleton
---

# Phase 4: 执行（{lang}-coder，可多语言并发）

> **加载时机**：Phase 3 用户选定方案后（或简单任务直接从 Phase 2 进入）。

## spawn 前必做（语言知识注入）

```yaml
memory_search:
  query: "{任务关键词} {lang}"
  tags: ["coding-{lang}-convention", "coding-{lang}-trap",
         "coding-{lang}-tooling", "coding-{lang}-verification",
         "coding-{lang}-gotcha"]
  tier: [project, shared]
  limit: 20
```

结果作为"语言上下文"段注入子 agent prompt。

**若结果为空**：触发 seed 流程（见 `memory-tier-strategy.md`）。
**绝不静默跳过**（R12）。

## MCP 4 触达点（执行时实时调）

| 触发 | MCP 工具 | 用途 |
|---|---|---|
| 改现有文件前 | `search_graph(file_pattern=...)` | 确认 CALLS 边 |
| 新增函数时 | `semantic_query` | 找类似 pattern 复用 |
| 改 public API | `trace_path` | 验证影响范围 |
| 改测试时 | `search_code` | 找相关 test cases |

## Adaptive Control 遥测（每 subtask 后返回）

```json
{
  "estimated_files": 3, "actual_files": 7,
  "estimated_loc": 150, "actual_loc": 420,
  "unplanned_dependencies": ["github.com/new/lib"],
  "super_violations": [{"module": "internal/auth", "principle": "S", "before": "🟢", "after": "🟡"}],
  "test_failures_unexpected": 2
}
```

drift_score 计算 + 决策见 `adaptive-control.md`。

## 跨语言并发

任务涉及多语言（Go 后端 + Python 脚本 + TS 前端）→ spawn 多个 `{lang}-coder` 并发。
每个独立查自己的 `coding-{lang}-*` memory tags。

## 子 agent prompt 模板（5 段规范）

1. **角色 + 边界**：做什么 / 不做什么
2. **输入字段**：明确 schema
3. **输出 schema**：JSON / diff / 文件列表
4. **失败处理**：降级链 + ⚠️ 标注
5. **工具预算**：token 上限 / 调用次数

## 编排模式（v3.2 继承，语言无关）

| 用户意图 | skill 链 |
|---|---|
| 重构 / 重组 | coder → (可选 simplify) |
| 新功能 | coder → tdd |
| 写测试 | coder + tdd |
| 修 bug | coder → diagnose |
| 审查代码 | coder → code-review |
| 审计代码 | coder 子 agent + code-audit-protocol |

## 跨模块一致性策略（v3.2 继承）

```
副作用（audit log / 通知 / 缓存）vs 主操作:
├── 必须强一致（金融/合规）→ 同事务 + DB audit + tx.Err()
├── 允许最终一致（行为日志/监控）→ 异步 sink + 幂等重试
└── 允许丢失（调试日志）→ stdout/file logger
```

## 子 agent allowed-tools 扩展（go-coder / python-coder）

新增：
- `mcp__codebase-memory-mcp__search_graph`
- `mcp__codebase-memory-mcp__search_code`
- `mcp__codebase-memory-mcp__trace_path`
- `mcp__codebase-memory-mcp__semantic_query`
- `mcp__codebase-memory-mcp__get_code_snippet`
- `mcp__context-mode__ctx_execute_file`
- `mcp__context-mode__ctx_batch_execute`
- `mcp__context7__query-docs`（写库代码时）

## TODO（待 step 2 扩充）

- [ ] go-coder / python-coder prompt 完整模板
- [ ] drift 遥测 schema 校验
- [ ] 跨语言并发的冲突处理

## 引用

- design.md §5.5 + §6.1 + §10
- `adaptive-control.md`（drift 决策）
- `memory-tier-strategy.md`（spawn 前 memory 注入）
- `codebase-memory-mcp.md` + `context-mode-integration.md` + `context7-integration.md`
