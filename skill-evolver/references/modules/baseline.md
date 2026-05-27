# Module: Baseline（基线评估 + 差距理解 + 轨迹收集）

合并原 Phase 0 + Phase 1 + Trace Collection。前置条件：无。预估 token：~12K。

## 关卡合并规则

与差距确认合并（关卡 baseline+gap）：
- 合并条件：首次进化 / 无 traces / 快速模式
- 拆分条件：有 traces 且用户要求逐步确认（拆为两次独立确认）

## 执行步骤

### Step 1: 确认进化范围

- 用户指定 → 直接使用
- 用户未指定 → 扫描所有 skill 的 5 维评分，展示 TOP-10 低分列表

### Step 2: Trace Collection（实证信号收集）

**核心改进**：进化信号来自真实使用轨迹，而非纯 rubric 猜测。

```bash
# 从 Claude Code 会话历史中提取目标 skill 的使用轨迹
# 会话存储在 ~/.claude/projects/ 下的 JSONL 文件中
# 搜索包含目标 skill 加载记录的会话
```

**Trace 提取规则**：
1. 搜索 `~/.claude/projects/` 下的会话文件
2. 找到加载目标 skill 的会话（搜索 skill name 关键词）
3. 从会话中提取：
   - 用户原始 prompt
   - skill 被如何调用
   - 执行结果（成功/失败/部分成功）
   - 用户的后续反馈（修正、抱怨、手动告知）
4. 保存到 `{skill}/.evolve/traces.jsonl`：
```json
{"ts":"...", "user_prompt":"...", "action_taken":"...", "result":"success|failure|partial", "user_feedback":"..."}
```

**Fallback（无可用 traces 时）**：
- 无会话记录 → 标记 `"trace_source": "none"`，gap 分析退化为 rubric-only
- 有 traces 但 <3 条 → 标记 `"trace_source": "sparse"`，rubric + traces 混合
- ≥3 条 traces → `"trace_source": "empirical"`，traces 驱动

### Step 3: 读取历史指标

读取 `{skill}/.evolve/metrics.json`，展示：
- 上次进化时间、总轮数、平均提升、策略命中历史
- 如果 `avg_score_delta < 5` 或 `total_rounds >= 5` → 提示"效率偏低，考虑 skill-creator 重写"
- 如果 `avg_token_efficiency < 0.4` → 提示"token 浪费严重，建议优化 prompt 精简度"
- 如果 `fallback_count >= 2` → 提示"ctx_index 稳定性问题"

### Step 4: 创建 git 分支（含并发冲突检测）

```bash
cd ~/.claude/skills
existing=$(git branch --list 'evolve/{skill}/*' | tr -d ' ')
IF -n "$existing"; THEN
  → 终止 baseline 模块
  → 记录日志：{"event":"conflict_detected","branch":"$existing","ts":"..."}
  → 输出："[CONFLICT] 检测到未完成的进化分支: $existing"
  → 输出："请先完成或删除该分支：git branch -D $existing"
ELSE
  git checkout -b evolve/{skill}/$(date +%Y%m%d)
FI
```

### Step 5: 基线评估

按 5 维 rubric 评分。维度 1-4 静态分析，维度 5 客观测试。

**校准锚点（每个维度 3 档）**：

| 维度 | 优秀(8-10) | 合格(5-7) | 不合格(0-4) |
|------|-----------|----------|------------|
| D1 Frontmatter | name + description 50-100字 + 触发词 8-15个 + 版本号 + 适用模型 | name + description + 触发词，缺版本号 | 缺 name 或 description 或无触发词 |
| D2 工作流 | 步骤有前置条件 + checkpoint + fallback + token 预估 | 步骤清晰但缺 fallback 或 token 预估 | 步骤模糊或缺失关键阶段 |
| D3 边界/安全 | 有输入校验 + 输出兜底 + 错误恢复 + 并发保护 | 有部分校验但缺错误恢复 | 无边界处理 |
| D4 指令精度 | 每个动词可直接执行 + 有参数默认值 + 有示例 | 多数指令清晰但部分模糊 | 大量模糊动词 |
| D5 实测效果 | **T_train 通过率 ≥80% + T_val 通过率 ≥60%** | T_train 通过率 60-79% | 通过率 <60% |

**D5 客观化改进**：
- D5 不再是主观评分，而是子 agent 执行 T_train 后的实际通过率
- 公式：D5 = (T_train_pass / T_train_total) × 10
- 如果有 T_val（来自 traces），D5 = (T_train_rate × 0.6 + T_val_rate × 0.4) × 10

### Step 6: 设计测试集（T_train / T_val 拆分）

设计 5-8 个测试 prompt，**必须拆分为 T_train 和 T_val**：

```json
{
  "T_train": [
    {"id": "T1", "type": "happy", "prompt": "...", "expect": "..."},
    {"id": "T2", "type": "complex", "prompt": "...", "expect": "..."},
    {"id": "T3", "type": "failure", "prompt": "...", "expect": "..."},
    {"id": "T4", "type": "edge", "prompt": "...", "expect": "..."}
  ],
  "T_val": [
    {"id": "V1", "type": "novel", "prompt": "...", "expect": "..."},
    {"id": "V2", "type": "adversarial", "prompt": "...", "expect": "..."}
  ],
  "source": "agent-designed | trace-extracted | mixed"
}
```

**T_train**（60%，4 条）：用于 exploration 阶段的策略评分
**T_val**（40%，2-3 条）：held-out，**仅在 deployment 阶段使用**，exploration 和 application 阶段不可见

**优先从 traces 提取真实 prompt**：
- traces ≥3 条 → 从中提取 T_train 和 T_val（真实用户 prompt 最有价值）
- traces <3 条 → 主 agent 设计，但 T_val 必须包含 1 条"未在 SKILL.md 中显式提及"的场景

保存到 `{skill}/.evolve/test-prompts.json`。

### Step 7: 初始化 .evolve 目录

```bash
mkdir -p {skill}/.evolve/audit-reports
touch {skill}/.evolve/evolution-log.jsonl
```

### Step 8: 差距分析

**信号收集**（按优先级取第一个有数据的）：

| 优先级 | 信号源 | 读取方式 | 优先级理由 |
|--------|--------|---------|-----------|
| 1 | `traces.jsonl` | `{skill}/.evolve/traces.jsonl` | 真实失败是最佳信号（论文核心） |
| 2 | `.stats/usage.jsonl` | skill-stats 格式 | 使用频率反映真实需求 |
| 3 | 基线评分 | Step 5 的 5 维评分（始终可用） | 退化为规范分析 |

**差距报告格式**：
```markdown
## 差距报告：{skill-name}

### 信号源
- trace_source: empirical / sparse / none
- traces 可用: N 条 (成功: X, 失败: Y, 部分: Z)

### 擅长
- ...
### 失败模式（来自 traces）
- 失败点1：...（出现 N 次）— 来自 trace 证据
- 失败点2：... — 来自 rubric 分析
### 评分短板交叉验证
- 维度X得分Y → 与失败模式Z 相关
### 差距描述 Δ
- 该 skill 应能做到 [A] 但实际在 [B] 场景下失败
- 根因分析：[C]
- 证据类型：trace-empirical / rubric-inferred
```

### Step 9: Checkpoint（CP-01）

```bash
cd ~/.claude/skills
git add {skill}/.evolve/ {skill}/.evolve/traces.jsonl
git commit --allow-empty -m "evolve {skill}: baseline+gap-r{r}"
```

## 关卡：用户确认

展示：
1. trace_source 状态（empirical/sparse/none）
2. 基线评分 + 差距报告
3. T_train/T_val 拆分结果
4. token 预算分配（总计 100K，baseline ~12K，剩余 ~88K）

用户确认后进入 exploration 模块。
