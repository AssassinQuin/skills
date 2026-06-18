# Module: Finalize + Validate（Phase 4）

对应论文 Algorithm 1 line 13-14：
```
v* ← argmax_{v ∈ {v_1..v_R}} score(v; T_train)    # line 13
return Validate(v*, T_val, V)                      # line 14
```

## 与 v7 deployment 的差异

| v7 deployment（已删） | v8 finalize |
|---------------------|-------------|
| branch-check + regression-check + T_val 实测（三重门） | 单一 Validate(v*, T_val, V) |
| 用户确认 deployment 结果 | 用户确认 v* 选择 + Validate 结果 |
| 部署后 traces 反哺 | 同（deployment-traces 机制保留） |

## 执行步骤

### Step 1: v* ← argmax score(T_train)（论文 line 13）

读取所有轮次的 v_r 在 T_train 上的累积得分：

```bash
# 从 traces.jsonl 统计每个 v_r 的通过率
jq -s 'group_by(.round) | map({round: .[0].round, pass_rate: (map(select(.y == 1)) | length) / length})' {skill_dir}/.evolve/traces.jsonl
```

选 v* = 通过率最高的 v_r（标量 reward 任务取均值最高的）。

**R ratchet（论文 implicit）**：v* 必须严格优于 BEFORE baseline。若所有 v_r 都不优于 BEFORE → 终止 + 报告失败。

```bash
# 保存 v* 副本
cp {skill_dir}/.evolve/snapshots/{skill}-v{r_star}.md {skill_dir}/.evolve/snapshots/{skill}-vSTAR.md
```

### Step 2: Validate(v*, T_val, V)（论文 line 14）

在 **held-out T_val** 上跑 V 个 trial（论文 V=5）。

**严格隔离**：T_val 在 Phase 1 拆分后从未被任何 Domain-Skill Agent 见过。

**v8.1 Gate 3 强制**：Phase 1 已拒绝 T_train = T_val（同源），这里再次校验：
```
if T_val.task_type == T_train.task_type AND T_val.data == T_train.data:
    FAIL "T_val 必须 held-out，禁止同源验证"
```

**v8.1 Skill 类型适配**：根据 Phase 1 Step 2b 检测的 skill 类型，选择 agent + reward：

| Skill 类型 | Agent | Reward |
|----------|-------|--------|
| 执行型 | Domain-Skill Agent (sonnet) | binary |
| 研究型 | Evaluation-Trace Agent (sonnet) | qualitative（A/B 对比、ranking） |
| 文档型 | Reviewer Checkpoint (sonnet) | 5-question review |

为 V 个 T_val prompt **并行** spawn V 个对应类型的 Agent：

```
Agent(
  description="validate-v{i}",
  subagent_type={按 skill 类型选},
  model="sonnet",
  prompt="""
[CANDIDATE SKILL v*]
{skill_dir}/SKILL.md  # 当前已是 v* 状态

[T_VAL TASK]
{t_val_prompt}  # 从未被见过的 prompt

[REWARD DEFINITION]
{reward_type + reward_def}  # binary / qualitative / review
"""
)
```

收集 V 个 (τ, y)。计算：
- **pass_rate_val** = pass / V
- **过拟合信号**：pass_rate_val 比 pass_rate_train（T_train）低 > 30% → 标 `[OVERFIT WARNING]`

### Step 3: 退化判定

```
if pass_rate_val >= threshold（建议 0.6）:
    v* 接受为正式版本
    进入 Step 4 部署
elif pass_rate_val < threshold 但 > BEFORE:
    部分接受（标 `[PARTIAL IMPROVEMENT]`）
    用户决定是否部署
else:
    拒绝 v*
    回滚到 BEFORE
    写 failure report
```

### Step 4: 痛点回归守卫（保留 v7 的核心约束）

如果用户在 Phase 1 时声明了"痛点"（pain points），Validate 后必须验证：

```bash
# 对每个用户声明的痛点，检查 v* 是否真的解决
# 例如："skill 触发太宽松" → 跑一个反例 prompt 看 skill 是否还会被误触发
```

未解决的痛点 → 标记并展示给用户，不阻塞部署但要在 changelog 里记录。

### Step 5: Git Commit + 更新指标

```bash
# v* 已在 SKILL.md 中
git add {skill_dir}/
git commit -m "evolve {skill-name}: r{r_star} v*={pass_rate_val} (was {before_rate})"
```

更新指标：

```bash
# 直接写 metrics.json（不再使用 metrics-update 脚本）
cat > {skill_dir}/.evolve/metrics.json <<EOF
{
  "last_round": {r_star},
  "v_star": "v{r_star}",
  "pass_rate_train": {train_rate},
  "pass_rate_val": {val_rate},
  "before_rate": {before_rate},
  "improvement": {val_rate - before_rate},
  "overfit_warning": {bool},
  "ts": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

### Step 6: 初始化 Deployment Traces（论文 Deployment-Grounded Learning）

```bash
# 创建 deployment-traces.jsonl（空文件，后续会话填充）
touch {skill_dir}/.evolve/deployment-traces.jsonl
```

**机制**（论文 §3.2 隐含 + v7 保留）：
- 部署后的实际使用反馈 → 反哺下一轮进化
- 后续会话中用户使用该 skill 时，主 agent 在结束时记录：
  ```json
  {"ts":"...","trigger":"用户输入匹配的触发词","success":true/false,"failure_point":"失败环节","user_correction":"是否手动纠正"}
  ```
- 下一轮 baseline 启动时 Step 3 读取此文件作为 trace_source

**最低要求**：即使没有自动化 hook，主 agent 在下次进化启动时应手动检查上次部署后的会话记录，提取使用问题。

### Step 7: Checkpoint（CP-FINAL）

**展示给用户**：
- 所有 v_r 的 T_train 通过率对比
- v* 选择理由
- V 个 T_val trial 结果
- pass_rate_val / pass_rate_train / 过拟合信号
- 痛点回归结果
- 决定：部署 v* / 部分接受 / 回滚
- Git commit hash
- 本轮局限：必须声明

**确认后 v* 正式生效**。

## Fallback

| 情况 | 处理 |
|------|------|
| Validate 全 fail（pass_rate_val = 0） | 回滚 BEFORE，写 failure report |
| T_val 跑不出 reward（任务无法客观判定） | 标 `validation=UNVERIFIED`，用户手动判定 |
| Domain-Skill Agent 全超时 | 减小 V，或简化 T_val prompt |

## 输出

完成后：
- `{skill_dir}/SKILL.md` = v*
- `.evolve/metrics.json`
- `.evolve/audit/r{r}.md` × 已审计轮次
- `.evolve/deployment-traces.jsonl`（空，待后续填充）
- `.evolve/evolution-log.jsonl` 增 `{"phase":"finalize","v_star":"v{r_star}","pass_rate_val":N,"committed":true|false}`
- Git commit
