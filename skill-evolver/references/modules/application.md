# Module: Application（精准应用）

前置条件：exploration checkpoint 已通过（最优候选已选定）。预估 token：~6K。

## 模块前置校验

```
1. exploration checkpoint 已通过 → 对话历史中有确认消息
2. 最优策略已选定 → S1-S6 之一

IF 不满足: 输出 [PRE-CHECK-FAIL] + 缺失项，禁止继续
```

## 原则

双轨编辑：根据改动范围自动选择模式（`diff-budget-check` 判定）。

## 执行步骤

### Step 1: 判定编辑模式

```bash
diff-budget-check {skill_dir} {affected_segment_count}
```

**BOUNDED_EDIT**（≤3 段）：行级 add/delete/replace，受 textual learning rate 约束（改动量 ≤ 原文对应段的 30%）。适合痛点修复、内容精简、局部改进。

**FULL_REWRITE**（>3 段或结构性变化）：完整重写受影响段落。适合范式转换、新增流程、章节重组。

### Step 1b: 检索最优候选（BOUNDED_EDIT 时跳过）

用 `ctx_search` 检索最优候选完整内容。

### Step 2: 改写 SKILL.md

主 agent 直接改写：
- 需要改的部分 → 完整重写
- 不涉及的部分 → 保持原样
- 新增边界条件有具体操作
- 整体结构连贯无矛盾

### Step 3: Git Commit（CP-03）

```bash
cd ~/.claude/skills
git add {skill}/SKILL.md
git commit -m "evolve {skill}: apply-r{r}-{策略}"
```

## 关卡：用户确认改动

展示完整 git diff + 评分预估（对照 rubric 锚点）。

用户可指出具体段落要求重写。确认后进入 audit 模块。

**Fallback**：预估分 ≤ 基线分 → 放弃改写，回 exploration 重新选策略（回滚到 CP-02）。

**局部回滚**：`git reset HEAD~1` 回到改写前。
