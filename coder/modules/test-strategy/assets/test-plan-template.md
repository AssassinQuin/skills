# Test Plan: {{SPEC_SLUG}}

**Generated**: {{DATE}}
**Phase**: 3
**Author**: test-strategist (sonnet) + oracle (opus)
**Methodology**: vertical tracer-bullet cycles（v6.2，from tdd）

---

## 0. v6.2 方法论声明

> **反 horizontal slicing**。本 plan 不规划"先写所有 test 再写所有 impl"。
> 每个 cycle 是一个 `test→impl` 配对，cycle N 的 test 响应 cycle N-1 学到的。
> **Never refactor while RED**。

---

## 1. 高危代码识别

| 改动位置 | 高危类型 | 原因 | 必测 |
|---|---|---|---|
{{HIGH_RISK_TABLE}}

### 高危分类参考

- **金融精度**：金额 / 汇率 / 手续费 / 舍入
- **并发安全**：lock / async shared state / DB transaction
- **IO 重操作**：DB 写 / 文件系统 / 网络请求
- **外部 API**：第三方 API（GitHub / Stripe / OpenAI）
- **用户输入**：CLI / API endpoint / form
- **认证 / 鉴权**：login / token / permission
- **迁移 / Schema**：DB migration / data format

---

## 2. Vertical Tracer-Bullet Cycles（v6.2 核心）

> 每个 cycle = 一个完整 user 行为 + `test→impl` 配对。
> 贯穿所有层（schema + API + logic + tests），独立 demoable。

{{VERTICAL_CYCLES}}

### Cycle 1: {{CYCLE_1_NAME}}（tracer bullet — 最小贯通）
- **User behavior**: {{用户能做什么}}
- **贯穿层**: schema({{X}}) → API({{Y}}) → logic({{Z}}) → tests
- **Test 1.1**: `{{test_name}}` (RED → GREEN)
- **独立 demo**: {{如何独立验证}}

### Cycle 2-{{N}}: ...
（cycle 2 测什么，**根据 cycle 1 实际行为决定**，不预设）

### Anti-horizontal 警告

- ❌ WRONG: 先写 test_login_correct / test_login_wrong / test_login_unknown / test_login_concurrent，再写所有 impl
- ✅ RIGHT: Cycle 1 完整（test→impl），观察实际行为，再决定 Cycle 2
- **Never refactor while RED**：所有 cycle GREEN 后才能 refactor

### 4 步 workflow（每 cycle）

```
1. Planning      —— 找下一个最高价值的 vertical slice
2. Tracer Bullet —— 写最小 test 贯穿所有层
3. Incremental Loop —— RED→GREEN→RED→GREEN
4. Refactor      —— 全 GREEN 后再重构（**Never refactor while RED**）
```

---

## 3. 测试范围（补充 vertical cycle）

### Property（金融 / 数学不变量必跑）

{{PROPERTY_TESTS}}

### Performance（性能敏感时）

{{PERFORMANCE_TESTS}}

### Integration（必跑，IO/DB/外部 API）

{{INTEGRATION_TESTS}}

---

## 4. 不需要测试的（声明 + 理由）

{{SKIP_TEST_SECTIONS}}

---

## 5. 测试 fixture / mock 策略

{{FIXTURES_STRATEGY}}

### Mock 反模式（避免）

- ❌ mock DB connection（应集成测真实 DB）
- ❌ mock 全部依赖（测的是 mock 不是代码）
- ✅ mock 外部 API（rate limit / timeout）
- ✅ mock 时间（freezegun）

---

## 6. 覆盖率要求

| 范围 | 要求 |
|---|---|
| 高危代码 | 100% |
| 总体 | ≥ {{COVERAGE_TARGET}}% |
| 新增代码 | ≥ 90% |

---

## 7. Phase 5 验收（test-runner subagent 必跑）

- [ ] 每个 vertical cycle 的 test 都 PASS（不止单元通过，是 cycle 完整贯通）
- [ ] 跑 property tests（如有）：{{PROPERTY_CMD}}
- [ ] 跑 integration tests：{{INTEGRATION_CMD}}
- [ ] 跑 performance benchmarks（如有）
- [ ] 生成覆盖率报告：{{COVERAGE_CMD}}
- [ ] 输出 test-result.md（PASS/FAIL per cycle + per category）

**失败处理**：
- vertical cycle RED → Phase 5 block，回 Phase 4 修复（不允许跳 cycle）
- property 失败 → Phase 5 block
- integration 失败 → 同上
- performance 超阈值 → warn（除非 spec 标 critical）
- 覆盖率不达 → warn（除非 spec 标 critical）

---

## 8. 与 design.md 的关系

test-plan.md 是 design.md 的**验证维度**。design 决定"做什么"，test-plan 决定"怎么证明做对了"。

任何 design 变更（用户改主意）必须同步更新 test-plan.md，**且重排 vertical cycles**。

