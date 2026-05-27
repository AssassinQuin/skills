# Phase 3: 精准应用

## 原则
准确完整地改写目标段落，不是打补丁。

## 步骤

1. 用 `ctx_search` 检索最优候选完整内容
2. 主 agent 直接改写目标 SKILL.md
   - 需要改的部分 → 完整重写
   - 不涉及的部分 → 保持原样
3. 改写要求：
   - 自成逻辑，不依赖隐含假设
   - 新增边界条件有具体操作
   - 整体结构连贯无矛盾
4. git commit：
   ```bash
   cd ~/.claude/skills
   git add {skill}/SKILL.md
   git commit -m "evolve {skill}: {策略}-R{轮次}-{改动摘要}"
   ```

## 关卡 3：用户确认

展示完整 git diff + 评分预估。用户可指出具体段落要求重写。
