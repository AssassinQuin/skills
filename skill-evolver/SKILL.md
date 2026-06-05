---
name: skill-evolver
version: "5.0"
description: >
  Skill 自进化框架。脚本驱动 + 渐进披露 + 双路径。v5: 冷知识合并到模块、约束去重。
  Trigger: "进化 X skill", "审计 X", "评估 X 质量", "进化 skill-evolver",
  "优化所有 skills", "查看进化历史", "重写 skill", "优化 X，痛点 Y", "优化 X skill".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Skill Evolver v5

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

痛点：`pp-create` → `.evolve/pain-points.jsonl` → `quick-fix-check` 判定路径。

## 流程

```
baseline → [quick-fix] → exploration → application → audit → deployment
                                  ↑                            │
                                  └── r < R 继续 ──── 退化回滚 ←┘
```

每阶段：`Read references/modules/{phase}.md` → `phase-check` + `phase-start` → 执行 → 用户确认。

## 子 Agent

| 任务 | subagent_type | model | 模板 |
|------|--------------|-------|------|
| 策略探索 S0-S6 | `evolver-explorer` | sonnet | [explorer-template.md](references/modules/prompts/explorer-template.md) |
| 独立审计 | `evolver-auditor` | opus | [auditor-template.md](references/modules/prompts/auditor-template.md) |
| T_val 验证 | `evolver-auditor` | opus | [deployer-template.md](references/modules/prompts/deployer-template.md) |
| D5 基线测试 | `evolver-explorer` | sonnet | 内联（baseline 模块内） |

R5.1：`Agent()` 必须同时传 `subagent_type` + `model`。

## 评分

5 维（D1-D5），各 0-10。权重、门控阈值、效率告警见 [baseline.md](references/modules/baseline.md)。

`score D1 D2 D3 D4 D5` 计算加权总分。门控：Score > 基线 且 无维度 < 5。

## 痛点

文件：`{skill}/.evolve/pain-points.jsonl`

状态：open → addressed → resolved。回归 → regressed。`regression_count >= 2` → wontfix。

CRUD：`pp-create` / `pp-resolve` / `pp-regress`

## 脚本

`source scripts/evolve.sh && <command>`

| 命令 | 用途 |
|------|------|
| `score D1..D5` | 加权总分 |
| `metrics-update` | 更新 metrics.json |
| `pp-create/resolve/regress` | 痛点 CRUD（pp-resolve 解锁 addressed→resolved，pp-regress 标记回归） |
| `git-setup / git-checkpoint` | 分支管理 |
| `phase-check / phase-start` | 阶段门控 |
| `quick-fix-check` | Quick Fix 判定 |
| `verify-metrics` | 评分验证 |

## Git

分支：`evolve/{skill}/YYYYMMDD`。BEFORE 写 `/tmp/`。

| 时机 | Checkpoint |
|------|-----------|
| baseline | CP-01: `git-setup` |
| exploration | CP-02: `git-checkpoint` |
| application | CP-03: `git-checkpoint` |
| deployment | CP-04: `git-checkpoint` |
| audit 失败 | `git reset HEAD~1` → CP-02 |
| 部署退化 | `git revert HEAD` → CP-03 |
| 收工 | `git checkout main && git merge` |

## 日志

| 文件 | 用途 |
|------|------|
| `evolution-log.jsonl` | 每轮 JSON（dimensions + score + pain_points） |
| `metrics.json` | 累积指标 |
| `test-prompts.json` | T_train(60%) + T_val(40%) |
| `traces.jsonl` | 使用轨迹 |
| `pain-points.jsonl` | 跨轮痛点 |

## 约束

1. 路径锚定 — 子 agent 绝对路径 + ls 验证
2. 审计隔离 — BEFORE 副本 + 全新上下文 opus
3. 子 agent 不重试 — 超时标记 N/A
4. 渐进披露 — 模块按需加载
5. Token 硬上限 — 单轮 ≤100K
6. 写入集中 — 主 agent 写，子 agent 不写
7. 完整改写 — 不打补丁
8. T_train/T_val 隔离 — exploration 不可见 T_val
9. R ratchet — 只保留有改进的版本
10. 脚本驱动 — 阶段入口必须 phase-check + phase-start
