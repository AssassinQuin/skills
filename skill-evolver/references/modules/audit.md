# Module: Audit（独立审计）

前置条件：application checkpoint 已通过 + SKILL.md 已改写 + 基线 Score 已知。
前置条件（模式 B）：仅需目标 SKILL.md 存在。

## 前置校验

```bash
phase-start audit {skill_dir}
```

## 强制要求

- 全新上下文子 agent（model=opus）
- 不继承任何进化过程信息
- Prompt 模板见 [auditor-template.md](prompts/auditor-template.md)

## 执行步骤

### Step 1: 准备 BEFORE 副本

```bash
BEFORE_PATH="/tmp/{skill}-before.md"
git show "HEAD~1:{git_rel}" > "$BEFORE_PATH"
# 回退：HEAD~1 不存在时复制当前版本
```

BEFORE 副本始终写 `/tmp/`。

### Step 2: 构造审计 prompt

给子 agent：BEFORE + AFTER + [auditor-guide.md](../auditor-guide.md)。
不给：Δ 描述、策略分析、测试集。

### Step 3: 5 维审计评分

每个维度 0-10 分。检查项和评分锚点见 [constants.md](../constants.md) 和 [auditor-guide.md](../auditor-guide.md)。

门控：Score > 基线 Score，且无单项 < 5。

### Step 4: 清理 + 保存报告

```bash
rm /tmp/{skill}-before.md
```

保存到 `.evolve/audit-reports/{skill}-R{round}.md`。

## 关卡

```
审计结果：Score = X.X/10
- Score > 基线 且 无维度 < 5：通过 → deployment
- Score ≤ 基线 或 有维度 < 5：git reset HEAD~1 → 回 exploration
```

**Fallback**：opus 超时 → 简化审计(sonnet, D4+D5) → 极速审计(主 agent, 仅 D4)。
