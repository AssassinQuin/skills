# Module: Deployment（部署验证）

前置条件：audit FAIL ≤ 2。预估 token：~10K。

## 模块前置校验

```
1. audit 结果可用 → FAIL 项数 ≤ 2
2. SKILL.md 改写已 commit → git log --oneline -1 显示改写 commit

IF 不满足: 输出 [PRE-CHECK-FAIL] + 缺失项
```

## 执行步骤

### Step 1: 子 agent 测试

sonnet 子 agent 用 `{skill}/.evolve/test-prompts.json` 测试。
同时加载 traces.jsonl 中的失败场景追加测试。

Prompt 模板见 [deployer-template.md](prompts/deployer-template.md)。

### Step 2: 三维验证

a. **失败场景改善**：≥50% 改善视为通过
b. **成功场景不退化**：happy path 仍通过
c. **新场景可用**：未在训练中出现的 prompt 可用

### Step 3: Token 追踪 + 效率计算

```json
{
  "round": 1,
  "token_budget": 100000,
  "tokens": {
    "baseline": "~8K",
    "exploration": "~38K",
    "application": "~6K",
    "audit": "~20K",
    "deployment": "~10K",
    "total_actual": "~82K"
  },
  "token_efficiency": 0.82,
  "agent_failure_count": 1,
  "rollback_count": 0
}
```

**token_efficiency** = total_actual / token_budget
- 理想：0.6-0.8
- <0.4：浪费严重
- >0.9：接近截断风险

### Step 4: 记录日志 + 更新指标

**进化日志完整 schema**：
```json
{
  "ts": "ISO-8601",
  "round": 1,
  "skill": "{skill}",
  "strategy": "S5+S1-merge",
  "score_before": 58,
  "score_after": 82,
  "delta": 24,
  "dimensions": {"D1": 9, "D2": 17, "D3": 14, "D4": 17, "D5": 25},
  "token_budget": 100000,
  "actual_tokens": 82000,
  "token_efficiency": 0.82,
  "agent_failure_count": 1,
  "audit_pass": 10,
  "audit_total": 10,
  "deploy_tests": [{"id": "T1", "result": "PASS"}, ...],
  "deltas_fixed": ["F1", "F2", "F4", "F6", "F8"],
  "rollback_count": 0
}
```

**更新 metrics.json**：
```bash
node -e "
  const fs = require('fs');
  const p = '{skill}/.evolve/metrics.json';
  const m = fs.existsSync(p) ? JSON.parse(fs.readFileSync(p)) : {};
  m.total_rounds = (m.total_rounds || 0) + 1;
  m.total_score_delta = (m.total_score_delta || 0) + {delta};
  m.avg_score_delta = Math.round(m.total_score_delta / m.total_rounds * 10) / 10;
  m.last_evolved = new Date().toISOString().split('T')[0];
  if (!m.strategy_hits) m.strategy_hits = {};
  m.strategy_hits['{strategy}'] = (m.strategy_hits['{strategy}'] || 0) + 1;
  m.total_token_actual = (m.total_token_actual || 0) + {actual_tokens};
  m.total_token_budget = (m.total_token_budget || 0) + {token_budget};
  m.avg_token_efficiency = Math.round(m.total_token_actual / m.total_token_budget * 100) / 100;
  m.total_agent_failures = (m.total_agent_failures || 0) + {agent_failure_count};
  fs.writeFileSync(p, JSON.stringify(m, null, 2));
"
```

### Step 5: Git Commit（CP-04）

```bash
cd ~/.claude/skills
git add {skill}/.evolve/ {skill}/SKILL.md
git commit -m "evolve {skill}: deploy-r{r}-score-{before}-{after}"
```

## 关卡：部署结果确认（与 audit 合并确认）

```
部署结果：
- 测试通过率：X/Y
- 退化检查：无/有
- Token：{actual} / {budget}（效率 {efficiency}）
- 子 agent 失败：{failures}

本轮总结：
- 策略：S{k}
- 评分：{before} → {after}（Δ +{N}）
- 审计：{X}/10 PASS
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
