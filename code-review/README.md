# Code Review

审查 git diff / PR 变更。7 维结构化审查，P0-P3 四级严重度，输出完整审计报告 + 修复优先级。

## Trigger

review、审查代码、review PR、review diff、代码审查、代码评审、审计代码

## Quick Start

```
/code-review review 这个 PR
/code-review 审查最近的 diff
```

## Workflow

1. P0 定位 — 检测语言、diff 范围、复杂度
2. P1 Quick Scan — grep 模式扫描（6 维度 × 4 语言）
3. P2 Deep Review — 7 维逐项审查（Quick Scan 模式跳过）
4. P3 输出报告 — P0-P3 严重度 + 修复优先级(MUST-FIX/SHOULD-FIX/NICE-TO-FIX/OPTIONAL)

## Directory Structure

```
SKILL.md                # Core instructions
README.md               # This file
```

## See Also

- coder — 编码 + 深度审计模式
- fin-code-review — 金融专项审查（hidden）
- simplify — 代码简化（hidden）
