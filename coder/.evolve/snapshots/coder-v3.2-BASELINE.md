---
name: coder
version: "3.2"
description: >
  多语言编码元 skill（编排 + 综合 + 路由）。按语言路由到垂直子 agent：
  go-coder / python-coder（按需扩展 typescript-coder / rust-coder 等）。


  显式 trigger：写代码、实现、重构、修复、修改、coder、编码、开发、debug、新增、审计代码、review
  diff。
  隐式 trigger："修这个 bug" / "加个 X 功能" / "重构这块" / "这块代码不对" / "为什么
  X 报错" / "改下 X"。
  架构（类似 revfactory/harness）：本 skill 是编排者，按语言分发到垂直子 agent，
  每个 agent 独立解决一类语言的全场景编码问题。
agent-compatible: true
skill_type: execution
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
---

# Coder — 多语言编码元 skill

**架构**（v3.2 重构，类似 revfactory/harness + web-research v2.3）：本 skill 是**编排者**，按语言分发到垂直子 agent。

```
用户请求 → Phase 1 调用方式 + 语言检测
        → Phase 2 路由判定（语言 → agents/{lang}-coder.md）
        → Phase 3 分发到垂直 agent（理解/方案/执行/验证/审查）
        → Phase 4 综合（编排模式 + 跨模块协议 + 汇报）
```

## 退出条件

| 条件 | 行为 |
|------|------|
| 无匹配语言且目标文件无法确定 | 退出，使用通用编码 |
| 纯文档任务 | 退出，使用文档 skill |
| 非 coding 任务 | 退出，使用通用能力 |

---

## Phase 1: 调用方式 + 语言检测

### 1.1 调用方式
- Agent 调用 → 加载通用 references（core-protocols / token-budget）+ 项目上下文
- Skill 调用 → 加载通用 references

### 1.2 语言检测（优先级：目标文件 > 项目文件 > prompt 关键词）

| 信号 | 路由 |
|------|------|
| 目标文件 `.go` 或项目含 `go.mod` | → [`agents/go-coder.md`](agents/go-coder.md) |
| 目标文件 `.py` 或项目含 `pyproject.toml`/`setup.py`/`requirements.txt` | → [`agents/python-coder.md`](agents/python-coder.md) |
| 目标文件 `.ts`/`.tsx`/`.js` | 暂无 agent，回退通用 + 提示扩展 |
| 目标文件 `.rs` | 暂无 agent，回退通用 + 提示扩展 |
| 三层未匹配 | 退出 |

---

## Phase 2: 复杂度评估（语言无关骨架）

| 复杂度 | 触发条件 | 路径 |
|-------|---------|------|
| 简单 | 删除/注释/常量/配置 | 快速 |
| 标准 | 新增函数/修改逻辑/同包重构，不含敏感词 | 标准（方案需确认）|
| 复杂 | 任一敏感词：金额/并发/auth/跨模块/框架 | 完整（保护测试 + Layer 2 强制）|

**复杂度不可主观降级**（硬约束）。语言专属风险子类型 + 验证策略见对应 agent。

---

## Phase 3: 分发到垂直 agent

按 Phase 1 路由结果，spawn 对应 `agents/{lang}-coder.md` 作为子 agent（model=sonnet）。

**子 agent 契约**（每个 agent 文件含）：
- 工具链探测（语言专属）
- references 加载时机（语言专属）
- 复杂度判据 + 风险子类型（语言专属）
- 并发原语决策树（语言专属）
- 保护测试 protocol（语言专项）
- 审计 checklist（语言专项）
- 输出 schema（JSON）
- 跑偏自查清单

**orchestrator（本 SKILL.md）只做**：路由 + 协调 + 综合。**不重复 agent 内部工作**。

### 3.1 通用执行路径（语言无关骨架）

| 路径 | 步骤 | 用户确认 |
|------|------|---------|
| 快速 | 理解 → 执行 → 验证 → 汇报 → 经验总结 | 否 |
| 标准 | 理解 → 方案 → 执行 → 验证 → 汇报 → 经验总结 | 方案步骤 |
| 完整 | 理解 → 方案 → 保护测试 → 执行 → 验证 → 汇报 → 经验总结 | 方案步骤 |

详细执行细节（工具链探测 / references 加载 / 复杂度风险类型 / 并发原语 / 保护测试 / 审计 checklist）**全部委托给对应 `agents/{lang}-coder.md`**。

---

## Phase 4: 编排模式（语言无关）

| 用户意图 | 模式 | skill 链 |
|---------|------|---------|
| 重构/重组/重命名 | 自主导 | 本 skill → (可选 simplify) |
| 新功能 | 单 skill | tdd |
| 写测试/单元测试 | 复合链 | tdd + unit-testing-best-practices |
| 修 bug | 单 skill | diagnose |
| 审查代码 | 单 skill | code-review |
| 审计代码 | 委托子 agent | `references/code-audit-protocol.md` |
| 诊断+修复+补测试 | 串联 | diagnose → 修复 → tdd |
| 审查+修复 | 串联 | code-review → diagnose → 修复 |
| 审计+修复 | 串联 | 子 agent 审计 → diagnose → 修复 |
| 混合 | 交互确认 | 列出 ≤3 候选 |

### 跨模块一致性策略（v3.1 加，v3.2 保留 — 语言无关）

```
副作用（audit log / 通知 / 缓存失效）与主操作关系？
├── 必须强一致（金融审计 / 合规）→ 同事务，DB audit 表 + tx.Err() 链路
├── 允许最终一致（行为日志 / 监控）→ 异步 sink（NSQ/Kafka/Queue）+ 幂等重试
└── 允许丢失（调试日志）→ stdout / file logger
```

测试策略随一致性变化：强一致测事务回滚；最终一致测幂等性；允许丢失不测。

---

## 审查门控（语言无关触发条件）

### Layer 1: 自审（强制触发）

| 复杂度 | 是否触发 | 范围 |
|-------|---------|------|
| 简单 | 跳过 | - |
| 标准 | **强制** | 风格 + 副作用 + 测试覆盖存在性 + **委托语义覆盖复核**（grep 验证委托输出真覆盖目标模块）|
| 复杂 | **强制** | Layer 1 范围 + 委托 neat-freak skill（若未装则 code-review）|

### Layer 2: 深度审计（强制触发）

| 条件 | 是否触发 |
|------|---------|
| 复杂度 = 复杂（金额/并发/auth/跨模块）| **强制** |
| 用户显式（"审计"/"review diff"/"code audit"）| 强制 |
| 完整路径执行后 | 强制 |
| 标准/简单无敏感词 | 不触发 |

委托子 agent 加载 `references/code-audit-protocol.md`。**子类型审计 checklist 见对应 `agents/{lang}-coder.md`**（语言专属，如 Go 并发审计 / Python async 审计）。

---

## 汇报（v3.0 强制字段 + v3.2 加 agent 输出汇总）

```markdown
## 改动摘要
- 语言：{语言} | 文件数：{N} | 类型：{类型} | 风险：{等级}

## 路由 agent（v3.2 新增）
- agents/{lang}-coder.md → 输出 schema：{摘要}

## references 引用点（v3.0 强制）
- references/{file}.md → 抽取：{规则/段落}

## 编排过程（如有）
- [阶段1] {skill}: {结果摘要}

## 硬约束执行检查（v3.0 强制，见 references/hard-constraints-check.md）
- [✓/✗] 1. 上下文加载
- [✓/✗] 2. 工具链探测
- [✓/✗] 3. 验证链
- [✓/✗] 4. 审查门控
- [✓/✗] 5. 经验总结
- [✓/✗] 6. Token 预算

## 文件列表 + 验证结果
- path/to/file: {改动描述}
- lint: PASS | type: PASS | test: {M}P/{K}F
```

---

## 经验总结（汇报后必做，含失败/中断场景）

**触发场景**（v3.0 扩展）：成功 / 失败回滚 / 用户中断（必触发，不可跳过）。

| 触发条件 | 存储内容 | 标准 tag |
|---------|---------|---------|
| 踩坑（工具报错/降级/重试 2+）| "踩坑: {描述}。正确做法: {做法}" | `coding-{lang}-gotcha` |
| 用户修正（纠正 ≥1 次）| "修正: {原始} → {正确}" | `coding-{lang}-gotcha` |
| 新发现 | "发现: {语言/框架} 中 {模式} 的规律" | `coding-{lang}-convention` |
| 工具链发现 | "环境: {工具} 关键命令: {命令}" | `coding-{lang}-toolchain` |
| 审计发现 | "审计: {代码类型} 常见问题: {模式}" | `coding-{lang}-audit` |

`{lang}` 必须小写：`go` / `python` / `typescript` / `rust`。详见 [core-protocols.md](references/core-protocols.md)。

---

## 约束

- 不改范围外文件
- 单文件 ≤ 800 行（SKILL.md 例外，元 skill 允许稍长）
- 每次输出包含：当前步骤、语言、风险等级
- 异常标注: "T{n} 异常: {类型} | {现象} | {已尝试} | {建议}"
- 涉及自动生成目录时禁止手动编辑，必须框架命令重新生成
- 经验总结不可跳过（即使无新经验也输出"本次无新经验"确认）
- **Token 预算**：单次任务主上下文 ≤ 30k + 长文件 ctx_index（详见 [token-budget.md](references/token-budget.md)）
- **references 加载证据**：📂 已加载 + 汇报含引用点
- **硬约束自验证**：汇报末尾含硬约束检查清单（详见 [hard-constraints-check.md](references/hard-constraints-check.md)）
- **复杂度不可主观降级**
- **语言专属细节委托给 agents/{lang}-coder.md**（v3.2 加，禁止在 SKILL.md 重复 agent 内部内容）

---

## 新语言扩展协议（v3.2 新增）

新增语言（如 TypeScript / Rust / Java）按此协议：

1. 在 `agents/` 新建 `{lang}-coder.md`（参考 go-coder.md / python-coder.md 结构）
2. 在 `references/` 新建 4 个文件（最小集合）：
   - `{lang}-tooling.md`（工具选择 + 导航）
   - `{lang}-editing-rules.md`（编辑规则 + 陷阱）
   - `{lang}-verification-loop.md`（验证链）
   - `{lang}-conventions.md`（编码惯例）
3. 在本 SKILL.md Phase 1.2 路由表加对应行

缺任一文件 → 该语言不可用，决策树退出"未匹配"。

---

## 相关文件

- 垂直子 agent：[`agents/go-coder.md`](agents/go-coder.md) / [`agents/python-coder.md`](agents/python-coder.md)
- 通用 references：
  - [`references/core-protocols.md`](references/core-protocols.md) — 编排协议 + 经验持久化
  - [`references/code-audit-protocol.md`](references/code-audit-protocol.md) — Layer 2 审计
  - [`references/token-budget.md`](references/token-budget.md) — token 预算
  - [`references/hard-constraints-check.md`](references/hard-constraints-check.md) — 硬约束自验证
- 语言专属 references（被 agents/{lang}-coder.md 引用）：
  - Go: `go-conventions.md` / `go-editing-traps.md` / `go-gopls-strategy.md` / `go-verification-loop.md`
  - Python: `python-conventions.md` / `python-editing-rules.md` / `python-tooling.md` / `python-verification-loop.md`
