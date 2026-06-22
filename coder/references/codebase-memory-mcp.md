---
name: codebase-memory-mcp
description: codebase-memory-mcp 集成 — 5 触达点（Phase 1/2/3/4/5）+ 子 agent 工具白名单 + 降级链。
source: "design.md §7.1 + v4.0 §6"
status: skeleton
---

# codebase-memory-mcp 集成

> **加载时机**：任 Phase 调 codebase-memory-mcp 工具时。

## 5 触达点（按 Phase）

| Phase | MCP 工具 | 用途 | 触发 |
|---|---|---|---|
| **1** | `index_status` + `get_architecture(aspects=[file_tree])` | 项目骨架 + Leiden 社区 | `codebase_indexed=true` |
| **2** | `search_graph(file_pattern="**/target.{ext}")` | 目标文件存在 + CALLS 边 | 改现有文件时 |
| **3** | `trace_path(from=A, to=B, max_hops=2)` | 影响范围（谁调用 / 被谁调用） | 改 public API / 跨模块 |
| **4** | `search_code` + `semantic_query` | 找类似 pattern 复用 | 新增函数/类 |
| **5** | `search_graph(neighbors_of=changed_nodes)` | 影响节点的测试覆盖 | always |

## 14 工具分类（v0.8.1）

| 类别 | 工具 |
|---|---|
| 索引 | `index_repository` / `index_status` / `list_projects` / `delete_project` |
| 搜索 | `search_code` / `search_graph` / `semantic_query` |
| 图谱 | `query_graph` (Cypher) / `trace_path` |
| 架构 | `get_architecture` / `get_graph_schema` |
| 代码 | `get_code_snippet` |
| 元数据 | `manage_adr` |

## 子 agent 工具白名单

**子 agent 暴露**（安全 + 常用）：
- `index_status` / `get_architecture` / `search_code` / `search_graph`
- `trace_path` / `semantic_query` / `get_code_snippet`

**不暴露**（避免误用 / 高开销 / 破坏性）：
- `index_repository`（orchestrator 提示用户手动跑）
- `delete_project`（破坏性）
- `query_graph`（Cypher 原生查询，子 agent 可能写错）

## 降级链（失败显性化，R12）

```
codebase-memory-mcp 调用失败
    ↓
检测 index_status
    ↓ 未索引 / 超时
降级 grep + glob + Read
    ↓
汇报里标注 "⚠️ MCP 降级，影响分析可能不全"
```

**绝不静默降级**。

## 按子 agent 分配工具

| 子 agent | 暴露的 codebase-memory-mcp 工具 |
|---|---|
| `explorer` | `index_status`, `get_architecture` |
| `oracle` | `trace_path`, `search_graph` |
| `reviewer` | `search_graph` |
| `go-coder` / `python-coder` | `search_graph`, `search_code`, `trace_path`, `semantic_query`, `get_code_snippet` |
| `researcher` | 不暴露（其本职是 web 调研）|

## TODO（待 step 2 扩充）

- [ ] 每个工具的具体调用例子
- [ ] Leiden 社区检测的输出 schema
- [ ] 增量索引的触发条件（Phase 6）

## 引用

- design.md §7.1
- v4.0 design.md §6（更详细）
- 各 phase-*.md（触达点对应章节）
