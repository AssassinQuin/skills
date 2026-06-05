# Module: Deployment（部署验证 + T_val 验证）

前置条件：audit 已通过（Score > 基线 且 无维度 < 5）。预估 token：~14K。

## 前置校验

```bash
phase-check deployment {skill_dir}
```

## 执行步骤

### Step 1: T_train 回归测试（sonnet 子 agent）

用 T_train 测试改写后的 skill + traces.jsonl 失败场景。

### Step 2: T_val Held-out 验证（独立 opus 子 agent）

独立 opus agent 在全新上下文中读取 SKILL.md + T_val，模拟执行每个 T_val prompt，输出通过率。Prompt 模板见 [deployer-template.md](prompts/deployer-template.md)。

### Step 3: 退化判定

| 指标 | 进步 | 部分进步 | 退化 |
|------|------|---------|------|
| T_train 回归 | ≥基线+10% | ≥基线 | <基线 |
| T_val 泛化 | ≥80% | ≥60% | <60% |
| Trace 失败改善 | ≥70% | ≥50% | <50% |

综合：进步→接受；部分进步→接受并记录限制；退化→回滚。

### Step 4: 痛点回归守卫

对 `pain-points.jsonl` 中 `status=="resolved"` 的痛点逐一验证：
- 回归率 > 30% → 自动 `git revert HEAD` + `pp-regress` 更新状态
- 单痛点 `regression_count >= 2` → 标记 `wontfix`

### Step 5: 记录日志 + 更新指标

```bash
metrics-update {skill_dir} {round} {strategy} {before} {after} {d1} {d2} {d3} {d4} {d5} {t_train_rate} {t_val_rate}
```

进化日志写入 `.evolve/evolution-log.jsonl`，字段见 SKILL.md 日志文件节。`audit_score` = 审计产出的加权平均分（0-10）。

### Step 6: 更新痛点状态

```bash
pp-resolve {skill_dir} {pp_id} {strategy_id}
```

### Step 7: Git Commit（CP-04）

```bash
git-checkpoint "evolve {skill}: deploy-r{r}-score-{before}-{after}"
```

## 关卡：部署结果确认

```
部署结果：
- T_train 通过率：X/Y
- T_val 通过率：X/Y
- 痛点回归：X/Y
- 退化：progress / partial / regression
- Token：{actual} / {budget}

本轮总结：
- 策略：S{k}
- 评分：{before} → {after}（Δ +{N}）
- 审计：{audit_score}/10
- 痛点：[PP-id → resolved | open]
```

确认后：
- **r < R** → 回 exploration
- **r = R** → `git checkout main && git merge`

## 退化处理

| 场景 | 操作 |
|------|------|
| 部署严重退化 | `git revert HEAD`（回到 CP-03） |
| 审计未通过 | `git reset HEAD~1`（回到 CP-02） |
| 痛点回归率 >30% | `git revert HEAD` + `pp-regress` |
| 同一模块回滚≥2次 | 终止本轮 |
