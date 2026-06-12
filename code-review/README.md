# Code Review

审查 git diff / PR 变更：推断意图 → 可视化流程 → 7 维审查 → 交叉验证 → 完整审计报告 + 修复优先级。

## Trigger

review、审查代码、review PR、review diff、代码审查、代码评审、审计代码

## Quick Start

```
/code-review review 这个 PR
/code-review 审查最近的 diff
```

## Workflow

1. **P0 定位** — 检测语言、diff 范围、复杂度
2. **P1 理解变更** — 推断作者意图 + 收集上下文 + 变更摘要 + Mermaid 流程图
3. **P2 深度审查** — 7 维逐项审查（正确性/架构/安全/性能/可读性/测试/冗余）
4. **P3 交叉验证** — 2 个子 agent 并行验证，置信度评分
5. **P4 输出报告** — 完整审计报告 + 修复优先级(MUST-FIX/SHOULD-FIX/NICE-TO-FIX/OPTIONAL)

## Key Features

- **意图推断**：不盲目审查，先理解"作者想做什么"
- **Mermaid 可视化**：业务流 + 技术流图示变更
- **交叉验证**：子 agent 二次确认，避免误报
- **Agent 消费接口**：优先级+置信度字段供其他 agent（如 coder）判断是否修复

## Directory Structure

```
SKILL.md                # Core instructions
README.md               # This file
```
