# Module: Audit（独立审计）

前置条件（完整进化）：application checkpoint 已通过 + SKILL.md 已改写。
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

### Step 1: 准备

```bash
cp {skill}/SKILL.md {skill}/SKILL.md.before
```

### Step 2: 构造审计 prompt

**给**：BEFORE 文件 + AFTER 文件 + [auditor-guide.md](../auditor-guide.md)
**不给**：Δ 描述、策略分析、测试集、选择记录

Prompt 中必须标记：
```
文件 A (BEFORE): {绝对路径}/SKILL.md.before — 原始版本
文件 B (AFTER): {绝对路径}/SKILL.md — 改写后版本

先读 BEFORE，再读 AFTER，对比时始终引用标记名。
```

**误报防护规则**（必须写入审计 prompt）：
1. BEFORE 中存在的功能，AFTER 中仍存在 → 不应 FAIL "Coverage"
2. BEFORE 中的模糊指令，AFTER 中被精化 → 不应 FAIL "Untraceable imperative"（这是改进）
3. AFTER 新增了 BEFORE 没有的边界处理 → 不应 FAIL "Script bloat"（这是增强）
4. 格式变化不影响功能语义 → 不应 FAIL "Shape-bake"

### Step 3: 10 项审计清单

| # | 检查项 | 要点 |
|---|--------|------|
| 1 | Framing | 问题/范围准确定义？ |
| 2 | Literals | 路径/命令/参数字面正确？ |
| 3 | Script bloat | 不必要的 scripts？ |
| 4 | Untraceable imperative | 模糊指令→具体步骤？ |
| 5 | Shape-bake | 格式过度硬化？ |
| 6 | Coverage | 声明场景都有流程？ |
| 7 | X-ref | 引用路径可达？ |
| 8 | Under-abstraction | 重复逻辑？ |
| 9 | Silent-bypass | 关键步骤可被跳过？ |
| 10 | Overfit | 新 prompt 测试仍有效？ |

### Step 4: 审计后清理

```bash
rm {skill}/SKILL.md.before
```

### Step 5: 保存审计报告

保存到 `{skill}/.evolve/audit-reports/{skill}-R{round}.md`

## 关卡：审计结果确认（与 deployment 合并确认）

```
审计结果：X/10 PASS
- FAIL ≤2：修复 → 重审失败项
- FAIL ≥3：git reset HEAD~1 → 回 exploration 换策略
```

**Fallback 矩阵**：

| 场景 | 处理 |
|------|------|
| opus 审计超时(>120s) | 降级简化审计(sonnet, 3项) |
| 简化审计也失败 | 主 agent 极速审计(仅 Literals) |
| 完整审计 FAIL≥3 | git reset HEAD~1 |
| 简化审计 FAIL≥2(满分3) | git reset HEAD~1 |
| 修复后重审仍不通过 | 终止本轮 |

FAIL 阈值按满分等比缩放（完整10项→FAIL≥3，简化3项→FAIL≥2，极速1项→FAIL≥1）。

## Token 预估

- 完整审计(opus)：~20K
- 简化审计(sonnet)：~8K
- 极速审计(主agent)：~3K
