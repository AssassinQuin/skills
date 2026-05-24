---
name: unit-testing-best-practices
description: Khorikov 单元测试核心原则（Go 专项），四支柱+测试象限+Mock策略+可测性架构。用于设计和审查测试用例。
---

# Unit Testing Best Practices (Khorikov / Go)

基于 Vladimir Khorikov《Unit Testing: Principles, Practices, and Patterns》核心提炼，Go 示例贯穿。

## 触发条件

用户请求包含以下意图时加载本 skill：
- 写测试 / 设计测试 / 单元测试 / test / unit test
- 审查测试 / test review / 测试质量
- 测试覆盖率 / edge case / 边界条件
- mock / 打桩 / stub

## 1. 目标：可持续增长

测试存在的目标是**使项目能够可持续增长**，不是覆盖率、不是检查清单。

陷阱：90% 覆盖率仍可能有——每次重构都挂的误报、漏掉真 bug 的漏报、跑太慢没人愿意跑、没人看得懂。

## 2. 四支柱评估每个测试

| 支柱 | 含义 | 优先级 |
|------|------|--------|
| 回归保护 | 代码变更时能捕获 bug | 必须 |
| **重构抗性** | **内部实现变更时不会误报** | **最重要** |
| 快速反馈 | 执行速度快 | 必须 |
| 可维护性 | 易读易改 | 必须 |

**重构抗性为何最重要**：误报泛滥 → 团队习惯性忽略测试失败 → 测试套件废弃（狼来了效应）。

**误报根源**：测试耦合了实现细节。验证的是代码**怎么做**而非**做什么**。

## 3. 可观测行为 vs 实现细节

- **可观测行为** = 帮助调用方达成目标的操作或状态
- **其他一切都是实现细节**

### 单元 = 行为单元，不是代码单元

> 正确："我叫狗的时候，它过来。"
> 错误："我叫狗的时候，它先动左前腿，再动右腿……"

### Go 示例

```go
// BAD: 测试算法（实现细节）
func TestCalculateDiscount_UsesCorrectFormula(t *testing.T) {
    rate := customer.discountRate()  // 暴露内部方法
    assert.Equal(t, 0.1, rate)       // 测试实现
}

// GOOD: 测试结果（可观测行为）
func TestCalculateDiscount_GoldCustomer(t *testing.T) {
    customer := Customer{TotalPurchases: 1000}
    discount := customer.CalculateDiscount(100.0)
    assert.Equal(t, 10.0, discount)
}
```

## 4. 三种测试风格（质量递减）

| 风格 | 方式 | 质量 | Go 模式 |
|------|------|------|---------|
| **输出型** | 输入→检查返回值 | 最高 | 纯函数 `result := Fn(input)` |
| 状态型 | 操作后检查状态 | 可接受 | `obj.Do(); assert(obj.Field)` |
| 通信型 | 验证与协作者的交互 | 避免 | `mock.AssertCalled("Method")` |

**优先输出型**：不耦合内部状态，不耦合协作者交互。将副作用推到边界。

## 5. 测试象限（测什么不测什么）

```
                    少协作者           多协作者
                    ─────────         ─────────
高复杂度或          领域/算法          过度复杂
领域意义            → 单元测试         → 重构！

低复杂度            平凡代码           控制器
                    → 不测试           → 集成测试
```

**关键**：高复杂度 OR 领域意义，满足其一就值得单元测试。

## 6. Mock 策略

### 何时可以 Mock：外部边界

只 mock **跨系统通信**——与外部世界的交互：
- 外部 API、邮件网关、支付处理器、消息队列
- 这是系统整体的可观测行为

### 何时 Mock 是坏味道：内部协作者

需要 mock **系统内通信** = 设计问题。

> "与其想办法测试一大堆互相纠缠的类，不如一开始就不要有这样的纠缠。"

**修复方法：重构设计**，而不是加更多 mock。

### Go 示例

```go
// OK: mock 外部邮件服务（跨系统通信）
func TestOrderProcessor_SendsConfirmationEmail(t *testing.T) {
    mockGateway := &SpyEmailGateway{}
    processor := OrderProcessor{EmailGateway: mockGateway}
    processor.CompleteOrder(order)
    assert.True(t, mockGateway.SendCalled)
}

// SMELL: mock 内部 repository（设计味道）
// → 说明领域逻辑太耦合基础设施

// BETTER: 重构使领域逻辑不需要 repository
func TestCalculateOrderTotal(t *testing.T) {
    order := Order{Items: []Item{{Price: 10}, {Price: 20}}}
    total := order.CalculateTotal()  // 纯函数
    assert.Equal(t, 30.0, total)
}
```

## 7. 可测性架构

```
┌─────────────────────────────────┐
│     Application Service         │  ← 集成测试
│     (控制器/编排器)              │
├─────────────────────────────────┤
│         Domain Layer            │  ← 单元测试
│     (业务逻辑、算法)             │
├─────────────────────────────────┤
│       Infrastructure            │
│   (DB, API, 文件系统等)          │
└─────────────────────────────────┘
```

### Humble Object 模式

当代码既有高复杂度又有多协作者（过度复杂象限），拆分：
- **深代码**：复杂逻辑、少/无协作者 → 单元测试
- **宽代码**：简单编排、多协作者 → 集成测试

> "代码深度 vs 代码宽度——永远不要两者兼有。"

## 8. 两阶段工作流

### 开发阶段（TDD）
测试引导设计。此时可以写所有测试，有些是"脚手架"。

### 提交前（Khorikov 再平衡）

| 象限 | TDD 产出 | Khorikov 操作 |
|------|----------|---------------|
| 平凡代码 | 单元测试 | **删除** |
| 领域/算法 | 单元测试 | **保留** |
| 控制器 | 单元测试 | **替换为集成测试** |

TDD 阶段有价值的测试（帮你思考设计），在 CI 中可能有害（每次重构都挂、测试实现细节）。

## 9. 覆盖率

覆盖率是**负向指标**，不是正向指标。

- < 60%：肯定有问题
- 高覆盖率：不代表任何事
- 永远不要把覆盖率当目标

> 高覆盖率 + 低质量测试 < 中等覆盖率 + 高质量测试

## 10. 测试设计检查清单

写测试前过检：

| 检查项 | 标准 |
|--------|------|
| 测试可观测行为？ | 验证结果，不验证算法 |
| 可追溯到业务需求？ | 不能追溯 → 删 |
| 一个测试一个行为？ | 只有一个逻辑断言 |
| 不依赖其他测试？ | 正交、独立、任意顺序可运行 |
| Mock 只在外部边界？ | 内部 mock = 设计味道 |
| 属于正确象限？ | 领域逻辑单元测试，控制器集成测试 |
| 命名清晰（S/S/R）？ | Subject_Scenario_ExpectedResult |

## Go Table-Driven 模式（推荐）

对于领域逻辑，优先使用 table-driven 测试覆盖边界条件：

```go
func TestCalculateDiscount(t *testing.T) {
    tests := []struct {
        name     string
        userType CustomerType
        amount   float64
        want     float64
    }{
        {"gold customer gets 10%", CustomerTypeGold, 100.0, 10.0},
        {"silver customer gets 5%", CustomerTypeSilver, 100.0, 5.0},
        {"regular customer gets nothing", CustomerTypeRegular, 100.0, 0.0},
        {"zero amount", CustomerTypeGold, 0.0, 0.0},
        {"negative amount", CustomerTypeGold, -100.0, 0.0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            u := User{Type: tt.userType}
            assert.Equal(t, tt.want, u.CalculateDiscount(tt.amount))
        })
    }
}
```

## 应用到本项目（Go + mockey + gtest + testify）

| 场景 | 策略 |
|------|------|
| 纯计算逻辑（价格计算、金额转换） | table-driven 输出型测试 |
| DAO 层（数据库操作） | 集成测试，打真库，不打 mock |
| 外部 API 调用 | mockey 打桩 mock |
| 内部 service 调用 | 重构使逻辑解耦，或用 mockey `Mock` 方法级打桩 |
| 编排器（Award 主流程） | 集成测试，验证组件串联 |

---

*基于 Khorikov, Vladimir. "Unit Testing: Principles, Practices, and Patterns." Manning, 2020. Go 示例来自 binaryphile.com 提炼。*
