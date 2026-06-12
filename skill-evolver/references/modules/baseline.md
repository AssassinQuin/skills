# Module: Baseline（基线评估 + 差距理解 + 轨迹收集）

前置条件：无。预估 token：~14K。

## 评分体系（唯一定义）

| 维度 | 权重 | 审计检查项 |
|------|------|-----------|
| D1 Frontmatter | 10% | Framing + X-ref |
| D2 Workflow | 20% | Coverage + Silent-bypass |
| D3 Boundary | 15% | Script-bloat + Shape-bake |
| D4 Precision | 20% | Literals + Untraceable + Under-abstraction |
| D5 Empirical | 35% | Overfit (T_val) |

**公式**：`Score = D1×0.10 + D2×0.20 + D3×0.15 + D4×0.20 + D5×0.35`（0-10）

**D5 客观化**：`D5 = (T_train_pass / T_train_total) × 10`

### 门控阈值

| 阈值 | 值 |
|------|-----|
| 部署通过 | Score > 基线 AND 无维度 < 5 |
| 痛点回归 | 回归率 > 30% → 自动 git revert |
| 痛点熔断 | regression_count >= 2 → wontfix |
| trace 推断 | 同一失败点 >= 3 次 |
| 审计推断 | 连续 2 轮同维度 <= 4 |

### Token 预算

| 阶段 | 预估 | 子 Agent |
|------|------|---------|
| 单轮上限 | 100K | 超时 120s，不重试 |
| exploration | ~40K | K=6/7 并行，最小成功候选 2 |
| audit | ~20K | opus 独立 |
| deployment | ~14K | opus 独立 |
| baseline | ~14K | — |
| application | ~6K | — |

K=3 压缩模式：预算 < 70K 时启用。

### T_train / T_val

| 参数 | 值 |
|------|-----|
| 拆分比例 | 60% / 40% |
| T_val 通过标准 | >= 60% |
| 过拟合信号 | T_val 比 T_train 低 > 30% |

### Quick Fix 条件

以下**全部满足**时跳过 exploration：
1. pain-points.jsonl 有 open 条目，用户明确描述了痛点
2. 修复策略可唯一确定
3. 改动范围 <= 3 个文件

### 效率告警

metrics.json 以下任一成立则提示：
- `avg_score_delta < 0.5` / `total_rounds >= 5` / `avg_token_efficiency < 0.4`
- `fallback_count >= 2` / `avg_T_val_pass_rate < 0.5` / `pain_point_regression_rate > 0.3`

## 失败模式诊断（FM1-FM7）

用于 baseline 评估和 audit 诊断分类。

| FM | 模式 | 检测信号 | 缓解 |
|----|------|---------|------|
| 1 | 约束衰减 | 连续 5+ 轮行为偏离 | 硬约束写 frontmatter + 自检标记 |
| 2 | 工具漂移 | 超时后换替代工具不回来 | 显式工具优先级 + 降级条件 |
| 3 | 输出膨胀 | 输出远超需求 | 长度限制 + 禁止输出列表 |
| 4 | 依赖断裂 | 步骤间数据量不匹配 | assert 式计数验证 |
| 5 | 并行孤岛 | 子 agent 结论矛盾直接合并 | 去重 + 一致性校验 |
| 6 | 触发模糊 | 不该触发时触发 | DO NOT trigger + 歧义默认行为 |
| 7 | 幻觉填充 | 无结果时编造答案 | 无来源 = 不输出 |

**策略匹配**：FM1/FM3 → S1/S2；FM6 → S3；FM4/FM5 → S4。

## 执行步骤

### Step 1: 确认范围 + 初始化

```bash
source scripts/evolve.sh
phase-start baseline {skill_dir}
```

### Step 2: Trace Collection

搜索 `~/.claude/projects/` 会话文件，提取使用记录。保存到 `.evolve/traces.jsonl`。
trace_source：≥3→empirical，1-2→sparse，0→none。

### Step 3: 历史指标 + 痛点 + 部署反馈

读 metrics.json，按效率告警阈值检查。
Mode G 时：用户提供痛点 → `pp-create`，source="user-stated"。

**Deployment-Grounded Learning（论文核心闭环）**：
- 检查 `.evolve/deployment-traces.jsonl` 是否存在
- 存在 → 读取上次部署后的实际使用反馈，提取失败模式
- 失败模式加入 trace_source，权重高于 traces.jsonl 的历史 trace
- 标记 trace_source 为 "deployment-grounded"
- 清空 deployment-traces.jsonl（已消费）

### Step 4: Git 分支 + BEFORE 快照

```bash
git-setup {skill_name} {skill_dir}
```

保存 BEFORE 快照（必须使用脚本，禁止手动 cp）：

```bash
source /path/to/evolve.sh && snapshot-save {skill_dir}
```

**禁止**：将副本保存到 `/tmp/` 或任何非 `.evolve/snapshots/` 的位置。

### Step 5: 基线评估

按评分体系打分。`score D1 D2 D3 D4 D5`

### Step 6: T_train / T_val 拆分

5-8 个测试 prompt → `.evolve/test-prompts.json`。T_train(60%) / T_val(40%)。

### Step 7: 初始化 .evolve

```bash
mkdir -p {skill}/.evolve/audit-reports
```

### Step 8: 差距分析

traces 同一失败点 >= 3 次 → `pp-create`(trace-inferred)。
连续 2 轮某维度 <= 4 → `pp-create`(audit-found)。

### Step 8b: 补丁饱和检测

读取 `metrics.json`，检测补丁累积信号：

| 信号 | 检测方法 | 阈值 | 处理 |
|------|---------|------|------|
| 补丁轮次过多 | `total_rounds` >= 5 | 提示精简 | 保留框架，删补丁式说明 |
| 补丁边际递减 | `avg_score_delta` 连续 2 轮 < 0.5 | 提示精简 | 同上 |
| 约束堆叠 | 约束数 > 15 | 合并去重 | 不改框架 |

**轮次 >= 5 时**，输出精简建议：

```
检测到补丁饱和（已有 {N} 轮进化，边际收益 Δ={delta}）：
- 框架结构保持不变
- 建议精简：删除补丁式累积的重复说明，合并冗余约束
[A] 精简内容（推荐，框架不变）
[B] 继续补丁进化
```

用户选 A → 策略限定 S4(上下文优化)：删除补丁式说明、合并重复段，不改变流程结构。
用户选 B → 正常流程。

### Step 9: Quick Fix 判定

```bash
quick-fix-check {skill_dir}
```

### Step 10: Checkpoint（CP-01）

```bash
git-checkpoint "evolve {skill}: baseline+gap-r{r}"
```

## 关卡

展示：trace_source + 基线评分 + 差距报告 + Quick Fix 判定。用户确认后继续。
