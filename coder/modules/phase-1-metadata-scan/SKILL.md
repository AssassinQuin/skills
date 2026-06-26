---
phase: 1
name: phase-1-metadata-scan
description: Phase 1 元数据扫描 + 3 路并发架构（explorer + get_architecture + researcher）+ v7.3 新增 deepening opportunities 维度（from mattpocock improve-codebase-architecture）。7 维扫描 + shallow→deep module 候选识别。
source: "design.md §5.2 + §5 + mattpocock-optimization.md 优化 6"
status: active
tokens_estimate: 1800
load_priority: on-demand
load_when: "进入 Phase 1"
keywords: metadata scan explorer get_architecture S.U.P.E.R heatmap deepening opportunities shallow deep module AI-navigability
domain: coding
subdomain: phase
parent_skill: coder
version: "1.1"
license: Apache-2.0
frameworks:
  solid:
    - 单一职责（每个 module/class 只做一件事）
    - 依赖倒置（依赖抽象，不依赖具体）
  notes: "架构 discovery + AI-navigability + v7.3 加 deepening opportunities"
---

# Phase 1: 元数据 + 架构 + Deepening Opportunities（v7.3）

> **加载时机**：Phase 0 完成后，orchestrator 进入 Phase 1。
> **v7.3 升级**：在原 3 路并发基础上，加 **deepening opportunities** 维度（识别 shallow → deep module 候选）。
> 来源：mattpocock `improve-codebase-architecture` skill。

## 3 路并发分工（v6.0 沿用 + v7.3 加第 4 维）

| 并发分支 | model | 任务 | 工具 |
|---|---|---|---|
| `explorer`（扩展）| haiku | 7 维元数据扫描 + **deepening opportunities**（v7.3 新）| Read/Glob/Grep/Bash + `mcp__codebase-memory-mcp__index_status` + `search_graph` |
| orchestrator 直调 | — | `get_architecture(aspects=[file_tree, clusters])` | `mcp__codebase-memory-mcp__get_architecture` |
| `researcher`（触发式）| sonnet | 框架/库调研（仅 unknown framework 时）| searxng + web_reader + github |

**并发完成后**：orchestrator 合并 → 内联 S.U.P.E.R 评分 + **deepening candidates** 给 Phase 3 oracle。

## 7 维元数据（explorer schema）

| 维度 | Go | Python | TypeScript |
|---|---|---|---|
| framework | `grep -E "gin\|echo\|fiber" go.mod` | `pyproject.toml deps` | `package.json deps` |
| test_runner | `go test`（默认）| `pytest` | `vitest` / `jest` |
| linter | `.golangci.*` | `ruff.toml` | `.eslintrc.*` / `biome.json` |
| arch_pattern | `ls internal/ cmd/`（layered）| `ls src/{domain,app}/`（ddd）| `ls src/features/` |
| build_tool | `Makefile` | `uv.lock` / `poetry.lock` | `package.json scripts` |

## v7.3 新增：Deepening Opportunities

> **Deep module**（mattpocock 定义）：简单接口 + 封装大量功能 + 很少变 + 可测试隔离。
> **Shallow module**：接口复杂 / 功能少 / 难测 / 易变。
> Phase 1 的 explorer 现在也要识别 **shallow → deep 候选**，给 Phase 3 oracle 参考。

### Deepening 识别 4 步（explorer 任务）

#### 步骤 1：找 shallow module

判定信号：
- 接口面（method 数）≥10 但每 method LOC ≤5 → "pass-through" wrapper，封装不足
- 一个 module 被 >5 个其他 module import 但只暴露 1-2 个 method → 命名不准
- 同一业务概念分散在多个 module（如 `auth_login.py` + `auth_session.py` + `auth_token.py`）→ 应合并
- 测试时需要 mock >3 个依赖 → 抽象漏了

工具：
```
mcp__codebase-memory-mcp__query_graph(
  project="{name}",
  query="MATCH (m:File) WHERE m.method_count >= 10 AND m.avg_method_loc <= 5 RETURN m"
)
```

#### 步骤 2：找 deep module（参考正面）

判定信号：
- 接口面 2-5 method，每 method LOC ≥20
- 封装清晰边界（如 LoginService 封装了 auth + session + audit）
- 测试只需 mock 1-2 个外部依赖

工具：
```
mcp__codebase-memory-mcp__query_graph(
  project="{name}",
  query="MATCH (m:File) WHERE m.method_count <= 5 AND m.avg_method_loc >= 20 RETURN m"
)
```

#### 步骤 3：找 tightly-coupled 簇

判定信号：
- N 个 module 互相 import（环 / 密集）
- 一个改动需要改 ≥3 个 module

工具：
```
mcp__codebase-memory-mcp__get_architecture(project="{name}", aspects=["clusters"])
# 看 Leiden community detection 结果，cohesion 低的 cluster
```

#### 步骤 4：找 testability 差的地方

判定信号：
- 测试文件 / 源文件比例 <30%
- 一个 module 没有对应 test 文件
- 测试用 mock >3 个依赖

工具：
```
# 找无测试的源文件
mcp__codebase-memory-mcp__query_graph(
  project="{name}",
  query="MATCH (s:File) WHERE NOT EXISTS { MATCH (t:File) WHERE t.path CONTAINS 'test_' AND t.path CONTAINS split(s.path, '/')[0] } RETURN s"
)
```

### explorer 输出 schema（v7.3 加 deepening_candidates）

```yaml
metadata:
  language: go
  framework: {primary: gin, secondary: [gorm]}
  # ... (7 维)
modules:
  - path: internal/auth
    loc: 245
    incoming: 2
    outgoing: 3
index_status:
  ready: true

# v7.3 新增
deepening_candidates:
  shallow_modules:
    - path: utils/helpers.py
      reason: "pass-through wrapper（10 methods, avg 3 LOC）"
      suggestion: "合并到调用方 / 或抽 deep module"
      effort_hours: 4
  merge_candidates:
    - modules: [auth/login.py, auth/session.py, auth/token.py]
      reason: "同一业务概念分散"
      suggested_name: "AuthService"
      effort_hours: 8
  tightly_coupled_clusters:
    - cluster: [order/, payment/, billing/]
      cohesion_score: 0.3  # 低 = 耦合差
      reason: "三模块互调频次 >50"
  untested_modules:
    - path: utils/logger.py
      reason: "无对应 test 文件"
      risk: low  # 简单 wrapper
    - path: payment/refund.py
      reason: "金融精度但无 property test"
      risk: high

deep_modules_reference:  # 正面参考
  - path: services/LoginService.py
    note: "deep module 典范（2 method, 封装 auth+session+audit）"
```

## 缓存策略

- **存储**：项目根 `.coder-metadata.yaml`（gitignore）
- **失效**：manifest 文件 mtime 变化（go.mod / pyproject.toml / package.json）
- **v7.3 加**：deepening_candidates 失效条件 = `git log --since="7 days ago" --name-only` 改动 ≥5 文件

## codebase-memory-mcp 探测

```
若 codebase_indexed=false:
  search_graph(file_pattern="**/*.go")  # 看是否有索引
  若空 → 提示用户跑 cli index_repository（不自动索引，避免改用户环境）
```

## 下游使用（Phase 3 oracle 拿到 deepening_candidates 后）

oracle 在设计 alternatives 时**必须**考虑：
1. spec 涉及的 module 是否在 `shallow_modules` → 这次任务顺便深化？
2. spec 涉及的 module 是否在 `merge_candidate` → 这次任务合并？
3. spec 涉及的 module 是否在 `tightly_coupled_clusters` → 这次任务解耦？
4. spec 涉及的 module 是否在 `untested_modules` 且 risk=high → 这次任务补 test？

**Anti-pattern**：oracle 忽略 deepening_candidates 直接套 spec → 错过深化机会。

## Verification（如何确认本 Phase 成功）

- [ ] 7 维元数据已扫描（metadata.yaml 生成）
- [ ] codebase-memory-mcp.get_architecture 已触发（或显式标注 fallback）
- [ ] v7.3：deepening_candidates 已识别（即使为空，也要声明）
- [ ] v7.3：4 类候选（shallow / merge / coupled / untested）都有判定
- [ ] metadata + deepening_candidates 已传给 Phase 3 oracle

## 引用

- design.md §5.2 + §5
- [`phase-1-super-check.md`](phase-1-super-check.md)（S.U.P.E.R 评分规则）
- [`codebase-memory-mcp.md`](codebase-memory-mcp.md)（MCP 触达点 1）
- v7.3 来源：mattpocock `improve-codebase-architecture` skill
