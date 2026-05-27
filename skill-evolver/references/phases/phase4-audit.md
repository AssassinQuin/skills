# Phase 4: 独立审计

## 强制要求
- 全新上下文子 agent（model=opus）
- 不继承任何进化过程信息

## 准备工作

```bash
cp {skill}/SKILL.md {skill}/SKILL.md.before
```

## 审计 agent 输入

给子 agent 的 prompt 必须用明确标记：
```
文件 A (标记为 BEFORE): {绝对路径}/SKILL.md.before — 原始版本
文件 B (标记为 AFTER): {绝对路径}/SKILL.md — 改写后版本

先读 BEFORE，再读 AFTER，对比时始终引用标记名。
```

**给**：BEFORE 文件、AFTER 文件、audit-checklist.md（见 references/）
**不给**：Δ 差距描述、Phase 2-3 分析、测试 prompt 集、策略选择记录

## 10 项审计清单

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

## 审计后清理

```bash
rm {skill}/SKILL.md.before
```

## 关卡 4（与关卡 5 合并确认）

```
审计结果：X/10 PASS
- FAIL ≤ 2：修复 → 重审失败项
- FAIL ≥ 3：git revert HEAD → 回 Phase 2 换策略
```
