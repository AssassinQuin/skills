# Phase Gates（exit-checklist）

每个 Phase 完成后必须执行对应 checklist。**全部打勾才能进入下一阶段**。

## P1 Exit（缺口诊断）

```
□ Actionability 评分完成（1-5）+ 证据（SKILL.md 行号）
□ Scope fit 评分完成 + 证据
□ Uniqueness 评分完成 + 证据
□ Currency 评分完成 + 证据
□ Content Depth 评分完成（v1.1 新增，1-5）+ 证据
□ Trigger Precision 评分完成（v1.2 新增，1-5）+ 证据
□ Currency 验证：用 WebSearch 查工具/命令/API 是否过期
□ 6 维度综合 verdict（Keep/Improve/Update/Retire/Merge，v1.2 新增）
□ 优先深化方向明确（P2-P4 重点）
□ AskUserQuestion 展示诊断报告等用户确认
```

## P2 Exit（反推通道）

```
□ 至少 2 个真实任务被 Domain-Skill Agent 跑过
□ Domain-Skill Agent 是真 spawn（subagent_type="general-purpose", model="sonnet"），非主 agent 模拟
□ 至少 2 个失败案例 + 触发场景 + expert 正确做法
□ 至少 3 个 expert reasoning gap 清单
□ gap 必须可追溯（来自真实轨迹，非主 agent 反思）
□ AskUserQuestion 展示反推报告等用户确认
```

## P3 Exit（内容采集）

```
□ 每个 expert reasoning gap 都有对应采集结果
□ 采集工具分类正确：
  - 缺方法论 → web-research
  - 缺思维框架 → huashu-nuwa
  - 缺踩坑 → memory_search + Agent
  - 缺判断标准 → 综合
□ Cognitive Apprenticeship 四要素全过滤（Modeling + Coaching + Scaffolding + Fading）
□ 每个分类至少 3 条采集结果
□ AskUserQuestion 展示采集报告等用户确认
```

## P4 Exit（内容重写）

```
□ 至少 3 段新增内容（从 4 类中选）：
  - 专家出声思考段（>💡 专家视角）
  - 脚手架问题段（执行前反问）
  - 失败案例库段（来自 P2）
  - do/don't 判断标准段
□ 结构未变（frontmatter / Phase 划分 / references 引用）
□ 行数 ≤ 原行数 × 1.5
□ 所有案例可追溯（非编造）
□ 所有"do/don't"含具体场景
□ AskUserQuestion 展示 diff 等用户确认
```

## P5 Exit（多专家评审）

```
□ 3 角色 auditor 全 spawn（subagent_type="evolver-auditor", model="opus"）
  - 方法论严谨者
  - 案例真实者
  - 领域准确者
□ 每个角色独立 fresh context（不能共享 context）
□ 综合 verdict 输出（accept / revise / reject）
□ 改进清单（如 revise）
□ 改进后重新评审（如 reject）
□ AskUserQuestion 展示评审报告等用户确认
```

## P6 Exit（持久化）

```
□ BEFORE 快照保存到 .deepen/{date}/BEFORE-SKILL.md
□ P1-P5 报告分别保存
□ raw/domain-skill-agent-trajectory.json 保存
□ Memory 持久化（tag: deepen-{skill-name}, deepen-experience）
□ Git commit（branch: deepen/{skill}/{date}）
□ AskUserQuestion 展示完成报告
```

## 退化处理

任何 Phase 退化（评分低于基线）→ 立即 git reset HEAD~1 回滚到上一 checkpoint。

退化定义：
- P1 4 维度总和低于深化前
- P5 任一角色 reject
- SKILL.md 行数超预算
- 现有 v_n 段落被删除（结构破坏）
