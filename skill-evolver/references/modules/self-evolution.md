# Module: Self-Evolution（v8.1 适配）

skill-evolver 自我进化时的流程适配。解决循环依赖：SKILL.md 既是进化目标，又是流程定义。

> **v8.1 重写说明**：v8.0 删除了 v7 的 5 模式 A-E + Quick Fix + baseline→exploration→application→audit→deployment 流程，回归单一 Algorithm 1（Phase 1-4）。本文档原版（v7 时代）引用的模式 D / 模式 E / phase-check / quick-fix-check 脚本已删除。本文档重写为 v8.1 Phase 1-4 适配。

## v8.1 自我进化的特殊性

| 阶段 | 普通 skill 进化 | 自我进化（skill-evolver → skill-evolver） | 原因 |
|------|---------------|-----------------------------------------|------|
| Phase 1 Initialize | 读目标 SKILL.md 评分 | **同**（SKILL.md 未改） | - |
| Phase 3 Refinement | Domain-Skill Agent 读 v_r | **副本隔离**：子 agent 读 `.evolve/snapshots/SKILL.before.md`，不读正在进化的 SKILL.md | 防循环依赖 |
| Phase 3 Patch | 改 SKILL.md + references/ | **扩展范围**：SKILL.md + references/modules/ + references/paper-spec.md | 框架自身的 references 也在范围内 |
| Phase 3 Audit | evolver-auditor 读 v_{r+1} | **同**（已 commit，正常对比） | - |
| Phase 4 Validate | Domain-Skill Agent 跑 T_val | **Meta 测试**：跑流程可执行性（不是 skill 业务能力） | 验证框架本身 |

## 副本隔离协议（Phase 3 Refinement 阶段）

```bash
# Phase 1 结束后、Phase 3 开始前
cp skill-evolver/SKILL.md skill-evolver/.evolve/snapshots/SKILL.before.md
cp skill-evolver/references/paper-spec.md skill-evolver/.evolve/snapshots/paper-spec.before.md
cp skill-evolver/references/modules/audit.md skill-evolver/.evolve/snapshots/audit.before.md
# ... 其他 references/modules/

# Evaluation-Trace Agent / Domain-Skill Agent prompt 中将 skill 路径替换为 snapshot 路径
# Phase 3 Patch 结束后保留 snapshots（供 Phase 3 Audit 对比）
```

子 agent prompt 额外注入：
```
注意：此 skill 是进化框架本身。改写时：
- 保留 Phase 1-4 骨架（不退回 v7 的 5 模式 A-E）
- 保留论文一致性（references/paper-spec.md 是唯一规范）
- 策略可影响 SKILL.md + references/modules/ + references/paper-spec.md
- 不破坏 9-check audit + Algorithm 1 主结构
- v8.1 增强可加：skill 类型检测 / Evaluation-Trace Agent / Check 10 / held-out gate
```

## Meta 测试设计（Phase 4 Validate）

自我进化的 T_val 测"流程可执行性"，不是 skill 业务能力：

```json
{
  "T_train": [
    {"id": "T1", "type": "Phase 完整性", "prompt": "进化 {any-skill}", "expect": "走完整 Phase 1→4，每个 Phase 后 AskUserQuestion"},
    {"id": "T2", "type": "决策入口路由", "prompt": "审计 {any-skill}", "expect": "走 audit.md 10-check（含 v8.1 Check 10），不触发完整 Phase 1→4"},
    {"id": "T3", "type": "Skill 类型检测", "prompt": "进化 {any-research-skill}", "expect": "Phase 1 检测为研究型，启用 Evaluation-Trace Agent + qualitative reward"}
  ],
  "T_val": [
    {"id": "V1", "type": "边界场景", "prompt": "进化 skill-evolver（自我进化）", "expect": "启用副本隔离 + Meta 测试"},
    {"id": "V2", "type": "Skill 类型识别", "prompt": "进化 {any-execution-skill}", "expect": "Phase 1 检测为执行型，用 Domain-Skill Agent + binary reward"}
  ],
  "source": "meta-designed"
}
```

## Phase 3 Patch 扩展

自我进化的 commit 包含：
```bash
git-checkpoint "evolve skill-evolver: apply-r{r}-{策略}"
```
commit 范围：SKILL.md + 所有修改过的 `references/modules/*.md` + `references/paper-spec.md`。

## Audit 自我进化特殊性

自我进化时，Auditor 检查的 candidate 是 skill-evolver 本身。需要额外注意：

| Check | 自我进化时的特殊考虑 |
|-------|---------------------|
| 1 Framing | skill-evolver 的 description 不应嵌入具体目标 skill 名（用 {any-skill} 占位符） |
| 2 Literals | 不应硬编码具体 skill 绝对路径（用相对路径或环境变量） |
| 6 X-ref | 不应在 SKILL.md / paper-spec.md 引用具体进化的 skill 名作为案例（用通用占位符） |
| 7 Under-abstraction | 不应将单一进化案例作为规则的 justifying evidence（规则应能跨案例推导） |
| 10 硬约束自验证 | 自我进化时主 agent 必须用 v8.1 框架走一遍 Phase 1→4，验证新加的 gate 真的能执行 |

## 不适配的部分（与普通进化完全相同）

- Phase 1 Initialize（axes 解析通用）
- Phase 3 Audit（evolver-auditor 独立审计，读已 commit 文件）
- Phase 4 Validate（在 T_val 上跑 held-out 验证）
- Git 分支策略、日志格式、约束规则

## 反例（v8.0 → v8.1 修复）

### 反例 1: v7 残留概念（v8.0 重构损失）
**问题**：v8.0 重构删除了模式 A-E，但 self-evolution.md（v7 时代）仍引用模式 D / phase-check / quick-fix-check，文档腐烂。
**修复**：v8.1 重写为 Phase 1-4 适配（本文档）。

### 反例 2: 自我进化时跳过 held-out
**问题**：用 v8.0 进化某 skill 时，T_train = T_val（同一评估对象），过拟合。
**修复**：v8.1 Gate 3 强制 T_train ≠ T_val，自我进化时用 meta-designed T_val（流程可执行性测试）。

### 反例 3: 自我进化时 Audit 漏 Check 10
**问题**：v8.0 audit 只 9 check，没检查"硬约束自验证"。进化某 skill 时硬约束声明但执行零调用，audit 没发现。
**修复**：v8.1 Check 10 强制对照 traces 验证硬约束执行。
