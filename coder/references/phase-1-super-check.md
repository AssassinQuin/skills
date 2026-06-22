---
phase: 1
name: phase-1-super-check
description: S.U.P.E.R 模块健康评估 5 原则 + 🟢🟡🔴 评分规则 + 检测信号。
source: "design.md §7"
status: skeleton
---

# Phase 1: S.U.P.E.R 模块健康评估

> **加载时机**：Phase 1 explorer 返回 modules 清单后，orchestrator 评分时。

## 5 原则（抄 spec_driven_develop）

| 原则 | 含义 | 检测信号 |
|---|---|---|
| **S**ingle Purpose | 一模块一职责 | 模块内函数语义聚类度；文件 >500 行警告 |
| **U**nidirectional Flow | 数据单向，无环 | `trace_path` 检测循环依赖 |
| **P**orts over Implementation | 接口先于实现 | abstract/interface 比例；公开 API 文档化率 |
| **E**nvironment-Agnostic | 无硬编码 | grep 硬编码 URL/path/key/secret |
| **R**eplaceable Parts | 可替换 | 模块入度/出度比；swap 成本估算 |

## 评分规则

每个 Phase 0 涉及的模块逐个评分：

```
module: internal/auth
  S 🟢  (245 行，单一职责)
  U 🟡  (依赖 internal/user，但 user 反向引用 auth 的 1 个工具函数)
  P 🟢  (LoginPort interface 定义清晰)
  E 🔴  (hardcoded "localhost:5432" in dev fallback)
  R 🟢  (swap 成本低，2 个入度)
```

## 汇总热图

```
🔴 热点：internal/auth (E🔴), internal/payment (S🔴 U🔴)
🟡 观察：internal/user (U🟡)
🟢 健康：其他 12 个模块
```

## 范围

**只评 Phase 0 涉及的模块**（按需，避免 token 爆炸 — Q3 已决策）。

## 与审查门控整合

- 新改动让模块从 🟢 → 🟡/🔴 → **强制 Phase 5 深度审计**
- 新改动未改善已存在 🔴 热点 → 标注技术债（不阻塞，但汇报）

## 检测命令示例

```bash
# S 单一职责
wc -l internal/auth/*.go  # >500 行警告

# U 单向流
# 用 mcp__codebase-memory-mcp__trace_path 检测循环

# E 无硬编码
grep -rE "(localhost|127\.0\.0\.1|password|secret|api_key)" internal/ --include="*.go"

# R 可替换
# 用 get_architecture 看 incoming/outgoing 比
```

## TODO（待 step 2 扩充）

- [ ] 每个原则的具体阈值（🟢/🟡/🔴 界定）
- [ ] 衰减记录到 memory (`coding-super-decay` tag)
- [ ] 跨任务比较（同模块本次 vs 上次评分）

## 引用

- design.md §7
- `phase-5-verification.md`（S.U.P.E.R 回归由 reviewer-2 做）
