## R1 — 2026-06-04
- **策略**：S4（上下文优化）+ S3（边界增强）+ S1（指令精化）
- **为什么改**：SKILL.md 混入了 Go 经验知识（gopls 策略、tab 陷阱、验证循环），应该拆到 references/；委托接口缺少注入参数；缺少边界处理
- **改了什么**：
  1. Go 经验知识拆到 4 个 references 文件（gopls-strategy/editing-traps/verification-loop/go-conventions）
  2. 委托协议升级为 Pre/Inject/Post 三步注入表，每个委托目标有具体 gopls 命令和参数模板
  3. 新增 DO NOT trigger 区 + 前置条件检查（go.mod + gopls 可用性）
- **痛点解决**：PP-1→resolved, PP-2→resolved, PP-3→resolved
- **结果**：评分 5.5 → 7.9（Δ +2.4），T_train 4/4 Pass，T_val 3/3 Pass（100%）
- **遗留**：4 条 WARN（allowed-tools 字段、Phase 2 停止条件、触发词扩展、占位符推导）

## R2 — 2026-06-04
- **策略**：S2（工作流重组）+ S1（指令精化）
- **为什么改**：只有重构有执行骨架，其他任务类型靠"委托给 skill"就完了，缺少通用执行闭环，用户不知道改动是否准确
- **改了什么**：
  1. 新增通用 5 步执行骨架（理解→方案→执行→验证→汇报），所有任务类型共用
  2. 步骤 2（方案）必须用户确认后才执行，解决"用户如何知道改动准确"
  3. 每种任务类型在步骤 3 有差异化子流程（重构/新需求/Bug修复/简化/审查）
  4. 步骤 5（汇报）定义了结构化摘要格式
- **痛点解决**：PP-4→resolved
- **结果**：SKILL.md 129→206 行（+60%），新增完整执行闭环

## R3 — 2026-06-04
- **策略**：S2（工作流重组）
- **为什么改**：用户反馈"每次有风险的重构、修改，都应先创建单元测试"，当前 SKILL.md 重构子流程直接改代码，中/高风险改动无测试保护网
- **改了什么**：
  1. 5步→6步骨架，插入步骤 2.5 保护测试（中/高风险必须执行）
  2. 风险评级从模糊建议升级为 4 级枚举式判定表（高=金额/并发/API签名，中=流程重组/跨包/DB）
  3. 步骤 2.5 含完整 table-driven 测试模板 + 4 种 Fallback + 兜底用户确认门控
- **痛点解决**：PP-5→resolved
- **结果**：评分 7.9 → 9.0（Δ +1.1），T_train 4/4 Pass，T_val 3/3 Pass（100%），审计 8/10 PASS
- **遗留**：保护测试模板未覆盖 service 接口 + init() mock 场景（WARN）

## R4 — 2026-06-04
- **策略**：S0（session 经验）+ S1（指令精化→铁律）+ S2（流程重组→快速路径）+ S4（上下文优化→规则内联）
- **为什么改**：本次"删除体验消费"任务暴露 5 个结构性问题：Edit 对 tab 文件失败导致 sed 链条（PP-6）、Read 5 文件 40KB 进上下文（PP-7）、gopls MCP 零调用（PP-8）、references 从不加载（PP-9）、6 步流程简单任务也一刀切（PP-10）
- **改了什么**：
  1. 新增「Go 编辑铁律」3 条：**铁律1** Go 文件禁用 Edit，改用 Write/sed；**铁律2** 步骤 1 必须用 gopls 不是 grep；**铁律3** Read 按需（全文=Write，片段=offset+limit，分析=ctx_execute_file）
  2. 新增「任务复杂度分级」：简单（删除/注释→快速路径 4 步跳过方案和测试）、标准、复杂（含保护测试）
  3. References 加载从"按需"改为"必须"：步骤 1 强制加载 gopls-strategy，步骤 3 强制加载 editing-traps，步骤 4 强制加载 verification-loop
  4. 步骤 3 执行模式优化：先完成所有文件改动，再一次性验证（不再每文件验证一次）
- **痛点解决**：PP-6→addressed, PP-7→addressed, PP-8→addressed, PP-9→addressed, PP-10→addressed
- **结果**：SKILL.md 减少表意符号（风险评级从 4 级改为 3 级与复杂度对齐），关键规则内联到正文（铁律不可跳过）
- **遗留**：待下一次实际部署验证铁律是否有效

## R5 — 2026-06-05 (迁移：go-coder → coder)

- **策略**：架构升级 — 单语言 → 多语言路由器
- **为什么改**：用户要求将 go-coder 升级为通用 coder skill，支持多语言（Go + Python），语言特定知识存 references/，可扩展
- **改了什么**：
  1. 目录从 `go-coder/` 重命名为 `coder/`
  2. Go references 文件加 `go-` 前缀（gopls-strategy → go-gopls-strategy 等）
  3. 新增 4 个 Python references：python-tooling, python-editing-rules, python-verification-loop, python-conventions
  4. SKILL.md 重写为多语言路由器：语言检测表 + 动态 references 加载 + 按语言的注入参数表
  5. 保留 6 步执行骨架、复杂度分级、保护测试、委托协议等核心架构
- **Go 知识保留**：全部 4 个 Go references 内容不变，仅文件名加前缀
- **Python 工具链**：ruff (lint+format) + pytest (测试) + pyright (类型检查) + uv (包管理)
- **可扩展性**：新增语言只需添加 references/{lang}-*.md 文件 + 在 SKILL.md 语言检测表增加一行