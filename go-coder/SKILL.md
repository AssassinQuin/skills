---
name: go-coder
description: Go 项目编码编排层。根据任务类型路由到对应 skill，并在委托前加载 Go 专项上下文（gopls 策略、编辑陷阱、验证循环）。触发词：写代码、实现、重构、修复、go coder、Go 编码、Go 项目。当用户在 Go 项目中要求修改代码时默认激活。
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

## 阶段式重构流程（本 skill 主导路径）

当任务涉及结构性改动（重命名、文件拆分、常量重组、包迁移），加载全部 references 后按以下阶段执行：

### Phase 1: 理解现状（只读）

- `go_package_api({pkg})` → 提取公开函数签名列表
- `go_search` + `go_symbol_references` → 符号定位 + 引用计数（决定删除/重命名风险）
- `Read` → 仅读需要 Edit 的文件

**输出**：改动清单 + 引用计数 + 风险评级（零/低/中/高）。

### Phase 2: 按风险排序执行

| 风险 | 操作 | 验证 |
|------|------|------|
| 零 | 删除零引用标识符（`go_symbol_references` 确认后） | `go_diagnostics` |
| 低 | 同包文件拆分/合并 | `go build` |
| 低 | 重命名（sed 批量，见 editing-traps.md） | `go_diagnostics` |
| 中 | 跨包移动 | `go build` + 改 import |
| 高 | 公开 API 签名变更 | `go build` + `go test` |

**原则**：每步独立验证，高风险单独做，不与低风险混合。

### Phase 3: 最终验证

执行 `verification-loop.md` 中的完整验证链。

## 输出保障

每次输出必须包含：

1. **当前阶段**：前置检查 / 理解现状 / 执行改动 / 最终验证
2. **已委托的 skill**：已激活了哪些子 skill（无则为"无委托"）
3. **Go 模式**：gopls 正常 / 降级，涉及的包/文件，验证状态

## References 文件清单

| 文件 | 内容 | 加载时机 |
|------|------|----------|
| `references/gopls-strategy.md` | 工具优先级表 + rename 实战 + 批量替换命令 | 涉及符号查找/重命名/包理解时 |
| `references/editing-traps.md` | tab 缩进陷阱 + 批量替换 + 文件归属决策 | 涉及 Edit/Write 操作时 |
| `references/verification-loop.md` | diagnostics→build→test→vet 循环 + 预存失败识别 | 每次改动后 |
| `references/go-conventions.md` | 常量组织模式 + 架构分层 + 代码模式 | 涉及新增/重组代码时 |
