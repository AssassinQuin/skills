# Module: Deployment（部署验证 + T_val 验证）

前置条件：audit FAIL ≤ 2。预估 token：~10K。

## 模块前置校验

```
1. audit 结果可用 → FAIL 项数 ≤ 2
2. SKILL.md 改写已 commit → git log --oneline -1 显示改写 commit

IF 不满足: 输出 [PRE-CHECK-FAIL] + 缺失项
```

## 执行步骤

### Step 1: T_train 回归测试（子 agent）

sonnet 子 agent 用 `T_train` 测试改写后的 skill。
同时加载 traces.jsonl 中的失败场景追加测试。

Prompt 模板见 [deployer-template.md](prompts/deployer-template.md)。

**关键约束**：子 agent 只能用 T_train，不可见 T_val。

### Step 2: T_val Held-out 验证（独立子 agent，opus）

**核心改进**：T_val 是 exploration 和 application 阶段从未见过的测试 prompt，提供客观的泛化评估。

```
独立 opus 子 agent 执行：
1. 读取改写后的 SKILL.md
2. 读取 T_val（仅 test-prompts.json 中的 "T_val" 数组）
3. 对每个 T_val prompt 模拟执行
4. 判定 PASS/PARTIAL/FAIL
5. 输出 T_val 通过率
```

**T_val 不可见规则**：
- exploration 子 agent 不可见 T_val
- application 主 agent 不可见 T_val
- 只有 deployment 阶段的 opus 验证 agent 可见 T_val

### Step 3: 四维验证

a. **T_train 回归**：通过率 ≥80%（不可低于基线的 T_train 通过率）
b. **T_val 泛化**：通过率 ≥60%（客观指标，不可主观打分）
c. **失败场景改善**：≥50% 的 trace 失败场景得到改善
d. **成功场景不退化**：基线通过的场景仍通过

**退化判定**（改进版）：

| 指标 | 进步 | 部分进步 | 退化 |
|------|------|---------|------|
| T_train 通过率 | ≥基线+10% | ≥基线 | <基线 |
| T_val 通过率 | ≥80% | ≥60% | <60% |
| Trace 失败改善 | ≥70% | ≥50% | <50% |

**综合判定**：
- 进步：T_train ≥基线 AND T_val ≥60% AND 失败改善 ≥50% → 接受
- 部分进步：T_train ≥基线 AND (T_val <60% OR 失败改善 <50%) → 接受但记录限制
- 退化：T_train <基线 → 回滚

### Step 4: Token 追踪 + 效率计算

```json
{
  "round": 1,
  "token_budget": 100000,
  "tokens": {
    "baseline": "~12K",
    "exploration": "~38K",
    "application": "~6K",
    "audit": "~20K",
    "deployment": "~10K",
    "total_actual": "~86K"
  },
  "token_efficiency": 0.86,
  "agent_failure_count": 0,
  "rollback_count": 0,
  "evaluation": {
    "T_train_pass_rate": 0.80,
    "T_val_pass_rate": 0.67,
    "trace_improvement_rate": 0.75
  }
}
```

### Step 5: 记录日志 + 更新指标

**进化日志完整 schema**：
```json
{
  "ts": "ISO-8601",
  "round": 1,
  "skill": "{skill}",
  "strategy": "S0+S5-merge",
  "trace_source": "empirical|sparse|none",
  "score_before": 39.5,
  "score_after": 75,
  "delta": 35.5,
  "dimensions": {"D1": 8, "D2": 8, "D3": 8, "D4": 8, "D5": 8},
  "T_train_pass_rate": 0.80,
  "T_val_pass_rate": 0.67,
  "trace_improvement_rate": 0.75,
  "verdict": "progress|partial|regression",
  "token_budget": 100000,
  "actual_tokens": 86000,
  "token_efficiency": 0.86,
  "agent_failure_count": 0,
  "audit_pass": 10,
  "audit_total": 10,
  "deploy_tests": [{"id": "T1", "result": "PASS"}, ...],
  "val_tests": [{"id": "V1", "result": "PASS"}, ...],
  "deltas_fixed": ["F1", "F2"],
  "rollback_count": 0
}
```

**更新 metrics.json**：同原逻辑，额外追踪：
- `avg_T_val_pass_rate`
- `avg_trace_improvement_rate`
- `trace_source_distribution`

### Step 6: Git Commit（CP-04）

```bash
cd ~/.claude/skills
git add {skill}/.evolve/ {skill}/SKILL.md
git commit -m "evolve {skill}: deploy-r{r}-score-{before}-{after}"
```

## 关卡：部署结果确认（与 audit 合并确认）

```
部署结果：
- T_train 通过率：X/Y（回归检查）
- T_val 通过率：X/Y（held-out 泛化）
- Trace 失败改善：X/Y（≥50% 为通过）
- 退化检查：progress / partial / regression
- Token：{actual} / {budget}（效率 {efficiency}）
- 子 agent 失败：{failures}

本轮总结：
- 策略：S{k}
- 评分：{before} → {after}（Δ +{N}）
- 审计：{X}/10 PASS
- T_val：{pass_rate}（客观泛化指标）
- 回滚：{rollback_count} 次
```

确认后：
- **r < R** → 回 exploration
- **r = R** → `git checkout main && git merge evolve/{skill}/YYYYMMDD`

## 退化处理

```bash
cd ~/.claude/skills && git revert HEAD
```

## 局部回滚

| 场景 | 命令 |
|------|------|
| 部署严重退化 | `git revert HEAD`（回到 CP-03） |
| 审计 FAIL≥3 | `git reset HEAD~1`（回到 CP-02） |
| 同一模块回滚≥2次 | 终止本轮 |
