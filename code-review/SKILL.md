---
name: code-review
description: >
  统一代码审查。7 维结构化审查 + 金融专项 + 自动修复，三模式合一。
  触发词：review、code review、审查代码、review PR、review diff、代码审查、代码评审、
  金融审查、fin review、金融 code review、审查交易代码、审查支付代码、
  simplify、简化代码、修复代码。
  模式：默认(通用审查) / --fin(金融专项) / --fix(审查+自动修复)。
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Agent
  - Edit
  - Write
metadata:
  version: "2.0"
---

# Code Review — 统一代码审查

7 维结构化审查，支持金融专项和自动修复。

## 决策表

| 意图 / 触发词 | 模式 | 流程 |
|-------------|------|------|
| "review" / "审查代码" / "review PR" / "review diff" | **Review** | P0→P1→P2→P3 |
| "金融审查" / "fin review" / "审查交易/支付/风控/结算" | **Fin** | P0→P1-fin→P2-fin→P3-fin→P4 |
| "simplify" / "简化代码" / "修复代码" / `--fix` | **Fix** | Review→自动应用修复 |

## 执行流程

```
P0 定位 → P1 Quick Scan → [P2 Deep Review] → P3 输出报告
                                ↓ Fix 模式
                           P4 自动应用修复
```

### P0: 定位（10 秒）

1. 检测语言（扩展名 + 项目文件：go.mod / pyproject.toml / package.json / Cargo.toml）
2. 识别审查范围（git diff / 文件列表 / 目录）
3. 判断模式：Review / Fin / Fix
4. 复杂度：简单(≤3 文件, ≤200 行) / 标准 / 复杂(≥10 文件 或 涉及金额/并发/API)

### P1: Quick Scan（所有模式必做）

grep 模式扫描，命中项标记「待深入」：

| 维度 | 通用 | Go | Python | TS/JS |
|------|------|-----|--------|-------|
| 安全 | `eval(`, SQL 拼接, 硬编码 key | `template.Execute` 无转义 | `pickle.loads`, `shell=True` | `innerHTML` |
| 正确性 | nil/None/null 未检查, 空 catch | `err` 未处理, `defer Close()` 无 err | bare `except:`, mutable default | `== null` vs `===` |
| 性能 | 循环内 IO/查询, 大对象复制 | goroutine 泄漏 | list comp 替代循环 | `useEffect` 缺 deps |
| 架构 | 函数 > 50 行, 嵌套 > 4 层 | interface 过大 | class 继承 > 3 层 | 组件 > 300 行 |
| 冗余 | 注释代码, 未使用 import | `_ = unused` | `# noqa` 滥用 | unused deps |
| 测试 | 同目录测试文件是否存在 | `*_test.go` | `test_*.py` | `*.test.ts` |

**Fin 模式追加**：金额/余额/利率字段用 float → 立即 Critical；共享金额变量无锁 → Critical。

### P2: Deep Review

对 P1 命中项 + 核心逻辑，按 7 维审查：

**D1 正确性**：边界条件、错误处理完整性、逻辑分支、类型安全
**D2 架构(SOLID)**：函数过长→违反 S；switch 散布→违反 O；接口过大→违反 I
**D3 安全**：注入攻击、认证授权、敏感数据、加密正确性
**D4 性能**：算法复杂度、N+1 查询、内存、IO
**D5 可读性**：命名、函数长度(≤50 行)、嵌套(≤3 层)、注释价值
**D6 测试**：核心路径覆盖(正常+边界+错误)
**D7 冗余代码**：注释代码/未使用/重复(>80%相似度)/过度抽象/过时 TODO

**Fin 模式**：替换 P2 为金融专项审查。详见 `references/fin-review.md`。
三个维度按优先级：**数据完整性 > 流程正确性 > 安全合规**。

### P3: 输出报告

| 级别 | 定义 | 行动 |
|------|------|------|
| **P0 Critical** | 安全漏洞、数据丢失、必现 bug | 必须修复，阻塞合并 |
| **P1 High** | 高概率 bug、架构问题、严重性能 | 强烈建议修复 |
| **P2 Medium** | 边界问题、可维护性、测试不足 | 建议修复 |
| **P3 Low** | 风格、命名、小改进 | 可选 |

```markdown
## Code Review Report

**范围**：{N} 文件 {M} 行 | **语言**：{lang} | **模式**：{Review/Fin/Fix}

### Critical (P0)
- [{维度}] `{文件}:{行号}` — {问题描述} — **建议**: {修复方向}

### High (P1) / Medium (P2) / Low (P3)
- [{维度}] `{文件}:{行号}` — {问题描述}

### 删除候选 | 总结 | 正面评价
```

**Fin 模式**输出按 P1-数据 / P2-流程 / P3-安全 分组，附关键风险提示和测试建议。

### P4: Fix（仅 Fix 模式）

Review 完成后，对 P0-P2 发现自动应用修复。每项修复：
1. 保留行为不变
2. 遵循项目惯例
3. 优先清晰而非紧凑
4. 逐项应用，每项后运行测试

简化原则详见 `references/simplify-guide.md`。

## 约束

1. **Review-only（默认）** — 不自动修改代码，仅 Fix 模式自动修复
2. **P0 立即报告** — 发现 P0 在当前步骤就输出
3. **证据驱动** — 每个发现必须有 `{文件}:{行号}`，无证据不输出
4. **复杂度适配** — 简单变更用 Quick Scan + 简化输出
5. **Fin 模式**：金额相关代码逐行检查，数据完整性问题最先审查
6. **Fix 模式**：每个修复必须保留行为，不确定则跳过
