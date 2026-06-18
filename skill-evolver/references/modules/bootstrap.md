# Module: Bootstrap（Phase 2，r=0）

对应论文 Algorithm 1 line 2-5：从无到有创建 v_1。

```
S_0 ← DiverseStrategies(axes, ∅, ∅)       # line 2
τ_0 ← Explore(T_train, S_0, v=∅, K)        # line 3
Δ_0 ← Contrast(τ_0+, τ_0-)                # line 4
v_1 ← Patch(∅, Δ_0)                       # line 5：first skill from scratch
```

## 与 Refinement 的关键差异

| 维度 | Bootstrap (r=0) | Refinement (r>0) |
|------|----------------|------------------|
| 起始状态 | v=∅（无 skill） | v_r 已存在 |
| 策略目标 | 覆盖 axes | 针对 v_r 弱点 |
| Patch 形式 | **从无到有创建 v_1** | surgical patch v_r |
| Trial 行为 | Domain-Skill Agent 凭策略自己解题 | Domain-Skill Agent 用 candidate skill 解题 |

Bootstrap 时**还没有 skill 给 Domain-Skill Agent 用**，trial 实际上是"裸 agent + 策略提示"解题。论文 line 3 `Explore(T_train, S_0, v=∅, K)` 中 v=∅ 的含义就是"无 skill 可用"。

## 执行步骤

### Step 1: 写策略集 S_0 = DiverseStrategies(axes, ∅, ∅)（论文 §3.2.1）

主 agent（SkillEvolver Agent）直接写 K 个策略文件。**不 spawn 子 agent 写**。

```bash
mkdir -p {skill_dir}/.evolve/strategies/r0
```

每个策略是一个 markdown 文件 `s_0_{i}.md`，包含：
- 策略名（如 "jq-first"、"python-pandas"、"literal-strict"）
- 覆盖的 axis（必须不同于其他策略）
- 高层方案描述
- 该策略下"理想 Domain-Skill Agent"应该怎么做

**强制两个检查**（论文原话）：

1. **去重检查**：`checks that no two strategies are identical on all major axes`
   ```bash
   # 主 agent 自检：K 个策略在主要 axis 上不能完全相同
   ```

2. **参数化检查**：`for every parametric axis, at least one strategy must derive the value at runtime rather than copy the training value`
   ```bash
   # 对每个 parametric constant（来自 axes.json），至少有一个策略要求 Domain-Skill Agent
   # 在执行时"重新推导"该值，而不是直接告诉它
   ```

记录到 strategies.jsonl：
```json
{"round":0,"strategies":["s_0_1","s_0_2",...],"axes_covered":{...},"parametric_derivation_required":["input_filename",...]}
```

### Step 2: Explore(T_train, S_0, v=∅, K)（论文 line 3）

为 K 个策略**并行** spawn K 个 Domain-Skill Agent：

```
Agent(
  description="trial-r0-s{i}",
  subagent_type="domain-skill-agent",
  model="sonnet",
  prompt="""
[CANDIDATE SKILL]
none (bootstrap, v=∅)

[T_TRAIN TASK]
{t_train_prompt}

[STRATEGY s_0_{i}]
{策略内容}

[REWARD DEFINITION]
{reward_type + reward_def}

执行任务并返回 trajectory。
"""
)
```

**K 个 Agent 调用放在同一消息内并行**（参考 Claude Code Agent tool 用法）。

每个 Domain-Skill Agent 返回 (τ, y)。记录到 traces.jsonl：
```json
{"round":0,"strategy":"s_0_1","agent":"trial-r0-s1","y":1,"trajectory_summary":"...","silent_bypass":false,"primary_script_called":false}
```

**强制**：
- 超时 120s，不重试（论文 single-pass）
- y 必须是真实判定，未执行 → `UNVERIFIED`（不填 0/1）
- 全部 K 个 trial 都 fail → 触发 Fallback（见下）

### Step 3: Contrast(τ_0+, τ_0-) → Δ_0（论文 §3.2.2 Eq.2）

主 agent 选出：
- **τ+** = Top({τ_0_i}, y_0_i)（binary 任务 = passing trials；scalar 任务 = top-scoring）
- **τ-** = Bottom({τ_0_i}, y_0_i)

**Verbal reinforcement**（论文原话）：
> "we use the contrast as verbal reinforcement to refine a frozen-weight agent's skill document"

主 agent 做"语言对比"，不是数值优化。对比 τ+ 和 τ-，识别：
- **Δ+**：τ+ 有而 τ- 没有的（成功因素）—— 加入 v_1
- **Δ-**：τ- 有而 τ+ 没有的（失败因素）—— 排除
- **candidate feature filter**：每个 Δ+ 候选必须问"这是 pretraining 已知的吗？" → 是 → 不加入

输出 Δ_0 = 一组 candidate feature / constraint / code pattern，每个标注来源 τ+。

### Step 4: Patch(∅, Δ_0) → v_1（论文 §3.2.2 line 5）

r=0 时 v=∅，所以是从**高奖励轨迹的可复用代码 + 对比信号**创建 v_1：

```bash
# 主 agent 直接编辑 {skill_dir}/SKILL.md（或新建，如果不存在）
# 吸收 Δ_0 + τ+ 里观察到的可复用模式
# 严格遵守 paper-spec.md §11 的"不抄 SkillOpt 概念"
```

**v_1 的内容**：
- Frontmatter（name, description, allowed-tools）
- 触发词
- 工作流（从 τ+ 学到的）
- 约束（从 Δ- 排除的失败模式）
- 必要的 scripts（从 τ+ 的可复用代码提取）

### Step 5: Checkpoint（CP-02）

**展示给用户**：
- S_0 策略集 + 去重检查结果
- K 个 trial 的 (τ, y) 摘要
- τ+ / τ- 选择
- Δ_0 candidate feature 列表 + filter 结果
- v_1 的内容（diff vs BEFORE，或全新创建）
- 本轮局限：必须声明

**确认后才能进入 Phase 3 Refinement**。

## Fallback

| 情况 | 处理 |
|------|------|
| K 个 trial 全 fail | Fallback L2：主 agent 单策略直改（参考失败模式做反向设计） |
| L2 也失败 | Fallback L3：终止 + 诊断（写 failure report 到 evolution-log） |
| K 个 trial 全成功（无 τ-） | 跳过 Contrast，直接合并所有 τ+ 的可复用模式创建 v_1 |
| Domain-Skill Agent 全部超时 | 检查任务难度，可能需要拆分 T_train |

## 输出

完成后：
- `strategies/r0/s_0_{i}.md` × K
- `traces.jsonl` 增 K 条 r=0 记录
- `evolution-log.jsonl` 增 `{"phase":"bootstrap","round":0,"v":"v_1","delta_count":N,"t_plus_count":N}`
- `{skill_dir}/SKILL.md` 已更新为 v_1
- `snapshots/{skill}-v1.md` 保存 v_1 副本
