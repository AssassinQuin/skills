---
phase: 3
name: test-strategy
description: 测试策略。高危代码识别 + 测试范围（unit/integration/property）+ test-plan.md 模板。
source: ".deepen/20260625-execution-flow/design.md §3 Phase 3"
status: active
tokens_estimate: 1500
load_priority: on-demand
load_when: "Phase 3 + test-strategist"
keywords: high-risk 7 categories financial concurrency IO external-API auth migration property-test
domain: coding
subdomain: strategy
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  test_pyramid:
    - unit tests（逻辑层）
    - integration tests（IO/DB/外部 API）
    - property tests（数学不变量）
    - performance benchmarks（性能基准）
  owasp_top_10:
    - OWASP Top 10 全覆盖
  notes: "高危代码 7 类 + 测试金字塔 + property test"
---

# 测试策略（v6.0 Phase 3 输出）

> **加载时机**：Phase 3 oracle 设计方案时，必出 test-plan.md。
> **目的**：避免"改了核心代码没测，上线炸"。

## 1. 高危代码识别

oracle 在设计阶段**必须**识别哪些代码是 high-risk，需要重点测试。

### 高危代码 7 类

| 类型 | 识别信号 | 测试要求 |
|---|---|---|
| **金融精度** | 金额计算 / 汇率 / 手续费 / 精度舍入 | property test（任意输入都成立） |
| **并发安全** | lock / semaphore / async shared state / DB transaction | 并发场景 unit + integration |
| **IO 重操作** | DB 写 / 文件系统 / 网络请求 | integration test（不 mock 真实 IO） |
| **外部 API** | 第三方 API（GitHub / Stripe / OpenAI） | mock + integration + rate limit 测试 |
| **用户输入** | CLI / API endpoint / form 输入 | boundary + injection 测试 |
| **认证 / 鉴权** | login / token / permission check | 安全审查 + 边界测试 |
| **迁移 / Schema** | DB migration / data format change | 回滚测试 + 兼容性测试 |

### 不算高危（可不写新测试）

- 简单 wrapper（logger / formatter）
- 纯 stdlib 调用且无业务逻辑
- 已有覆盖的 refactoring（行为不变）

## 2. 测试范围决策树

```
改了高危代码？
├─ 是 → MUST 写测试
│   ├─ unit（逻辑层）
│   ├─ integration（IO / DB / 外部 API）
│   └─ property（如有数学不变量）
└─ 否 → SHOULD 评估
    ├─ 现有测试已覆盖？→ 跑一遍 PASS 即可
    └─ 行为不变 refactoring？→ 跑现有测试
```

## 3. test-plan.md 输出（Phase 3）

写到 `.claude/coder-state/specs-active/{ts}-{slug}/test-plan.md`，按 [`templates/test-plan.md.template`](../templates/test-plan.md.template) 渲染。

### 必填字段

```markdown
# Test Plan: {slug}

## 1. 高危代码识别
| 改动位置 | 高危类型 | 原因 | 必测 |
|---|---|---|---|
| auth/login.py:commit_user | 并发 + IO | DB 写 + race condition | ✅ |
| payment/refund.py | 金融精度 | 金额计算 | ✅ |
| utils/logger.py | 无 | 简单 wrapper | ❌ |

## 2. 测试范围
### Unit（必跑）
- LoginService.commit_user 并发（pytest-asyncio）
- RefundService.calculate 精度（hypothesis）

### Integration（必跑）
- 登录流程 end-to-end（真实 DB）
- GitHub OAuth callback（mock server）

### Property（金融必跑）
- refund 金额 = 原金额 - 手续费（hypothesis）

### Performance（性能敏感时）
- 登录 < 200ms p99
- DB query < 50ms p99

## 3. 不需要测试的（声明 + 理由）
- utils/logger.py：简单 wrapper，无业务逻辑
- migrations/001_xxx.py：纯 schema，由 integration 覆盖

## 4. 测试 fixture / mock 策略
- DB：用真实 SQLite（in-memory），不 mock
- 外部 API：用 responses / no-resmi mock server
- 时间：用 freezegun

## 5. 覆盖率要求
- 高危代码：100%
- 总体：≥80%（项目特定可调）
```

## 4. Phase 5 验证执行

Phase 5 spawn test-runner subagent（script 或 haiku agent）：
1. 读 test-plan.md
2. 跑列出的测试（unit + integration + property + performance）
3. 输出 test-result.md：
   ```
   ## Unit: 8/8 PASS
   ## Integration: 3/3 PASS  
   ## Property: 5/5 PASS
   ## Performance: ✅ all under threshold
   ## Coverage: 87% (target: 80%)
   ```

不达 spec 的 acceptance_criteria → Phase 5 失败，回 Phase 4 返工。

## 5. 测试反模式

### ❌ Mock 一切

```python
@mock.patch("db.connection")
@mock.patch("auth.verify") 
def test_login():
    ...
```

**问题**：mock 太多，测的是 mock 不是代码。
**正确**：integration test 用真实 DB（如 §11.6 "mock 测试过但 prod 失败"反例）。

### ❌ 测实现而不是行为

```python
def test_called_internal_method():
    assert service._internal.called  # ❌ 测实现细节
```

**正确**：测行为（输入 → 输出 + 副作用），不测私有方法。

### ❌ 测 happy path 就够

```python
def test_login():
    assert login("valid", "valid") == success  # 只测 happy
```

**正确**：必测边界（错误密码 / 用户不存在 / DB down / 并发 / race condition）。

### ❌ Property test 用固定输入

```python
@given(st.floats())
def test_refund(amount):
    assert refund(amount) >= 0  # property
```

但写 `assert refund(100) == 95` 是 unit test 不是 property。property test 是**任意输入都成立的不变式**。

## 6. 与 §11 Anti-pattern 的关系

- §11.3 "测试过就算验证通过" → 测试**范围**对了吗？（高危代码必测）
- §11.6 "简单任务滑坡" → 改 1 行也评估测试必要性
- §11.7 "Edit 前没排查同类模式" → 测试也要 grep 同类（如改了 LoginService，其他用 LoginService 的地方也要测）

## 引用

- 设计：[`.deepen/20260625-execution-flow/design.md`](../.deepen/20260625-execution-flow/design.md) §3 Phase 3
- 模板：[`templates/test-plan.md.template`](../templates/test-plan.md.template)
- 相关：[`phase-5-verification.md`](phase-5-verification.md)
- 金融审查（高危代码深化）：见 [`fin-code-review` skill](../../fin-code-review/SKILL.md)
