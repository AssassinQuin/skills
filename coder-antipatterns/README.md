# Coder-Antipatterns

**Anti-pattern 案例库**（从历次执行偏离中提炼）。下次遇到类似情境必须识别并拒绝。

## Trigger

- 每次 coder 流水线执行（always loaded）
- 识别反模式时引用具体 AP-X
- 汇报里标注违反了哪个 AP

## Quick Start

```
（always loaded，自动加载）
```

## Workflow

1. AP-1 to AP-10 案例库（含场景 + 反例 + 正例）
2. 每次执行对照检查
3. 发现新 anti-pattern → 追加到 SKILL.md
4. 汇报里引用 AP-X 编号

## Directory Structure

```
SKILL.md / scripts/anti-pattern-runner / README.md
```

## Output Format

```
AP 检查清单（每次执行对照）
```

## See Also

coder-constraints (硬约束) / coder (主 router)
