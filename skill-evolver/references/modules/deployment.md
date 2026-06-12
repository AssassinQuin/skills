# Module: Deployment（部署验证 + T_val 验证）

前置条件：audit 已通过（Score > 基线 且 无维度 < 5）。预估 token：~14K。

## 前置校验

```bash
phase-check deployment {skill_dir}
```

## 执行步骤

### Step 1: T_train 回归测试（sonnet 子 agent）

**必须 spawn sonnet 子 agent 执行**，禁止主 agent 自行验证。子 agent 读取 SKILL.md + T_train，模拟执行每个 prompt，返回通过/失败结果。

如果 T_train 未由子 agent 实际执行，日志中 T_train_rate 必须标记为 "UNVERIFIED"，不可填写通过率。

### Step 2: T_val Held-out 验证（独立 opus 子 agent）

独立 opus agent 在全新上下文中读取 SKILL.md + T_val，模拟执行每个 T_val prompt，输出通过率。Prompt 模板见 [deployer-template.md](prompts/deployer-template.md)。

**T_val 是 deployment 的硬性门控**。如果未 spawn opus 子 agent 执行 T_val，deployment 必须中止。

### Step 3: 退化判定

| 指标 | 进步 | 部分进步 | 退化 |
|------|------|---------|------|
| T_train 回归 | ≥基线+10% | ≥基线 | <基线 |
| T_val 泛化 | ≥80% | ≥60% | <60% |
| Trace 失败改善 | ≥70% | ≥50% | <50% |

综合：进步→接受；部分进步→接受并记录限制；退化→回滚。

### Step 4: 痛点回归守卫（强制）

对 `pain-points.jsonl` 中 `status=="resolved"` 的痛点逐一验证：

```bash
source evolve.sh
# 读取所有 resolved 痛点
cat {skill_dir}/.evolve/pain-points.jsonl | jq -c 'select(.status=="resolved")'
```

对每个 resolved 痛点：
1. 读取其 `description` 和 `symptom`
2. 检查 SKILL.md 中对应的修复内容是否仍然存在
3. 验证方法：grep SKILL.md 中与痛点修复相关的关键词/段落
4. 结果：PASS（修复仍有效）/ FAIL（回归）

回归处理：
- 任何 FAIL → `pp-regress {skill_dir} {pp_id}` + 记录回归原因
- 回归率 > 30% → 自动 `git revert HEAD` + 终止部署
- 单痛点 `regression_count >= 2` → 标记 `wontfix`

输出格式：
```
痛点回归测试：
| 痛点 | 状态 | 验证结果 |
|------|------|---------|
| PP-xxx | resolved | PASS: {验证证据} |
| PP-yyy | resolved | FAIL: {回归原因} |
回归率: X/Y (Z%)
```

### Step 5: 记录日志 + 更新指标

```bash
metrics-update {skill_dir} {round} {strategy} {before} {after} {d1} {d2} {d3} {d4} {d5} {t_train_rate} {t_val_rate}
```

进化日志写入 `.evolve/evolution-log.jsonl`，字段见 SKILL.md 日志文件节。`audit_score` = 审计产出的加权平均分（0-10）。

### Step 6: 更新痛点状态

```bash
pp-resolve {skill_dir} {pp_id} {strategy_id}
```

### Step 7: Git Commit（CP-04）+ 初始化 deployment-traces

```bash
git-checkpoint "evolve {skill}: deploy-r{r}-score-{before}-{after}"
# 确保 deployment-traces.jsonl 存在
touch {skill_dir}/.evolve/deployment-traces.jsonl
```

## 关卡：部署结果确认

```
部署结果：
- T_train 通过率：X/Y（子 agent 执行 / UNVERIFIED）
- T_val 通过率：X/Y（opus 子 agent 执行 / UNVERIFIED）
- 痛点回归：X/Y
- 退化：progress / partial / regression
- Token：{actual} / {budget}
- BEFORE 快照：.evolve/snapshots/ 存在 / 不存在
- 审计报告：.evolve/audit-reports/ 存在 / 不存在

诚信自检：
□ T_train 由子 agent 实际执行（非主 agent 自评）
□ T_val 由 opus 子 agent 独立执行
□ 审计由 opus 子 agent 独立执行（Quick Fix 也不例外）
□ BEFORE 快照保存在 .evolve/snapshots/（非 /tmp/）
□ 审计报告已保存到 .evolve/audit-reports/
□ deployment-traces.jsonl 已创建

本轮总结：
- 策略：S{k}
- 评分：{before} → {after}（Δ +{N}）
- 审计：{audit_score}/10
- 痛点：[PP-id → resolved | open]
```

确认后：
- **r < R** → 回 exploration
- **r = R** → `git checkout main && git merge`

### Step 8: Deployment Feedback 收集（Deployment-Grounded Learning）

部署后的实际使用反馈 → 反哺下一轮进化。

**机制**：
1. 部署完成后，在 `.evolve/` 下创建 `deployment-traces.jsonl`
2. 后续会话中使用该 skill 时，记录以下信息：
   ```json
   {"ts":"...", "trigger":"用户输入匹配的触发词", "success":true/false,
    "failure_point":"失败环节（如有）", "user_correction":"用户是否手动纠正"}
   ```
3. 下一轮 baseline 的 Step 3 读取此文件作为 trace_source
4. 形成闭环：**部署 → 使用反馈 → 下一轮进化输入**

**最低要求**：即使没有自动化 hook，主 agent 在下次进化启动时应手动检查上次部署后的会话记录，提取使用问题。

## 退化处理

| 场景 | 操作 |
|------|------|
| 部署严重退化 | `git revert HEAD`（回到 CP-03） |
| 审计未通过 | `git reset HEAD~1`（回到 CP-02） |
| 痛点回归率 >30% | `git revert HEAD` + `pp-regress` |
| 同一模块回滚≥2次 | 终止本轮 |
