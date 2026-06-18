# skill-deepener

Skill 内容深化器。专门给已有但内容空泛的 skill 补专家深度。

## 为什么需要它

skill-evolver (arXiv:2605.10500) 是**结构合规器**，产出的 skill 流程化但缺专业深度。

| skill | 做什么 | 不做什么 |
|-------|--------|---------|
| skill-evolver | 结构合规、防过拟合、流程优化 | 创造新内容、专家知识 codify |
| **skill-deepener** | **专家知识 codify、失败案例沉淀、深度重写** | 改结构、改流程 |

## 核心方法（来自调研）

1. **Anthropic 反推法** — 先收集真实失败 case，从失败反推该补什么专家知识
2. **Cognitive Apprenticeship** — Model/Coach/Scaffold/Fade 四要素写进 SKILL.md
3. **Agent-as-a-Judge** — 多专家角色评审（方法论严谨 / 案例真实 / 领域准确）
4. **ECC 4 维度诊断** — Actionability / Scope fit / Uniqueness / Currency

## 流程（6 Phase）

```
P1 缺口诊断 → P2 反推通道 → P3 内容采集 → P4 内容重写 → P5 多专家评审 → P6 持久化
```

详见 [SKILL.md](SKILL.md)。

## 触发词

- 深化 X skill / X skill 内容深度
- 让 X 更专业 / X 缺方法论 / X 缺真实案例
- X 流程化但缺深度
- skill 不够垂直 / skill 不够专业

## 与其他 skill 协作

```
新做专业 skill：
  huashu-nuwa（蒸馏）→ skill-creator（结构化）→ skill-deepener（深化）→ skill-evolver（合规）

优化已有空泛 skill：
  skill-deepener（深化）→ skill-evolver（合规）

审计已有 skill：
  skill-evolver audit（结构）+ skill-deepener P1（深度）
```

## 不用于

- 创建 skill（用 skill-creator）
- 结构合规（用 skill-evolver）
- 写代码（用 coder）

## 关键 references

- [phase-gates.md](references/phase-gates.md) — P1-P6 exit-checklist
- [gap-diagnosis.md](references/gap-diagnosis.md) — ECC 4 维度诊断协议
- [cognitive-apprenticeship.md](references/cognitive-apprenticeship.md) — Model/Coach/Scaffold/Fade
- [expert-role-audit.md](references/expert-role-audit.md) — 3 角色评审
- [case-distillation.md](references/case-distillation.md) — 失败案例沉淀方法论

## 来源

- 论文：arXiv:2601.15153 (Codified Human Expertise) / arXiv:2508.02994 (Agent-as-a-Judge) / arXiv:2303.11366 (Reflexion)
- 工业：[affaan-m/ECC rules-distill](https://github.com/affaan-m/ECC/blob/master/skills/rules-distill/SKILL.md) + skill-stocktake
- 方法论：[Anthropic Equipping Agents](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) + [Cognitive Apprenticeship](https://edtechbooks.org/promptbook/from-model-to-mentor)

调研报告：[web-research/data/20260618-skill-depth-research/](../web-research/data/20260618-skill-depth-research/)
