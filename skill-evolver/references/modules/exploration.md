# Module: Exploration（S0 动态策略 + K=6 固定策略 + 对比学习）

前置条件：Δ 报告已确认 + token 预算充足（≥70K 剩余）。预估 token：~38K。

## 模块前置校验

```
1. baseline checkpoint 已通过 → 对话历史中有确认消息
2. Δ 报告已确认 → 报告包含"差距描述"段落
3. token 预算充足 → 剩余 ≥ 70K

IF 任一不满足:
  输出 [PRE-CHECK-FAIL] + 具体缺失项
  禁止继续
```

## 策略矩阵：S0 + S1-S6

### S0: 动态策略（Trace-Driven，优先级最高）

**核心改进**：从真实失败模式生成针对性策略，而非仅使用固定 S1-S6。

**生成条件**：
- `trace_source == "empirical"`（≥3 条 traces）→ **强制生成 S0**
- `trace_source == "sparse"`（1-2 条 traces）→ 建议生成 S0
- `trace_source == "none"` → 跳过 S0，仅用 S1-S6

**生成方法**：
1. 从 traces.jsonl 提取所有 failure/partial 类型的轨迹
2. 分析失败模式（归类：路由错误、标签缺失、内容过长、边界遗漏等）
3. 为每种失败模式生成一个针对性策略描述
4. 合并为一个 S0 策略文件，格式同 S1-S6

```
S0 示例（来自 memory skill 的真实失败）：
策略名：Trace-Driven Tag Enforcement + Output Compression
诊断信号：100/100 条记忆无 tags；Phase 3 输出 281K 字符
核心操作：
  1. 将标签规则从当前位置移到紧邻存储操作处（消除 340 行跨度）
  2. Phase 3 加载加入硬上限：limit≤20, 总输出≤2000字符
  3. 存储操作前增加强制标签检查（缺一拒绝）
```

**S0 的优势**：论文的策略也是每轮根据任务决策轴动态生成的。S0 是对这一点的工程化近似。

### S1-S6: 固定策略矩阵（保留，作为多样性保障）

| 策略 | 决策轴 | 核心操作 |
|------|--------|---------|
| S1: 指令精化 | 指令粒度 | 模糊动词→精确操作序列+参数 |
| S2: 工作流重组 | 流程拓扑 | 步骤合并/拆分/重排 |
| S3: 边界增强 | 容错范围 | IF-ELSE/fallback/校验/兜底 |
| S4: 上下文优化 | 信息密度 | 拆分过密/补示例/调模板 |
| S5: 范式转换 | 组织范式 | 线性↔决策树↔状态机↔表格 |
| S6: 拆分/合并 | 边界重组 | 大skill拆分 / 相关skill合并 |

详细策略指南见 [evolution-strategies.md](../evolution-strategies.md)。

## 执行步骤

### Step 0: 预算检查

```
remaining = 100K - 已消耗估算
IF remaining < 70K:
  IF remaining >= 35K:
    → 压缩模式：K=3（S0 + 2个最相关固定策略）
    → 记录：{"event":"budget_compress","k_reduced":"3","ts":"..."}
  ELSE:
    → 终止 [BUDGET-ABORT]
```

### Step 1: K=6/7 并行探索

**有 S0 时**：S0 + S1-S6 = 7 个并行子 agent
**无 S0 时**：S1-S6 = 6 个并行子 agent

子 agent prompt 模板见 [explorer-template.md](prompts/explorer-template.md)。

- 子 agent 用 `ctx_index(content=完整候选, source="{skill}-S{k}")` 存储
- 响应只返回摘要（≤500字）：策略名 + 评分 + 关键改动 ≤3 条
- **不用 Write/Edit 写文件**
- **不在响应中返回完整候选**

**关键约束**：
- 所有子 agent **只能使用 T_train 测试**（不可见 T_val）
- T_val 在 exploration 阶段是 sealed 的

**子 agent 超时保护**：
```
每个子 agent 上限 120s。
超时处理：
  1. 记录：{"event":"subagent_timeout","agent":"S{k}","ts":"..."}
  2. 标记该候选为 N/A
  3. 不重试
  4. 继续等待其他

完成后统计：
  成功 ≥2 → 正常对比学习
  成功 ==1 → 该候选直接作为最优
  成功 ==0 → 触发 Fallback L2
```

### Step 2: 按需检索 + 评分（仅用 T_train）

- `ctx_search(queries=["完整候选"], source="{skill}-S{k}")` 按需检索
- **评分只使用 T_train**（T_val 不可见）
- 逐个评分 + 用 T_train 测试
- 标记 τ+(success) 和 τ-(failure)
- **不要一次拉取所有候选到主 context**

### Step 3: 对比学习（Δr 提取）

仅当成功候选 ≥2 时执行。

- 逐段 diff 每个候选 vs 原始
- 分类：成功版本独有 → +，失败版本独有 → -，两者都有 → =
- Δr = {+段} \ {=段}，按出现频率排序

详见 [evolution-strategies.md](../evolution-strategies.md) 的"对比学习详细操作"。

**论文对比**：
- 论文：Δ_r = φ(τ+) \ φ(τ-)，高奖励 vs 低奖励**轨迹**的对比
- 本实现：Δr = 成功候选 vs 失败候选**版本**的对比
- 区别：论文对比的是部署轨迹，我们对比的是策略产出。不够理想但实用。

### Step 4: 选最优

- T_train 评分最高 → 主推荐
- Δr 置信度最高 → 辅助参考
- 不一致 → 同时展示

## Checkpoint（CP-02）

展示排名 + 对比分析 + trace_source 状态，用户选择策略。

```bash
cd ~/.claude/skills
git commit --allow-empty -m "evolve {skill}: exploration-r{r}-S{k}"
```

**Fallback 矩阵**：

| 场景 | 处理 |
|------|------|
| 成功 ≥2 | 正常流程 |
| 成功 ==1 | 跳过对比学习，直接采用 |
| 成功 ==0 | Fallback L2 |
| Fallback L2 失败 | Fallback L3（终止+诊断） |
| 预算 <35K | 终止 [BUDGET-ABORT] |
| 预算 <70K | 压缩 K=3 |

**局部回滚**：同一模块最多回滚 2 次，超过则终止本轮。
