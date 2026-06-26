---
name: context7-integration
description: context7 MCP 集成 — 库文档查询触发条件 + 子 agent prompt 注入模板。
source: "design.md §7.5"
status: skeleton
tokens_estimate: 600
load_priority: on-demand
load_when: "子 agent 写库代码"
keywords: context7 library-docs resolve-library-id query-docs third-party API
domain: coding
subdomain: mcp
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  notes: "library API docs + third-party integration"
---

# context7 MCP 集成（触发式）

> **加载时机**：子 agent 写库代码（React/Gin/ORM/SDK）或用户提到具体 API。

## 触发条件

- 子 agent 写库代码（用 React / Gin / GORM / Prisma 等）
- 用户提到具体 API 名（"用 useEffect 实现 X"）
- 编译错误涉及库 API（"GORM 的 Preload 用法"）

## 工具

| 工具 | 用途 |
|---|---|
| `resolve-library-id(libraryName, query)` | 库名 → Context7 ID |
| `query-docs(libraryId, query)` | 查 API 文档 |

**单题最多 3 次调用**（官方限制）。

## 调用者（子 agent 自调）

orchestrator 不直调。在子 agent prompt 里提示："**若不确定 API，先调 context7**"。

## 子 agent prompt 注入模板

```
你是 {lang}-coder。

写 {library} 代码时，若不确定 API:
1. 先调 mcp__context7__resolve-library-id(libraryName="{library}", query="{task}")
2. 拿到 libraryId 后调 mcp__context7__query-docs(libraryId, query="{specific question}")
3. 单题最多 3 次调用（官方限制）
4. 调用结果作为权威，覆盖你训练数据中的过期 API

常见场景:
- React: useEffect 依赖 / Suspense 边界 / Server Components
- Go Gin: middleware 顺序 / context 参数传递
- GORM: Preload / Transaction / Hooks
- Prisma: schema.prisma 语法 / migrate 流程
```

## 何时 NOT 调 context7

- 写业务逻辑（不涉及库 API）
- 写测试代码（除非用 testing 库的高级 API）
- 简单类型 / 标准库（Go 标准库 / Python 标准库）

## 降级

context7 不可用：
- 子 agent 用训练数据知识 + ⚠️ 标"API 可能过期"
- 提示用户手动查官方文档

## 与 web-research / researcher 的边界

- **context7**: 单一库的具体 API 查询（快，权威）
- **researcher**: 多库对比 / 框架选型（慢，综合）
- **web-research skill**: 主观问题（"X vs Y 哪个好"）

coder 内部主要用 context7（快），researcher 是 fallback。

## TODO（待 step 2 扩充）

- [ ] 常用库的 Context7 ID 清单（React / Gin / GORM 等）
- [ ] 各语言的"何时调 context7"决策树
- [ ] 调用结果如何注入 diff（注释 / 命名）

## 引用

- design.md §7.5
- `phase-4-execution-protocol.md`（子 agent prompt 模板）
