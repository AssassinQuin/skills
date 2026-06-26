# Coder v5.0

Multi-language coding meta-skill — **router + 7 Phase pipeline + parallel subagents**.
v3.2 → v5.0 推倒重做（2026-06-22）。完整设计见 [`{repo}/coder/.deepen/20260622-v5.0/design.md`](.deepen/20260622-v5.0/design.md)。

## Trigger

显式：写代码、实现、重构、修复、修改、coder、编码、开发、debug、新增、审计代码、review diff、add feature、implement、build、fix。

隐式："修这个 bug" / "加个 X 功能" / "重构这块" / "这块代码不对" / "为什么 X 报错" / "改下 X"。

不触发：纯问答、解释、分析、调研（用 `web-research` / `researcher`）、人物思维（用 `huashu-nuwa`）。

## Quick Start

```
/coder 修 internal/auth 的 nil pointer
/coder 加一个 GET /users/:id handler
/coder 重构 payment 模块，拆分 billing 子包
```

## 7 Phase 流水线（v5.0 核心）

| Phase | 名字 | 执行者 | 并发 |
|---|---|---|---|
| 0 | 需求捕获 | orchestrator（内联）| — |
| 1 | 元数据 + 架构 | explorer + get_architecture + researcher | 🌟 3 路并发 |
| 2 | 语言路由 | orchestrator（内联）| — |
| 3 | 设计方案 | oracle（2-4 个，按复杂度）| 🌟 N oracle 并发 |
| 4 | 执行 | `{lang}-coder`（sonnet）| 🌟 多语言可并发 |
| 5 | 验证 | reviewer × 3（正确性/S.U.P.E.R/安全）| 🌟 3 reviewer 并发 |
| 6 | 持久化 | orchestrator（内联）| — |

简单任务（<3 文件 / 无 API 变更）跳过 Phase 3。

## v5.0 三大架构支柱

1. **Progressive disclosure** — SKILL.md 是 router（≤200 行），14 个 references 按需加载
2. **Parallel subagents** — Phase 1/3/5 默认并发（parallel exploration，Anthropic best practices）
3. **Orchestrator-as-router** — 主 agent 只做 4 件事：路由 / spawn / 合并 / 用户交互

## 语言知识在 memory MCP（v5.0 核心决策）

**语言约束 / 踩坑 / 经验不在 references 文件**，全部在 memory MCP（项目 / 共享 / 全局三层 tier）。

| tag | tier | 用途 |
|---|---|---|
| `coding-{lang}-convention` / `-trap` / `-tooling` / `-verification` | 共享级 | 跨项目通用 |
| `coding-{lang}-gotcha` | 项目级 | 项目专属（子 agent 可写）|
| `coding-super-decay` / `coding-audit-finding` | 共享 / 项目 | 评分 + 审计 |
| `coding-user-pref` | 全局级 | 用户偏好 |

首次使用 memory 为空 → orchestrator 检测 → AskUserQuestion（是 / 这次否 / 永不问）→ 跑 `scripts/seed-memory.py`（step 3.5 实施）。

## Directory Structure

```
coder/
├── SKILL.md                   # v5.0 router (203 行)
├── README.md                  # 本文件
├── agents/                    # 编码子 agent（被 orchestrator spawn）
│   ├── go-coder.md            # + v5.0 frontmatter + 15 allowed-tools
│   └── python-coder.md        # 同上
├── modules/                   # 22 个 modular skills（v7.0，progressive disclosure）
│   ├── phase-0-intent-capture.md
│   ├── phase-1-metadata-scan.md
│   ├── phase-1-super-check.md
│   ├── phase-3-design-options.md
│   ├── phase-4-execution-protocol.md
│   ├── phase-5-verification.md
│   ├── phase-6-persistence.md
│   ├── codebase-memory-mcp.md
│   ├── context-mode-integration.md
│   ├── memory-tier-strategy.md
│   ├── github-integration.md
│   ├── context7-integration.md
│   ├── adaptive-control.md
│   ├── hard-constraints.md
│   └── legacy/                # 12 个 v3.2 文件归档（待 seed 到 memory）
├── snapshots/                 # SKILL-v3.2.md.bak
└── .deepen/20260622-v5.0/     # 完整设计文档（716 行）
```

## 全局复用子 agent

v5.0 复用 `skills/agents/` 里 4 个已注册 agent（不新建，按 coding-rules R8）：

| agent | model | v5.0 用途 |
|---|---|---|
| `explorer` | haiku | Phase 1 元数据扫描 |
| `oracle` | opus | Phase 3 方案设计（N 并发）+ drift ≥0.4 重分解 |
| `reviewer` | sonnet | Phase 5 验证（3 并发：正确性/S.U.P.E.R/安全）|
| `researcher` | sonnet | Phase 1 触发式框架调研 |

## 评估

skill-evolver Phase 1 STRUCTURAL_SCORE：**v5.0 = 8.1 vs v3.2 = 6.1**（Δ=+2.0）。

详见 `{repo}/coder/.evolve/logs/baseline-score-v5.0-vs-v3.2.md`。

## See Also

- 完整设计：[`.deepen/20260622-v5.0/design.md`](.deepen/20260622-v5.0/design.md)（716 行，9 Open Questions 全部拍板）
- v4.0 废弃对照：[`.deepen/20260622-v4.0/design.md`](.deepen/20260622-v4.0/design.md)
- 评估报告：[`.evolve/logs/baseline-score-v5.0-vs-v3.2.md`](.evolve/logs/baseline-score-v5.0-vs-v3.2.md)
- skill-evolver — 进化 / 评估本 skill
- code-review — 轻量审查（不是 fresh-context）
- diagnose — bug 诊断（Phase 4 可串联）
