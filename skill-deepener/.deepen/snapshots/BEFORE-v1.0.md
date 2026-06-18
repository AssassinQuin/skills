---
name: skill-deepener
version: "1.0"
description: >
  Skill 内容深化器。专门给已有但内容空泛的 skill 补专家深度。与 skill-evolver
  互补：skill-evolver 做结构合规（robustness），skill-deepener 做内容深化（depth）。
  核心方法：Anthropic 反推法（失败 case → references）+ Cognitive Apprenticeship
  （Model/Coach/Scaffold/Fade）+ Agent-as-a-Judge（多专家角色评审）+ ECC 4 维度
  诊断。触发词：深化 X skill、X skill 内容深度、让 X 更专业、X 缺方法论、X 缺
  真实案例、X 流程化但缺深度、skill 不够垂直、skill 不够专业。
  不用于：创建 skill（用 skill-creator）、结构合规（用 skill-evolver）、写代码
  （用 coder）。
agent-compatible: true
skill_type: research
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
  - WebSearch
  - WebFetch
  - mcp__searxng__searxng_web_search
  - mcp__searxng__web_url_read
  - mcp__github__search_repositories
  - mcp__github__search_code
  - mcp__zread__read_file
  - mcp__zread__get_repo_structure
  - mcp__memory__memory_search
  - mcp__memory__memory_store
user-invocable: true
---

# Skill Deepener — 内容深化器

把已有但**结构合规、内容空泛**的 skill 升级为**有专家深度**的 skill。

**与 skill-evolver 的边界**：

| skill | 做什么 | 不做什么 |
|-------|--------|---------|
| **skill-evolver** | 结构合规、防过拟合、流程优化、9-check audit | 创造新内容、专家知识 codify |
| **skill-deepener** | 专家知识 codify、失败案例沉淀、深度重写、多专家评审 | 改结构、改流程、9-check |

**原则**：深化只动内容，不动结构（结构归 skill-evolver）。

---

## 输入

- 已有 skill（必须有 SKILL.md）
- 期望深化方向（用户给）：
  - "缺真实案例" → Phase 2 重点跑真实任务
  - "缺方法论" → Phase 3 重点采专家方法
  - "缺判断标准" → Phase 4 重点写 do/don't
  - "整体空泛" → 全流程跑

---

## 流程

```
P1 缺口诊断 → P2 反推通道 → P3 内容采集 → P4 内容重写 → P5 多专家评审 → P6 持久化
     ↓             ↓            ↓            ↓            ↓
 [exit-check]  [exit-check]  [exit-check]  [exit-check]  [exit-check]
 不通过→补完   不通过→补完   不通过→补完   不通过→补完   不通过→补完
```

每个 Phase 完成后必须 AskUserQuestion 展示结果等确认。见 [phase-gates.md](references/phase-gates.md)。

---

### P1: 缺口诊断（4 维度）

用 ECC `skill-stocktake` 4 维度（[gap-diagnosis.md](references/gap-diagnosis.md)）评估目标 skill：

| 维度 | 评分标准 |
|------|---------|
| **Actionability** | code examples / commands / steps 能否立即行动？还是泛泛而谈？ |
| **Scope fit** | name / trigger / content 是否对齐？是否过宽或过窄？ |
| **Uniqueness** | 是否能被 MEMORY.md / CLAUDE.md / 其他 skill 替代？ |
| **Currency** | 技术参考是否过期？（用 WebSearch 验证工具/命令/API） |

每个维度 1-5 分，输出**缺口报告**：

```markdown
## P1 缺口诊断

| 维度 | 评分 | 证据 | 深化方向 |
|------|------|------|---------|
| Actionability | X/5 | {引用 SKILL.md 具体段落} | {补什么} |
| Scope fit | X/5 | {引用} | {补什么} |
| Uniqueness | X/5 | {引用} | {补什么} |
| Currency | X/5 | {引用} | {补什么} |

**优先深化方向**：{P2-P4 重点}
```

**P1 Exit**: 4 维度全评分 + 优先方向明确 + 用户确认。

---

### P2: 反推通道（Anthropic evaluation-first）

**核心方法**：先收集真实失败 case，从失败反推该补什么专家知识。不是写"我觉得该补 X"，是"任务跑下来缺 X"。

**Step 2a: spawn Domain-Skill Agent 跑真实任务**

```
Agent(
  subagent_type="general-purpose",
  model="sonnet",
  prompt="""
你是 Domain-Skill Agent，真实执行 {target_skill} 的代表性任务。

[TASKS]
{2-3 个典型任务，覆盖 skill 的核心场景}

[要求]
1. 按 {target_skill}/SKILL.md 流程真实走
2. 记录每步：做了什么 / 引用 SKILL.md 哪段 / 是否有 expert reasoning gap
3. 输出 JSON：trajectory + reward + expert_reasoning_gaps
  expert_reasoning_gaps = "expert 会怎么判断这步，但 SKILL.md 没说"
"""
)
```

**Step 2b: 萃取失败案例 + expert reasoning gap**

从 Domain-Skill Agent 轨迹萃取：

```markdown
## P2 反推通道

### 失败案例 1
- 任务：{任务描述}
- 失败点：{哪一步出错或低质量}
- Expert 会怎么做：{专家真实判断}
- 当前 SKILL.md 缺什么：{具体段落 / 缺什么原则}

### Expert reasoning gap 清单
1. {gap 描述}
2. {gap 描述}
...
```

**P2 Exit**: 至少 2 个失败案例 + 3 个 expert reasoning gap + 用户确认。

---

### P3: 内容采集（research）

**核心方法**：用 web-research / huashu-nuwa / memory_search 三源并行补内容。

**Step 3a: 分类采集**

按 P2 expert reasoning gap 分类：

| Gap 类型 | 采集工具 | 输出 |
|---------|---------|------|
| 缺方法论 | `web-research` 调研论文/开源项目 | 方法论文档 |
| 缺思维框架 | `huashu-nuwa` 蒸馏专家思考 | 思维框架段 |
| 缺踩坑经验 | `memory_search` 历史经验 + `Agent` 跑踩坑场景 | 失败案例库 |
| 缺判断标准 | 主 agent 综合 P1/P2 + 调研 | do/don't 清单 |

**Step 3b: Cognitive Apprenticeship 四要素提炼**

每个 gap 都用 [cognitive-apprenticeship.md](references/cognitive-apprenticeship.md) 四要素过滤：

```
Modeling（专家出声思考）：
  - "专家这一步会想什么？"
  - "专家为什么这样判断，不那样？"

Coaching（练习时反馈）：
  - "如果用户输入是 X，专家会怎么回应？"
  - "这种情况下，专家会停下来澄清什么？"

Scaffolding（搭脚手架）：
  - "执行前必须问用户的 1-2 个问题？"
  - "用户的什么回答会改变流程？"

Fading（逐步撤支撑）：
  - "什么信号表示用户已经熟练，可以省略这一步？"
  - "什么场景下，新手需要详细脚手架，老手不需要？"
```

**P3 Exit**: 每个分类至少 3 条采集结果 + Cognitive Apprenticeship 过滤完成 + 用户确认。

---

### P4: 内容重写（不动结构）

**核心原则**：只改 SKILL.md 内容，不改结构（不改 frontmatter / Phase 划分 / references 引用）。

**Step 4a: 加"专家出声思考"段**

在每个 Phase 步骤后加 `> 💡 专家视角：{为什么这样判断 / 边角案例}`。

**反例**（流程化）：
```
3. 加载历史经验：memory_search(query="{language} coding gotcha", limit=5)
```

**正例**（深化后）：
```
3. 加载历史经验：memory_search(query="{language} coding gotcha", limit=5)

   > 💡 专家视角：limit=5 不是随便选的——超过 5 条经验 agent 注意力会
   > 分散，反而漏掉最相关的那条。如果 memory_search 返回 8 条，先看
   > 创建时间最近 3 条 + 相关度最高 2 条。如果返回 0 条，标注 "⚠️ 无历史
   > 经验"，提醒用户首次踩坑风险。
```

**Step 4b: 加"脚手架问题"段**

在执行前加反问用户的问题：

```markdown
### 执行前脚手架（必问）

| 问题 | 用户回答影响 |
|------|------------|
| "这次任务是新增还是重构？" | 重构 → 启用保护测试；新增 → 委托 tdd |
| "改动范围单文件还是跨模块？" | 跨模块 → 升级复杂度为完整路径 |
```

**Step 4c: 加"失败案例库"段**

把 P2 的失败案例沉淀进 references/ 或 SKILL.md：

```markdown
### 失败案例库（来自实战）

#### 案例 1：{任务类型}
- **触发场景**：{什么时候会遇到}
- **失败模式**：{agent 实际怎么错的}
- **Expert 正确做法**：{专家怎么做}
- **对应规则**：{SKILL.md 哪条 do/don't 防这个}
```

**Step 4d: 加"do/don't 判断标准"段**

把抽象指导改为可操作 do/don't（ECC rules-distill 标准）：

**反例**：
```
- 重视代码质量
```

**正例**：
```
- DO：每次改动后跑 lint，少于 3 个 warning 才进下一步
- DON'T：跳过 lint 因为"改动很小"
```

**P4 Exit**: 至少 3 段新增内容（专家视角 / 脚手架 / 失败案例 / do-don't）+ 结构未变 + 用户确认。

---

### P5: 多专家角色评审（Agent-as-a-Judge）

**核心方法**：spawn 3 个角色评审（[expert-role-audit.md](references/expert-role-audit.md)）。

| 角色 | 评估维度 |
|------|---------|
| **方法论严谨者** | 是否有具体方法论？是否经得起推敲？ |
| **案例真实者** | 案例是否真实可追溯？是否包含失败模式？ |
| **领域准确者** | 领域术语是否准确？是否符合 expert 共识？ |

**Step 5a: 并行 spawn 3 个 auditor**

```
Agent(
  subagent_type="evolver-auditor",
  model="opus",
  prompt="{role-specific 评估 prompt}"
)
```

**Step 5b: 汇总 + 改进**

```markdown
## P5 多专家评审

### 方法论严谨者：{verdict} {score}
- 优点：{1-2 条}
- 缺点：{1-2 条}
- 建议：{具体改动}

### 案例真实者：{verdict} {score}
...

### 领域准确者：{verdict} {score}
...

**综合 verdict**：accept / revise / reject
**改进清单**：{汇总}
```

**P5 Exit**: 3 角色全评审 + 综合 verdict + 改进清单 + 用户确认。

---

### P6: 持久化

**本地保存**：

```
{target_skill}/.deepen/{YYYYMMDD}/
├── p1-gap-diagnosis.md       # P1 4 维度诊断
├── p2-reverse-channel.md     # P2 失败案例 + expert gap
├── p3-research.md            # P3 采集结果
├── p4-rewrite-diff.md        # P4 改动 diff
├── p5-expert-audit.md        # P5 多专家评审
├── BEFORE-SKILL.md           # 深化前快照
└── raw/
    └── domain-skill-agent-trajectory.json
```

**Memory 持久化**：

```
memory_store(
  content="{skill-name} 深化经验: {核心 finding}",
  tags="deepen-{skill-name}, deepen-experience"
)
```

---

## 硬约束

1. **不动结构** — frontmatter / Phase 划分 / references 引用保持不变（结构归 skill-evolver）
2. **不删现有内容** — 增量深化，禁止删除 v_n 已有段落
3. **案例必须真实** — 不能编造失败案例 / 数据 / URL（违反 coding-rules R12）
4. **专家语言必须具体** — 禁止"重视 X" / "X 很重要"，必须 "do X" / "don't Y" + 具体场景
5. **P2 必须 spawn Domain-Skill Agent** — 禁止主 agent 模拟执行（论文 §3.1 价值锚定）
6. **P5 必须 3 角色** — 不能合并为单 auditor
7. **Cognitive Apprenticeship 四要素全过滤** — 不能只用 Modeling 跳过其他三个
8. **不超过 SKILL.md 行数预算** — 深化后总行数 ≤ 原行数 × 1.5（避免膨胀，Anthropic 反 monolithic）

---

## 与其他 skill 的协作

| 场景 | skill 链 |
|------|---------|
| 想从零造专业 skill | huashu-nuwa（蒸馏）→ skill-creator（结构化）→ skill-deepener（深化）→ skill-evolver（合规） |
| 想优化已有空泛 skill | **skill-deepener**（深化）→ skill-evolver（合规） |
| 想审计已有 skill | skill-evolver audit（结构）+ skill-deepener P1（深度） |
| 想拆 monolithic skill | 暂无（建议手动拆 + skill-deepener 分别深化） |

---

## 退出条件

| 条件 | 行为 |
|------|------|
| 目标 skill 不存在 | 退出，提示用 skill-creator 创建 |
| 目标 skill 是新建（无任何使用历史） | 退出，提示先用 huashu-nuwa/web-research 调研 |
| 目标 skill 已 expert-level（P1 全 5/5） | 退出，提示无需深化 |
| 用户未明确深化方向 | P1 后 AskUserQuestion 让用户选 |
