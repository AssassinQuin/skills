# Research-Skill Track（研究型 skill 进化协议）

为研究型 skill（输出是分析/评估/报告而非 binary 结果的 skill）设计的 Algorithm 1 适配。

## 何时启用

Phase 1 Initialize 检测到 skill 是研究型（见 [skill-taxonomy.md](skill-taxonomy.md)）。

## 与执行型的差异

| 维度 | 执行型 Algorithm 1 | 研究型 Track |
|------|-------------------|------------|
| Domain-Skill Agent | 跑任务，binary reward | Evaluation-Trace Agent，qualitative reward |
| T_train 任务类型 | 编码 / 文件操作 | 评估一个外部对象（仓库/skill/PR） |
| Reward | y ∈ {0, 1} | y ∈ {A, B, C, D, F} 或 ranking |
| Contrast 信号 | 成功轨迹 vs 失败轨迹 | 高质量产出 vs 低质量产出 |
| Held-out 必要性 | 强（避免过拟合到特定任务） | **更强**（避免过拟合到特定评估对象） |

## Evaluation-Trace Agent 设计

```
输入：
- candidate skill 路径（v_r）
- T_train 评估任务（"评估 X 仓库" / "对比 A vs B skill"）
- BEFORE skill 路径（v_0）作为 baseline

执行：
1. 读 candidate skill + BEFORE skill
2. 用 candidate skill 跑 T_train 评估任务，产出 τ_r
3. 用 BEFORE skill 跑同一任务，产出 τ_0
4. 对比 τ_r vs τ_0，输出 qualitative reward：
   - 是否命中 expected outcome 字段？
   - 产出深度是否提升？（定性比较）
   - 流程合规度是否提升？（exit-checklist 通过率）

输出：
- τ_r 轨迹（执行步骤 + 中间产出）
- y_r ∈ {A, B, C, D, F}（candidate 的产出等级）
- y_0 ∈ {A, B, C, D, F}（BEFORE 的产出等级）
- diff_signal = qualitative diff（candidate 比 BEFORE 好在哪 / 差在哪）
```

## Qualitative Reward 转化为 Contrast 信号

论文 §3.2.2 Contrast 用 (τ+, τ-) 配对。研究型 track 的转化：

```
如果 y_r > y_0：
  τ+ = τ_r（candidate 的轨迹）
  τ- = τ_0（BEFORE 的轨迹）
  Δ = "candidate 比 BEFORE 好的方面"

如果 y_r < y_0：
  τ+ = τ_0
  τ- = τ_r
  Δ = "candidate 比 BEFORE 差的方面"（回滚信号）

如果 y_r == y_0：
  无 contrast 信号，patch 无效，进入下一轮策略
```

## Held-out 强制（研究型特别严）

研究型 skill 容易过拟合到单一评估对象（如某次进化全程用同一仓库作为评估目标）。

**T_train / T_val 拆分协议**：

```
T_train = [评估对象 1, 评估对象 2, 评估对象 3]
T_val = [评估对象 4, 评估对象 5]（held-out，类型不同）

通用示例（参数化）：
T_train = [{同类型评估对象 1-3}]（如 3 个 meta-skill 仓库）
T_val   = [{不同类型 held-out 对象 4-5}]（如 2 个执行型 skill 仓库）

Phase 4 Validate(v*, T_val, V=2)：
- candidate v* 在 T_val 上跑评估
- 用 qualitative reward 验证泛化能力
- 如果 T_val 表现显著差于 T_train → 过拟合，回滚
```

**禁止**：T_train = T_val（同一评估对象）。Phase 1 Initialize 强制拒绝。

## Evaluation-Trace Agent 不是 Domain-Skill Agent 的子类

虽然协议类似，但 Evaluation-Trace Agent 有独特职责：
- 它**不修改 candidate skill**（Domain-Skill Agent 也如此）
- 它**真实跑评估**（不是模拟）
- 它**产出可对比的 qualitative 轨迹**（不是 binary reward）

子 agent 配置：
- subagent_type: `general-purpose` 或 `Explore`（评估任务通常 read-only）
- model: `sonnet`（执行型用 sonnet，研究型也用 sonnet 保持一致）

## 反例诊断（v8.0 → v8.1 修复）

### 反例 1: 研究型 skill 进化跳过 Evaluation-Trace Agent
**v8.0 做法**：主 agent 直接做 surgical patch，用"上一版评估复盘"作为 failure signal。
**问题**：这不是 (τ, y) 轨迹，是事后归因。
**v8.1 修复**：spawn Evaluation-Trace Agent 真实跑 v_{n+1} 评估一个目标对象，对比 v_n 跑同一任务，产出 qualitative diff。

### 反例 2: T_train = T_val
**v8.0 做法**：进化 + 验证都用同一评估对象。
**问题**：过拟合到单一场景，audit Check 6/7 暴露训练案例渗透。
**v8.1 修复**：T_train 含 3 个不同类型对象，T_val held-out 含 2 个不同类型对象。

### 反例 3: Audit 只在最后做
**v8.0 做法**：早轮 patch 跳过 audit，最后一轮才做。
**问题**：早轮带病前进，过拟合 violation 累积到最后才暴露。
**v8.1 修复**：每个 patch 后立即 audit，audit reject 立即 patch（不允许跨轮带病）。
