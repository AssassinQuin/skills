---
name: programmer
description: >
  全流程编程执行引擎。当用户提出开发需求、功能需求、bug修复、功能增强时触发。
  自动执行：项目记忆检索与整理 → 代码考古 → 可选外部调研 → 任务拆解 →
  分批并行实现 → 规范校验 → 记忆更新。
  触发词：「开发」「实现」「新增功能」「加一个」「修复」「改一下」「refactor」
  「feature」「fix」「需求」「帮我做」「add feature」「implement」「build」。
  不触发：纯问答、解释、分析、调研等非编码类请求。
---

# Programmer — 全流程编程执行引擎

## 概览

```
Phase R: 会话恢复 → 审计已完成任务 → 进度定位 → 上下文加载
Phase 0 (条件): 首次使用 → 记忆整理
Phase 1: 记忆检索 + 代码考古 + [调研] → requirements.md + overview.md → 🔒用户确认需求 → Git 创建功能分支
Phase 2: @oracle 任务拆解 → task-plan.md → 🔒用户确认计划
Phase 3: 智能调度(≤3子进程) → 在功能分支上代码变更 → 按任务粒度 commit
Phase 4: 测试审计 → test-report.md → 🔒用户确认测试报告 → 记忆更新 → 🔒用户确认 → Git 合并回主分支
```

**语言：面向用户一律中文。task-plan.md 是任务状态唯一真相源。**

---

## 治理模型：4 文档审查制

AI 全程自主编码，人类通过审查 4 个文档把控质量，**不看代码**。每个文档生成后🔒暂停等用户确认。

| # | 文档/操作 | 阶段 | 确认点 |
|---|----------|------|--------|
| 1 | `requirements.md` 需求文档 | Phase 1 | 🔒 Phase 1 末尾 |
| 2 | `task-plan.md` 计划文档 | Phase 2 | 🔒 Phase 2.2 |
| 3 | Phase R.2 审计报告 | Phase R | 恢复时展示 |
| 4 | `test-report.md` 测试报告 | Phase 4 | 🔒 Phase 4.2 |
| 5 | Git 分支合并 | Phase 4.7 | 🔒 Phase 4.6 确认后执行 |

**铁律**：🔒未确认 = 不进入下一 Phase。文档修改后必须重新确认。

---

## Agent 职责矩阵

| Agent | 触发阶段 |
|-------|---------|
| **@explorer** 代码搜索/考古 | Phase 1.2, R.2, 4.1 |
| **@librarian** 外部调研（条件触发） | Phase 1.3, Phase 3 |
| **@fixer** 代码实现/测试 | Phase 3 |
| **@oracle** 分析/评审/重构 | Phase 2.1, Phase 3 重构 |
| **@designer** UI/样式 | Phase 3 UI 任务 |
| **主进程** 计划文档/记忆操作 | Phase 1.1/1.4/2.2/4 |

**约束**：≤3子进程并行 | 同类agent≤2 | @oracle串行 | 有依赖→同一agent

---

## Git 分支管理

> 当项目根目录存在 `.git` 时，开发流程自动集成 git 分支管理，所有代码变更在功能分支上进行。

### 分支策略

| 时机 | Git 操作 | 工具 |
|------|---------|------|
| Phase 1.7 需求确认后 | 创建功能分支 | `github_create_branch` 或 `git checkout -b` |
| Phase 3 每个子任务完成 | 提交变更 | `github_push_files` 或 `git add + commit` |
| Phase 4.7 最终确认后 | 合并回主分支 | `github_create_pull_request` 或 `git merge` |

### 分支命名规则

```
{类型}/{YYYYMMDD}-{需求简述}

类型: feat(新功能) | fix(修复) | refactor(重构)
示例: feat/20260428-card-winrate-analysis
      fix/20260428-powerlog-encoding
      refactor/20260428-card-data-api
```

### 优先使用 GitHub MCP 工具

所有 git 操作**优先使用 GitHub MCP 工具**（适用于远程仓库），本地 git 命令作为回退：

| 操作 | GitHub MCP 工具 | 本地回退 |
|------|----------------|---------|
| 创建分支 | `github_create_branch` | `git checkout -b {branch}` |
| 推送文件 | `github_push_files` | `git add + git commit + git push` |
| 创建 PR | `github_create_pull_request` | — |
| 合并 PR | `github_merge_pull_request` | `git merge --no-ff {branch}` |
| 查看分支 | `github_list_branches` | `git branch` |
| 查看差异 | `github_pull_request_read(get_diff)` | `git diff main...HEAD` |

**降级条件**：GitHub MCP 不可用（无 remote / 无权限 / 非 GitHub 仓库）→ 使用本地 git 命令。

### Commit 规范

Phase 3 中每个子任务（T1, T2, ...）完成后独立提交：

```
{type}({scope}): {简述}

type: feat | fix | refactor | test | docs
scope: 受影响的模块/文件名
示例: feat(analysis): add winrate trend calculation
      fix(parser): fix Power.log encoding error
```

### 非 Git 项目

项目无 `.git` → 跳过所有 git 操作，不影响主流程。Phase 1.7 和 Phase 4.7 自动跳过。

---

## Phase R: 会话恢复

检查 `docs/dev-*/session-state.md` 是否存在且未完成。

**恢复三步**：验证 → 定位 → 加载，确保从真实进度继续。

### R.2 任务审计（@explorer）

触发：未完成会话 + ≥1 已完成任务。

**@explorer 指令**：
```
项目根目录: {project_root}
开发文档: {dev_doc_dir}

请阅读 task-plan.md，对所有标记为 ✅ 已完成的任务逐一验证：
1. 读取任务描述中的「涉及文件」和「改动描述」
2. 检查对应文件是否存在
3. 检查文件内容是否包含任务描述中的改动（函数/类/逻辑是否存在）
4. 如有测试文件，检查测试是否覆盖了该任务的改动

输出: ## 任务审计报告 → | 任务 | 声明 | 审计 | 缺失项 | 摘要表格
```
每个任务 ≤30s，只做表面验证。

### R.3 进度定位

基于审计生成进度报告：✅已确认 / ⚠️部分完成 / ❌未完成 / 🔵当前断点 / ⬜待执行。

自动修正 task-plan：⚠️→`🔄部分完成` | ❌→`⬜待执行`，追加变更记录。

### R.4 上下文加载

| 加载项 | 来源 |
|--------|------|
| 项目规范 | `memory_search(tags=["project"])` |
| 全局偏好 | `memory_search(tags=["global"])`（独立展示，不与项目合并） |
| 质量洞察 | `memory_search(query="{项目名} 洞察", tags=["project", "context"])` |
| overview.md + task-plan.md | docs/dev-*/ |
| Git 分支信息 | session-state.md 中的分支名 + `git branch --show-current` 验证 |

展示进度报告 + 异常任务 + **当前分支状态**（是否仍在功能分支上） → 询问用户从断点继续还是先处理异常。

### R.5 子 agent 注入

Phase 3 调度时注入两部分上下文：

**1. 项目约束块**（从 R.4 加载的记忆，直接粘贴）：
```
## 项目约束（必须遵守）
### 编码规范
{项目规范记忆内容}
### 全局偏好
{全局记忆内容}
```

**2. 审计上下文块**（R.2 审计结果）：
```
## 任务审计上下文
以下任务经审计发现问题，实现时需注意：
- ⚠️ T{n} 部分完成：{缺失项} — 请在完成当前任务时一并补全
- ❌ T{m} 实际未完成 — 需要重新实现
已确认完成的任务（可作为参考）：✅ T1, T2, T4
```

### R.6 上下文压缩规范

> 会话上下文即将压缩时的行为规范。

压缩前**必须**写 `session-state.md`。

**必须保留**：规范表格(含来源) | 任务状态 | 决策理由 | 质量洞察 | 恢复锚点 | Git 分支名。

**禁止**：精简规范内容 / 丢弃任务状态 / 省略失败原因 / 删除分支信息。

---

## Phase 0: 首次使用记忆整理

触发：Phase 1.1 返回混乱（重复≥2、无scope tag、矛盾）。

### 0.1 记忆扫描

`memory_list(tags=["project"])` → 输出全部项目记忆条目。

### 0.2 整理操作

逐条处理，每条执行以下之一：
- **合并**：内容重复（语义相同）→ 保留最新/最完整的一条，删其余
- **确认**：记忆矛盾 → 中文展示矛盾点 → 询问用户选哪个
- **补全**：无 scope tag → 补 `project` tag；无 type → 根内容推断补 `convention`/`decision`/`bug`/`context`
- **删除**：明显过时（旧技术栈、已解决bug、废弃约定）→ 确认后删

### 0.3 存储与确认

整理后的规范摘要存入 `memory_store(tags=["project", "convention"])`。中文展示整理结果（合并N条/删除N条/补全N条）→ 用户确认。

---

## Phase 1: 信息收集

### 1.1 项目记忆检索

并行 4 个 memory_search。详见 [memory skill Cross-Skill API](../memory/SKILL.md)。

```
tags: ["project", "convention"]  query: "{项目名} 项目规范 编码规范"
tags: ["project", "bug"]         query: "{项目名} 踩坑 注意事项"
tags: ["project", "decision"]    query: "{项目名} 技术栈 架构 决策"
tags: ["global"]                 query: "通用规范 工作流"
```

项目名在 query，tags 只用 `scope+type`。项目/全局规范**独立展示不合并**，标注来源 `[项目]` `[全局]`，冲突时项目优先但不回写全局。混乱→Phase 0。均无→新项目。

### 1.2 代码考古（@explorer）

浏览顶层→识别技术栈 | glob+grep定位文件 | 记录路径/函数/行号/依赖 | 识别命名约定。输出：技术栈 + 文件清单表 + **代码风格规范**。

**代码风格规范必须提取以下维度**（写入 overview.md，供 Phase 3 项目约束块注入）：

| 维度 | 提取方式 | 示例 |
|------|---------|------|
| 命名风格 | 观察变量/函数/类命名 | `camelCase` / `snake_case` / `PascalCase` |
| 缩进与格式 | 观察源文件 | 2空格 / 4空格 / Tab |
| 注释风格 | 观察 docstring 和行注释 | JSDoc / docstring / 行内 `//` |
| 文件组织 | 观察目录结构 | 按功能分模块 / 按层分目录 |
| import 风格 | 观察导入语句 | 绝对导入 / 相对导入 / 分组排序 |

### 1.3 外部调研（@librarian，条件）

仅当：需新框架/外部API/选型≥2方案。模板见 [references/research-template.md](references/research-template.md)。

### 1.4 生成开发文档

```
docs/dev-{YYYYMMDD-HHmm}-{需求简述}/
├── requirements.md     ← 治理文档1（本Phase生成）
├── overview.md         ← 规范摘要+考古结果
├── research.md         ← 调研报告（若有）
├── task-plan.md        ← 治理文档2（Phase 2 生成）
├── test-report.md      ← 治理文档4（Phase 4 生成）
└── session-state.md    ← 恢复指针
```

**requirements.md 字段**：背景 | 需求描述 | 验收标准（checkbox列表） | 非功能需求 | 约束

### 1.5 🔒 用户确认需求

展示 requirements.md 内容 → **等用户确认后才进 Phase 2**。用户可修改/补充。

### 1.6 复杂度判定

| 条件 | 路径 |
|------|------|
| 单文件<50行，无新依赖 | 简单→跳Phase 2，主进程生成最小 task-plan |
| 2-3文件（含测试） | 中等→Phase 2 |
| 3+文件或新模块 | 复杂→Phase 2 + 必须调研 |

> 文件数含预计新增/修改的测试文件。

**Bug 修复特例判定**：当需求含「修复/fix」关键词时，无论复杂度，额外判定：

| 条件 | 附加路径 |
|------|---------|
| 同类 bug 历史≥2次 或 改动≥3文件 | 升级为**重构**→走 Phase 2 完整流程（不跳过） |
| 单点修复，根因明确 | 简单路径 + Bug 修复 6 步规范（Phase 3.6） |
| 根因不明 | 中等以上→Phase 2，@oracle 参与根因分析 |

简单任务也必须生成最小 task-plan.md（确保 Phase 3 和 Phase 3.6 Bug Fix 规范可用）。

### 1.7 Git 分支创建

触发条件：项目根目录存在 `.git`。

1. **检测当前状态**：
   - `git status` — 确认工作树是否干净
   - `git branch --show-current` — 记录当前分支名
   - 工作树脏 → 询问用户：stash / commit / 放弃
2. **生成分支名**：基于 Phase 1.6 复杂度判定 + 需求简述
   - `feat/{YYYYMMDD}-{简述}` | `fix/{YYYYMMDD}-{简述}` | `refactor/{YYYYMMDD}-{简述}`
3. **创建并切换分支**：
   - 优先：`github_create_branch(owner, repo, branch, from_branch)`
   - 回退：`git checkout -b {branch}`
4. **记录**：将分支名写入 `session-state.md` 基本信息

跳过条件：项目无 `.git` → 记录"非 Git 项目"到 session-state.md，后续 Phase 4.7 自动跳过。

---

## Phase 2: 任务拆解

### 2.1 @oracle 分析

```
项目根目录: {project_root}
需求: {user_requirement}
开发文档目录: {dev_doc_dir}

请阅读: overview.md + research.md（若有）+ 项目规范摘要
任务: 将需求拆解为子任务，每个包含:
- 任务编号 (T1, T2, ...) / 标题 / 涉及文件和行号
- 具体改动描述 / 依赖的前置任务编号
- 预估复杂度 (低/中/高) / 可并行标记

拆解规则: 500+行→框架+分批 | 1000+行→拆多文件

输出示例:
### T1: 新增 API 客户端框架
- **文件**: `src/api_client.py` (新建)
- **改动**: 创建 HTTP 客户端类骨架，含请求/重试/错误处理方法签名
- **依赖**: 无 | **复杂度**: 中 | **可并行**: 是

### T2: 实现数据拉取逻辑
- **文件**: `src/api_client.py` L30-L80
- **改动**: 填充 get_cards()、get_decks() 等方法实现
- **依赖**: T1 | **复杂度**: 中
```

写入 task-plan.md。模板见 [references/task-plan-template.md](references/task-plan-template.md)。

### 2.2 🔒 用户确认计划

中文展示任务清单+并行组 → **等用户确认后才进 Phase 3**。

---

## Phase 3: 并行实现

### 3.1 大文件策略

**行数阈值**：
- 500+行：骨架→分批填充(≤300行/批)→逐批验证
- 1000+行→拆多文件(≤800行/文件)

**逻辑拆分原则**（拆分时按优先级选择）：

| 优先级 | 原则 | 适用场景 | 示例 |
|--------|------|---------|------|
| 1 | 按职责/关注点 | 文件含多种不相关逻辑 | `api_client.py` → `api/auth.py` + `api/data.py` |
| 2 | 按实体/领域 | 文件操作多种数据实体 | `models.py` → `models/card.py` + `models/deck.py` |
| 3 | 按层级 | 文件跨越架构层 | `handler.py` → `routes.py` + `service.py` + `repository.py` |

**拆分后验证**：每个拆分出的文件应能独立导入（无循环依赖），对外接口通过 `__init__.py` 重导出保持兼容。

### 3.2 调度路由

| 任务特征 | Agent | 模式 |
|---------|-------|------|
| 纯实现/测试 | @fixer | 标准 |
| 架构/重构 | @oracle→@fixer | 先评后做 |
| UI/样式 | @designer | 独立 |
| 查新API | @librarian→@fixer | 先查后做 |
| Bug(简单) | @fixer | Bug Fix 6步 |
| Bug(重构) | @oracle→@fixer | 评审+Bug Fix |

调度循环：就绪任务→路由→≤3子进程启动→完成更新task-plan→**Git 提交（项目有 .git 时）**→超时(>5min)→检查新就绪。

**调度优先级**（当就绪任务 N > 3 时，按以下规则选择前 3 个）：

| 优先级 | 规则 | 理由 |
|--------|------|------|
| 1 | **解除阻塞**：优先选择被最多后续任务依赖的任务 | 最大化后续可并行度 |
| 2 | **同类合并**：同类 agent 的任务尽量同批调度 | 减少上下文切换 |
| 3 | **复杂度降序**：同优先级中复杂度高的先调度 | 长任务先跑，短任务可穿插 |

### 3.3 Agent 指令模板

**约束注入机制**：子 agent 可访问 memory MCP 工具，但需要引导。主进程调度时**必须注入**以下上下文块：

```
## 项目约束（必须遵守）

### 编码规范
{Phase 1.1 检索到的项目规范，直接粘贴}

### 全局偏好
{Phase 1.1 检索到的全局记忆，直接粘贴}

### 质量洞察
{Phase 4.0 或 R.4 加载的历史洞察，如有}
```

**基础指令**（所有 agent）：
```
项目根目录: {project_root}
开发文档: {dev_doc_dir}
请读: overview.md + task-plan.md 中 T{n}
任务: 执行 T{n}
约束: 遵守上方「项目约束」| 不改范围外文件 | 保持代码风格 | 单文件≤800行 | 完成后更新task-plan | 发现异常须标注 | **Git项目: 完成后执行 git add + commit**
补充读取: 如需更多上下文，可执行 memory_search(tags=["project"]) 或读取 docs/dev-*/ 下的文档
```

**@fixer Bug Fix 专用追加**：
```
Bug描述: {bug现象}
强制6步: 根因分析(记录现象→根因→方案, inconclusive时向主进程报告)
→ 同类排查(全局搜索, 发现同类追加变更记录)
→ 方案评估(含重构评估)
→ 实现(禁止硬编码绕过/吞异常)
→ 补测试(覆盖复现+边界)
→ 更新完成说明(根因+方案+排查结果+测试+发现)
```

**@oracle 追加**：读相关源文件 → 输出：

| # | 输出项 | 说明 |
|---|--------|------|
| 1 | 推荐方案 | 含理由和替代方案对比 |
| 2 | 风险点 | 实现中需注意的陷阱 |
| 3 | 重构建议 | 若需要，给出重构方向 |
| 4 | 步骤拆解 | 供 @fixer 执行的具体步骤 |

→ 写入 task-plan T{n} 的评审备注中。

### 3.4 异常处理

| 异常 | 处理 |
|------|------|
| agent失败 | ❌标记+记录+继续其他 |
| 需求偏差 | 暂停+中文确认 |
| 文件冲突 | 串行化 |
| 环境/依赖 | 修复→失败报告用户 |
| 文件>800行 | 自动拆分 |
| agent超时>5min | ⚠️+询问用户 |
| memory失败 | 跳过→Phase4重试→仍失败报告 |
| librarian失败 | 降级主进程+不阻塞并行 |
| 外部并发修改 | diff→合并或暂停询问 |
| 代码考古无结果 | 绿地项目→跳过考古，overview.md 记录为空 |
| 全部记忆为空 | 新项目→跳 Phase 0，直接 Phase 1.4 |
| 无测试可审计 | test-report.md 记录「无已有测试」，建议补充 |

### 3.5 子任务同步

唯一真相源：task-plan.md。变更→更新(追加/取消🚫/修改/拆分)→变更记录→一致性检查。同步点：agent完成时 | 调度循环 | Phase3结束全量校验。**Git项目：每个同步点同时执行 git commit，message 遵循 commit 规范。**

### 3.6 Bug 修复专项规范

> Phase 3 调度路由中 Bug 类型任务的执行规范，由 @fixer 遵循。

**不得敷衍。每次修复视为改善代码健康度的机会。**

| 等级 | 触发 | 要求 |
|------|------|------|
| 快速 | 单点，根因明确 | 修复+补测试+踩坑记录 |
| 系统 | 多处相似，同一根因 | 统一修复+补测试+记录 |
| **重构** | 需改核心逻辑/架构 | 回退到 Phase 2 完整流程 |
| 防御 | 修复引入新风险 | 回归+边界测试 |

**强制6步**：根因分析(禁止只修表面) → 同类排查(全局搜索) → 方案评估(含重构评估) → 实现(禁止硬编码/吞异常) → 补测试 → 记录。

重构触发（任一）：同bug≥2次 | 改动≥3文件 | 设计不合理 | 复杂度反增。触发后暂停当前修复，向主进程报告建议升级为重构任务。

---

## Phase 4: 收尾

### 4.0 质量洞察

检测：测试>30s | 重复≥3处 | 函数>50行 | 嵌套≥4层 | 循环依赖 | 硬编码 | API无错误处理 | 无分页。

汇总 task-plan「发现」+主动检测 → 洞察报告 → 存记忆(tags: `["project", "context"]`)。

### 4.1 测试审计（@explorer）+ 生成 test-report.md

@explorer 扫描已完成任务的测试覆盖，输出：`| 任务 | 测试文件 | 覆盖功能点 | 缺失测试 | 结果 |`

**test-report.md 字段**：测试概览(文件数/用例数/通过失败跳过/耗时) | 覆盖矩阵(任务×测试) | 边界与错误测试 | 未覆盖风险项

### 4.2 🔒 用户确认测试报告

展示 test-report.md → **等用户确认后才继续收尾**。未覆盖项需用户决定：接受风险/补充测试。

### 4.3 文档收尾

task-plan 终态 | overview 更新架构(若有变) | requirements.md 更新验收状态。

### 4.4 记忆更新

⚠️ **只存项目记忆，不存全局**。详见 [memory skill Cross-Skill API](../memory/SKILL.md)。

**写入规则**（每条存储前必须执行）：
- **精炼内容**：去掉对话语气词和冗余，一句话说清，脱离上下文仍可理解，单条≤120字
- **先去重**：`memory_search(query="<摘要>", limit=5)` → 相似度>0.85 则更新而非新建
- **双标签**：tags 必须含 scope+type

| tags | type | 模板 |
|------|------|------|
| `["project","decision"]` | decision | `"在 {project} 中，{决策}，原因: {原因}"` |
| `["project","convention"]` | convention | `"{project} 规范: {内容}"` |
| `["project","bug"]` | bug | `"{project} 踩坑: {问题} → {方案}"` |
| `["project","decision"]` | decision | `"{project} 技术栈: {栈}; 命名: {约定}"` |
| `["project","context"]` | context | `"{project} 质量洞察: {发现}"` |

### 4.5 记忆清理

`memory_list(tags=["project"])` → 过时删/重复合并/不精确优化 → 中文确认。

### 4.6 最终确认🔒

中文展示 4 文档审查结果：📋 需求达标 | 📋 计划终态 | 🔍 审计摘要 | ✅ 测试覆盖。附加：文档路径 | 记忆变更 | 质量洞察。

### 4.7 Git 分支合并

触发条件：Phase 4.6 🔒用户最终确认通过 + 项目有 `.git`。

**合并流程**：

1. **展示变更摘要**：
   - `git diff main...HEAD --stat` — 变更文件列表和行数
   - `git log main..HEAD --oneline` — 功能分支上的所有 commit
   - 中文展示摘要

2. **执行合并**（优先 GitHub MCP）：

   **路径 A — GitHub 远程仓库**：
   ```
   a. github_create_pull_request(title, body, head=功能分支, base=main)
   b. 展示 PR 链接给用户
   c. 用户确认后 → github_merge_pull_request(pullNumber, merge_method="squash")
   d. 合并成功 → 展示结果
   ```

   **路径 B — 本地 Git 仓库**（GitHub MCP 不可用时降级）：
   ```
   a. git checkout main
   b. git merge --no-ff {功能分支}
   c. 解决冲突（如有）→ 暂停询问用户
   d. 合并成功 → git branch -d {功能分支}（可选清理）
   ```

3. **合并后验证**：
   - 确认当前在 main 分支
   - 确认所有变更已合入
   - 如有 CI/CD → 触发并等待结果（可选）

4. **异常处理**：

   | 异常 | 处理 |
   |------|------|
   | 合并冲突 | 暂停 → 展示冲突文件 → 询问用户处理方式 |
   | PR 创建失败 | 降级到路径 B 本地合并 |
   | 合并后测试失败 | 不自动回滚 → 展示失败信息 → 询问用户 |
   | 非 Git 项目 | 整个 Phase 4.7 跳过，无提示 |
