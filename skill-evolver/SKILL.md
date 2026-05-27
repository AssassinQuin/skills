---
name: skill-evolver
version: "2.0"
description: >
  部署驱动的 Skill 自进化框架。从真实使用数据中识别失败模式，用 K=6 多策略并行探索
  + 对比学习 + 10项独立审计驱动 skill 持续进化。三层容错：ctx_index fallback链 +
  子agent超时保护 + token预算硬上限。
Use when: "skill进化", "evolve skill", "优化skill", "skill不work", "skill优化",
  "达尔文", "darwin", "auto optimize", "skill review", "skill诊断", "skill改进",
  "进化skill", "审计skill", "评估skill".
---

# Skill Evolver v2 — 部署驱动的 Skill 自进化框架

> 进化信号来自真实部署中的成败轨迹，不靠猜测。
> [SkillEvolver](https://arxiv.org/abs/2605.10500) + [darwin-skill](https://github.com/alchaincyf/darwin-skill)

## 决策入口

| 用户意图 | 模式 | 执行模块 |
|----------|------|---------|
| "进化 X skill" | A: 完整进化 | baseline → exploration → application → audit → deployment |
| "审计 X" | B: 快速审计 | audit（独立执行） |
| "评估 X 质量" | C: 质量评估 | baseline（仅 Phase 0+1） |
| "进化 skill-evolver" | D: 自我进化 | 完整进化，基线用本文件，策略应用于 SKILL.md + references/ |
| "优化所有 skills" | E: 批量 | baseline 筛选 → 逐个完整进化 |
| "查看进化历史" | F: 只读 | 读 `{skill}/.evolve/evolution-log.jsonl` |
| "重写 skill" | 跳过 | 直接 skill-creator |

## 子 Agent 模型分配

| 任务 | 模型 | Prompt 模板 |
|------|------|------------|
| K=6 策略探索 | sonnet ×6 并行 | [explorer-template.md](references/modules/prompts/explorer-template.md) |
| 候选评分 + 测试 | sonnet | 内联（exploration 模块内） |
| 独立审计 | opus | [auditor-template.md](references/modules/prompts/auditor-template.md) |
| 部署测试 | sonnet | [deployer-template.md](references/modules/prompts/deployer-template.md) |

### 数据传输协议

子 agent 无法写文件。用 **ctx_index → ctx_search** 中转：
- 写入侧：`ctx_index(content=完整候选, source="{skill}-S{k}")`，响应仅返回摘要
- 读取侧：`ctx_search` 按需检索，不全量加载

**Fallback 链（3 级）**：
- L1: ctx_index 成功 → 正常并行流程
- L2: ctx_index 失败 → 主 agent 单策略直改（选与 Δ 最匹配的 1 个策略）
- L3: 主 agent 也失败 → 终止，输出结构化诊断到 evolution-log.jsonl

## 5 维评估 Rubric（总分 100）

| # | 维度 | 权重 | 校准锚点 |
|---|------|------|---------|
| 1 | Frontmatter | 10 | 见 [baseline.md](references/modules/baseline.md) 校准表 |
| 2 | 工作流 | 20 | 同上 |
| 3 | 边界/安全 | 15 | 同上 |
| 4 | 指令精度 | 20 | 同上 |
| 5 | 实测效果 | 35 | 必须跑子 agent 测试，不可干跑 |

总分 = Σ(维度分 × 权重) / 10。改进后必须严格高于改进前。

## 流程骨架（R=3 轮迭代）

```
baseline ──── Read references/modules/baseline.md
  │            前置条件：无 | 预估 token：~8K | CP-01
  ▼            关卡 baseline+gap 合并确认
exploration ─ Read references/modules/exploration.md
  │            前置条件：Δ 已确认 | 预估 token：~38K | CP-02
  ▼            关卡 exploration 独立确认
application ─ Read references/modules/application.md
  │            前置条件：策略已选定 | 预估 token：~6K | CP-03
  ▼            关卡 application 独立确认
audit ─────── Read references/modules/audit.md
  │            前置条件：改写已 commit | 预估 token：~20K | CP-04
  ▼            关卡 audit+deployment 合并确认
deployment ── Read references/modules/deployment.md
  │            前置条件：audit FAIL≤2 | 预估 token：~10K
  ▼
  ├─ r < R → 回 exploration
  └─ r = R → git merge 到 main
```

**Token 预算**：单轮总计 ≤ 100K。进入每个模块前检查剩余预算，不足则压缩或终止。

**渐进式披露**：每个模块的详细指令在 `references/modules/` 中。进入时 **必须 Read 对应文件**。

## 关卡合并规则

| 合并点 | 条件 | 拆分条件 |
|--------|------|---------|
| baseline+gap | 首次进化 / 无 traces / 快速模式 | 有 traces 且用户要求逐步确认 |
| audit+deployment | 审计无 FAIL≥3 且 diff≤200 行 | FAIL≥3 或 diff>200 行 |

## Git 版本控制

`~/.claude/skills/` 是 git 仓库。分支策略：`evolve/{skill}/YYYYMMDD`

| 时机 | 操作 | Checkpoint |
|------|------|-----------|
| baseline Step 3 | `git checkout -b evolve/{skill}/YYYYMMDD` | CP-01 |
| application Step 3 | `git commit` 改写结果 | CP-03 |
| deployment Step 5 | `git commit` 部署日志 | CP-04 |
| audit FAIL≥3 | `git reset HEAD~1` | 回到 CP-02 |
| deployment 退化 | `git revert HEAD` | 回到 CP-03 |
| 同一模块回滚≥2次 | 终止本轮 | — |
| 收工 | `git checkout main && git merge` | — |

## 日志与指标

- **进化日志**：`{skill}/.evolve/evolution-log.jsonl`（每轮一条 JSON，含 token 效率字段）
- **累积指标**：`{skill}/.evolve/metrics.json`（含 avg_token_efficiency、total_agent_failures）
- **测试集**：`{skill}/.evolve/test-prompts.json`（baseline 保存，deployment 回测）
- **审计报告**：`{skill}/.evolve/audit-reports/{skill}-R{round}.md`

baseline 启动时读取 metrics.json，若以下任一成立则提示效率偏低：
- `avg_score_delta < 5` 或 `total_rounds >= 5`
- `avg_token_efficiency < 0.4`
- `fallback_count >= 2`

## 约束规则（4 类）

**可靠性**：
1. 路径锚定 — 子 agent 绝对路径 + ls 验证
2. 测试守卫 — 首步验证文件存在
3. 审计隔离 — .before 副本 + BEFORE/AFTER 标记
4. 独立审计 — 新上下文 + opus，不可降级（除非预算不足）
5. 子 agent 不重试 — 超时/失败标记 N/A，继续其他

**效率**：
6. Token 节约 — ctx_index 中转，按需检索
7. 写入集中 — 主 agent 写，子 agent 不写
8. 最小 K 保证 — 成功候选≥2 才做对比学习；仅 1 个则直接采用
9. Token 硬上限 — 单轮 ≤100K，每模块入口检查

**质量**：
10. 完整改写 — 不打补丁
11. 不改核心功能 — 优化"怎么执行"
12. K=6 不可减 — 策略多样性（预算不足时降至 K=2）
13. R ratchet — 只保留有改进的版本

**流程**：
14. 关卡不可跳 — 用户确认必须等待
15. 维度 5 不可干跑 — 必须实测
16. Runtime 中立 — 不引入硬编码
17. 渐进披露 — 模块细节在 references/modules/ 中按需加载
