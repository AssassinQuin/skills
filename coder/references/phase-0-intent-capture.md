---
phase: 0
name: phase-0-intent-capture
description: Phase 0 需求捕获协议。AskUserQuestion 模板 + 跳过条件 + 验收 checklist 格式。
source: "design.md §5.1"
status: skeleton
---

# Phase 0: 需求捕获（orchestrator 内联）

> **加载时机**：orchestrator 进入 Phase 0 且识别到需求不清时。

## 核心流程

1. 复述用户请求（≤2 句）
2. 检查 4 个清晰度维度（任一不明 → AskUserQuestion）
3. 输出意图声明 + 验收 checklist

## 清晰度 4 维度

| 维度 | 不明信号 |
|---|---|
| 验收标准 | 用户没说"做完后用什么检查" |
| 范围限定 | "加 X 功能"但 X 涉及多模块 |
| 边界排除 | 没说不动 API / DB schema / 公共接口 |
| 优先级 | 同时改多个，没说哪个先 |

## 跳过条件（直接进 Phase 1）

- 用户请求已含明确验收（"按 X spec 实现，跑 Y 测试通过"）
- 单文件小改动（"改第 N 行的 typo"）

## AskUserQuestion 模板

```
问题: {用户原请求}
意图复述: {我理解你要做的是 X，对吗？}
需要澄清（≤2 次）:
  Q1: 验收标准 — {候选 A/B/C}
  Q2: 范围 — {候选 A/B/C}
```

总 AskUserQuestion ≤2 次（R10 长任务检查点）。

## 输出格式

```yaml
intent: "{1-2 句意图声明}"
acceptance_checklist:
  - "{可验证条件 1}"
  - "{可验证条件 2}"
  - "{3-5 条}"
```

## TODO（待 step 2 扩充）

- [ ] 3-5 个真实例子（模糊需求 → 精准意图）
- [ ] 反模式（过度澄清 / 漏关键边界）
- [ ] 与 brainstorm skill 的边界（创意捕获 vs 需求澄清）

## 引用

- design.md §5.1
- 相关：`phase-1-metadata-scan.md`（Phase 0 输出 → Phase 1 输入）
