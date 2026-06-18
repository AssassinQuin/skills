---
name: skill-evolver
version: "8.0"
description: >
  SkillEvolver 论文实现（arXiv:2605.10500）。Meta-skill 模式：双 Agent 架构（SkillEvolver Agent
  编辑 skill + Domain-Skill Agent 真实使用 skill）+ Strategy-Diversified Exploration +
  Contrastive Patch + 9-check Auditor + Held-out Validate。重构规范见 references/paper-spec.md。
  Trigger: "进化 X skill", "审计 X", "评估 X 质量", "进化 skill-evolver",
  "优化所有 skills", "查看进化历史", "重写 skill", "优化 X，痛点 Y", "优化 X skill",
  "验证 X skill".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
user-invocable: true
---

# Skill Evolver v8.0

**唯一规范**：[references/paper-spec.md](references/paper-spec.md)。本文档是流程入口，所有方法细节以 paper-spec.md 为准。

## 价值锚定

> 宁可产出低分但诚实的进化结果，也不要高分但编造的通过率。诚实的 UNVERIFIED 比虚假的 4/4 更有价值。

## 双 Agent 架构（论文 §3.1）

| 角色 | 在本实现中 | 职责 |
|------|----------|------|
| **SkillEvolver Agent** | 主 agent（加载本 SKILL.md） | 编辑目标 skill；写策略；做 contrast + patch |
| **Domain-Skill Agent** | 子 agent（fresh context） | 拿到 candidate skill + T_train 任务，**真实执行**，产出轨迹 (τ, y) |
| **Auditor** | 子 agent（fresh context） | 跑 9 个机械检查，返回 binary gate + violations |

**学习信号必须来自 Domain-Skill Agent 的真实执行轨迹**，不是主 agent 反思、不是子 agent 模拟执行（论文 §3.1 原话）。

## Algorithm 1（论文 §3.2 + Appendix A.1）

```
Input: task T=(T_train, T_val); iteration cap R; explore width K; validate trials V
Output: π(v*; T_val)

Phase 1: Initialize
  axes ← Parse(T_train)
  T_train / T_val split + Git branch + BEFORE snapshot

Phase 2: Bootstrap (r=0)
  S_0 ← DiverseStrategies(axes, ∅, ∅)            # K 个动态策略
  τ_0 ← Explore(T_train, S_0, v=∅, K)            # K 个 fresh Domain-Skill Agent 执行
  Δ_0 ← Contrast(τ_0+, τ_0-)                     # verbal reinforcement
  v_1 ← Patch(∅, Δ_0)                            # 从无到有创建

Phase 3: Refinement Loop (r=1..R)
  Install v_r as dependency in trial workspace
  S_r ← DiverseStrategies(axes, v_r, traces_{<r})  # 针对 v_r 弱点
  τ_r ← Explore(T_train, S_r, v_r, K)
  Δ_r ← Contrast(τ_r+, τ_r-)
  ṽ_{r+1} ← Patch(v_r, Δ_r)                      # surgical patch (not rewrite)
  (a_r, E_r) ← Audit(ṽ_{r+1}, T_train, traces)
    if a_r = reject: 用 E_r 做 targeted patch，同 r 重试

Phase 4: Finalize + Validate
  v* ← argmax_{v ∈ {v_1..v_R}} score(v; T_train)
  return Validate(v*, T_val, V)                  # V 个 held-out trials
```

**默认参数**（论文 Appendix A.4）：R=2, K=4, V=5。可按 skill 复杂度调整。

## 决策入口

| 意图 | 路径 |
|------|------|
| "进化 X" / "优化 X" / "优化 X，痛点 Y" | 全流程 Phase 1→4 |
| "审计 X" | 仅 [audit.md](references/modules/audit.md) 9-check |
| "评估 X 质量" / 编辑 SKILL.md 后 | Phase 1 Initialize（axes + 评分） |
| "进化 skill-evolver" | 全流程 + 副本隔离（见 [self-evolution.md](references/modules/self-evolution.md)） |
| "查看进化历史" | 读 `.evolve/evolution-log.jsonl` |

（已删除 v7 的 5 模式 A-E + Quick Fix。论文只有一个算法。）

## Phase 入口

每个 Phase 完成后 **必须 AskUserQuestion** 展示结果并等待确认。未确认禁止进入下一 Phase。

按顺序读取对应模块并执行：

| Phase | 模块 |
|-------|------|
| 1 Initialize | [initialize.md](references/modules/initialize.md) |
| 2 Bootstrap | [bootstrap.md](references/modules/bootstrap.md) |
| 3 Refinement | [refinement.md](references/modules/refinement.md) |
| 4 Finalize + Validate | [finalize.md](references/modules/finalize.md) |
| Audit（Phase 3 内嵌） | [audit.md](references/modules/audit.md) |

## 子 Agent（论文 §3.1 双 Agent + §3.2.3 Auditor）

| 任务 | subagent_type | model | 说明 |
|------|--------------|-------|------|
| **Domain-Skill Agent 执行 T_train** | `domain-skill-agent` | sonnet | fresh context，**唯一职责是真实使用 skill 执行任务** |
| **Auditor 9-check** | `evolver-auditor` | opus | fresh context，跑机械检查，返回 binary gate |

R5.1：`Agent()` 必须同时传 `subagent_type` + `model`。

**已删除** v7 的 `evolver-explorer`（策略探索者）。策略由主 agent 直接写（论文要求 SkillEvolver Agent 自己写策略集 S_r，不是 spawn 子 agent 写）。

## 评分 / Git / 日志

- **评分体系**：v* ← argmax score(T_train)，y 是 task reward（binary 或 scalar），详见 [initialize.md](references/modules/initialize.md)
- **失败模式**：FM1-FM7 诊断，详见 [failure-modes.md](references/failure-modes.md)
- **Git**：分支 `evolve/{skill}/YYYYMMDD`，BEFORE 快照，各 Phase 末尾 checkpoint
- **日志**：`{skill}/.evolve/` 下
  - `evolution-log.jsonl` — 每轮 v_r → v_{r+1} 的 Δ_r 和 audit 结果
  - `traces.jsonl` — 所有 Domain-Skill Agent 执行轨迹 (τ, y)
  - `strategies.jsonl` — 每轮的策略集 S_r
  - `test-prompts.json` — T_train / T_val 拆分
  - `snapshots/` — BEFORE 副本 + 每轮 v_r 副本

## 约束

### 绝对不做（违反 = 进化结果无效）

1. **不编造通过率** — Domain-Skill Agent 未执行就填 y 值
2. **不跳过 Auditor** — 每个 ṽ_{r+1} 必须经过 9-check
3. **不用模拟执行代替真实 trial** — Domain-Skill Agent 必须真的跑任务
4. **不在未执行时填结果** — 子 agent 未 spawn 则标记 UNVERIFIED
5. **不丢弃失败经验** — Audit 拒绝时 E_r 必须记录到 traces.jsonl 并用于下一轮 targeted patch
6. **不泄露训练集** — Auditor 不能看 T_val；Domain-Skill Agent 不能看 SkillEvolver Agent 的策略分析/gap 推理

### 流程约束

1. **学习信号接地** — Δ_r 必须来自真实 Domain-Skill Agent 轨迹对比，不是文本 diff
2. **Surgical Patch** — r>0 时只打补丁，不完整重写（论文 line 11 明确）
3. **策略动态生成** — 每轮 S_r 针对当前 v_r 的弱点，不是固定矩阵
4. **Workspace 隔离** — Domain-Skill Agent 子 agent prompt 只传 candidate skill 路径 + T_train 任务；禁止传 evolution-log / traces / 策略分析
5. **Auditor 输入白名单** — candidate skill + task + T_train + labelled traces；禁止传 T_val / SkillEvolver context
6. **R ratchet** — v* 从所有 v_r 中 argmax 选出；audit reject 的版本不入选
7. **Held-out 强制** — Validate 必须在 T_val 上跑，T_train 上过拟合的 v* 会在此暴露
8. **路径锚定** — 子 agent 绝对路径 + ls 验证

### 论文一致性自检（重构后必须满足）

见 [paper-spec.md §13](references/paper-spec.md)。简版：

- ✅ Domain-Skill Agent 真实执行（不是模拟）
- ✅ 策略每轮动态生成（不是 S1-S6）
- ✅ Contrast 输出 patch Δ（不是 K-best selection）
- ✅ r>0 时 surgical patch（不是完整重写）
- ✅ Auditor 9-check + binary gate（不是 rubric 打分）
- ✅ Workspace 隔离用 prompt 边界（hook 后续补）

## 已删除的概念（v7 → v8 重构）

| 删除项 | 原因 |
|--------|------|
| SkillOpt 双轨编辑（bounded/full rewrite） | SkillEvolver 一直是 surgical patch |
| textual learning rate | SkillOpt 独有，论文 §3 无此概念 |
| Slow Update / Patch Saturation | SkillOpt epoch-wise meta update |
| S1-S6 固定策略矩阵 | 论文要求每轮动态生成 |
| D1-D5 rubric 5 维评分 | Auditor 改为 9-check binary gate |
| 5 模式 A-E + Quick Fix | 论文只有一个 Algorithm 1 |
| diff-budget-check / slow-update-check / quick-fix-check / phase-check / phase-start 脚本 | 包装 jq 一行，无额外能力 |
| 三重质量门（branch-check + regression-check + T_val） | 改为单一 Validate(v*, T_val, V) |
| evolver-explorer agent | 策略由主 agent 直接写；执行由 domain-skill-agent 接管 |
