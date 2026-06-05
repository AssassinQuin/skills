# Module: Audit（独立审计）

前置条件（完整进化）：application checkpoint 已通过 + SKILL.md 已改写 + 基线 Score 已知。
前置条件（快速审计模式 B）：仅需目标 SKILL.md 存在。

**此模块可独立执行（模式 B）。**

## 强制要求

- 全新上下文子 agent（model=opus）
- 不继承任何进化过程信息
- Prompt 模板见 [auditor-template.md](prompts/auditor-template.md)

## 执行步骤

### Step 0: 预算检查

```
remaining = 100K - 已消耗估算
IF remaining < 20K:
  → 降级为简化审计（sonnet, 3 项：Literals + Coverage + Silent-bypass）
  → 记录：{"event":"audit_simplified","reason":"budget","ts":"..."}
ELSE IF remaining < 10K:
  → 终止 [BUDGET-ABORT]
```

### Step 1: 准备（路径感知）

```bash
# 路径解析：git show 需要相对 git root 的路径，不是相对 cwd
SKILL_DIR="{skill}"  # 如 "novel-setup"
GIT_REL=$(cd "${SKILL_DIR}" && git ls-files SKILL.md)  # git-root 相对路径
BEFORE_PATH="/tmp/${SKILL_DIR}-before.md"

# BEFORE 副本从上一 commit 取（改写前的版本）
git show "HEAD~1:${GIT_REL}" > "${BEFORE_PATH}"

# 回退：如果 HEAD~1 不存在（首轮进化），复制当前版本
if [ ! -s "${BEFORE_PATH}" ]; then
  cp "${SKILL_DIR}/SKILL.md" "${BEFORE_PATH}"
fi
```

**注意**：BEFORE 副本始终写 `/tmp/`，不用 skill 目录内（避免路径嵌套问题）。
所有后续路径引用必须用绝对路径：`{cwd}/{skill}/SKILL.md` 和 `/tmp/{skill}-before.md`。

### Step 2: 构造审计 prompt

**给**：BEFORE 文件 + AFTER 文件 + [auditor-guide.md](../auditor-guide.md)
**不给**：Δ 描述、策略分析、测试集、选择记录

Prompt 中必须标记：
```
文件 A (BEFORE): /tmp/{skill}-before.md — 原始版本（绝对路径）
文件 B (AFTER): {cwd}/{skill}/SKILL.md — 改写后版本（绝对路径）

先读 BEFORE，再读 AFTER，对比时始终引用标记名。
```

**误报防护规则**（必须写入审计 prompt）：
1. BEFORE 中存在的功能，AFTER 中仍存在 → 不应 FAIL "Coverage"
2. BEFORE 中的模糊指令，AFTER 中被精化 → 不应 FAIL "Untraceable imperative"（这是改进）
3. AFTER 新增了 BEFORE 没有的边界处理 → 不应 FAIL "Script bloat"（这是增强）
4. 格式变化不影响功能语义 → 不应 FAIL "Shape-bake"

### Step 3: 5 维审计评分（0-10）

每个维度对应 2-3 个检查项，综合评定 0-10 分：

| 维度 | 权重 | 检查项 | 评分锚点 |
|------|------|--------|----------|
| D1 Frontmatter | 10% | Framing（问题/范围准确？）+ X-ref（引用路径可达？） | 8+: 元数据完整 + 所有引用可达；5-7: 部分缺失；0-4: 缺关键元数据 |
| D2 Workflow | 20% | Coverage（声明场景都有流程？）+ Silent-bypass（关键步骤可被跳过？） | 8+: 全覆盖 + 有强制校验；5-7: 部分场景缺流程；0-4: 关键步骤可跳过 |
| D3 Boundary | 15% | Script-bloat（不必要的脚本？）+ Shape-bake（格式过度硬化？） | 8+: 无膨胀 + 格式灵活；5-7: 轻微膨胀；0-4: 明显膨胀或过度硬化 |
| D4 Precision | 20% | Literals（字面正确？）+ Untraceable（无模糊动词？）+ Under-abstraction（无重复？） | 8+: 全部可执行 + 无重复；5-7: 部分模糊；0-4: 大量模糊/错误 |
| D5 Empirical | 35% | Overfit（T_val held-out 验证） | 8+: T_val ≥80%；5-7: 60-79%；0-4: <60% |

**总分**：`Score = D1×0.10 + D2×0.20 + D3×0.15 + D4×0.20 + D5×0.35`

**门控**：Score > 基线 Score，且无单项 < 5。否则 NEEDS-FIX。

### Step 4: 审计后清理

```bash
rm /tmp/{skill}-before.md
```

### Step 5: 保存审计报告

保存到 `{skill}/.evolve/audit-reports/{skill}-R{round}.md`

## 关卡：审计结果确认（与 deployment 合并确认）

```
审计结果：Score = X.X/10
- Score > 基线 且 无单项 < 5：通过 → 修复低分项（可选）→ deployment
- Score ≤ 基线 或 有单项 < 5：git reset HEAD~1 → 回 exploration 换策略
```

**Fallback 矩阵**：

| 场景 | 处理 |
|------|------|
| opus 审计超时(>120s) | 降级简化审计(sonnet, D4+D5) |
| 简化审计也失败 | 主 agent 极速审计(仅 D4 Precision) |
| 有维度 < 5 | git reset HEAD~1 |
| Score ≤ 基线 | git reset HEAD~1 |
| 修复后重审仍不通过 | 终止本轮 |

## Token 预估

- 完整审计(opus)：~20K
- 简化审计(sonnet)：~8K
- 极速审计(主agent)：~3K
