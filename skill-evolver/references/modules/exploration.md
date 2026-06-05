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

子 agent prompt 模板见 [explorer-template.md](prompts/explorer-template.md)。

关键约束：
- 子 agent 只能用 T_train，不可见 T_val
- 超时 120s，不重试
- 成功 >= 2 → 正常对比学习；成功 == 1 → 直接采用；成功 == 0 → Fallback L2

### Step 2: 评分 + 对比学习

按需 `ctx_search` 检索候选。评分只用 T_train。

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
