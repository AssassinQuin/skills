# 常量定义

所有阈值的唯一定义。模块文件和脚本引用本文件，不重复声明。

## 评分权重

| 维度 | 权重 | 审计检查项 |
|------|------|-----------|
| D1 Frontmatter | 10% | Framing + X-ref |
| D2 Workflow | 20% | Coverage + Silent-bypass |
| D3 Boundary | 15% | Script-bloat + Shape-bake |
| D4 Precision | 20% | Literals + Untraceable + Under-abstraction |
| D5 Empirical | 35% | Overfit (T_val) |

**公式**：`Score = D1×0.10 + D2×0.20 + D3×0.15 + D4×0.20 + D5×0.35`（0-10）

**D5 客观化**：`D5 = (T_train_pass / T_train_total) × 10`

## 门控阈值

| 阈值 | 值 | 用途 |
|------|-----|------|
| 部署通过 | Score > 基线 AND 无维度 < 5 | audit→deployment 门控 |
| 痛点回归 | 回归率 > 30% | 自动 git revert |
| 痛点熔断 | regression_count >= 2 | 标记 wontfix |
| trace 推断 | 同一失败点 >= 3 次 | 自动创建痛点 |
| 审计推断 | 连续 2 轮同维度 <= 4 | 自动创建痛点 |

## Token 预算

| 阶段 | 预估 |
|------|------|
| 单轮上限 | 100K |
| baseline | ~14K |
| exploration | ~40K |
| application | ~6K |
| audit | ~20K |
| deployment | ~14K |

## 子 Agent

| 参数 | 值 |
|------|-----|
| 超时 | 120s |
| 最小成功候选 | 2（对比学习） |
| exploration 并行数 | K=6（无 S0）或 K=7（有 S0） |
| exploration 压缩模式 | K=3（预算 < 70K 时） |

## T_train / T_val

| 参数 | 值 |
|------|-----|
| 拆分比例 | 60% / 40% |
| T_val 通过标准 | >= 60% |
| 过拟合信号 | T_val 比 T_train 低 > 30% |

## Quick Fix 条件

以下条件**全部满足**时走 Quick Fix（跳过 exploration）：

1. pain-points.jsonl 有 open 条目，用户明确描述了痛点
2. 修复策略可唯一确定（不需要对比多个候选）
3. 改动范围 <= 3 个文件

任一不满足 → 走完整 Full Evolution。

## 效率告警

读取 metrics.json 时，以下任一成立则提示效率偏低：

- `avg_score_delta < 0.5`
- `total_rounds >= 5`
- `avg_token_efficiency < 0.4`
- `fallback_count >= 2`
- `avg_T_val_pass_rate < 0.5`
- `pain_point_regression_rate > 0.3`
