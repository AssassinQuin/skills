# Code Review

统一代码审查。7 维结构化审查 + 金融专项 + 自动修复，三模式合一。

## 触发

- 通用审查：review、审查代码、review PR、review diff、代码审查
- 金融专项：金融审查、fin review、审查交易代码、审查支付代码
- 自动修复：simplify、简化代码、`--fix`

## 模式

| 模式 | 说明 |
|------|------|
| **Review**（默认） | 7 维审查，只出报告不修改代码 |
| **Fin** | 金融专项：数据完整性 > 流程正确性 > 安全合规 |
| **Fix** | 审查后自动应用修复，逐项验证行为不变 |

## Workflow

1. P0 定位 — 检测语言、范围、复杂度、模式
2. P1 Quick Scan — grep 模式扫描（安全/正确性/性能/架构/冗余/测试）
3. P2 Deep Review — 7 维逐项审查（Fin 模式替换为金融专项）
4. P3 输出报告 — P0-P3 四级严重度
5. P4 Fix — 仅 Fix 模式，自动应用修复

## Directory Structure

```
SKILL.md                        # Core instructions (3-in-1)
references/
  fin-review.md                 # Financial-specific check tables
  simplify-guide.md             # Simplification principles for Fix mode
agents/
  claude-code.yaml              # Sub-agent orchestration config
```

## 合并说明

v2.0 合并了三个原独立 skill：
- `code-review` → Review 模式
- `fin-code-review` → Fin 模式（详见 references/fin-review.md）
- `simplify` → Fix 模式（详见 references/simplify-guide.md）

## See Also

- coder — 编码+深度审计模式
- security-review — 安全专项审计
