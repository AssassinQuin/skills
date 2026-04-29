---
name: web-research
description: >
  多源并行调研 skill。当用户请求包含以下任一意图时必须触发：
  调研、研究、搜索研究、web research、search and analyze、查找资料、
  搜集信息、investigate、study、调研报告、技术调研、方案调研、文献、
  literature review、deep dive、研究报告、技术调研报告、调研分析。
  也包括隐式调研意图：对比分析、生态调研、方案选型、技术选型。
  Workflow: local-first scan → brainstorm → parallel search → summarize → persist.
  Output: structured research report in {skill_dir}/data/.
user-invocable: true
allowed-tools:
  - searxng_searxng_web_search
  - searxng_web_url_read
  - exa_web_search_exa
  - exa_web_fetch_exa
  - websearch_web_search_exa
  - webfetch
  - github_search_repositories
  - github_search_code
  - github_get_file_contents
  - github_list_commits
  - web-search-prime_web_search_prime
  - zread_search_doc
  - zread_read_file
  - zread_get_repo_structure
  - memory_memory_search
  - memory_memory_store
---

# Web Research Skill

多源并行调研：本地优先 → 头脑风暴 → 搜索 → 综合 → 持久化。

**MANDATORY 语言：面向用户中文。每个发现必须可追溯真实来源。**
**MANDATORY 工具优先级：SearXNG > Exa > GitHub > webfetch > 智普(fallback)。**

## 核心原则

| 优先级 | 规则 |
|--------|------|
| 搜索来源 | skill目录已有 → 项目目录已有 → memory已有 → 网络搜索 |
| 工具选择 | SearXNG(开源聚合) → Exa(语义搜索) → GitHub(API) → webfetch(兜底) → 智普(最后fallback) |
| 保存位置 | 原始数据+最终报告统一存 `{skill_dir}/data/`（跨项目复用） |
| 工具参数 | 详细参数见 `references/tool-specs.md`，SKILL.md 定义流程和子agent指令 |

## 三链工具体系

| 链 | 主工具 | 最佳场景 |
|----|--------|---------|
| **A SearXNG** | `searxng_searxng_web_search` + `searxng_web_url_read` | 通用搜索、中文、时效性、URL内容提取 |
| **B Exa** | `exa_web_search_exa` + `exa_web_fetch_exa` | 英文技术/学术语义搜索、批量全文提取 |
| **C GitHub** | `github_search_repositories` + `github_search_code` + `github_get_file_contents` | 开源项目发现、代码搜索、仓库文档深挖 |
| 兜底 | `webfetch` | 页面提取、llms.txt 探测 |
| 智普fallback | `web-search-prime_web_search_prime`, `zread_*` | ⚠️ 仅当 Tier 1 全部不可用时 |

## 流程概览

```
Phase 0: 快速判定    → 小查询直接答 / 深度调研走完整流程
Phase 1: 本地优先    → skill目录 → 项目目录 → memory（任一命中可短路）
Phase 2: 头脑风暴    → 搜索主题 + 工具链分配 + 🔒确认
Phase 3: 并行搜索    → ≤3 子agent 分工搜索（按链分工）
Phase 4: 综合+持久化 → 去重 → @oracle总结 → 🔒确认 → 保存到skill目录 + memory
```

---

## Phase 0: 快速判定

评估用户请求规模：

| 信号 | 判定 | 路径 |
|------|------|------|
| 单一事实（"Exa pricing是什么"） | 快速查询 | 直接用 searxng/exa 搜1-2次，返回答案+来源，不进完整流程 |
| 对比/分析/多角度/调研 | 深度调研 | 进 Phase 1 |

---

## Phase 1: 本地优先扫描

**目标**：复用已有研究，避免重复搜索。按优先级依次扫描，任一级命中可短路。

### 1.1 Skill 目录扫描（最高优先级）

**Step 1 关键词匹配**：
```
glob(pattern="{skill_dir}/data/**/*.md")
grep(pattern="{研究主题关键词}", path="{skill_dir}/data/")
```

**Step 2 语义补充**（关键词未命中时）：
```
memory_search(query="{研究主题}", mode="semantic", limit=5)
```

**命中判定**：
- 任一步找到相关内容 → 读取 → 展示摘要 → 🔒询问："直接复用 / 增量更新 / 重新开始"
- 选择"直接复用" → 跳到 Phase 4 仅做总结
- 选择"增量更新" → Phase 2 仅搜索已有研究未覆盖的方向

### 1.2 项目目录扫描

```
glob(pattern="{project_root}/docs/**/*.md")
grep(pattern="{研究主题关键词}", path="{project_root}/docs/")
```

**命中处理**：同 1.1，纳入 Phase 2 头脑风暴上下文。

### 1.3 Memory 检索

```
memory_search(query="{研究主题} 研究 调研", tags=["global","reference"], limit=10)
```

**命中处理**：展示摘要 → 纳入 Phase 2 上下文。

### 1.4 无命中

直接进 Phase 2。

---

## Phase 2: 头脑风暴与搜索方案

### 2.1 搜索主题

基于 Phase 1 上下文 + 用户需求，生成 3-6 个搜索主题：

```markdown
1. **{主题A}** — {为什么相关，期望找到什么}
2. **{主题B}** — ...
```

### 2.2 工具链分配

工具参数规范见 **[references/tool-specs.md](references/tool-specs.md)**。

**分配规则**（按语言和内容类型选链）：

| 主题类型 | 主链 | 交叉验证链 |
|----------|------|-----------|
| 中文内容 | A (SearXNG, language=zh) | B (Exa 英文交叉) |
| 英文技术/学术 | B (Exa 语义搜索) | A (SearXNG 交叉) |
| 代码/开源实现 | C (GitHub) | A (SearXNG 搜 site:github.com) |
| 时效性新闻 | A (SearXNG, time_range=day/week) | — |
| 综合调研 | A+B+C 混合 | 交叉验证 |

**每主题至少 2 个工具交叉验证**（如 SearXNG + Exa，或 Exa + GitHub）。

**⚠️ 智普工具使用条件**：仅在 SearXNG 和 Exa 均不可用时，才能使用 `web-search-prime` 或 `zread_*`，且必须在输出中标注 `⚠️ 智普fallback`。

### 2.3 预算

默认 30 次工具调用（3 agents × 10次/agent）。超限停止→标注"未完成"→进 Phase 4。

### 2.4 🔒 用户确认

展示：主题列表 + 工具方案 + 预估调用数。确认后进 Phase 3。

---

## Phase 3: 并行搜索

⚠️ **本 Phase 的子 agent 指令是 MANDATORY 的，子 agent 必须严格遵循。orchestrator 必须将下方「子 Agent Prompt 模板」的完整内容原样注入每个子 agent 的 prompt 中，不得省略或改写。**

最多 **3 个子agent** 并行。按工具链分工，非按主题分工。

### 3.1 角色选择（⚠️ MCP 工具能力决定分工）

子 agent 的 MCP 工具由 oh-my-opencode 配置决定，不同角色拥有不同的 MCP 工具。**必须按角色实际 MCP 能力分工，而非假设所有角色都能用所有工具。**

**标准 MCP 能力矩阵**（oh-my-opencode-slim.json 默认配置）：

| 角色 | 可用 MCP | 适合的搜索链 |
|------|---------|------------|
| @explorer | searxng, github, exa, web-search-prime | 链A+B+C 全链（通用搜索角色） |
| @librarian | context7, grep_app, web-search-prime, zread, searxng | 链A（SearXNG）+ 文档检索 |
| @oracle | memory, github | 链C（GitHub）+ 分析评估 |
| @fixer | github, memory | 链C（GitHub）+ 实现 |
| @designer | exa, searxng | 链A+B（Exa+SearXNG） |

> **角色选择策略**：优先 @explorer（通用搜索），其次按 MCP 能力匹配。如果 explorer 没有 MCP 工具配置（mcps=[]），则用 @librarian（有 searxng）+ @oracle（有 github）+ @designer（有 exa）组合替代。

**推荐分工方案**：

| Agent | 角色 | 工具链 | 职责 |
|-------|------|--------|------|
| Agent 1 | @explorer 或 @librarian | 链A+B: `searxng_searxng_web_search`, `searxng_web_url_read`, `exa_web_search_exa`, `exa_web_fetch_exa` | 主搜索 + 内容提取 + 交叉验证 |
| Agent 2 | @explorer 或 @oracle | 链C: `github_search_repositories`, `github_search_code`, `github_get_file_contents` | 开源项目发现 + 仓库文档深挖 |
| Agent 3 | @explorer 或 @librarian | 交叉验证: `searxng_searxng_web_search`, `webfetch` | 补充搜索 + 验证关键结论 |

> ⚠️ **关键**：每个子 agent prompt 中**只列出该角色实际可用的工具**，不要列出它无法调用的工具。模板中的工具列表必须与角色 MCP 能力匹配。

### 3.2 🔴 MANDATORY 子 Agent Prompt 模板

**orchestrator 必须将以下模板原样注入子 agent prompt。大括号 `{...}` 处替换为实际值，其余内容一字不改。**

---

**[MANDATORY 指令开始 — 子 agent 必须严格遵循以下所有规则]**

你是调研子 agent。你的任务是用指定搜索工具收集研究资料。

**研究主题**: {主题名}
**分配工具链**: {链标识，如 "链A+B: SearXNG + Exa"}
**具体可用工具**: {列出该 agent 可用的工具全名}

### 工具调用规范（MANDATORY）

你必须使用以下工具，按指定参数格式调用：

**SearXNG 搜索** `searxng_searxng_web_search`:
- 参数: `{"query": "关键词", "language": "zh或en", "pageno": 1, "safesearch": 0}`
- query 用关键词（非自然语言），中文搜中文 query，英文搜英文 query

**SearXNG 内容提取** `searxng_web_url_read`:
- 参数: `{"url": "https://...", "maxLength": 5000}`
- 对搜索结果中高相关 URL 提取全文

**Exa 语义搜索** `exa_web_search_exa`:
- 参数: `{"query": "描述理想页面内容的自然语言，20-70字符", "numResults": 10}`
- query 用自然语言描述（非关键词）

**Exa 批量提取** `exa_web_fetch_exa`:
- 参数: `{"urls": ["https://..."], "maxCharacters": 5000}`

**GitHub 仓库搜索** `github_search_repositories`:
- 参数: `{"query": "topic:x language:y stars:>100", "sort": "stars", "perPage": 10}`

**GitHub 代码搜索** `github_search_code`:
- 参数: `{"query": "content:xxx language:python", "perPage": 10}`

**GitHub 文件读取** `github_get_file_contents`:
- 参数: `{"owner": "user", "repo": "project", "path": "README.md"}`

**webfetch 兜底提取** `webfetch`:
- 参数: `{"url": "https://...", "format": "markdown", "extract_main": true, "prefer_llms_txt": "auto", "include_metadata": true, "save_binary": false}`

### 工具优先级（MANDATORY）

1. 优先使用 SearXNG / Exa / GitHub 工具
2. ⚠️ 只有当以上工具全部返回空结果或报错时，才能使用智普工具（`web-search-prime_web_search_prime`, `zread_*`）
3. 如果被迫使用智普工具，必须在输出中标注 `⚠️ 智普fallback`

### 执行步骤

1. 为每个搜索主题构造 2-3 个 query，调用搜索工具（每 query 取 top 5-10 结果）
2. 从搜索结果中选出 2-3 个高相关 URL，提取全文内容
3. 如果某个工具返回空结果或报错，立即换另一个工具重试（如 SearXNG 空→换 Exa）
4. 所有结果按以下格式输出

### 🔴 MANDATORY 输出格式

你的输出必须且只能包含以下格式的来源条目。每个搜索结果都必须包含完整的 5 个字段，缺一不可。

```markdown
### 来源 1: {标题}
- **URL**: {完整URL}
- **工具**: {实际调用的工具全名，如 searxng_searxng_web_search}
- **Query**: {实际使用的搜索 query}
- **相关性**: 高/中/低
- **摘要**: {2-3句话概括内容}

### 来源 2: {标题}
- **URL**: {完整URL}
- **工具**: {工具全名}
- **Query**: {搜索query}
- **相关性**: 高/中/低
- **摘要**: {2-3句话概括内容}

### 来源 3: {标题}
...
```

如果提取了全文，额外添加：
```markdown
- **全文要点**: {全文的关键要点，3-5条}
```

### 约束（MANDATORY）

1. 中文输出
2. 只返回与主题相关的结果，过滤噪音
3. 每条结果必须包含 **URL + 工具名 + Query**（可追溯性）
4. 不要输出任何其他格式的内容（不要输出 JSON、不要输出纯文本列表、不要省略字段）
5. 如果所有搜索工具都无结果，输出：`⚠️ 未找到相关结果。已尝试的 query: [列出]`

**[MANDATORY 指令结束]**

---

### 3.3 orchestrator 职责

orchestrator 在 Phase 3 必须：

1. **检查角色 MCP 能力**：在分发任务前，确认所用角色的 MCP 配置包含所需工具。如果角色缺少必要 MCP 工具，切换到有该 MCP 的角色
2. **匹配工具列表**：子 agent prompt 中的工具列表只包含该角色实际可用的 MCP 工具名，不列它无法调用的工具
3. **原样注入** 3.2 的模板内容到每个子 agent 的 prompt 中（仅替换 `{...}` 占位符）
4. **不要让子 agent 自己读** `references/tool-specs.md`——工具参数已内联在模板中
5. **收集所有子 agent 输出后**，验证每条结果是否包含 URL/工具/Query/相关性/摘要 五个字段
6. 格式不合格时：要求该子 agent 重试一次（将不合格输出 + 正确格式模板回传）；重试仍不合格则标记 `⚠️ 格式不完整` 纳入 Phase 4

---

## Phase 4: 综合 + 持久化

### 4.1 去重去噪

- URL去重 | 内容去重（多来源合并标注） | 噪音过滤 | 过滤格式不完整的结果

### 4.2 @oracle 综合报告

⚠️ **以下模板由 orchestrator 原样注入 @oracle 的 prompt，不使用代码块包裹。**

你是研究总结专家。根据搜索结果生成结构化报告。

主题: {主题}
数据: {Phase 4.1整理结果}

输出结构（按顺序）:
1. 背景与目标
2. 核心发现（每条标注 [来源#N]）
3. 方案对比（仅对比型调研时包含，用表格）
4. 结论与建议
5. 信息源列表（所有 URL + 来源编号）

规则: 中文 | 交叉验证标注 [来源A,B验证] | 知识空白标 ⚠️ | 不编造

### 4.3 🔒 用户确认

展示报告。选项：✅确认 / 🔄补充搜索(回Phase 2) / ✏️修改 / ❌放弃

### 4.4 持久化

**保存到 skill 目录**（权威位置，跨项目复用）：

```
{skill_dir}/data/{YYYYMMDD}-{topic-slug}/
├── 研究报告.md
├── raw/
│   ├── agent-a.md
│   ├── agent-b.md
│   └── sources-index.md
```

**Memory 存储**（概述，可定位）：

```
content: "{主题}研究: {概述，含关键发现和结论}。详情: {skill_dir}/data/{slug}/"
tags: "global,reference"
```

---

## 异常处理

| 异常 | 处理 |
|------|------|
| **触发词未识别** | orchestrator 发现用户意图包含调研/研究/对比分析但未触发本 skill → 主动加载并执行 Phase 0 |
| Memory不可用 | 跳过memory操作，继续搜索 |
| SearXNG 不可用 | 降级到 Exa → 再不可用用 web-search-prime（智普fallback，标注⚠️） |
| Exa 限流/超时 | 降级到 SearXNG，重试1次 |
| GitHub search 无结果 | 放宽条件（去掉 stars/language 过滤），或 SearXNG 搜 `site:github.com` |
| 全文提取失败 | 保留搜索摘要，标注"无法提取全文" |
| 子agent超时 | 收集已完成结果，标注"部分搜索" |
| 子agent输出格式不合规 | 标记 `⚠️ 格式不完整`，仍纳入 Phase 4 去重处理 |
| 无搜索结果 | 调整query重试一次→仍无则报告 |
| 用户中断 | 保存已有结果到skill目录 |
| skill_dir不存在 | 用mkdir -p创建 |
| Tier 1 全部不可用 | 使用智普工具（web-search-prime + zread），报告标注 `⚠️ 智普fallback模式` |
