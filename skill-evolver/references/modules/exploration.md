# Module: Exploration（策略探索）

前置条件：baseline checkpoint 已通过 + Δ 已确认。预估 token：~40K。

## 前置校验

```bash
phase-check exploration {skill_dir} && phase-start exploration {skill_dir}
```

## 策略矩阵

### S0: 动态策略（trace_source == "empirical" 时强制）

从 traces.jsonl 提取失败模式 → 合并为策略文件。

### S1-S6: 固定策略

见 [evolution-strategies.md](../evolution-strategies.md)。

## 执行步骤

### Step 1: K=6/7 并行探索

- 有 S0 时：S0 + S1-S6 = 7 个并行子 agent
- 无 S0 时：S1-S6 = 6 个并行子 agent

子 agent prompt 模板见 [templates.md](prompts/templates.md#Explorer)。

关键约束：
- 子 agent 只能用 T_train，不可见 T_val
- 超时 120s，不重试
- 成功 >= 2 → 正常对比学习；成功 == 1 → 直接采用；成功 == 0 → Fallback L2

### Step 2: 评分 + 显式对比学习（τ+/τ- Contrastive Update）

按需 `ctx_search` 检索候选。评分只用 T_train。

**显式对比分析（论文核心机制）**：

1. 从 K 个候选中选出最高分（τ+）和最低分（τ-）
2. 逐段 Diff 对比：
   - τ+ 独有的改进 → 标记为 `Δr+`（正向差异，保留）
   - τ- 独有的退化 → 标记为 `Δr-`（负向差异，排除）
   - 两者共有的变更 → 标记为 `Δr=`（中性，按需保留）
3. 提取 `Δr+` 关键差异列表
4. 将 `Δr+` patch 应用到当前 SKILL.md 生成 application 候选

**输出格式**：
```
## Contrastive Analysis
- τ+ (S{k}): score={highest} | 关键改进: {Δr+ 列表}
- τ- (S{k}): score={lowest}  | 退化原因: {Δr- 列表}
- Targeted patch: {从 τ+ 提取的具体改动项}
```

### Step 3: Checkpoint（CP-02）

展示排名 + 对比分析，用户选择策略。

```bash
git-checkpoint "evolve {skill}: exploration-r{r}-S{k}"
```

## Fallback

| 成功数 | 处理 |
|--------|------|
| >= 2 | 正常流程 |
| == 1 | 跳过对比学习 |
| == 0 | Fallback L2（主 agent 单策略直改） |
| L2 也失败 | L3（终止 + 诊断） |
