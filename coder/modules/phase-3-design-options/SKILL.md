---
phase: 3
name: phase-3-design-options
description: Phase 3 设计方案 — 2-4 oracle(opus) + 1 test-strategist(sonnet) 并发模板（硬上限 5）。parallel exploration 实施细节。
source: "design.md §5.4 + §6.2 + v7.1 §4 #14 并发上限"
status: skeleton
tokens_estimate: 1200
load_priority: on-demand
load_when: "进入 Phase 3"
keywords: design alternatives oracle N-concurrent test-plan high-risk spawn limit model explicit
domain: coding
subdomain: phase
parent_skill: coder
version: "1.1"
license: Apache-2.0
frameworks:
  solid:
    - 单一职责（每个 module/class 只做一件事）
    - 开闭原则（扩展开放，修改封闭）
    - 里氏替换（子类能替换父类）
    - 接口隔离（client 不应被迫依赖未用的接口）
    - 依赖倒置（依赖抽象，不依赖具体）
  twelve_factor:
    - IV. Backing Services - 把外部服务当可替换资源
    - V. Build/Release/Run - 严格分离三阶段
  notes: "设计阶段全 SOLID 评估 + 模块边界 + v7.1 model 显式 + [3,5] 上限"
---

# Phase 3: 设计方案（🌟 2-4 oracle + 1 test-strategist 并发，核心创新）

> **加载时机**：复杂任务（4 条简单条件全不满足）才进入。

## 简单任务跳过条件（全部满足才简单）

- 改动 <3 文件
- 无 public API / 接口签名变更
- 无跨模块影响（`search_graph` 确认 CALLS 边只在本模块内）
- 无新依赖

## oracle 数量决策表（v7.1：硬上限 5，含 test-strategist）

| 任务特征 | oracle 数 | + test-strategist | 总 spawn | 典型场景 |
|---|---|---|---|---|
| **2 oracle** | 跨模块 ≤2 / 改动 3-7 文件 / 无 API 变更 | +1 | **3** ✓ | "加新字段 + 改对应 handler" |
| **3 oracle**（默认）| 跨模块 ≥3 / 改动 8-20 文件 / 单接口变更 | +1 | **4** ✓ | "重构 internal/auth 模块" |
| **4 oracle** | 跨模块 ≥5 / 改动 >20 文件 / 多接口 / 涉及 🔴 热点 | +1 | **5** ✓（上限） | "拆 monolith 为 3 个服务" |

**绝对禁止 5 oracle + 1 test-strategist = 6**（超 §4 #14 硬上限）→ 改成 4 oracle + 1 test-strategist，或拆任务分批。

## 方向命名约定

```
oracle-A: 方向"最小改动"（保持 public API, 内部重构）       [永远存在]
oracle-B: 方向"架构升级"（port-adapter / DDD / 模块拆分）   [2+ 时存在]
oracle-C: 方向"外部替换"（迁移到 pkg/ 或换库）              [3+ 时存在]
oracle-D: 方向"重写/混合"（推翻现有, 重新设计）            [仅 4 时存在]
```

## 并发模板（单条消息多 spawn，**每个必显式 model**）

```yaml
spawn:
  - subagent_type: oracle
    model: opus           # ← v7.1 必填（R5.1 + §4 #2）
    description: "方案 A: 最小改动"
    prompt: "${ORACLE_PROMPT_TEMPLATE_A}"
  - subagent_type: oracle
    model: opus           # ← 同 model 但不同方向 = 合规（不同职责 prompt）
    description: "方案 B: 架构升级"
    prompt: "${ORACLE_PROMPT_TEMPLATE_B}"  # 互不可见
  - subagent_type: oracle
    model: opus
    description: "方案 C: 外部替换"
    prompt: "${ORACLE_PROMPT_TEMPLATE_C}"
  - subagent_type: test-strategist
    model: sonnet         # ← 不同 model，不同职责
    description: "test-plan + vertical cycle"
    prompt: "${TEST_STRATEGIST_PROMPT}"
# orchestrator 等齐后合并
# 总数 = 4 ✓（在 [3,5] 内）
```

**Model 选择理由**：
- `oracle` = opus：方案设计是战略性推理，需 opus
- `test-strategist` = sonnet：test-plan 是工程性推理，sonnet 够用

## 单个 oracle 的 prompt 模板

```
你是方案设计师，独立完成方向 "{方向名}"。

输入:
- 需求意图: {Phase 0 输出}
- 架构热图: {Phase 1 S.U.P.E.R}
- metadata: {语言/框架/arch_pattern}

任务:
1. 调 trace_path 拉影响范围（2 跳）
2. 调 search_graph 查 CALLS 边
3. 给出方案:
   - 实现思路（≤200 字）
   - 风险（3-5 条）
   - 工作量估算（文件数 + LOC + 天数）
   - S.U.P.E.R 影响（哪些模块从 X → Y）
   - 是否改善 🔴 热点

边界:
- 不输出其他方向的方案
- 不评判其他方向
- 不调超过 5 次 MCP（token 预算）

输出 schema: JSON
```

## orchestrator 合并 + 用户决策

1. N 方案对比表（思路 / 风险 / 工作量 / S.U.P.E.R）
2. 标注推荐 + 理由
3. 🔒 `AskUserQuestion` 让用户选

## 互不可见的关键

并发 oracle 的 prompt 里**不提及其他方向的存在**（像 brainstorm-collider 设计）。
避免趋同，强制发散 — 这是 Anthropic parallel exploration 的核心价值。

## oracle 工具扩展（allowed-tools 新增）

- `mcp__codebase-memory-mcp__trace_path`
- `mcp__codebase-memory-mcp__search_graph`

## TODO（待 step 2 扩充）

- [ ] oracle-A/B/C/D 完整 prompt 模板
- [ ] 合并对比表的 markdown 模板
- [ ] 2/3/4 oracle 选择的边缘 case

## 引用

- design.md §5.4 + §6.2
- `phase-1-super-check.md`（热图输入）
- `phase-5-verification.md`（方案选定后的执行 + 审查）
