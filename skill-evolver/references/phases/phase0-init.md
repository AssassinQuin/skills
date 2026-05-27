# Phase 0: 初始化

## 步骤

1. **确认进化范围**
   - 用户指定 → 直接使用
   - 用户未指定 → 扫描所有 skill 的 5 维评分，展示 TOP-10 低分列表

2. **读取历史指标**（如有）
   - 读取 `{skill}/.evolve/metrics.json`
   - 展示：上次进化时间、总轮数、平均提升、策略命中历史
   - 如果 `avg_score_delta < 5` 或 `total_rounds >= 5` → 提示"效率偏低，考虑 skill-creator 重写"

3. **创建 git 分支**
   ```bash
   cd ~/.claude/skills && git checkout -b evolve/{skill}/YYYYMMDD
   ```

4. **基线评估**
   - 按 5 维 rubric 完整评分（维度 5 必须跑子 agent 测试）
   - 维度 1-4 静态分析，维度 5 用子 agent 实测
   - 记录基线总分和各维度分

5. **设计测试集**
   - 设计 3-5 个测试 prompt（happy path + 复杂场景 + 已知失败场景）
   - **保存到** `{skill}/.evolve/test-prompts.json`
   - 格式：
   ```json
   [
     {"id": "T1", "type": "happy", "prompt": "..."},
     {"id": "T2", "type": "complex", "prompt": "..."},
     {"id": "T3", "type": "failure", "prompt": "..."}
   ]
   ```

6. **初始化 .evolve 目录**（如不存在）
   ```bash
   mkdir -p {skill}/.evolve
   touch {skill}/.evolve/evolution-log.jsonl
   ```

## 关卡 0：用户确认

展示：
```
进化范围：[skill 列表]
历史指标：[如有的话]
基线评分：[5 维得分 + 总分]
测试 prompt：[已保存到 {skill}/.evolve/test-prompts.json]
```

用户确认后进入 Phase 1。
