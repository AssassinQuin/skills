# Coder-Constraints

**14 条硬约束完整版**（含检查命令 + 例子 + 反例）。orchestrator + 所有子 agent 永远加载。

## Trigger

- 每次 coder 流水线执行（always loaded）
- 需要检查硬约束违规
- 新 agent 加载时注入

## Quick Start

```
（always loaded，自动加载）
```

## Workflow

1. R1-R12（基础编码规则 + AI 代理协作）
2. #13 Edit 前 grep 同类模式
3. #14 单条消息并发 ∈ [3,5]（v7.1 新）
4. 每次汇报必填 14 项检查清单
5. 任一 ✗ 必须解释

## Directory Structure

```
SKILL.md / README.md
```

## Output Format

```
硬约束执行检查清单（14 项 ✓/✗）
```

## See Also

coder (主 router) / coder-antipatterns (案例库) / coding-rules.md (R1-R12 原文)
