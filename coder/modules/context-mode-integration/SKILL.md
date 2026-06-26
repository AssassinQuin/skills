---
name: context-mode-integration
description: context-mode MCP 集成 — ctx_execute_file / ctx_batch_execute / ctx_search 场景 + 节省 token 估算。
source: "design.md §7.2"
status: skeleton
tokens_estimate: 800
load_priority: on-demand
load_when: "子 agent 读大文件 / 批量命令"
keywords: context-mode ctx_batch_execute ctx_execute_file token optimization
domain: coding
subdomain: mcp
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  notes: "token economy + progressive disclosure"
---

# context-mode MCP 集成（v5.0 新增，关键）

> **加载时机**：子 agent 读大文件 / 批量命令 / 查历史索引时。

## 为什么用 context-mode

官方数据：**主 context 节省 60-90% token**。v4.0 零集成是硬伤，v5.0 必补。

核心哲学：**Think-in-Code** — 让代码在 sandbox 处理大输出，只 console.log 答案回主 context。

## 5 个核心工具

| 工具 | 场景 | 替代 |
|---|---|---|
| `ctx_execute_file(path, code)` | 子 agent 读大文件（>500 行）| Read（爆 context）|
| `ctx_batch_execute(commands, queries)` | 并行 git log + diff + 多文件读 | 多次 Bash 串行 |
| `ctx_search(queries)` | 查历史索引 / 跨 session 经验 | memory_search 补充 |
| `ctx_index(content, source)` | 索引项目文档 / API spec | — |
| `ctx_fetch_and_index(url)` | 抓 web 文档（结合 researcher）| WebFetch |

## 子 agent 调用模板

### go-coder / python-coder 读大文件

```python
# 不要：
content = Read("internal/big.go")  # 爆 context

# 要：
ctx_execute_file(
  path="internal/big.go",
  code="""
    const lines = FILE_CONTENT.split('\\n');
    const handlers = lines.filter(l => l.includes('func Handle'));
    console.log(`Found ${handlers.length} handlers:`);
    console.log(handlers.join('\\n'));
  """,
  intent="find all HTTP handlers"
)
# 只把 handlers 列表回主 context，文件原文不进
```

### orchestrator 并行 git 三连

```yaml
ctx_batch_execute:
  commands:
    - {label: "log", command: "git log --oneline -10"}
    - {label: "diff", command: "git diff HEAD~3"}
    - {label: "files", command: "find . -name '*.go' | head -50"}
  queries:
    - "recent commits about auth"
    - "files changed in last 3 commits"
  concurrency: 3
# raw bytes 留 sandbox，只有 queries 答案回主 context
```

## 按子 agent 分配

| 子 agent | context-mode 工具 |
|---|---|
| orchestrator | 全部 |
| `explorer` | `ctx_batch_execute`（扫描）|
| `oracle` | `ctx_search`（历史经验）|
| `reviewer` | `ctx_execute_file`（读大文件 diff）|
| `go-coder` / `python-coder` | `ctx_execute_file` + `ctx_batch_execute` |
| `researcher` | 已自带（不需要扩）|

## 降级（context-mode 不可用）

| 场景 | 降级 | 标注 |
|---|---|---|
| `ctx_execute_file` 失败 | 用 Read | ⚠️ token 成本增加 |
| `ctx_batch_execute` 失败 | 多次 Bash 串行 | ⚠️ 时间成本增加 |
| `ctx_search` 失败 | 用 memory_search | ⚠️ 检索精度降低 |

## 加载策略

子 agent prompt 提示："**若读文件 >500 行 / 批量命令 ≥3 个 / 需查历史索引，用 context-mode**"。

## TODO（待 step 2 扩充）

- [ ] 各语言的 ctx_execute_file 代码模板（Go / Python / TypeScript）
- [ ] ctx_batch_execute 的 5 个常用组合
- [ ] ctx_search 与 memory_search 的边界

## 引用

- design.md §7.2
- 官方文档：context-mode README
