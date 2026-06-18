# Skill Evolver

SkillEvolver 论文（arXiv:2605.10500）实现。Meta-skill：编辑其他 skill 的 skill。

**唯一规范**：[references/paper-spec.md](references/paper-spec.md)。

## Trigger

"进化 X skill", "审计 X", "评估 X 质量", "进化 skill-evolver", "优化所有 skills", "查看进化历史", "优化 X，痛点 Y"

## Quick Start

```bash
# 在主 agent 里：
"进化 huashu-nuwa"
# 或带痛点：
"优化 coder，痛点 Sonnet 子 agent 调用没传 model"
```

主 agent 会自动加载 SKILL.md 并按 Algorithm 1 走 4 个 Phase。

## 双 Agent 架构（论文 §3.1）

| 角色 | 实现 | 职责 |
|------|------|------|
| **SkillEvolver Agent** | 主 agent | 编辑目标 skill；写策略；做 contrast + patch |
| **Domain-Skill Agent** | `agents/domain-skill-agent.md` (sonnet) | fresh context 真实使用 skill 执行 T_train，产出 (τ, y) |
| **Auditor** | `agents/evolver-auditor.md` (opus) | fresh context 跑 9-check，返回 binary gate |

## Algorithm 1（论文核心）

```
Phase 1: Initialize
  axes ← Parse(T_train)
  T_train / T_val 拆分 + Git + BEFORE snapshot

Phase 2: Bootstrap (r=0)
  S_0 = DiverseStrategies(axes)
  τ_0 = Explore(T_train, S_0, v=∅, K)     # K 个 Domain-Skill Agent 解题
  Δ_0 = Contrast(τ_0+, τ_0-)
  v_1 = Patch(∅, Δ_0)                     # 从无到有

Phase 3: Refinement (r=1..R)
  Install v_r as dependency
  S_r = DiverseStrategies(axes, v_r, traces_{<r})  # 针对 v_r 弱点
  τ_r = Explore(T_train, S_r, v_r, K)
  Δ_r = Contrast(τ_r+, τ_r-)
  ṽ_{r+1} = Patch(v_r, Δ_r)              # surgical patch
  (a_r, E_r) = Audit(ṽ_{r+1}, T_train, traces)

Phase 4: Finalize + Validate
  v* = argmax score({v_1..v_R}; T_train)
  Validate(v*, T_val, V)
```

默认参数：R=2, K=4, V=5（论文 Appendix A.4）。

## Directory Structure

```
skill-evolver/
├── SKILL.md                          # v8 主入口
├── README.md                         # 本文件
├── references/
│   ├── paper-spec.md                 # 论文规范（重构唯一依据）
│   ├── evolution-strategies.md       # 策略设计参考
│   ├── failure-modes.md              # FM1-FM7 诊断
│   └── modules/
│       ├── initialize.md             # Phase 1
│       ├── bootstrap.md              # Phase 2 (r=0)
│       ├── refinement.md             # Phase 3 (r=1..R)
│       ├── audit.md                  # Auditor 9-check
│       ├── finalize.md               # Phase 4
│       ├── self-evolution.md         # Mode D: 进化 skill-evolver 自己
│       └── prompts/                  # 子 agent prompt 模板
└── scripts/
    └── evolve.sh                     # v8 精简版辅助脚本
```

## Sub-Agents

| Subagent | Model | Used by |
|----------|-------|---------|
| `domain-skill-agent` | sonnet | skill-evolver Phase 2/3 Trial |
| `evolver-auditor` | opus | skill-evolver Phase 3 Audit |

## Evolution History

每次进化在 `{skill}/.evolve/` 留下：
- `evolution-log.jsonl` — 每轮 v_r → v_{r+1} 的 Δ_r + audit 结果
- `traces.jsonl` — 所有 Domain-Skill Agent 执行轨迹 (τ, y)
- `strategies.jsonl` — 每轮策略集 S_r
- `test-prompts.json` — T_train / T_val 拆分
- `axes.json` — 决策轴
- `snapshots/` — BEFORE 副本 + 每轮 v_r 副本
- `audit/r{r}.md` — 每轮 Auditor 9-check 报告
- `metrics.json` — v* 最终指标

## v7 → v8 重构变更

| 删除 | 替代 |
|------|------|
| SkillOpt 双轨编辑 / textual learning rate / slow update / patch saturation | 论文 surgical patch（一直） |
| D1-D5 rubric 5 维评分 | 9-check binary gate |
| 5 模式 A-E + Quick Fix | 单一 Algorithm 1 |
| 固定 S1-S6 策略矩阵 | 每轮动态生成 |
| evolver-explorer（编辑者） | domain-skill-agent（使用者） + 主 agent 直接写策略 |
| 13+ evolve.sh 命令 | 5 个精简命令 |
| branch-check + regression-check + T_val 三重门 | 单一 Validate(v*, T_val, V) |

## See Also

- [darwin-skill](../darwin-skill/) — 8 维 rubric + hill-climbing（评分器，长期可作为 SkillEvolver 的 reward 近似）
- [skill-creator](../skill-creator/) — 手动创建 skill
- [paper-spec.md](references/paper-spec.md) — 论文规范
