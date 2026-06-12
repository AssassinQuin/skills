---
name: code-review
description: >
  通用代码审查。7 维结构化审查（正确性/架构SOLID/安全/性能/可读性/测试/冗余代码），
  P0-P3 四级严重度，Quick Scan + Deep Review 双模式。Review-only 不自动修改。
  触发词：review、code review、审查代码、review PR、review diff、代码审查、代码评审。
  不用于：深度审计（用 coder 审计模式）、金融专项审查（用 fin-code-review）。
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Agent
metadata:
  version: "1.0"
---

# Code Review — 通用代码审查

7 维结构化审查。Review-only：输出发现，不自动修改代码。

## 适用范围

- 语言：通用（Go/Python/TypeScript/Java/Rust/C++ 自动适配）
- 输入：git diff / PR / 指定文件 / 指定目录
- 不适用于：深度审计（用 coder 审计模式）、金融专项（用 fin-code-review）

## 模式判定

| 输入 / 意图 | 模式 | 流程 |
|------------|------|------|
| "快速审查" / "scan" / ≤ 3 文件简单变更 | Quick Scan | P0 → P1(grep) → P3 |
| PR / diff / 指定文件 | Deep Review | P0 → P1(grep) → P2(逐项) → P3 |
| 文件 > 10 或变更 > 500 行 | Batch | 分批 ≤ 10 文件，逐批 Deep Review |

## 执行流程

```
P0 定位 → P1 Quick Scan(grep) → [P2 Deep Review] → P3 输出
```

### P0: 定位（10 秒）

1. 检测语言（扩展名 + 项目文件：go.mod / pyproject.toml / package.json / Cargo.toml）
2. 识别审查范围（git diff / 文件列表 / 目录）
3. 判断复杂度：简单(≤ 3 文件, ≤ 200 行) / 标准 / 复杂(≥ 10 文件 或 涉及金额/并发/API)

### P1: Quick Scan（grep 快速扫描，所有模式必做）

对审查范围执行 grep 模式扫描，命中项标记「待深入」进入 P2：

| 维度 | 通用扫描 | Go 特征 | Python 特征 | TS/JS 特征 |
|------|---------|---------|-------------|-----------|
| 安全 | `eval(`, SQL 拼接, 硬编码 key/secret/password | `template.Execute` 无转义 | `pickle.loads`, `yaml.load`, `shell=True` | `innerHTML`, `dangerouslySetInnerHTML` |
| 正确性 | nil/None/null 未检查, 空 catch/except, 硬编码魔数 | `err` 未处理, `defer Close()` 无 err | bare `except:`, mutable default args | `any` 类型滥用, `== null` vs `===` |
| 性能 | 循环内 IO/查询, 大对象复制 | goroutine 泄漏, `append` 循环未预分配 | list comprehension 替代循环, `@lru_cache` | `useEffect` 缺 deps, O(n²) 渲染 |
| 架构 | 函数 > 50 行, 嵌套 > 4 层, 参数 > 5 个 | interface 过大, struct 耦合 | class 继承 > 3 层 | 组件 > 300 行, prop drilling |
| 冗余 | 注释代码, 未使用 import/变量 | `_ = unused` | `# noqa` 滥用 | unused deps |
| 测试 | 同目录测试文件是否存在 | `*_test.go` | `test_*.py` / `*_test.py` | `*.test.ts` / `*.spec.ts` |

### P2: Deep Review（Deep Review / Batch 模式）

对 P1 命中项 + 变更涉及的核心逻辑，按 7 维逐项审查：

**D1 正确性**：边界条件(空值/零值/越界/并发)、错误处理完整性、逻辑分支完备性、类型安全

**D2 架构(SOLID)**：
- 函数/类过长 → 违反 S(单一职责)
- switch/type-check 散布多处 → 违反 O(开闭)
- 接口方法过多 → 违反 I(接口隔离)
- 直接依赖具体实现而非抽象 → 违反 D(依赖倒置)

**D3 安全**：输入校验、注入攻击(SQL/XSS/命令)、认证授权、敏感数据泄露、加密使用正确性

**D4 性能**：算法复杂度、N+1 查询、内存使用、IO 效率

**D5 可读性**：命名清晰度、函数长度(≤50 行理想)、嵌套深度(≤3 层理想)、注释价值(解释 why)

**D6 测试覆盖**：测试文件存在性、核心路径覆盖(正常+边界+错误)、测试质量

**D7 冗余代码(Removal Candidates)**：

| 类型 | 判定标准 |
|------|---------|
| 注释代码 | 被注释掉的代码块（git 有历史，无需注释保留） |
| 未使用 | import/变量/函数无引用 |
| 重复 | 相似度 > 80% 的代码块 |
| 过度抽象 | 仅 1 个实现的接口/抽象层 |
| 过时 TODO | 无 issue 编号或 > 6 个月的 TODO/FIXME |

### P3: 输出报告

## 严重性

| 级别 | 定义 | 行动 |
|------|------|------|
| **P0 Critical** | 安全漏洞、数据丢失风险、必定 bug | 必须修复，阻塞合并 |
| **P1 High** | 高概率 bug、明显架构问题、严重性能问题 | 强烈建议修复 |
| **P2 Medium** | 边界问题、可维护性差、测试不足 | 建议修复 |
| **P3 Low** | 风格、命名、小改进 | 可选修复 |

## 输出格式

Quick Scan 简化输出（仅列出命中项）。Deep Review / Batch 完整输出：

```markdown
## Code Review Report

**范围**：{N} 文件 {M} 行 | **语言**：{lang} | **模式**：{Quick/Deep/Batch}

### Critical (P0) — 必须修复
- [{D1-正确性}] `{文件}:{行号}` — {问题描述}
  **建议**: {修复方向}

### High (P1) — 强烈建议修复
- [{D2-架构}] `{文件}:{行号}` — {问题描述}

### Medium (P2) — 建议修复
- [{D6-测试}] `{文件}:{行号}` — {问题描述}

### Low (P3) — 可选改进
- [{D5-可读性}] `{文件}:{行号}` — {问题描述}

### 删除候选
| `{文件}:{行号}` | {类型} | {原因} |

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

### 正面评价
- {做得好的地方，≤ 3 条}
```

## 约束

1. **Review-only** — 不自动修改代码，只输出发现和建议
2. **P0 立即报告** — 发现 P0 在当前步骤就输出，不等全部完成
3. **证据驱动** — 每个发现必须有 `{文件}:{行号}` + 具体问题描述，无证据不输出
4. **不先入为主** — 不假设代码质量好坏，基于具体代码证据判断
5. **复杂度适配** — 简单变更(≤ 3 文件)用 Quick Scan + 简化输出；复杂变更完整 7 维
6. **敏感场景提升** — 涉及金额/并发/敏感数据时，自动提升 D1+D3 检查深度；金融专项建议使用 fin-code-review
7. **范围不发散** — Diff Review 只审查变更部分（理解上下文时可读取调用方，但不输出调用方的问题）
