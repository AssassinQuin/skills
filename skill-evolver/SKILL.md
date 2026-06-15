---
name: skill-evolver
version: "7.1"
description: >
  Skill 自进化框架。基于 SkillEvolver(arXiv:2605.10500) + SkillOpt(arXiv:2605.23904)实现。
  命令驱动 + 脚本强制 + 渐进披露 + 双轨编辑 + 部署接地审计 + 负反馈闭环 + 三重质量门。
  Trigger: "进化 X skill", "审计 X", "评估 X 质量", "进化 skill-evolver",
  "优化所有 skills", "查看进化历史", "重写 skill", "优化 X，痛点 Y", "优化 X skill",
  "验证 X skill".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
user-invocable: true
---

# Skill Evolver v7.1

## 决策入口

| 意图 | 模式 | 路径 |
|------|------|------|
| "进化 X" / "优化 X" / "优化 X，痛点 Y" | A | baseline → exploration → application → audit → deployment（痛点路径由 `quick-fix-check` 自动判定） |
| "审计 X" | B | audit 独立执行 |
| "评估 X 质量" / "验证 X" / 编辑 SKILL.md 后 | C | baseline（评估+轨迹）或 `skill-validate` 轻量检查 |
| "进化 skill-evolver" | D | A + [self-evolution.md](references/modules/self-evolution.md) 适配 |
| "优化所有 skills" | E | baseline 筛选 → 逐个 Mode A |
| "查看进化历史" | — | 读 `.evolve/evolution-log.jsonl` |
| "重写 skill" | — | 直接 skill-creator |

## 价值锚定

> 宁可产出低分但诚实的进化结果，也不要高分但编造的通过率。诚实的 UNVERIFIED 比虚假的 4/4 更有价值。

## 流程（命令驱动）

```
baseline → [quick-fix] → exploration → application → audit → deployment
              ↓ skip          ↑                            │
              └──────→ application ──→ audit → deployment ←┘
                                           ↑
                              └── r < R 继续 ──── 退化回滚
```

**Quick Fix**：跳过 exploration，但不跳过 audit 和 deployment。

**迭代上限**：baseline→deployment 最多 3 轮（R ≤ 3）。单 Phase 回滚 ≥ 2 次 → 终止。

### Phase 入口（强制 Bash，不可跳过）

每个 Phase 开始时按顺序执行：

```bash
source /Users/ganjie/skills/skill-evolver/scripts/evolve.sh && phase-check <phase> <skill_dir>
source /Users/ganjie/skills/skill-evolver/scripts/evolve.sh && phase-start <phase> <skill_dir>
```

然后：`Read references/modules/<phase>.md` → 按模块步骤执行。

**脚本等价操作必须用脚本**（禁止手动替代）：

| 操作 | 脚本命令 | 主要 Phase |
|------|---------|-----------|
| 评分 | `score D1 D2 D3 D4 D5` | baseline, audit, deployment |
| 痛点 CRUD | `pp-create` / `pp-resolve` / `pp-regress` | baseline, audit, deployment |
| 指标更新 | `metrics-update` | deployment |
| Git | `git-setup` / `git-checkpoint` | baseline, 各 Phase 末尾 |
| Quick Fix 判定 | `quick-fix-check <dir> [file_count]` | baseline |
| 编辑模式判定 | `diff-budget-check <dir> <segment_count>` | application |
| 失败经验记录 | `rejected-edit-record <dir> <strategy> <reason>` | audit |
| 测试结果记录 | `test-record <dir> <label> <json_string>` | baseline, deployment |
| 分支验证 | `branch-check <dir>` | deployment（前置） |
| 痛点回归 | `regression-check <dir>` | deployment（前置 + Step 4） |
| Silent-bypass | `silent-bypass-check` | audit |
| 快照/审计保存 | `snapshot-save` / `audit-save` | baseline, audit |
| 轻量检查 | `skill-validate <dir>` | Mode C |

### 确认点

每个 Phase 完成后 **必须 AskUserQuestion** 展示结果并等待确认。未确认禁止进入下一 Phase。

每个 Phase 模块的 **关卡** 章节定义了具体展示内容（含"本轮局限"声明，禁止写"无"）和检查点意义。

## 子 Agent

| 任务 | subagent_type | model |
|------|--------------|-------|
| 策略探索 S0-S6 | `evolver-explorer` | sonnet |
| 独立审计 | `evolver-auditor` | opus |
| T_val 验证 | `evolver-auditor` | opus |
| D5 基线测试 | `evolver-explorer` | sonnet |

Prompt 模板见 [templates.md](references/modules/prompts/templates.md)。

R5.1：`Agent()` 必须同时传 `subagent_type` + `model`。Agent 是 deferred 工具，调用前需 `ToolSearch select:Agent` 加载 schema。

## 评分 / 痛点 / Git / 日志

- **评分体系**：5 维 0-10 评分 + 痛点生命周期，详见 [baseline.md](references/modules/baseline.md)
- **失败模式**：FM1-FM7 诊断，详见 [failure-modes.md](references/failure-modes.md)
- **Git**：分支 `evolve/{skill}/YYYYMMDD`，BEFORE 快照 → `snapshot-save`，各 Phase → `git-checkpoint`
- **日志**：`{skill}/.evolve/` 下 `evolution-log.jsonl`、`metrics.json`、`pain-points.jsonl`、`deployment-traces.jsonl`、`rejected-edits.jsonl`、`test-results.json`
- **Deployment-Grounded Learning**：每次 baseline 启动时检查 `deployment-traces.jsonl`，详见 baseline.md Step 3

## 约束

### 绝对不做（违反 = 进化结果无效）

1. **不编造通过率** — T_train/T_val 未执行就填数字
2. **不跳过审计** — Quick Fix 也不跳过 audit 和 deployment
3. **不跳过痛点回归** — deployment 必须验证 resolved 痛点
4. **不在未执行时填结果** — 子 agent 未 spawn 则标记 UNVERIFIED
5. **不忽略历史痛点** — 已解决痛点回归时必须记录
6. **不丢弃失败经验** — 审计失败必须 `rejected-edit-record` 记录到 rejected-edits

### 流程约束

1. **命令驱动** — Phase 入口必须 Bash 执行 `phase-check` + `phase-start`
2. **脚本等价优先** — 有脚本命令的操作禁止手动替代
3. **路径锚定** — 子 agent 绝对路径 + ls 验证
4. **审计隔离** — BEFORE 副本 + 全新上下文 opus + Quick Fix 也独立审计
5. **写入集中** — 主 agent 写，子 agent 只读
6. **双轨编辑** — `diff-budget-check` 自动选择：≤3 段 bounded edit（受 textual learning rate 约束），>3 段或结构性变化 full rewrite
7. **R ratchet** — 只保留有改进的版本；退化回滚
8. **补丁饱和检测** — `total_rounds >= 5` 时提示精简
9. **测试真实执行** — T_train/T_val 必须由子 agent 实际执行，结果通过 `test-record` 结构化存储
10. **BEFORE 可追溯** — 副本必须保存到 `.evolve/snapshots/`
11. **跨轮次对比** — 连续 2 轮 delta < 0.5 触发 slow update（放宽搜索粒度）
12. **测试结构化输出** — 子 agent 测试结果必须返回 JSON（pass/partial/fail + evidence），自由文本不被接受
13. **部署三重门** — deployment 前置必须 `branch-check`（防读错分支）+ `regression-check`（防痛点回归）+ T_val 子 agent 实测（防静态审计虚高）

### Mode C: skill-validate

`source evolve.sh && skill-validate <dir>` — 6 项轻量检查（frontmatter、补丁饱和、参考文件数、silent-bypass、约束数）。详见 [baseline.md](references/modules/baseline.md) 或运行脚本查看。

已合并到约束/脚本的旧约束：渐进披露(→模块按需加载)、Token上限(→baseline.md)、子agent不重试(→exploration.md)、重构优先补丁(→约束8)、silent-bypass(→脚本命令)、Git锚定(→git-setup)、用户确认(→确认点)、workspace隔离(→约束4)、行数膨胀(→补丁饱和检测)
