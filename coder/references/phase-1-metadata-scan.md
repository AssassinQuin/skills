---
phase: 1
name: phase-1-metadata-scan
description: Phase 1 元数据扫描 + 3 路并发架构（explorer + get_architecture + researcher）。7 维扫描命令映射。
source: "design.md §5.2 + §5（元数据策略）"
status: skeleton
---

# Phase 1: 元数据 + 架构（🌟 3 路并发）

> **加载时机**：Phase 0 完成后，orchestrator 进入 Phase 1。

## 3 路并发分工

| 并发分支 | model | 任务 | 工具 |
|---|---|---|---|
| `explorer`（扩展）| haiku | 7 维元数据扫描 + 模块清单 | Read/Glob/Grep/Bash + `mcp__codebase-memory-mcp__index_status` |
| orchestrator 直调 | — | `get_architecture(aspects=[file_tree, clusters])` | `mcp__codebase-memory-mcp__get_architecture` |
| `researcher`（触发式）| sonnet | 框架/库调研（仅 unknown framework 时）| searxng + web_reader + github |

**并发完成后**：orchestrator 合并 → 内联 S.U.P.E.R 评分（需 Phase 0 context）。

## 7 维元数据（explorer schema）

| 维度 | Go | Python | TypeScript |
|---|---|---|---|
| framework | `grep -E "gin\|echo\|fiber" go.mod` | `pyproject.toml deps` | `package.json deps` |
| test_runner | `go test`（默认）| `pytest` | `vitest` / `jest` |
| linter | `.golangci.*` | `ruff.toml` | `.eslintrc.*` / `biome.json` |
| arch_pattern | `ls internal/ cmd/`（layered）| `ls src/{domain,app}/`（ddd）| `ls src/features/` |
| build_tool | `Makefile` | `uv.lock` / `poetry.lock` | `package.json scripts` |

## explorer 输出 schema

```yaml
metadata:
  language: go
  framework: {primary: gin, secondary: [gorm]}
  test_runner: go test
  linter: golangci-lint
  arch_pattern: layered
  build_tool: make
  codebase_indexed: true
modules:
  - path: internal/auth
    loc: 245
    incoming: 2
    outgoing: 3
index_status:
  ready: true
```

## 缓存策略

- **存储**：项目根 `.coder-metadata.yaml`（gitignore）
- **失效**：manifest 文件 mtime 变化（go.mod / pyproject.toml / package.json）

## codebase-memory-mcp 探测

```
若 codebase_indexed=false:
  search_graph(file_pattern="**/*.go")  # 看是否有索引
  若空 → 提示用户跑 cli index_repository（不自动索引，避免改用户环境）
```

## TODO（待 step 2 扩充）

- [ ] 各语言 7 维扫描的完整命令清单
- [ ] explorer 扩展 allowed-tools 的具体语法
- [ ] metadata.yaml 校验脚本

## 引用

- design.md §5.2 + §5
- `phase-1-super-check.md`（评分规则）
- `codebase-memory-mcp.md`（MCP 触达点 1）
