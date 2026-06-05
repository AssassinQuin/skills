---
name: skill-evolver
version: "3.1"
description: >
  Skill Evolver v3.1 — 部署驱动的 Skill 自进化框架（痛点感知 + 回归守卫）。
  进化信号优先来自真实部署轨迹与结构化痛点，辅以 rubric 分析。
  Trigger: "进化 X skill", "审计 X", "评估 X 质量", "进化 skill-evolver",
  "优化所有 skills", "查看进化历史", "重写 skill",
  "优化 X，痛点 Y", "X 有痛点", "优化 X skill".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Skill Evolver v3.1

> 进化信号优先来自真实部署中的成败轨迹与结构化痛点；无轨迹时退化为 rubric 分析。
> [SkillEvolver](https://arxiv.org/abs/2605.10500) + [darwin-skill](https://github.com/alchaincyf/darwin-skill)

**与论文差异**：见 [references/paper-comparison.md](references/paper-comparison.md)

**v3.1 新增**：痛点生命周期管理 + 部署回归守卫 + 进化上下文持久化（S2 工作流重组 + S3 边界增强融合）

## 决策入口

| 用户意图 | 模式 | 执行模块 |
|----------|------|---------|
| "进化 X skill" | A: 完整进化 | baseline → exploration → application → audit → deployment |
| "优化 X，痛点 Y" | **G: 痛点驱动** | baseline(痛点加载) → exploration(痛点聚焦) → application → audit → deployment(回归守卫) |
| "优化 X"（无痛点） | A: 完整进化 | **提示用户**："未检测到具体痛点。继续 rubric 分析？" 确认后进入 Mode A |
| "审计 X" | B: 快速审计 | audit（独立执行） |
| "评估 X 质量" | C: 质量评估 | baseline（仅评估 + 轨迹收集） |
| "进化 skill-evolver" | D: 自我进化 | 适配模块 [self-evolution.md](references/modules/self-evolution.md) |
| "优化所有 skills" | E: 批量 | baseline 筛选 → 逐个完整进化 |
| "查看进化历史" | F: 只读 | 读 `{skill}/.evolve/evolution-log.jsonl` + `evolution-context.md` |
| "重写 skill" | 跳过 | 直接 skill-creator |

**"优化" 触发词处理规则**：
1. 匹配 `优化 {target}` 后，检查是否附带痛点描述
2. 有痛点 → 提取痛点文本，写入 `pain-points.jsonl`（status: "open"），进入 Mode G
3. 痛点为空或过于模糊（<5 字）→ 提示用户提供具体痛点示例或确认 rubric 模式
4. 无痛点关键词 → 确认后进入 Mode A（用户未确认则默认进入 Mode A）

**Mode G vs Mode A 差异**：

| 步骤 | Mode A（标准） | Mode G（痛点驱动） |
|------|---------------|-------------------|
| baseline 差距分析 | traces → stats → rubric | **痛点第一优先级** → traces → stats → rubric |
| exploration | S0-S6 均等权重 | **痛点门控**：策略须声明解决 >=1 个 open 痛点，否则降权(×0.8) |
| deployment | T_train/T_val 验证 | **额外**：痛点回归检查（验证 resolved 痛点未复发） |
| 产物 | evolution-log + metrics | **额外**：更新 pain-points.jsonl 状态 |

## 痛点生命周期（pain-points.jsonl）

**文件位置**：`{skill}/.evolve/pain-points.jsonl`

**Schema**（每行一个 JSON）：
```json
{
  "id": "PP-{seq}",
  "skill": "{skill-name}",
  "description": "用户描述的痛点",
  "symptom": "可观测的症状",
  "source": "user-stated | trace-inferred | audit-found",
  "status": "open | addressed | resolved | regressed | wontfix",
  "created_at": "ISO-8601",
  "resolved_at": "ISO-8601 或 null",
  "resolved_by": "策略标识 (如 S3) 或 null",
  "round": 进化轮次编号,
  "regression_count": 0
}
```

**状态机**：
```
open ──(exploration 选定策略)──→ addressed ──(deployment 通过)──→ resolved
  │                                                                │
  │                        (回归守卫检测到复发)                      │
  └────────────────────────────────────────────────────────────────┘
                                                                │
                                          (regression_count >= 2) → wontfix
```

**写入时机**：
- 用户显式提供（"优化 X，痛点 Y"）→ baseline Step 3，source="user-stated"
- traces 失败模式（同一失败点 >=3 次）→ baseline Step 8，source="trace-inferred"
- 审计发现（连续 2 轮同维度 <=4）→ baseline Step 8，source="audit-found"

**熔断规则**：`regression_count >= 2` → 自动标记 `wontfix`，阻止反复修复-回退循环。

**文件守卫**：baseline 入口检查 `pain-points.jsonl` 是否存在，不存在则创建空文件。

## 子 Agent 模型分配

| 任务 | subagent_type | 模型 | 独立性 | Prompt 模板 |
|------|--------------|------|--------|------------|
| S0+S1-S6 策略探索 | `evolver-explorer` | sonnet ×6/7 | 新上下文 | [explorer-template.md](references/modules/prompts/explorer-template.md) |
| 独立审计 | `evolver-auditor` | opus | **全新上下文** | [auditor-template.md](references/modules/prompts/auditor-template.md) |
| T_val 独立验证 | `evolver-auditor` | opus | **全新上下文** | [deployer-template.md](references/modules/prompts/deployer-template.md) |
| D5 基线测试 | `evolver-explorer` | sonnet | 新上下文 | 内联（baseline 模块内） |

**模型强制规则（R5.1）**：每次 `Agent()` 调用**必须**同时传 `subagent_type` 和 `model` 参数。两者缺一视为违规。`model` 值必须与本表一致。审计步骤必须验证本轮所有 `Agent()` 调用的模型合规性。

### 数据传输协议

子 agent 无法写文件。用 **ctx_index → ctx_search** 中转：
- 写入侧：`ctx_index(content=完整候选, source="{skill}-S{k}")`，响应仅返回摘要
- 读取侧：`ctx_search` 按需检索，不全量加载

**Fallback 链（3 级）**：
- L1: ctx_index 成功 → 正常并行流程
- L2: ctx_index 失败 → 主 agent 单策略直改（选与 Δ 最匹配的 1 个策略）
- L3: 主 agent 也失败 → 终止，输出结构化诊断到 evolution-log.jsonl

## 5 维评估 Rubric

**评分制**：0-10 分（1 位小数）。每个维度独立评 0-10，加权平均得总分。

| # | 维度 | 权重 | 评估方式 |
|---|------|------|---------|
| D1 | Frontmatter | 10% | 静态分析 |
| D2 | 工作流 | 20% | 静态分析 |
| D3 | 边界/安全 | 15% | 静态分析 |
| D4 | 指令精度 | 20% | 静态分析 |
| D5 | 实测效果 | 35% | **子 agent 客观测试**（T_train 通过率） |

**公式**：`Score = D1×0.10 + D2×0.20 + D3×0.15 + D4×0.20 + D5×0.35`（结果 0-10）

**D5 客观化**：`D5 = (T_train_pass / T_train_total) × 10`

> **Rubric 评分 vs 审计清单是两套独立系统**：
> - **Rubric**（本节）：D1-D5 各 0-10，加权平均 → 衡量 skill 质量
> - **审计清单**（audit 模块）：10 项 PASS/FAIL 检查 → 部署质量门控
> - 两者不要混用。audit "X/10 PASS" 是通过计数，不是 Rubric 分数。

**失效模式诊断**（FM1-FM7 + FM-PP）：评估时按 [failure-modes.md](references/failure-modes.md) 分类风险，audit 报告标注 FM 编号。

**FM-PP（痛点回归失效）**：改写版本重新引入 pain-points.jsonl 中已 resolved 的同类问题。审计时必须检查。

改进后 Score 必须严格高于改进前。

## 流程骨架（R=3 轮迭代）

```
baseline ──── Read references/modules/baseline.md
  │            前置条件：无 | 预估 token：~14K | CP-01
  │            包含：轨迹收集 + 痛点收集 + T_train/T_val 拆分
  │            v3.1: 确保 pain-points.jsonl 存在；Mode G 时提取痛点为 Δ 第一约束
  ▼            关卡 baseline+gap 合并确认
exploration ─ Read references/modules/exploration.md
  │            前置条件：Δ 已确认 | 预估 token：~40K | CP-02
  │            包含：痛点聚焦 + S0 动态策略 + 仅用 T_train 评分
  │            v3.1: 有 open 痛点时，策略须声明解决 >=1 个，否则降权
  ▼            关卡 exploration 独立确认
application ─ Read references/modules/application.md
  │            前置条件：策略已选定 | 预估 token：~6K | CP-03
  │            v3.1: 选定策略后，将对应 pain-points 标记为 "addressed"
  ▼            关卡 application 独立确认
audit ─────── Read references/modules/audit.md
  │            前置条件：改写已 commit | 预估 token：~20K | CP-04
  │            独立 opus + 标记验证 + T_val Overfit 检查
  │            v3.1: FM-PP 审计 — 检查改写是否引入 resolved 痛点的同类问题
  ▼            关卡 audit 独立确认
deployment ── Read references/modules/deployment.md
  │            前置条件：audit FAIL≤2 | 预估 token：~14K
  │            独立 opus T_val 验证 + 痛点回归守卫（不继承进化上下文）
  │            v3.1: 回归守卫 — 对 resolved 痛点逐一验证；
  │                  回归率 >30% → 自动 git revert HEAD + 更新 pain-points
  │                  部署成功后写入 evolution-context.md + 更新 pain-points 状态
  ▼
  ├─ r < R → 回 exploration
  └─ r = R → git merge 到 main
```

**Token 预算**：单轮总计 ≤ 100K。进入每个模块前检查剩余预算，不足则压缩或终止。

**渐进式披露**：每个模块的详细指令在 `references/modules/` 中。进入时 **必须 Read 对应文件**。

## T_train / T_val 拆分（反过拟合）

`test-prompts.json` 拆为 T_train(60%) + T_val(40%)。可见性规则：**exploration/application 不可见 T_val**，仅 deployment 的独立 opus agent 可见。

## 策略矩阵：S0 + S1-S6

| 策略 | 来源 | 条件 |
|------|------|------|
| **S0: 动态策略** | traces.jsonl 失败模式 + pain-points.jsonl 痛点 | trace_source=="empirical"时强制；痛点非空时纳入 S0 输入 |
| S1-S6 | [evolution-strategies.md](references/evolution-strategies.md) | 始终 |

## 关卡合并规则

| 合并点 | 条件 | 拆分条件 |
|--------|------|---------|
| baseline+gap | 首次进化 / 无 traces / 快速模式 / Mode G | 有 traces 且用户要求逐步确认 |
| audit+deployment | 审计无 FAIL≥3 且 diff≤200 行 | FAIL≥3 或 diff>200 行 |

## Git 版本控制

Skill 文件所在目录是 git 仓库（通过 `git rev-parse --show-toplevel` 定位根目录）。分支策略：`evolve/{skill}/YYYYMMDD`

**路径规则**：所有 git 操作用 `git -C $(git rev-parse --show-toplevel)` 或确保路径相对 git root。BEFORE 副本写 `/tmp/`，不用 skill 目录内。

| 时机 | 操作 | Checkpoint |
|------|------|-----------|
| baseline Step 4 | `git checkout -b evolve/{skill}/YYYYMMDD` | CP-01 |
| application Step 3 | `git commit` 改写结果 | CP-03 |
| deployment Step 6 | `git commit` 部署日志 + pain-points.jsonl | CP-04 |
| audit FAIL≥3 | `git reset HEAD~1` | 回到 CP-02 |
| deployment 退化 | `git revert HEAD` | 回到 CP-03 |
| 回归守卫触发 | `git revert HEAD` + 更新 pain-points 为 regressed | 回到 CP-03 |
| 同一模块回滚≥2次 | 终止本轮 | — |
| 收工 | `git checkout main && git merge` | — |

## 日志与指标

- **进化日志**：`{skill}/.evolve/evolution-log.jsonl`（每轮一条 JSON，含 T_val 率 + 痛点统计）
- **累积指标**：`{skill}/.evolve/metrics.json`
- **测试集**：`{skill}/.evolve/test-prompts.json`（T_train + T_val 拆分）
- **轨迹**：`{skill}/.evolve/traces.jsonl`（真实使用轨迹）
- **痛点**：`{skill}/.evolve/pain-points.jsonl`（结构化痛点，跨轮持久化）
- **审计报告**：`{skill}/.evolve/audit-reports/{skill}-R{round}.md`
- **进化上下文**：`{skill}/.evolve/evolution-context.md`（每轮追加 why + what + result）

### pain-points.jsonl 写入/读取时机

**写入**：
- baseline Step 3（Mode G 提取用户痛点）
- baseline Step 8（从 traces 或 rubric 推断痛点）
- deployment 成功后（更新 status: addressed → resolved）
- 回归守卫触发时（更新 status: resolved → regressed，递增 regression_count）

**读取**：
- baseline Step 3（差距分析输入）
- exploration（痛点聚焦，注入子 agent prompt）
- audit（FM-PP 交叉检查）
- deployment（回归守卫验证）

### evolution-context.md 格式

每轮部署成功后追加（不覆盖历史）：
```markdown
## R{N} — {YYYY-MM-DD}
- **策略**：S{k}（{策略名}）
- **为什么改**：Δ 描述（1-2 句）
- **改了什么**：关键改动摘要（≤3 条）
- **痛点解决**：[PP-id → resolved | open]
- **结果**：评分 {before} → {after}（Δ +{N}），T_val {rate}
- **遗留**：未解决的痛点/风险（如有）
```

### 进化日志扩展 schema

```json
{
  "...": "（原有字段不变）",
  "pain_points": {
    "total": 5,
    "open_before": 3,
    "newly_fixed": 2,
    "regressed": 0
  }
}
```

baseline 启动时读取 metrics.json，若以下任一成立则提示效率偏低：
- `avg_score_delta < 0.5` 或 `total_rounds >= 5`（0-10 分制下 delta <0.5 为低效）
- `avg_token_efficiency < 0.4`
- `fallback_count >= 2`
- `avg_T_val_pass_rate < 0.5`（held-out 验证持续失败）
- `pain_point_regression_rate > 0.3`（**v3.1**：痛点回退率过高。regression_rate = regressed_count / (resolved_count + regressed_count)）

## 脚本工具箱

`scripts/evolve.sh` 提供标准化操作，减少手动计算错误和 token 消耗：

| 命令 | 用途 | 使用阶段 |
|------|------|----------|
| `score D1 D2 D3 D4 D5` | 计算加权总分(0-10) | baseline, deployment |
| `metrics-update <args>` | 更新 metrics.json | deployment |
| `pp-create <args>` | 创建痛点条目 | baseline |
| `pp-resolve <dir> <id> <by>` | 标记痛点解决 | deployment |
| `pp-regress <dir> <id>` | 标记痛点回归 | deployment(回归守卫) |
| `git-setup <skill>` | 创建 evolve 分支 | baseline |
| `git-checkpoint <msg>` | 标准化 commit | 各模块 |
| `verify-metrics <dir>` | 验证评分范围[0,10] | deployment |

**用法**：`source scripts/evolve.sh && <command>`

**何时用脚本 vs 模板**：

| 类型 | 适用场景 | 载体 |
|------|----------|------|
| **脚本** | 确定性计算（评分、CRUD、git） | `scripts/evolve.sh` |
| **模板** | 结构化 prompt（子 agent 注入） | `references/modules/prompts/*.md` |
| **LLM 判断** | 差距分析、策略选择、SKILL 改写 | 不模板化 |

## 约束规则（5 类 23 条）

**可靠性**：
1. 路径锚定 — 子 agent 绝对路径 + ls 验证
2. 测试守卫 — 首步验证文件存在
3. 审计隔离 — .before 副本 + BEFORE/AFTER 标记验证（行数确认）
4. 独立审计 — 全新上下文 + opus（`evolver-auditor`），审计和部署验证均用独立 agent
5. 子 agent 不重试 — 超时/失败标记 N/A，继续其他
6. 痛点文件守卫 — baseline 入口确保 pain-points.jsonl 存在

**效率**：
7. Token 节约 — ctx_index 中转，按需检索
8. 写入集中 — 主 agent 写，子 agent 不写
9. 最小 K 保证 — 成功候选≥2 才做对比学习
10. Token 硬上限 — 单轮 ≤100K，每模块入口检查

**质量（反过拟合）**：
11. 完整改写 — 不打补丁
12. 不改核心功能 — 优化"怎么执行"
13. T_train/T_val 严格隔离 — exploration 不可见 T_val
14. R ratchet — 只保留有改进的版本
15. 部署验证独立 — opus 新上下文（`evolver-auditor`），不继承进化信息
16. FM-PP 交叉审计 — 审计时检查改写是否重新引入已 resolved 痛点

**痛点保障**（v3.1 新增）：
17. 痛点持久化 — pain-points.jsonl 跨轮保存，不因进化轮次重置
18. 痛点回归守卫 — deployment 阶段验证 resolved 痛点未复发，回归率 >30% 自动回滚
19. 痛点门控 — exploration 阶段策略须声明解决 >=1 个 open 痛点（有痛点时），否则降权
20. 痛点退化熔断 — 单痛点 regression_count >= 2 → 自动标记 wontfix，阻止循环

**流程**：
21. 关卡不可跳 — 用户确认必须等待
22. D5 客观化 — 通过率而非主观评分
23. 渐进披露 — 模块细节在 references/modules/ 中按需加载
24. **模型强制（R5.1）** — 每次 Agent() 调用必须同时传 subagent_type + model，缺一不可。模型值必须匹配"子 Agent 模型分配"表。审计步骤必须验证本轮所有 Agent() 调用的模型合规，违规记为 WARN
