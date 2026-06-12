---
name: skill-evolver
version: "6.0"
description: >
  Skill 自进化框架。基于 SkillEvolver 论文(arXiv:2605.10500)实现。
  命令驱动 + 脚本强制 + 渐进披露 + 双路径 + 部署接地审计。
  v6: 范式转换——文档式→命令驱动，脚本强制调用，轻量验证模式。
  Trigger: "进化 X skill", "审计 X", "评估 X 质量", "进化 skill-evolver",
  "优化所有 skills", "查看进化历史", "重写 skill", "优化 X，痛点 Y", "优化 X skill",
  "验证 X skill".
origin-paper: references/origin-paper-SkillEvolver.docx
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

# Skill Evolver v6

## 决策入口

| 意图 | 模式 | 路径 |
|------|------|------|
| "进化 X" / "优化 X" | A | baseline → exploration → application → audit → deployment |
| "优化 X，痛点 Y" | G | baseline(痛点) → Quick Fix 判定 → application/exploration → audit → deployment |
| "审计 X" | B | audit 独立执行 |
| "评估 X 质量" | C | baseline（仅评估 + 轨迹） |
| "进化 skill-evolver" | D | 适配 [self-evolution.md](references/modules/self-evolution.md) |
| "优化所有 skills" | E | baseline 筛选 → 逐个 Mode A |
| "查看进化历史" | F | 读 `.evolve/evolution-log.jsonl` |
| "重写 skill" | 跳过 | 直接 skill-creator |
| "验证 X" / 编辑 SKILL.md 后 | H | `skill-validate` 轻量质量检查 |

痛点：`pp-create` → `.evolve/pain-points.jsonl` → `quick-fix-check` 判定路径。

## 流程（命令驱动）

```
baseline → [quick-fix] → exploration → application → audit → deployment
                              ↑                            │
                              └── r < R 继续 ──── 退化回滚 ←┘
```

### Phase 入口（强制 Bash 命令，不可跳过）

每个 Phase 开始时，**必须按顺序执行以下 Bash 命令**：

```bash
# 1. 前置条件检查（失败 = 停止）
source /Users/ganjie/.claude/skills/skill-evolver/scripts/evolve.sh && phase-check <phase> <skill_dir>
# 2. 开始标记
source /Users/ganjie/.claude/skills/skill-evolver/scripts/evolve.sh && phase-start <phase> <skill_dir>
```

然后：`Read references/modules/<phase>.md` → 按模块步骤执行。

**脚本等价操作必须用脚本**（禁止手动替代）：

| 操作 | 脚本命令 | 必用 Phase |
|------|---------|-----------|
| 评分 | `score D1 D2 D3 D4 D5` | baseline, audit, deployment |
| 痛点创建 | `pp-create <dir> <id> <desc> <symptom> <source> <round>` | baseline |
| 痛点解决 | `pp-resolve <dir> <id> <by>` | audit, deployment |
| 痛点回归 | `pp-regress <dir> <id>` | audit |
| 指标更新 | `metrics-update <dir> <round> <strategy> <before> <after> <d1>..<d5> <t_train> <t_val>` | deployment |
| Git 分支 | `git-setup <name> <dir>` | baseline |
| Git 提交 | `git-checkpoint <msg> <dir>` | 各 Phase 末尾 |
| Quick Fix | `quick-fix-check <dir>` | baseline |
| 绕过检测 | `silent-bypass-check <dir>` | audit |
| 质量验证 | `verify-metrics <dir>` | audit |
| 轻量检查 | `skill-validate <dir>` | Mode H / 编辑后 |

### 确认点（AskUserQuestion 强制）

每个 Phase 完成后，**必须**调用 `AskUserQuestion` 展示结果并等待用户确认。未收到确认禁止进入下一 Phase。

| Phase | 展示内容 | 确认后 |
|-------|---------|--------|
| baseline | 基线评分 + 痛点表 + Quick Fix 判定 | → exploration |
| exploration | 候选策略排名 + 对比分析 | → application |
| application | 修改文件列表 + diff 摘要 | → audit |
| audit | 审计报告 | → deployment |
| deployment | 最终评分对比 + T_val 结果 | → merge to main |

## 子 Agent

| 任务 | subagent_type | model | 模板 |
|------|--------------|-------|------|
| 策略探索 S0-S6 | `evolver-explorer` | sonnet | [explorer-template.md](references/modules/prompts/explorer-template.md) |
| 独立审计 | `evolver-auditor` | opus | [auditor-template.md](references/modules/prompts/auditor-template.md) |
| T_val 验证 | `evolver-auditor` | opus | [deployer-template.md](references/modules/prompts/deployer-template.md) |
| D5 基线测试 | `evolver-explorer` | sonnet | 内联（baseline 模块内） |

R5.1：`Agent()` 必须同时传 `subagent_type` + `model`。

## 评分

5 维 D1-D5，各 0-10。`score D1 D2 D3 D4 D5` 是唯一评分方式。

权重：D1×10% + D2×20% + D3×15% + D4×20% + D5×35%。门控：Score > 基线 且 无维度 < 5。

详细阈值、Token 预算、T_train/T_val 参数见 [baseline.md](references/modules/baseline.md)。

## 痛点

文件：`{skill}/.evolve/pain-points.jsonl`。状态流转：open → addressed → resolved。回归 → regressed。`regression_count >= 2` → wontfix。

## Git

分支：`evolve/{skill}/YYYYMMDD`。BEFORE 写 `/tmp/`。

| 时机 | Checkpoint |
|------|-----------|
| baseline | CP-01: `git-setup <name> <dir>` |
| exploration | CP-02: `git-checkpoint <msg> <dir>` |
| application | CP-03: `git-checkpoint <msg> <dir>` |
| deployment | CP-04: `git-checkpoint <msg> <dir>` |
| audit 失败 | `git reset HEAD~1` → CP-02 |
| 部署退化 | `git revert HEAD` → CP-03 |
| 收工 | `git checkout main && git merge` |

## 日志

| 文件 | 用途 |
|------|------|
| `evolution-log.jsonl` | 每轮 JSON |
| `metrics.json` | 累积指标 |
| `test-prompts.json` | T_train(60%) + T_val(40%) |
| `traces.jsonl` | 使用轨迹 |
| `pain-points.jsonl` | 跨轮痛点 |
| `deployment-traces.jsonl` | 部署反馈 |

## 约束（8 条）

**Mode H: skill-validate 检查清单**（`source evolve.sh && skill-validate <dir>`）

| # | 检查项 | 通过标准 |
|---|--------|---------|
| 1 | SKILL.md 存在 | 文件可读 |
| 2 | Frontmatter 必需字段 | 有 name + description |
| 3 | 膨胀检测 | SKILL.md ≤ 200 行 |
| 4 | 参考文件数 | references/ ≤ 10 个 .md |
| 5 | Silent-bypass 信号 | 无 WARN 信号 |
| 6 | 约束数量 | ≤ 15 条 |

1. **命令驱动** — Phase 入口必须通过 Bash 执行 `phase-check` + `phase-start`；Phase 结尾必须 `AskUserQuestion`
2. **脚本等价优先** — 有脚本命令的操作禁止手动替代（评分、痛点、Git、指标）
3. **路径锚定** — 子 agent 绝对路径 + ls 验证
4. **审计隔离** — BEFORE 副本 + 全新上下文 opus + 禁止引用 training traces
5. **写入集中** — 主 agent 写，子 agent 只读
6. **完整改写** — 不打补丁；T_train/T_val 隔离
7. **R ratchet** — 只保留有改进的版本；退化回滚
8. **膨胀检测** — SKILL.md > 200 行 or total_rounds >= 4 → 强制重构

已合并到约束/脚本的旧约束：渐进披露(→模块按需加载)、Token上限(→baseline.md)、子agent不重试(→exploration.md)、重构优先补丁(→约束8)、silent-bypass(→脚本命令)、Git锚定(→git-setup参数)、用户确认(→确认点表格)、workspace隔离(→约束4)
