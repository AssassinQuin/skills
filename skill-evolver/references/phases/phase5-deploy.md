# Phase 5: 部署验证

## 步骤

### Step 1: 子 agent 测试
- sonnet 子 agent 用 `{skill}/.evolve/test-prompts.json` 测试
- 加 traces.jsonl 中的失败场景（如有）

### Step 2: 三维验证
a. 失败场景改善
b. 成功场景不退化
c. 新场景可用

### Step 3: 记录日志 + 更新指标

**追加进化日志**：
```bash
# 追加一条 JSON 到 {skill}/.evolve/evolution-log.jsonl
echo '{"ts":"...","round":1,"strategy":"S1","score_before":63.5,"score_after":80.5,...}' >> {skill}/.evolve/evolution-log.jsonl
```

**更新指标**：
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
  fs.writeFileSync(p, JSON.stringify(m, null, 2));
"
```

**Git 提交**：
```bash
cd ~/.claude/skills
git add {skill}/.evolve/ {skill}/SKILL.md
git commit -m "evolve {skill}: R{轮次} score {before}→{after}"
```

## 关卡 5（与关卡 4 合并确认）

```
部署结果：
- 测试通过率：X/Y
- 退化检查：无/有

本轮总结：
- 策略：S{k}
- 评分：{before} → {after}（Δ +{N}）
- 审计：{X}/10 PASS
```

## 退化处理

如部署验证发现退化：
```bash
cd ~/.claude/skills && git revert HEAD
```
