---
name: programmer
description: >
  全流程编程执行引擎。当用户提出开发需求、功能需求、bug修复、功能增强时触发。
  自动执行：项目记忆检索与整理 → 代码考古 → 可选外部调研 → 任务拆解 →
  分批并行实现 → 规范校验 → 记忆更新。
  触发词：「开发」「实现」「新增功能」「加一个」「修复」「改一下」「refactor」
  「feature」「fix」「需求」「帮我做」「add feature」「implement」「build」。
  不触发：纯问答、解释、分析、调研等非编码类请求。
metadata:
  version: 2
---

# Programmer — 全流程编程执行引擎

## 概览

```
Phase R: 会话恢复 → 审计已完成任务 → 进度定位 → 上下文加载
Phase 0 (条件): 首次使用 → 记忆整理
Phase 1: 记忆检索 + 代码考古 + [调研] → requirements.md + overview.md → 🔒用户确认 → Git 创建分支
Phase 2: @oracle 任务拆解 → task-plan.md → 🔒用户确认计划
Phase 3: 智能调度(≤3子进程) → 在功能分支上代码变更 → 按任务粒度 commit
Phase 4: 测试审计 → test-report.md → 🔒用户确认 → 记忆更新 → 🔒最终确认 → Git 合并
```

**语言：面向用户一律中文。task-plan.md 是任务状态唯一真相源。**

---

## 治理模型：4 文档审查制

AI 全程自主编码，人类通过审查 4 个文档把控质量，**不看代码**。每个文档生成后🔒暂停等用户确认。

| # | 文档 | 阶段 | 确认点 |
|---|------|------|--------|
| 1 | `requirements.md` | Phase 1 | 🔒 Phase 1.5 |
| 2 | `task-plan.md` | Phase 2 | 🔒 Phase 2.2 |
| 3 | Phase R.2 审计报告 | Phase R | 恢复时展示 |
| 4 | `test-report.md` | Phase 4 | 🔒 Phase 4.2 |
| 5 | Git 分支合并 | Phase 4 | 🔒 Phase 4.6 后执行 |

**铁律**：🔒未确认 = 不进入下一 Phase。文档修改后必须重新确认。

---

## Skill 集成

### Memory

遵循 [memory skill Cross-Skill API](../memory/SKILL.md)（稳定接口）：

- **scope 别名**：`project` / `shared` / `global` / `session`
- **检索**：`memory_search(tags=["project"], limit=50)` — 至少指定 scope
- **存储**：`memory_store(content, metadata={tags: "project,decision"})` — 双标签
- **去重**：存储前 `memory_search(query="<摘要>", limit=5)` → 相似>0.85 则更新
- **降级**：memory 不可用时跳过，不阻塞主流程

### Web Research

Phase 1.3 调研委托 [web-research skill](../web-research/SKILL.md)：

- **触发**：需新框架/外部API/选型≥2方案
- **委托**：`@librarian` 加载 web-research skill，传入 `{query, 技术栈, 项目上下文}`
- **输出**：research.md（按 [research-template.md](references/research-template.md)）

### 委托边界

| 功能 | 由 programmer 自行处理 | 委托外部 skill |
|------|----------------------|---------------|
| 调研 | — | web-research skill（Phase 1.3） |
| 记忆读写 | Cross-Skill API 直调 | memory skill 守门（首次加载） |
| 任务规划 | @oracle 拆解（含行号/依赖） | 不委托 planning-with-files |
| 代码精简 | — | simplify skill（仅 Phase 4.0 检测后建议） |

---

## Agent 规范

### 职责矩阵

| Agent | 触发阶段 | 输入 | 输出 |
|-------|---------|------|------|
| **@explorer** | P1.2, R.2, 4.1 | project_root, scan_scope | 技术栈+文件清单+代码风格 |
| **@librarian** | P1.3 | query, 技术栈, 项目上下文 | research.md |
| **@fixer** | P3 | project_root, T{n}, 约束块 | 变更摘要(见下方) |
| **@oracle** | P2.1, P3重构 | project_root, 需求, 源文件 | 方案+风险+步骤 |
| **@designer** | P3 UI任务 | project_root, UI需求, 设计上下文 | UI代码+样式 |

**约束**：≤3子进程并行 | 同类agent≤2 | @oracle串行 | 有依赖→同一agent

### @explorer 指令

```python
输入:
  project_root: str       # 项目根目录
  scan_scope: str         # "顶层" | "特定目录:{path}" | "文件模式:{glob}"
任务:
  1. 浏览目录结构，识别技术栈
  2. glob+grep 定位关键文件
  3. 记录路径/函数/行号/依赖关系
  4. 提取代码风格规范（5维度：命名/缩进/注释/文件组织/import）
输出格式:
  ## 技术栈: {语言} {框架} {构建工具} {测试框架}
  ## 文件清单: | 路径 | 职责 | 关键函数/类 |
  ## 代码风格: | 维度 | 规范 |
约束: 只读不写 | 单次≤60s
```

### @librarian 指令

```python
输入:
  query: str              # 调研问题
  tech_stack: str         # 当前技术栈
  project_context: str    # 项目背景
任务:
  加载 web-research skill → 执行调研 → 输出 research.md
输出: research.md（按 research-template.md）
约束: 只查最新版文档 | 查新API也算触发条件
```

### @fixer 指令

```python
输入:
  project_root: str
  dev_doc_dir: str
  task: T{n} 描述（来自 task-plan.md）
  constraint_block: 项目约束（见约束注入）
任务: 执行 T{n}
输出格式（完成后必须返回）:
  ## 变更摘要
  ### 修改文件: | 文件路径 | 操作(新增/修改) | 行数变化 |
  ### 测试结果: | 测试文件 | 用例数 | 通过/失败 |
  ### 变更说明: {一句话描述改动}
约束:
  遵守项目约束 | 不改范围外文件 | 保持代码风格
  单文件≤800行 | 完成后更新 task-plan
  通过 github_push_files 提交 | 发现异常须标注
异常报告（向主进程）:
  格式: "⚠️ T{n} 异常: {类型} | {现象} | {已尝试} | {建议}"
  类型: inconclusive根因 | 环境依赖缺失 | 超出范围
  主进程收到后: 暂停该任务 → 评估 → 降级/升级/用户确认
```

### @oracle 指令

```python
输入:
  project_root: str
  requirement: str        # 用户需求
  source_files: list      # 相关源文件路径
任务:
  阅读源文件 → 分析 → 输出评审结果
输出格式:
  | # | 输出项 | 说明 |
  |---|--------|------|
  | 1 | 推荐方案 | 含理由和替代方案对比 |
  | 2 | 风险点 | 实现中需注意的陷阱 |
  | 3 | 重构建议 | 若需要，给出重构方向 |
  | 4 | 步骤拆解 | 供 @fixer 执行的具体步骤 |
约束: 只分析不实现 | 输出写入 task-plan 评审备注
```

### @designer 指令

```python
触发判定: 任务涉及以下任一 → 路由到 @designer
  - UI组件/页面/布局
  - CSS/样式/主题/响应式
  - 动画/交互/微交互
  - 视觉一致性/设计系统
输入:
  project_root: str
  ui_requirement: str     # UI 需求描述
  design_context: str     # 现有设计规范/组件库
任务: 实现 UI 变更
输出: 同 @fixer 变更摘要格式
约束: 只处理视觉/交互/响应式 | 遵循现有设计系统
```

### 约束注入（统一模板）

Phase R.5 和 Phase 3 调度时，注入以下上下文块：

```
## 项目约束（必须遵守）
### 编码规范
{Phase 1.1 检索到的项目规范}
### 全局偏好
{Phase 1.1 检索到的全局记忆}
### 代码风格
{Phase 1.2 @explorer 提取的代码风格规范}
### 质量洞察
{Phase 4.0 或 R.4 加载的历史洞察，如有}
```

---

## Git 规范（GitHub MCP）

> 所有代码变更在功能分支上进行，通过 GitHub MCP 工具管理。

### 参数来源

```python
# Phase 1.7 前置：获取 owner/repo（后续所有 GitHub MCP 调用复用）
me = github_get_me()
owner = me.login
repo = basename(project_root)  # 通常与 GitHub repo 名一致

# 前置检查（任一不满足 → 提示用户并等待）：
# 1. .git 存在？→ 无则 git init && git add . && git commit -m 'initial'
# 2. github remote？→ git remote -v 含 github.com → 无则 git remote add
# 3. me 可访问仓库？→ github_get_me() 成功
```

### 分支策略

| 时机 | MCP 操作 | 参数 |
|------|---------|------|
| P1.7 需求确认后 | `github_create_branch` | `owner, repo, branch="feat/...", from_branch=当前主分支` |
| P3 每个子任务完成 | `github_push_files` | `owner, repo, branch=功能分支, files=[{path, content}], message="..."` |
| P4.7 最终确认后 | `github_create_pull_request` → `github_merge_pull_request` | 见 Phase 4.7 |

### 命名与 Commit

```
分支: {类型}/{YYYYMMDD}-{需求简述}
  类型: feat | fix | refactor
  示例: feat/20260428-card-winrate-analysis

Commit: {type}({scope}): {简述}
  type: feat | fix | refactor | test | docs
  scope: 受影响的模块/文件名
  示例: feat(analysis): add winrate trend calculation
```

### MCP 错误处理

| 异常 | 处理 |
|------|------|
| `github_get_me` 失败 | 提示检查 GitHub 认证 → 等待用户处理 |
| `github_create_branch` 分支已存在 | 切换到现有分支或追加后缀 `-2` |
| `github_push_files` 冲突 | 串行化该任务 |
| `github_merge_pull_request` 冲突 | 暂停 → 展示冲突 → 用户决定 |

---

## Phase R: 会话恢复

检查 `docs/dev-*/session-state.md` 是否存在且未完成。

### R.2 任务审计（@explorer）

```
项目根目录: {project_root}
开发文档: {dev_doc_dir}

请阅读 task-plan.md，对所有标记为 ✅ 已完成的任务逐一验证：
1. 读取任务描述中的「涉及文件」和「改动描述」
2. 检查对应文件是否存在
3. 检查文件内容是否包含任务描述中的改动
4. 如有测试文件，检查测试是否覆盖

输出: ## 任务审计报告 → | 任务 | 声明 | 审计 | 缺失项 |
```
每个任务 ≤30s，只做表面验证。

### R.3 进度定位

基于审计生成：✅已确认 / ⚠️部分完成 / ❌未完成 / 🔵当前断点 / ⬜待执行。

自动修正 task-plan：⚠️→`🔄部分完成` | ❌→`⬜待执行`，追加变更记录。

### R.4 上下文加载

| 加载项 | 来源 |
|--------|------|
| 项目规范 | `memory_search(tags=["project"], limit=50)` |
| 全局偏好 | `memory_search(tags=["global"], limit=20)` |
| 质量洞察 | `memory_search(query="{项目名} 洞察", tags=["project"], limit=10)` |
| overview + task-plan | docs/dev-*/ |
| Git 分支 | session-state.md 中的分支名 + `git branch --show-current` 验证 |

展示进度报告 + 异常任务 + 当前分支状态 → 询问继续还是处理异常。

### R.5 上下文压缩规范

压缩前**必须**写 `session-state.md`。

**必须保留**：规范表格(含来源) | 任务状态 | 决策理由 | 质量洞察 | 恢复锚点 | Git 分支名。

**禁止**：精简规范内容 / 丢弃任务状态 / 省略失败原因 / 删除分支信息。

---

## Phase 0: 首次使用记忆整理

触发：Phase 1.1 返回混乱（重复≥2、无scope tag、矛盾）。

### 0.1 记忆扫描

`memory_list(tags=["project"])` → 输出全部项目记忆条目。

### 0.2 整理操作

逐条处理：
- **合并**：语义重复 → 保留最新/最完整，删其余
- **确认**：矛盾 → 展示矛盾点 → 用户选哪个
- **补全**：无 scope tag → 补 `project`；无 type → 推断补 `convention`/`decision`/`bug`/`context`
- **删除**：明显过时 → 确认后删

### 0.3 存储与确认

整理后存入 `memory_store(metadata={tags: "project,convention"})`。展示整理结果 → 用户确认。

---

## Phase 1: 信息收集

### 1.1 项目记忆检索

并行 4 个 memory_search：

```
tags: ["project"]   query: "{项目名} 项目规范 编码规范"
tags: ["project"]   query: "{项目名} 踩坑 注意事项"
tags: ["project"]   query: "{项目名} 技术栈 架构 决策"
tags: ["global"]    query: "通用规范 工作流"
```

项目/全局规范**独立展示不合并**，标注来源 `[项目]` `[全局]`，冲突时项目优先。混乱→Phase 0。均无→新项目。

### 1.2 代码考古（@explorer）

按 @explorer 指令模板执行。输出写入 overview.md 的技术栈+文件清单+代码风格部分。

### 1.3 外部调研（@librarian + web-research，条件）

**触发条件**：需新框架/外部API/选型≥2方案/需查新API。

**执行**：`@librarian` 加载 web-research skill，传入 `{query, 技术栈, 项目上下文}`，输出 research.md（按 [research-template.md](references/research-template.md)）。

### 1.4 生成开发文档

```
docs/dev-{YYYYMMDD-HHmm}-{需求简述}/
├── requirements.md     ← 治理文档1（本Phase生成，格式见下方）
├── overview.md         ← 规范摘要+考古结果（格式见下方）
├── research.md         ← 调研报告（若有）
├── task-plan.md        ← 治理文档2（Phase 2 生成，模板见 references/）
├── test-report.md      ← 治理文档4（Phase 4 生成，格式见下方）
└── session-state.md    ← 恢复指针（格式见 references/session-state.md）
```

**requirements.md 格式**：
```markdown
# {需求标题}
## 背景
{业务背景}
## 需求描述
{具体需求}
## 验收标准
- [ ] {标准1}
- [ ] {标准2}
## 非功能需求
- 性能: {要求} | 安全: {要求}
## 约束
- {约束条件}
```

**overview.md 格式**：
```markdown
# 项目概览
## 技术栈
| 层 | 技术 | 版本 |
## 文件清单
| 路径 | 职责 | 关键函数/类 |
## 代码风格规范
| 维度 | 规范 | （来自 @explorer 输出）
## 规范摘要
| 来源 | 规范内容 | （来自 Phase 1.1 记忆检索）
```

**test-report.md 格式**：
```markdown
# 测试报告
## 测试概览
| 指标 | 值 |  （文件数/用例数/通过失败/耗时）
## 覆盖矩阵
| 任务 | 测试文件 | 覆盖功能点 | 缺失 | 结果 |
## 未覆盖风险项
- {风险}
```

### 1.5 🔒 用户确认需求

展示 requirements.md → **等用户确认后才进 Phase 2**。

### 1.6 复杂度判定

| 条件 | 路径 |
|------|------|
| 单文件<50行，无新依赖 | 简单→跳 Phase 2，主进程生成最小 task-plan |
| 2-3文件（含测试） | 中等→Phase 2 |
| 3+文件或新模块 | 复杂→Phase 2 + 必须调研 |

**Bug 修复特例**：

| 条件 | 路径 |
|------|------|
| 同类 bug 历史≥2次 或 改动≥3文件 | 升级重构→Phase 2 完整流程 |
| 单点修复，根因明确 | 简单路径 + Bug Fix 6步（Phase 3 Bug Fix 节） |
| 根因不明 | 中等以上→Phase 2，@oracle 参与根因分析 |

简单任务也必须生成最小 task-plan.md。

### 1.7 Git 分支创建

前置检查（见 Git 规范节「参数来源」）→ 通过后：

```
1. github_list_branches → 确认分支不存在
2. 生成分支名: feat/{YYYYMMDD}-{简述} | fix/... | refactor/...
3. github_create_branch(owner, repo, branch, from_branch=当前主分支)
4. 本地追踪: git fetch origin {branch} && git checkout {branch}
5. 记录分支名到 session-state.md
```

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

拆解规则: 500+行→框架+分批 | 1000+行→拆多文件（参考 Phase 3.1 逻辑拆分原则表）

输出示例:
### T1: 新增 API 客户端框架
- **文件**: `src/api_client.py` (新建)
- **改动**: 创建 HTTP 客户端类骨架
- **依赖**: 无 | **复杂度**: 中 | **可并行**: 是
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

**逻辑拆分原则**（优先级排序）：

| 优先级 | 原则 | 适用场景 | 示例 |
|--------|------|---------|------|
| 1 | 按职责/关注点 | 文件含多种不相关逻辑 | `api_client.py` → `api/auth.py` + `api/data.py` |
| 2 | 按实体/领域 | 文件操作多种数据实体 | `models.py` → `models/card.py` + `models/deck.py` |
| 3 | 按层级 | 文件跨越架构层 | `handler.py` → `routes.py` + `service.py` + `repository.py` |

拆分后通过 `__init__.py` 重导出保持兼容。

### 3.2 调度路由

| 任务特征 | Agent | 模式 |
|---------|-------|------|
| 纯实现/测试 | @fixer | 标准 |
| 架构/重构 | @oracle→@fixer | 先评后做 |
| UI/样式 | @designer | 独立 |
| 查新API | @librarian→@fixer | 先查后做 |
| Bug(简单) | @fixer | Bug Fix 6步 |
| Bug(重构) | @oracle→@fixer | 评审+Bug Fix |

**调度优先级**（就绪任务 N > 3 时）：

| 优先级 | 规则 | 理由 |
|--------|------|------|
| 1 | 解除阻塞：被最多后续任务依赖的先跑 | 最大化并行度 |
| 2 | 同类合并：同类 agent 任务尽量同批 | 减少上下文切换 |
| 3 | 复杂度降序：高复杂度先跑 | 长任务先启动 |

**调度循环**：就绪任务→路由→≤3子进程→完成更新 task-plan→`github_push_files`→超时(>5min)→检查新就绪。

**GitHub Push 参数**（每个子任务完成时）：
```python
github_push_files(
  owner=owner,           # 来自 Phase 1.7 前置获取
  repo=repo,
  branch=功能分支名,       # 来自 session-state.md
  files=[
    {"path": "src/new_file.py", "content": "文件内容"},
    {"path": "tests/test_new.py", "content": "测试内容"}
  ],
  message="feat(scope): 简述"   # 遵循 commit 规范
)
```

### 3.3 子任务同步

唯一真相源：task-plan.md。变更→更新(追加/取消🚫/修改/拆分)→变更记录→一致性检查。同步点：agent完成时 | 调度循环 | Phase3结束全量校验。每个同步点通过 `github_push_files` 提交。

### 3.4 Bug Fix 专项规范

> Phase 3 调度路由中 Bug 类型任务的执行规范，由 @fixer 遵循。

**Bug 等级**：

| 等级 | 触发 | 要求 |
|------|------|------|
| 快速 | 单点，根因明确 | 修复+补测试+踩坑记录 |
| 系统 | 多处相似，同一根因 | 统一修复+补测试+记录 |
| **重构** | 需改核心逻辑/架构 | 回退到 Phase 2 完整流程 |
| 防御 | 修复引入新风险 | 回归+边界测试 |

**强制 6 步**（@fixer Bug 任务必须执行）：

```
1. 根因分析: 记录现象→根因→方案。inconclusive → 向主进程报告（格式见 @fixer 指令）
2. 同类排查: 全局搜索相似模式，发现同类追加变更记录
3. 方案评估: 含重构评估。重构触发条件：同bug≥2次 | 改动≥3文件 | 设计不合理
4. 实现: 禁止硬编码绕过、禁止吞异常
5. 补测试: 覆盖复现路径+边界情况
6. 更新完成说明: 根因+方案+排查结果+测试+发现
```

重构触发后暂停，向主进程报告建议升级为重构任务。

### 3.5 异常处理

| 异常 | 处理 |
|------|------|
| agent 失败 | ❌标记+记录+继续其他 |
| 需求偏差 | 暂停+中文确认 |
| 文件冲突 | 串行化 |
| 环境/依赖 | 修复→失败报告用户 |
| 文件>800行 | 自动拆分（Phase 3.1） |
| agent 超时>5min | ⚠️+询问用户 |
| memory 失败 | 跳过→Phase4重试→仍失败报告 |
| librarian 失败 | 降级主进程+不阻塞并行 |
| 外部并发修改 | diff→合并或暂停询问 |
| 代码考古无结果 | 绿地项目→跳过考古，overview.md 记录为空 |
| 全部记忆为空 | 新项目→跳 Phase 0，直接 Phase 1.4 |
| 无测试可审计 | test-report.md 记录「无已有测试」，建议补充 |
| 用户中途追加需求 | 记入 task-plan「待处理」节 → 当前任务完成后统一处理 |

---

## Phase 4: 收尾

### 4.0 质量洞察

检测：测试>30s | 重复≥3处 | 函数>50行 | 嵌套≥4层 | 循环依赖 | 硬编码 | API无错误处理 | 无分页。

汇总 task-plan「发现」+主动检测 → 洞察报告 → 存 `memory_store(metadata={tags: "project,context"})`。

### 4.1 测试审计（@explorer）+ 生成 test-report.md

@explorer 扫描已完成任务的测试覆盖，输出：`| 任务 | 测试文件 | 覆盖功能点 | 缺失测试 | 结果 |`

test-report.md 按 Phase 1.4 定义的格式生成。

### 4.2 🔒 用户确认测试报告

展示 test-report.md → **等用户确认后才继续**。未覆盖项需用户决定：接受风险/补充测试。

### 4.3 文档收尾

task-plan 终态 | overview 更新架构(若有变) | requirements.md 更新验收状态。

### 4.4 记忆更新

⚠️ **只存项目记忆，不存全局**。

**写入规则**：
- **精炼内容**：单条≤120字，脱离上下文仍可理解
- **先去重**：`memory_search(query="<摘要>", limit=5)` → 相似>0.85 则更新
- **双标签**：`tags` 必须含 `project` + type

| tags | 模板 |
|------|------|
| `project,decision` | `"在 {project} 中，{决策}，原因: {原因}"` |
| `project,convention` | `"{project} 规范: {内容}"` |
| `project,bug` | `"{project} 踩坑: {问题} → {方案}"` |
| `project,context` | `"{project} 质量洞察: {发现}"` |

### 4.5 记忆清理

`memory_list(tags=["project"])` → 过时删/重复合并/不精确优化 → 中文确认。

### 4.6 🔒 最终确认

中文展示 4 文档审查结果：📋 需求达标 | 📋 计划终态 | 🔍 审计摘要 | ✅ 测试覆盖。附加：文档路径 | 记忆变更 | 质量洞察。

### 4.7 Git 分支合并

触发：Phase 4.6 🔒确认通过。

```
1. 展示变更摘要:
   - github_pull_request_read(method="get_diff", owner, repo, pullNumber)
   - github_list_commits(owner, repo, sha=功能分支)

2. 创建 PR:
   github_create_pull_request(
     title="{type}({scope}): {简述}",
     body="## Summary\n{变更摘要}\n\n## Test Plan\n{测试覆盖}",
     head=功能分支, base="main"
   )

3. 合并 PR:
   github_merge_pull_request(pullNumber, merge_method="squash")

4. 合并后验证:
   github_list_branches → 确认状态
   git checkout main && git pull
```

**合并异常**：

| 异常 | 处理 |
|------|------|
| 合并冲突 | 暂停 → 展示冲突文件 → 用户决定 |
| PR 创建失败 | 展示错误 → 询问用户 |
| 合并后测试失败 | 不自动回滚 → 展示失败 → 询问用户 |
