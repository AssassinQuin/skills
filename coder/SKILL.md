---
name: coder
version: "2.0"
description: 多语言编码元技能。检测语言→加载上下文→编排skill链→执行→审查→持久化经验。触发词：写代码、实现、重构、修复、修改、coder、编码、开发、debug、新增。
agent-compatible: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Coder — 多语言编码元技能

## 退出条件

| 条件 | 行为 |
|------|------|
| 无匹配语言且目标文件无法确定语言 | 退出，使用通用编码 |
| 纯文档任务（README/规范/变更日志） | 退出，使用文档 skill |
| 非 coding 任务（分析数据/翻译/计划） | 退出，使用通用能力 |

## 决策树

```
入口
 ├─ 调用方式检测
 │   ├─ Agent 调用 → 加载 references + 项目上下文 → 语言检测
 │   └─ Skill 调用 → 加载 references → 语言检测
 ├─ 语言检测
 │   ├─ 目标文件扩展名 → 直接确定
 │   ├─ 项目文件: go.mod→Go, pyproject.toml/setup.py/requirements.txt→Python
 │   └─ 未匹配 → 退出
 ├─ 复杂度评估
 │   ├─ 简单（删除/注释/常量/配置） → 快速路径
 │   ├─ 标准（新增函数/修改逻辑/同包重构） → 标准路径
 │   └─ 复杂（金额/并发/API签名/跨模块/框架交互） → 完整路径
 ├─ 执行路径
 ├─ 验证门 → 审查门控 → 汇报
```

## 上下文加载（强制，不可跳过）

| 时机 | 文件 | 内容 |
|------|------|------|
| 步骤 1 前 | `references/{prefix}-tooling.md` | 语义工具选择、导航策略 |
| 步骤 3 前 | `references/{prefix}-editing-rules.md` | 编辑规则、文件归属、格式化 |
| 步骤 4 前 | `references/{prefix}-verification-loop.md` | 验证链、预存失败识别 |
| 新增/重组代码时 | `references/{prefix}-conventions.md` | 编码惯例、架构模式 |
| 始终 | `references/core-protocols.md` | 编排协议、经验持久化、洞察发现、汇报格式 |

prefix 从项目文件探测：`go.mod`→`go-`，`pyproject.toml`/`setup.py`/`requirements.txt`→`python-`。

## 编排模式判定

| 用户意图 | 模式 | skill 链 |
|----------|------|----------|
| 重构/重组/重命名 | 自主导导 | 本 skill → (可选 simplify) |
| 新功能 | 单 skill | tdd |
| 修 bug | 单 skill | diagnose |
| 审查代码 | 单 skill | code-review |
| 诊断+修复+补测试 | 串联 | diagnose → 修复 → tdd |
| 审查+修复 | 串联 | code-review → diagnose → 修复 |
| 混合/不明确 | 交互确认 | 列出 ≤3 候选路径 |

串联编排协议、委托验收标准见 `references/core-protocols.md`。

## 执行路径

| 路径 | 步骤 | 用户确认 |
|------|------|---------|
| **快速** | 理解→执行→验证→汇报 | 否 |
| **标准** | 理解→方案→执行→验证→汇报 | 方案步骤需确认 |
| **完整** | 理解→方案→保护测试→执行→验证→汇报 | 方案步骤需确认 |

### 理解（所有路径共有）

1. 语义导航：引用关系、公开 API、同名符号
2. 洞察发现：主动扫描（详见 core-protocols.md）
3. 框架层错误专项：MCP/类型解析/序列化 → 对比同项目正常代码
4. 加载历史经验：`memory_search(query="{语言} coding gotcha", limit=5)`

### 方案（标准/完整路径）

展示：改动范围 + 改动类型 + 风险评级 + 验证计划。**等待用户确认**。

### 保护测试（仅完整路径）

识别行为锚点 → 参数化测试 → 全部 PASS。无法测试标注 `[未保护]` + 理由，全部 fallback 必须**用户确认**。

### 执行

先完成所有文件改动，再一次性验证。

| 任务类型 | 流程 |
|----------|------|
| 重构 | 本 skill 主导，按风险从低到高 |
| 新需求 | 委托 tdd + 注入语言上下文 |
| Bug 修复 | 语义定位 → 修复 → 回归测试 |
| 简化/删除 | 注入引用安全 → 逐点简化 |

### 验证

加载 `references/{prefix}-verification-loop.md`，执行完整验证链。失败处理：预存问题标注继续；新引入失败回退修复（最多 2 轮）。

## 审查门控（验证通过后）

| 复杂度 | 审查行为 |
|--------|---------|
| 简单 | 跳过 |
| 标准 | 自审清单（风格/副作用/测试覆盖） |
| 复杂 | 委托 neat-freak skill（若未安装则委托 code-review skill） |

## 汇报 + 经验持久化

汇报格式和经验持久化触发条件见 `references/core-protocols.md`。

## 约束

- 不改范围外文件
- 单文件 ≤ 800 行，超出需拆分
- 每次输出包含：当前步骤、语言、风险等级
- 发现异常标注: "T{n} 异常: {类型} | {现象} | {已尝试} | {建议}"
