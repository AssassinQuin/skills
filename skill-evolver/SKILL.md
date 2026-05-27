---
name: skill-evolver
version: "3.0"
description: >
  Skill Evolver v3 — 部署驱动的 Skill 自进化框架。
  进化信号优先来自真实部署轨迹，辅以 rubric 分析。
  Trigger: "进化 X skill", "审计 X", "评估 X 质量", "进化 skill-evolver",
  "优化所有 skills", "查看进化历史", "重写 skill"。
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Skill Evolver v3

> 进化信号优先来自真实部署中的成败轨迹；无轨迹时退化为 rubric 分析。
> [SkillEvolver](https://arxiv.org/abs/2605.10500) + [darwin-skill](https://github.com/alchaincyf/darwin-skill)

## 与论文的定位差异

| 方面 | 论文 SkillEvolver | 本框架 |
|------|-------------------|--------|
| 反馈信号 | 始终来自部署失败 | **优先**来自轨迹，退化时用 rubric |
| 评估 | avg@5 客观通过率 | T_train 通过率 + T_val held-out 验证 |
| 策略 | 每轮动态生成 | S0(动态) + S1-S6(固定)，S0 优先 |
| Agent 架构 | 双 Agent（进化者≠使用者） | 子 agent 隔离 + 独立 opus 审计/部署验证 |

## 决策入口

| 用户意图 | 模式 | 执行模块 |
|----------|------|---------|
| "进化 X skill" | A: 完整进化 | baseline → exploration → application → audit → deployment |
| "审计 X" | B: 快速审计 | audit（独立执行） |
| "评估 X 质量" | C: 质量评估 | baseline（仅评估 + 轨迹收集） |
| "进化 skill-evolver" | D: 自我进化 | 完整进化，基线用本文件，策略应用于 SKILL.md + references/ |
| "优化所有 skills" | E: 批量 | baseline 筛选 → 逐个完整进化 |
| "查看进化历史" | F: 只读 | 读 `{skill}/.evolve/evolution-log.jsonl` |
| "重写 skill" | 跳过 | 直接 skill-creator |

## 子 Agent 模型分配

| 任务 | 模型 | 独立性 | Prompt 模板 |
|------|------|--------|------------|
| S0+S1-S6 策略探索 | sonnet ×6/7 | 新上下文 | [explorer-template.md](references/modules/prompts/explorer-template.md) |
| 独立审计 | opus | **全新上下文** | [auditor-template.md](references/modules/prompts/auditor-template.md) |
| T_val 独立验证 | opus | **全新上下文** | [deployer-template.md](references/modules/prompts/deployer-template.md) |
| D5 基线测试 | sonnet | 新上下文 | 内联（baseline 模块内） |

### 数据传输协议

子 agent 无法写文件。用 **ctx_index → ctx_search** 中转：
- 写入侧：`ctx_index(content=完整候选, source="{skill}-S{k}")`，响应仅返回摘要
- 读取侧：`ctx_search` 按需检索，不全量加载

**Fallback 链（3 级）**：
- L1: ctx_index 成功 → 正常并行流程
- L2: ctx_index 失败 → 主 agent 单策略直改（选与 Δ 最匹配的 1 个策略）
- L3: 主 agent 也失败 → 终止，输出结构化诊断到 evolution-log.jsonl

## 5 维评估 Rubric（总分 100）

| # | 维度 | 权重 | 评估方式 |
|---|------|------|---------|
| 1 | Frontmatter | 10 | 静态分析 |
| 2 | 工作流 | 20 | 静态分析 |
| 3 | 边界/安全 | 15 | 静态分析 |
| 4 | 指令精度 | 20 | 静态分析 |
| 5 | 实测效果 | 35 | **子 agent 客观测试**（T_train 通过率） |

D5 客观化：D5 = (T_train_pass / T_train_total) × 10
总分 = Σ(维度分 × 权重) / 10。改进后必须严格高于改进前。

## 流程骨架（R=3 轮迭代）

```
baseline ──── Read references/modules/baseline.md
  │            前置条件：无 | 预估 token：~12K | CP-01
  │            包含：轨迹收集 + T_train/T_val 拆分
  ▼            关卡 baseline+gap 合并确认
exploration ─ Read references/modules/exploration.md
  │            前置条件：Δ 已确认 | 预估 token：~38K | CP-02
  │            包含：S0 动态策略 + 仅用 T_train 评分
  ▼            关卡 exploration 独立确认
application ─ Read references/modules/application.md
  │            前置条件：策略已选定 | 预估 token：~6K | CP-03
  ▼            关卡 application 独立确认
audit ─────── Read references/modules/audit.md
  │            前置条件：改写已 commit | 预估 token：~20K | CP-04
  │            独立 opus + 标记验证 + T_val Overfit 检查
  ▼            关卡 audit 独立确认
deployment ── Read references/modules/deployment.md
  │            前置条件：audit FAIL≤2 | 预估 token：~10K
  │            独立 opus T_val 验证（不继承进化上下文）
  ▼
  ├─ r < R → 回 exploration
  └─ r = R → git merge 到 main
```

**Token 预算**：单轮总计 ≤ 100K。进入每个模块前检查剩余预算，不足则压缩或终止。

**渐进式披露**：每个模块的详细指令在 `references/modules/` 中。进入时 **必须 Read 对应文件**。

## T_train / T_val 拆分（反过拟合核心机制）

```
test-prompts.json:
  T_train (60%, 4条) — exploration 评分 + deployment 回归
  T_val   (40%, 2-3条) — 仅 deployment 阶段可见，held-out 验证

可见性规则：
  baseline:      设计 T_train + T_val
  exploration:   仅 T_train（子 agent 不可见 T_val）
  application:   仅 T_train（主 agent 不可见 T_val）
  audit:         仅 T_val（Overfit 检查）
  deployment:    T_train（回归）+ T_val（泛化），独立 opus agent 执行
```

## 策略矩阵：S0 + S1-S6

| 策略 | 来源 | 优先级 |
|------|------|--------|
| **S0: 动态策略** | traces.jsonl 失败模式分析 | **最高**（有 traces 时） |
| S1: 指令精化 | 固定 | 基础 |
| S2: 工作流重组 | 固定 | 基础 |
| S3: 边界增强 | 固定 | 基础 |
| S4: 上下文优化 | 固定 | 基础 |
| S5: 范式转换 | 固定 | 基础 |
| S6: 拆分/合并 | 固定 | 基础 |

S0 生成条件：`trace_source == "empirical"`（≥3 条 traces）时强制生成。

## 关卡合并规则

| 合并点 | 条件 | 拆分条件 |
|--------|------|---------|
| baseline+gap | 首次进化 / 无 traces / 快速模式 | 有 traces 且用户要求逐步确认 |
| audit+deployment | 审计无 FAIL≥3 且 diff≤200 行 | FAIL≥3 或 diff>200 行 |

## Git 版本控制

`~/.claude/skills/` 是 git 仓库。分支策略：`evolve/{skill}/YYYYMMDD`

| 时机 | 操作 | Checkpoint |
|------|------|-----------|
| baseline Step 4 | `git checkout -b evolve/{skill}/YYYYMMDD` | CP-01 |
| application Step 3 | `git commit` 改写结果 | CP-03 |
| deployment Step 6 | `git commit` 部署日志 | CP-04 |
| audit FAIL≥3 | `git reset HEAD~1` | 回到 CP-02 |
| deployment 退化 | `git revert HEAD` | 回到 CP-03 |
| 同一模块回滚≥2次 | 终止本轮 | — |
| 收工 | `git checkout main && git merge` | — |

## 日志与指标

- **进化日志**：`{skill}/.evolve/evolution-log.jsonl`（每轮一条 JSON，含 T_val 率）
- **累积指标**：`{skill}/.evolve/metrics.json`
- **测试集**：`{skill}/.evolve/test-prompts.json`（T_train + T_val 拆分）
- **轨迹**：`{skill}/.evolve/traces.jsonl`（真实使用轨迹）
- **审计报告**：`{skill}/.evolve/audit-reports/{skill}-R{round}.md`

baseline 启动时读取 metrics.json，若以下任一成立则提示效率偏低：
- `avg_score_delta < 5` 或 `total_rounds >= 5`
- `avg_token_efficiency < 0.4`
- `fallback_count >= 2`
- `avg_T_val_pass_rate < 0.5`（新增：held-out 验证持续失败）

## 约束规则（4 类）

**可靠性**：
1. 路径锚定 — 子 agent 绝对路径 + ls 验证
2. 测试守卫 — 首步验证文件存在
3. 审计隔离 — .before 副本 + BEFORE/AFTER 标记验证（行数确认）
4. 独立审计 — 全新上下文 + opus，审计和部署验证均用独立 agent
5. 子 agent 不重试 — 超时/失败标记 N/A，继续其他

**效率**：
6. Token 节约 — ctx_index 中转，按需检索
7. 写入集中 — 主 agent 写，子 agent 不写
8. 最小 K 保证 — 成功候选≥2 才做对比学习
9. Token 硬上限 — 单轮 ≤100K，每模块入口检查

**质量（反过拟合）**：
10. 完整改写 — 不打补丁
11. 不改核心功能 — 优化"怎么执行"
12. T_train/T_val 严格隔离 — exploration 不可见 T_val
13. R ratchet — 只保留有改进的版本
14. 部署验证独立 — opus 新上下文，不继承进化信息

**流程**：
15. 关卡不可跳 — 用户确认必须等待
16. D5 客观化 — 通过率而非主观评分
17. Runtime 中立 — 不引入硬编码
18. 渐进披露 — 模块细节在 references/modules/ 中按需加载
