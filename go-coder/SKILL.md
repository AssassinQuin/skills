---
name: go-coder
description: Go 项目编码编排层。根据任务类型路由到对应 skill，并在委托前加载 Go 专项上下文（gopls 策略、编辑陷阱、验证循环）。触发词：写代码、实现、重构、修复、修改、go coder、Go 编码、Go 项目。当用户在 Go 项目中要求修改代码时默认激活。
---

# Go Coder — 编排层

## DO NOT trigger

| 条件 | 行为 |
|------|------|
| 非 Go 项目（无 go.mod 且目标文件非 .go） | 退出，使用通用编码能力 |
| 纯文档任务（写规范文档、README、变更日志） | 退出，使用文档 skill 或通用文本能力 |
| 非 coding 任务（分析数据、翻译、做计划） | 退出，使用通用能力 |
| 用户明确说"不用 Go 相关工具" | 尊重意图，降级到 grep/Read 模式 |

## 前置条件检查

激活后、执行任何 Go 操作前必须完成：

**检查 1: go.mod 存在性**
- `ls go.mod` 或 `find . -name go.mod -maxdepth 3`
- 不存在 → 向用户确认是否在 Go 项目中工作，否认则退出

**检查 2: gopls MCP 可用性**
- 尝试调用 `go_workspace`（轻量操作）
- 不可用 → 降级模式：所有 gopls 操作回退到 grep/Read，在输出中提示

## 定位

本 skill 是 Go 项目的编码入口路由器。不嵌入通用方法论，只负责：

1. **意图识别** → 路由到正确执行路径
2. **上下文注入** → 委托前加载 references/ 中的 Go 专项知识
3. **验证门控** → 确保每次改动通过 Go 验证链

| 本 skill 提供（Go 专项） | 委托给其他 skill |
|--------------------------|-----------------|
| gopls MCP 工具选择策略 | tdd — 测试驱动开发流程 |
| Go tab 缩进编辑陷阱 | simplify — 行为不变简化 |
| Go 构建验证循环 | code-review — diff 审查 |
| Go 项目文件归属决策 | unit-testing-best-practices — 测试设计 |
| Go 语义感知的重构方法论 | diagnose — bug 诊断循环 |

## 任务路由表

| 用户意图 | 执行路径 | 加载 references |
|----------|----------|-----------------|
| 重构/重组/重命名 | **本 skill 主导** → 阶段式重构流程 | gopls-strategy, editing-traps, verification-loop |
| 优化/简化 | **simplify** + 本 skill 验证门控 | verification-loop |
| 新功能 | **tdd** + 本 skill gopls 导航 | gopls-strategy |
| 写测试/设计测试 | **unit-testing-best-practices** | gopls-strategy |
| 修 bug | **diagnose** + 本 skill gopls 导航 | gopls-strategy, verification-loop |
| 审查代码 | **code-review** | verification-loop |
| 混合意图 | 先完成 Go 专项部分，再委托对应 skill | 按需加载 |
| 意图不明确 | 列出最多 3 条可能路径让用户选择 | - |

### 路由失败恢复

| 失败场景 | 恢复策略 |
|----------|----------|
| 目标 skill 未安装 | 回退通用编码模式 + 提示建议安装 |
| 多个 skill 可能匹配 | 列出候选 + 适用场景，请用户选择 |
| 委托后 skill 执行失败 | 回到本 skill 继续 Go 专项部分，不中止整体任务 |

## 委托协议

委托给其他 skill 前，执行三步注入：

```
1. Pre:  运行 gopls 命令收集 Go 语义上下文
2. Inject: 在调用 prompt 中注入收集到的 Go 上下文参数
3. Post: 运行验证链确认改动未破坏编译
```

### 注入参数表

| 委托目标 | Pre（调用前） | Inject（注入上下文） | Post（调用后验证） |
|----------|--------------|---------------------|-------------------|
| `/simplify` | `go_symbol_references({symbol})` 获取引用数 N | "引用数 {N}，验证链 diagnostics→build→test，Go 文件用 sed 不用 Edit" | `go_diagnostics` → `go build` → `go test` |
| `/tdd` | `go_package_api({pkg})` 提取函数签名；`go_search({keyword})` 检查已有实现 | "目标 API {签名列表}，Go 测试用 table-driven + gtest + testify，tab 文件用 sed" | `go_diagnostics` → `go build` → `go test -run Test{New}` |
| `/unit-testing-best-practices` | `go_package_api({pkg})` 提取被测签名；`Read` 实现理解分支 | "被测签名 {列表}，Go mock 用 mockey，断言用 testify，测试文件同目录 {name}_test.go" | `go test -v -run Test{Target}` |
| `/diagnose` | `go_search({error})` + `go_symbol_references({suspect})` 追踪调用链 | "错误 {msg}，调用链 {列表}，最小复现 go test -run {Case}，检查 ctx 传递" | `go test -run Test{ReproCase}` |
| `/code-review` | `git diff --stat` 获取改动文件；`go_diagnostics` 确认编译 | "改动文件 {列表}，Go 检查：① gerror.NewCode+i18n ② decimal 精度 ③ ctx 传递 ④ 显式 Transaction" | `go_diagnostics` → `go vet` |

## 通用执行骨架

所有任务类型共用 6 步流程。**步骤 2 必须等用户确认后才可执行。中/高风险改动必须经过步骤 2.5 保护测试。**

| 步骤 | 做什么 | 输出物 | 验证门 |
|------|--------|--------|--------|
| **1. 理解** | gopls 导航：搞清楚改什么、影响谁 | 改动清单 + 影响范围 + 风险评级 | 清单条目 > 0 |
| **2. 方案** | 告诉用户要改什么、为什么、风险等级 | diff 预览 + 改动说明 + 风险评级 + 保护测试计划 | **用户确认** |
| **2.5 保护测试** | 中/高风险改动先写测试锁定当前行为 | table-driven 测试文件 + 测试全部 PASS | `go test` 全绿 |
| **3. 执行** | 分步改动，每步验证 | 逐步改动结果 | 每步 `go_diagnostics` 零错误 |
| **4. 验证** | build + test + vet（含保护测试回归） | 通过/失败 + 失败归因 | `go build` 通过 + 保护测试全绿 |
| **5. 汇报** | 改了什么、为什么、验证结果 | 文件列表 + 每文件改动摘要 + 验证结果 | 包含文件列表 |

### 步骤 1：理解（只读，gopls 导航）

加载 `gopls-strategy.md`，根据任务类型收集语义上下文：

| 任务类型 | gopls 操作 | 必须回答的问题 |
|----------|-----------|---------------|
| 重构 | `go_package_api` + `go_symbol_references` + `Read` | 改什么？引用数多少？风险等级？ |
| 新需求 | `go_package_api` + `go_search` + `go_file_context` | 目标包 API？已有相关实现？依赖关系？ |
| Bug 修复 | `go_search` + `go_symbol_references` + `Read` | 错误位置？调用链？根因假设？ |
| 简化 | `go_symbol_references` + `Read` | 行为是什么？引用数？哪些可简化？ |
| 审查 | `git diff --stat` + `go_diagnostics` | 改了哪些文件？编译状态？ |

### 步骤 2：方案（**必须用户确认**）

展示方案，等用户确认后才执行。方案必须包含：

```
1. 改动范围：涉及哪些包/文件/函数
2. 改动内容：每个文件要做什么（新增/修改/删除/重命名）
3. 风险评级：零/低/中/高 + 理由（见下方判定表）
4. 验证计划：用哪些命令验证
5. 保护测试计划（中/高风险时）：锁定哪些行为、测试文件路径、用例数量
```

**风险评级判定条件**（满足任一即升级）：

| 风险等级 | 触发条件 |
|----------|----------|
| **高** | 金额计算逻辑（decimal 运算、奖励/扣费/汇率转换）、并发安全改动（锁/共享状态变更）、公开 API 签名变更（函数参数/返回值/接口方法变化） |
| **中** | 流程重组（改变业务执行顺序/条件分支/错误处理路径）、跨包移动、数据库/事务相关改动（DAO/SQL/事务边界变更） |
| **低** | 同包内重命名/拆分/删除、新增纯内部函数、修改日志/错误消息文本 |
| **零** | 纯文档/注释、配置文件格式调整（非逻辑变更）、代码格式化（无行为变化） |

### 步骤 2.5：保护测试（中/高风险改动必须执行）

**跳过条件**：风险评级为零/低时明确标注"跳过步骤 2.5（{风险等级}，理由：{描述}）"，直接进入步骤 3。

**执行流程**：

```
2.5a. 识别关键行为锚点
     - 从步骤 2 方案中提取：将被改动影响的所有公开函数/方法
     - 对每个锚点，列出当前的输入-输出映射（用 Read + gopls 理解）
     - 至少覆盖：正常路径 + 边界值 + 错误路径

2.5b. 编写 table-driven 保护测试
     - 文件：{目标文件同目录}/{name}_guard_test.go
     - 命名：Test{FuncName}Guard
     - 结构：table-driven，每个 case 标注"当前行为快照"
     - 目的：锁定改动前的行为，确保改动后行为一致

2.5c. 确认测试通过
     - 运行 go test -run Test{FuncName}Guard -v
     - 全部 PASS → 保护网建立完成，记录用例数
     - 有失败 → 修正测试（测试应反映当前真实行为，非期望行为）
```

**保护测试模板**：

```go
// {name}_guard_test.go — 步骤 2.5 保护测试，锁定改动前行为
func Test{FuncName}Guard(t *testing.T) {
    tests := []struct {
        name     string
        input    {InputType}
        want     {OutputType}
        wantErr  bool
    }{
        // 当前行为快照 — 改动前确认全绿
        {name: "正常路径", input: ..., want: ..., wantErr: false},
        {name: "边界值-zero", input: ..., want: ..., wantErr: false},
        {name: "错误路径", input: ..., want: ..., wantErr: true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := {FuncName}(tt.input...)
            if (err != nil) != tt.wantErr {
                t.Errorf("{FuncName}() error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("{FuncName}() = %v, want %v", got, tt.want)
            }
        })
    }
}
```

**无法写测试的 Fallback**：

| 场景 | 处理方式 |
|------|----------|
| 被改符号未导出（小写开头）且无测试入口 | 标注 [未保护]，建议用户审查 |
| 依赖外部服务（DB、MQ）无法在测试中启动 | 用 mockey mock 外部依赖，或标注 [未保护-外部依赖] |
| 涉及 `init()` 注册逻辑 | 写集成级测试验证注册后状态，或标注 [未保护-注册逻辑] |
| 改动超过 10 个函数 | 按调用链分组，每组独立保护测试 |

**步骤 2.5 输出物**：
- 保护测试文件路径
- 用例数量
- 测试运行结果（全绿确认）

### 步骤 3：执行（分步，每步验证）

根据任务类型走差异化子流程。**每步执行后运行 `go_diagnostics`，失败则停止。**

**执行完毕后必须重跑保护测试**：`go test -run Test{FuncName}Guard -v`，确认所有保护用例仍 PASS。如有失败，立即回退该步骤改动并分析差异。

#### 重构子流程

加载 `editing-traps.md`，按风险从低到高排序执行：

| 风险 | 操作 | 验证 |
|------|------|------|
| 零 | 删除零引用标识符 | `go_diagnostics` |
| 低 | 同包文件拆分/合并/重命名 | `go build` |
| 中 | 跨包移动 | `go build` + 改 import |
| 高 | 公开 API 签名变更 | `go build` + `go test`（含保护测试） |

#### 新需求子流程

委托 `/tdd`，注入 Go 上下文（见注入参数表）后执行 TDD 循环：
- 每个功能点：写测试 → 实现 → `go test -run` 验证 → 下一个

#### Bug 修复子流程

委托 `/diagnose`，注入 Go 上下文后执行：
- 定位根因 → 最小修复 → 添加回归测试 → `go test -run` 验证

#### 简化子流程

委托 `/simplify`，注入引用安全上下文后执行：
- 逐个简化点 → 每个简化后行为对比 → `go_diagnostics` 验证

#### 审查子流程

委托 `/code-review`，注入 Go 检查清单后执行：
- 逐文件审查 → 汇总发现 → `go_diagnostics` + `go vet`

### 步骤 4：验证

加载 `verification-loop.md`，执行完整验证链：

```
go_diagnostics → go build ./... → go test ./... → go vet ./...
```

**保护测试回归验证**（步骤 2.5 产出的测试）：
- `go test -run "Guard$" -v` 确认所有保护用例仍全绿
- 保护测试失败 → 标记为行为变更，需向用户确认是否为预期变更

测试失败时：
1. `git log --oneline -5 -- path/to/test.go` 检查是否预存问题
2. 预存问题 → 标注并继续
3. 新引入失败 → 回退到步骤 3，修复后重新验证

### 步骤 5：汇报

向用户汇报，必须包含：

```
## 改动摘要
- 改动文件：{N} 个
- 改动类型：{重构/新增/修复/简化}
- 风险等级：{最高风险等级}

## 保护测试结果（步骤 2.5）
- 保护测试文件：{path}（或"跳过：零风险"）
- 用例总数：{N}
- 回归结果：全部 PASS / {M} PASS {K} FAIL（需确认）

## 文件列表
- path/to/file.go: {改动描述}
- ...

## 验证结果
- go build: ✅ / ❌
- go test:  ✅ {M passed} / ❌ {N failed}（预存 {X}）
- go vet:   ✅ / ❌
```

## 输出保障

执行过程中每次输出包含：

1. **当前步骤**：理解 / 方案 / 保护测试 / 执行 / 验证 / 汇报
2. **已委托的 skill**：无 / {skill 名}
3. **Go 模式**：gopls 正常 / 降级
4. **风险等级**：零 / 低 / 中 / 高

## References 文件清单

| 文件 | 内容 | 加载时机 |
|------|------|----------|
| `references/gopls-strategy.md` | 工具优先级表 + rename 实战 + 批量替换命令 | 涉及符号查找/重命名/包理解时 |
| `references/editing-traps.md` | tab 缩进陷阱 + 批量替换 + 文件归属决策 | 涉及 Edit/Write 操作时 |
| `references/verification-loop.md` | diagnostics→build→test→vet 循环 + 预存失败识别 | 每次改动后 |
| `references/go-conventions.md` | 常量组织模式 + 架构分层 + 代码模式 | 涉及新增/重组代码时 |
