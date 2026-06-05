---
name: skill-evolver
version: "4.0"
description: >
  Skill 自进化框架。脚本驱动 + 披露式加载 + 双路径（Quick Fix / Full Evolution）。
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

# Skill Evolver v4

## 决策入口

| 用户意图 | 模式 | 执行 |
|----------|------|------|
| "进化 X skill" | A: 完整进化 | baseline → exploration → application → audit → deployment |
| "优化 X，痛点 Y" | G: 痛点驱动 | baseline(痛点加载) → **Quick Fix 判定** → application/exploration → audit → deployment |
| "优化 X"（无痛点） | A | 确认后进入 Mode A |
| "审计 X" | B: 快速审计 | audit（独立执行） |
| "评估 X 质量" | C: 质量评估 | baseline（仅评估 + 轨迹收集） |
| "进化 skill-evolver" | D: 自我进化 | 适配模块 [self-evolution.md](references/modules/self-evolution.md) |
| "优化所有 skills" | E: 批量 | baseline 筛选 → 逐个完整进化 |
| "查看进化历史" | F: 只读 | 读 `.evolve/evolution-log.jsonl` + `evolution-context.md` |
| "重写 skill" | 跳过 | 直接 skill-creator |

**痛点处理**：用户提供痛点 → `pp-create` 写入 `.evolve/pain-points.jsonl` → `quick-fix-check` 判定路径。

## 流程骨架

```
baseline ──── Read references/modules/baseline.md
  │            source scripts/evolve.sh && phase-start baseline {dir}
  │            包含：轨迹收集 + 痛点收集 + T_train/T_val 拆分 + 5 维评分
  ▼            关卡：用户确认基线 + 差距
  ┌─ quick-fix-check → QUICK_FIX_OK?
  │   YES → application（跳过 exploration）
  │   NO  → exploration
  ▼
exploration ─ Read references/modules/exploration.md
  │            phase-check exploration {dir} && phase-start exploration {dir}
  │            K=6/7 并行子 agent 探索策略
  ▼            关卡：用户选定策略
application ─ Read references/modules/application.md
  │            phase-check application {dir} && phase-start application {dir}
  │            完整改写 SKILL.md（不打补丁）
  ▼            关卡：用户确认改动
audit ─────── Read references/modules/audit.md
  │            phase-start audit {dir}
  │            独立 opus 5 维评分 + T_val Overfit 检查
  ▼            关卡：Score > 基线 且 无维度 < 5
deployment ── Read references/modules/deployment.md
  │            phase-check deployment {dir}
  │            T_val 验证 + 痛点回归守卫 + metrics 更新
  ▼
  └─ r < R → 回 exploration
     r = R → git merge 到 main
```

## 子 Agent 模型分配

| 任务 | subagent_type | 模型 | Prompt 模板 |
|------|--------------|------|------------|
| S0+S1-S6 策略探索 | `evolver-explorer` | sonnet | [explorer-template.md](references/modules/prompts/explorer-template.md) |
| 独立审计 | `evolver-auditor` | opus | [auditor-template.md](references/modules/prompts/auditor-template.md) |
| T_val 独立验证 | `evolver-auditor` | opus | [deployer-template.md](references/modules/prompts/deployer-template.md) |
| D5 基线测试 | `evolver-explorer` | sonnet | 内联（baseline 模块内） |

**R5.1**：每次 `Agent()` 调用必须同时传 `subagent_type` + `model`。缺一视为违规。

## 评分标准

唯一定义在 [references/constants.md](references/constants.md)，计算由 `scripts/evolve.sh score` 命令执行。

5 维（D1-D5），各 0-10 分，加权平均 = 总分（0-10）。门控：Score > 基线 且 无维度 < 5。

## 痛点生命周期

**文件**：`{skill}/.evolve/pain-points.jsonl`

**状态机**：open → addressed → resolved（部署通过）。回归 → regressed。regression_count >= 2 → wontfix。

**CRUD**：`pp-create` / `pp-resolve` / `pp-regress`（scripts/evolve.sh）

## 脚本工具箱

`source scripts/evolve.sh && <command>`

| 命令 | 用途 | 阶段 |
|------|------|------|
| `score D1 D2 D3 D4 D5` | 计算加权总分 | baseline, audit |
| `metrics-update <args>` | 更新 metrics.json | deployment |
| `pp-create/resolve/regress` | 痛点 CRUD | baseline, deployment |
| `git-setup <skill>` | 创建 evolve 分支 | baseline |
| `git-checkpoint <msg>` | 标准化 commit | 各模块 |
| `verify-metrics <dir>` | 验证评分范围 | deployment |
| `phase-check <phase> <dir>` | 前置条件检查 | 每个阶段入口 |
| `phase-start <phase> <dir>` | 写标记文件 | 每个阶段开始 |
| `quick-fix-check <dir>` | Quick Fix 判定 | baseline 之后 |

## Git 版本控制

分支策略：`evolve/{skill}/YYYYMMDD`。BEFORE 副本写 `/tmp/`。

| 时机 | 操作 | Checkpoint |
|------|------|-----------|
| baseline | `git-setup` | CP-01 |
| application | `git-checkpoint` 改写结果 | CP-03 |
| deployment | `git-checkpoint` 部署日志 | CP-04 |
| audit 未通过 | `git reset HEAD~1` | 回 CP-02 |
| deployment 退化 | `git revert HEAD` | 回 CP-03 |
| 收工 | `git checkout main && git merge` | — |

## 日志文件

| 文件 | 用途 |
|------|------|
| `.evolve/evolution-log.jsonl` | 每轮一条 JSON（含 dimensions + audit_score + pain_points） |
| `.evolve/metrics.json` | 累积指标（脚本维护） |
| `.evolve/test-prompts.json` | T_train(60%) + T_val(40%) |
| `.evolve/traces.jsonl` | 真实使用轨迹 |
| `.evolve/pain-points.jsonl` | 结构化痛点（跨轮持久化） |
| `.evolve/audit-reports/` | 审计报告 |
| `.evolve/evolution-context.md` | 每轮追加 why + what + result |

## 约束规则

**可靠性**：
1. 路径锚定 — 子 agent 绝对路径 + ls 验证
2. 审计隔离 — BEFORE 副本 + 标记验证
3. 独立审计 — 全新上下文 opus，不继承进化信息
4. 子 agent 不重试 — 超时标记 N/A
5. 渐进披露 — 模块细节在 references/modules/ 按需加载

**效率**：
6. Token 硬上限 — 单轮 ≤100K（阈值见 constants.md）
7. 写入集中 — 主 agent 写，子 agent 不写
8. 数据传输 — ctx_index 中转，按需检索

**质量**：
9. 完整改写 — 不打补丁
10. T_train/T_val 严格隔离 — exploration 不可见 T_val
11. R ratchet — 只保留有改进的版本
12. 部署验证独立 — opus 新上下文

**流程**：
13. 脚本驱动 — 阶段入口必须 `phase-check` + `phase-start`
14. 模型强制 — Agent() 必须传 subagent_type + model
