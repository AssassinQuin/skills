---
name: code-review
description: >
  代码审查。审查 git diff / PR 变更，7 维结构化审查（正确性/架构SOLID/安全/性能/可读性/测试/冗余代码），
  P0-P3 四级严重度，输出完整审计报告 + 修复优先级建议。
  触发词：review、code review、审查代码、review PR、review diff、代码审查、代码评审、审计代码。
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Agent
metadata:
  version: "3.0"
---

# Code Review — 代码审查

审查 git diff 变更，输出结构化审计报告与修复建议。

## 模式判定

| 输入 | 模式 | 流程 |
|------|------|------|
| "快速审查" / ≤ 3 文件简单变更 | Quick Scan | P0 → P1 → P3(简) |
| PR / diff / 指定文件 | Deep Review | P0 → P1 → P2 → P3 |
| > 10 文件或 > 500 行 | Batch | 分批 ≤ 10 文件，逐批 Deep Review |

## 执行流程

```
P0 定位 → P1 Quick Scan(grep) → [P2 Deep Review] → P3 输出报告
```

### P0: 定位

1. 检测语言（go.mod / pyproject.toml / package.json / Cargo.toml）
2. 获取 diff 范围（`git diff` / 指定文件 / 目录）
3. 复杂度：简单(≤ 3 文件, ≤ 200 行) / 标准 / 复杂(≥ 10 文件或涉及并发/API)

### P1: Quick Scan（grep 扫描，所有模式必做）

| 维度 | 通用 | Go | Python | TS/JS |
|------|------|-----|--------|-------|
| 安全 | `eval(`, SQL 拼接, 硬编码 key | `template.Execute` 无转义 | `pickle.loads`, `shell=True` | `innerHTML` |
| 正确性 | nil/null 未检查, 空 catch | `err` 未处理 | bare `except:`, mutable default | `== null` vs `===` |
| 性能 | 循环内 IO, 大对象复制 | goroutine 泄漏 | 缺 `@lru_cache` | `useEffect` 缺 deps |
| 架构 | 函数 > 50 行, 嵌套 > 4 层 | interface 过大 | 继承 > 3 层 | 组件 > 300 行 |
| 冗余 | 注释代码, 未使用 import | `_ = unused` | `# noqa` 滥用 | unused deps |
| 测试 | 测试文件是否存在 | `*_test.go` | `test_*.py` | `*.test.ts` |

### P2: Deep Review（Deep / Batch 模式）

**D1 正确性**：边界条件、错误处理完整性、逻辑分支、类型安全

**D2 架构(SOLID)**：函数过长→违反 S；switch 散布→违反 O；接口过大→违反 I；依赖具体实现→违反 D

**D3 安全**：注入(SQL/XSS/命令)、认证授权、敏感数据、加密正确性

**D4 性能**：算法复杂度、N+1 查询、内存、IO

**D5 可读性**：命名清晰度、函数长度(≤50 行)、嵌套(≤3 层)、注释解释 why

**D6 测试**：核心路径覆盖(正常+边界+错误)、测试质量

**D7 冗余代码**：

| 类型 | 判定标准 |
|------|---------|
| 注释代码 | 被注释掉的代码块（git 有历史） |
| 未使用 | import/变量/函数无引用 |
| 重复 | 相似度 > 80% |
| 过度抽象 | 仅 1 个实现的接口 |
| 过时 TODO | 无 issue 编号或 > 6 个月 |

### P3: 输出审计报告

```markdown
## Code Review Report

**范围**：{N} 文件 {M} 行 | **语言**：{lang} | **模式**：{Quick/Deep/Batch}

### Critical (P0) — 必须修复，阻塞合并
- [{D1-正确性}] `{文件}:{行号}` — {问题描述}
  **建议**: {修复方向}
  **修复优先级**: MUST-FIX

### High (P1) — 强烈建议修复
- [{D2-架构}] `{文件}:{行号}` — {问题描述}
  **建议**: {修复方向}
  **修复优先级**: SHOULD-FIX

### Medium (P2) — 建议修复
- [{D6-测试}] `{文件}:{行号}` — {问题描述}
  **修复优先级**: NICE-TO-FIX

### Low (P3) — 可选改进
- [{D5-可读性}] `{文件}:{行号}` — {问题描述}
  **修复优先级**: OPTIONAL

### 删除候选
| 文件:行号 | 类型 | 原因 |

### 总结
| 维度 | P0 | P1 | P2 | P3 |
|------|----|----|----|----|
| D1 正确性 | | | | |
| D2 架构 | | | | |
| D3 安全 | | | | |
| D4 性能 | | | | |
| D5 可读性 | | | | |
| D6 测试 | | | | |
| D7 冗余 | | | | |

**风险等级**：{高/中/低} — {1-2 句话}

**修复建议汇总**：
- MUST-FIX: {N} 项 — {列出}
- SHOULD-FIX: {N} 项 — {列出}
- NICE-TO-FIX / OPTIONAL: {N} 项

### 正面评价
- {做得好的地方，≤ 3 条}
```

## Agent 消费接口

审计报告中的 `**修复优先级**` 字段供其他 agent 判断是否自动修复：

| 优先级 | 含义 | 自动修复建议 |
|--------|------|-------------|
| `MUST-FIX` | 安全漏洞、数据丢失、必现 bug | 建议立即修复 |
| `SHOULD-FIX` | 高概率 bug、架构问题 | 建议本轮修复 |
| `NICE-TO-FIX` | 边界、可维护性 | 可选，不阻塞 |
| `OPTIONAL` | 风格、命名 | 仅在有明确需求时处理 |

其他 agent（如 coder）读取报告后，根据 `MUST-FIX` 和 `SHOULD-FIX` 决定是否进入修复流程。

## 约束

1. **Review-only** — 只输出发现，不修改代码
2. **P0 立即报告** — 发现 P0 在当前步骤就输出
3. **证据驱动** — 每个发现必须有 `{文件}:{行号}`，无证据不输出
4. **不先入为主** — 基于具体代码证据判断，不预设质量好坏
5. **复杂度适配** — 简单变更用 Quick Scan + 简化输出；复杂变更完整 7 维
6. **敏感场景提升** — 涉及金额/并发/敏感数据时，自动提升 D1+D3 检查深度
7. **范围不发散** — 只审查变更部分，不输出变更外的问题
