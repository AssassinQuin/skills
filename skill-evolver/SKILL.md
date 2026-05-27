---
name: skill-evolver
description: >
  部署驱动的 Skill 自进化框架。K=6 多策略并行探索 + 对比学习 + 10项独立审计。
  Use when: "skill进化", "evolve skill", "优化skill", "skill不work", "skill优化",
  "达尔文", "darwin", "auto optimize", "skill review", "skill诊断", "skill改进".
---

# Skill Evolver — 部署驱动的 Skill 自进化框架

> 进化信号来自真实部署中的成败轨迹，不靠猜测。
> [SkillEvolver](https://arxiv.org/abs/2605.10500) + [darwin-skill](https://github.com/alchaincyf/darwin-skill)

## 子 Agent 模型分配

| 任务 | 模型 |
|------|------|
| K=6 策略探索 | sonnet ×6 并行 |
| 候选评分 + 测试 | sonnet |
| 独立审计（Phase 4） | opus |
| 部署测试（Phase 5） | sonnet |

### 数据传输

子 agent 无法写文件。用 **ctx_index → ctx_search** 中转：
- 写入侧：`ctx_index(content=完整候选, source="{skill}-S{k}")`，响应仅返回摘要
- 读取侧：`ctx_search` 按需检索，不全量加载

### 可靠性协议

所有子 agent prompt 必须遵守：
1. **路径锚定**：包含项目绝对路径，第一步 `ls` 验证
2. **测试守卫**：验证目标文件存在，不存在则立即终止
3. **审计隔离**：Phase 4 用 `.before` 副本 + BEFORE/AFTER 标记

## 5 维评估 Rubric（总分100）

| # | 维度 | 权重 |
|---|------|------|
| 1 | Frontmatter | 10 |
| 2 | 工作流 | 20 |
| 3 | 边界/安全 | 15 |
| 4 | 指令精度 | 20 |
| 5 | 实测效果 | 35 |

总分 = Σ(维度分 × 权重) / 10。改进后必须严格高于改进前。

## 流程骨架（R=3 轮迭代）

```
Phase 0 初始化 ─── Read references/phases/phase0-init.md
  │
  ▼  ✓ 关卡 0+1 合并确认（基线+差距）
Phase 1 差距理解 ─── Read references/phases/phase1-gap.md
  │
Phase 2 K=6 探索 ─── Read references/phases/phase2-strategies.md
  │
  ▼  ✓ 关卡 2 策略确认
Phase 3 精准应用 ─── Read references/phases/phase3-apply.md
  │
  ▼  ✓ 关卡 3 改动确认
Phase 4 独立审计 ─── Read references/phases/phase4-audit.md
  │
Phase 5 部署验证 ─── Read references/phases/phase5-deploy.md
  │
  ▼  ✓ 关卡 4+5 合并确认（审计+部署）
  │
  ├─ r < R → 回 Phase 1
  └─ r = R → git merge 到 main
```

**渐进式披露**：每个 Phase 的详细指令在对应的 `references/phases/phase{N}-*.md` 文件中。进入该 Phase 时 **必须 Read 对应文件**，不要凭记忆执行。

## Git 版本控制

`~/.claude/skills/` 是 git 仓库。分支策略：`evolve/{skill}/YYYYMMDD`

| 时机 | 操作 |
|------|------|
| Phase 0 | `git checkout -b evolve/{skill}/YYYYMMDD` |
| Phase 3 | `git commit` 改写结果 |
| Phase 4 FAIL≥3 | `git revert HEAD` |
| Phase 5 退化 | `git revert HEAD` |
| 收工 | `git merge` 回 main |

## 日志与指标

- **进化日志**：`{skill}/.evolve/evolution-log.jsonl`（每轮一条 JSON）
- **累积指标**：`{skill}/.evolve/metrics.json`（total_rounds, avg_score_delta, strategy_hits）
- **测试集**：`{skill}/.evolve/test-prompts.json`（Phase 0 保存，Phase 5 回测）

Phase 0 启动时读取 metrics.json，若 `avg_score_delta < 5` 或 `total_rounds >= 5` 则提示效率偏低。

## 约束规则

1. **完整改写** — 不打补丁
2. **不改核心功能** — 优化"怎么执行"
3. **独立审计** — 新上下文 + opus，不可降级
4. **可回滚** — 所有改动在 git 上
5. **部署闭环** — 必须回测
6. **K=6 不可减** — 策略多样性
7. **关卡不可跳** — 用户确认必须等待
8. **维度5 不可干跑** — 必须实测
9. **Runtime 中立** — 不引入硬编码
10. **R ratchet** — 只保留有改进的版本
11. **模型匹配** — 探索 sonnet，审计 opus
12. **Token 节约** — ctx_index 中转，按需检索
13. **写入集中** — 主 agent 写，子 agent 不写
14. **路径锚定** — 子 agent 绝对路径 + ls 验证
15. **审计隔离** — .before 副本 + BEFORE/AFTER 标记
16. **测试守卫** — 首步验证文件存在
17. **渐进披露** — Phase 细节在 references/ 中按需加载

## 使用方式

```
"进化 brainstorm skill"  → Phase 0-5 完整流程（R=3）
"优化所有 skills"       → Phase 0 筛选 → 逐个进化
"skill不work"           → Phase 0-5，重点 S1+S3
"审计 brainstorm"       → 只执行 Phase 4
"评估 skill 质量"       → 只执行 Phase 0
"重写 skill"            → 跳过进化，直接 skill-creator
"查看进化历史"          → 读 {skill}/.evolve/evolution-log.jsonl
```

## 自我进化

skill-evolver 自身也可被进化。执行 `"/skill-evolver 进化 skill-evolver"` 时：
- Phase 0 的基线评分使用本文件
- Phase 2 的策略应用于本文件 + references/
- Phase 3 改写本文件（骨架）和 references/（详情）
- 日志记录到 `skill-evolver/.evolve/evolution-log.jsonl`
