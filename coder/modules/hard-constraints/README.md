# Hard Constraints (Module)

独立 module of coder skill v7.0+。13 条硬约束（R1-R12）。

## 用途

- `always` 加载（orchestrator + 所有子 agent）
- 强制编码规则（不是建议）

## 内容

- `SKILL.md`：13 条硬约束完整版（~1500 tokens）

## 13 条概览

| # | 约束 | 来源 |
|---|---|---|
| 1 | 意图不清必问 | R1 |
| 2 | 子 agent 显式指定 model | R5.1 |
| 3 | token 预算硬性 | R6 |
| 4 | 暴露冲突不折中 | R7 |
| 5 | 先读再写 | R8 |
| 6 | 测试验证意图 | R9 |
| 7 | 长任务检查点 | R10 |
| 8 | 惯例优先于新颖 | R11 |
| 9 | 失败显性化 | R12 |
| 10 | 外科手术式修改 | R3 |
| 11 | 简洁优先 | R2 |
| 12 | 编码前先思考 | R1 |
| 13 | Edit 前 grep 同类模式 | R8 扩展 |

## 框架映射

- SOLID: 全 (SRP/OCP/LSP/ISP/DIP)
- 12-Factor: 全 (I-XII)
- OWASP Top 10: A01-A10
- Test Pyramid: unit + integration

## 加载策略

`load_priority: always` — 每次 orchestrator 启动都加载（~1500 tokens 成本）。

## 与 Anti-patterns 的关系

[`anti-patterns`](../anti-patterns/) 是 13 硬约束的反面——历次执行偏离的真实案例。
