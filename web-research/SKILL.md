---
name: web-research
description: >
  多源并行调研。local-first → 6角度头脑风暴 → 并行agent搜索(sonnet) → 灵感追挖 → 综合报告。
  触发词：调研、研究、搜索研究、web research、对比分析、方案选型、文献、literature review、deep dive。
  Output: {skill_dir}/data/{date}-{slug}/
user-invocable: true
metadata:
  version: "3.0"
allowed-tools:
  - mcp__searxng__searxng_web_search
  - mcp__searxng__web_url_read
  - mcp__crawl4ai-mcp__scrape
  - mcp__crawl4ai-mcp__crawl
  - mcp__crawl4ai-mcp__crawl_site
  - mcp__crawl4ai-mcp__crawl_sitemap
  - mcp__web_reader__webReader
  - mcp__context-mode__ctx_fetch_and_index
  - mcp__context-mode__ctx_index
  - mcp__context-mode__ctx_search
  - mcp__context-mode__ctx_batch_execute
  - mcp__github__search_repositories
  - mcp__github__search_code
  - mcp__github__get_file_contents
  - mcp__github__list_commits
  - mcp__zread__search_doc
  - mcp__zread__read_file
  - mcp__zread__get_repo_structure
  - mcp__web-search-prime__web_search_prime
  - WebSearch
  - WebFetch
  - Agent
  - Grep
  - Glob
  - Read
  - Bash
  - mcp__memory__memory_search
  - mcp__memory__memory_store
---

# Web Research Skill v3.0

多源并行调研：本地优先 → 结构化头脑风暴(6角度+灵感) → 并行搜索(sonnet) → 深度追挖 → 综合 → 持久化。

**MANDATORY**: 中文输出。每个发现必须可追溯真实来源（URL + 工具 + Query）。

## 🔴 硬性规则（违反即失败）

| # | 规则 | 验证时机 |
|---|------|---------|
| R1 | **所有标题、摘要、结论必须中文**。专有名词可附英文原文括号，但不得出现纯英文标题或纯英文段落 | Phase 3/4 检查点 |
| R2 | **≥3 主题时必须 spawn 子 agent**。orchestrator 禁止在 ≥3 主题时直接执行搜索查询 | Phase 3 检查点 |
| R3 | **MCP 失败必须自动降级**，禁止静默跳过。每次失败记入降级日志 | Phase 3 降级链 |
| R4 | **Phase 3 完成后必须写入 raw/**，每个 agent 产出一个 `raw/agent-{N}.md` | Phase 3→4 检查点 |
| R5 | **每个主题文件 ≥80 行**，每条要点必须含 [数据/人名/机构/结论/时间] 中至少 2 项 | Phase 4 检查点 |

## 核心原则

| 规则 | 说明 |
|------|------|
| 信息优先级 | skill已有 → 项目已有 → memory已有 → 网络搜索 |
| 工具选择 | 按能力图谱降级链选择，详细参数见 `references/tool-specs.md` |
| MCP可用性 | 通过 `scripts/mcp-probe.sh` 缓存探测结果，模型只读缓存 |
| 保存位置 | `{skill_dir}/data/{YYYYMMDD}-{slug}/` |

## 工具能力图谱

| 能力 | MCP工具（按优先级） | 内置兜底 |
|------|---------------------|---------|
| **搜索** | `searxng_web_search` → `web_search_prime` | `WebSearch` |
| **提取** | `web_url_read` → `webReader` | `WebFetch` |
| **索引** | `ctx_fetch_and_index`(并发提取+索引) → `ctx_index`(内容索引) | — |
| **查询** | `ctx_search`(FTS5片段检索) | — |
| **爬取** | `crawl4ai scrape` → `crawl` → `crawl_site` → `crawl_sitemap` | — |
| **代码** | `github search_repositories` → `search_code` → `get_file_contents` | `zread` |

## 🔴 降级链自动执行协议

工具失败时按以下步骤**自动执行**（禁止静默跳过）：

```
Step 1: 捕获错误，记录降级日志条目
Step 2: 按该能力行的降级链，调用下一优先级工具
Step 3: 下一级仍失败 → 继续沿链直到内置兜底
Step 4: 所有工具均失败 → 标注 [⚠️ 信息缺失: {能力} 全链失败]
Step 5: Phase 3 完成后，将所有降级条目写入 raw/sources-index.md
```

降级日志格式：`[{时间}] {能力} 降级: {原工具} → {原因} → {降级到} → {结果}`

## 深度标准（全局约束）

| 指标 | 标准 | 验证方式 |
|------|------|---------|
| 主题文件行数 | ≥80行（不含元数据头） | Phase 4.4 保存时检查 |
| 信息源数量 | 每个主题≥3个独立来源 | 交叉验证时计数 |
| 要点证据密度 | 每条要点≥2项具体证据（数据/人名/机构/时间/因果链） | Phase 4.2 逐条验证 |
| 信息密度过滤 | 去掉某段后不影响理解→必须删掉 | Phase 4.2 逐段检查 |

**信息密度判据**（每句话必须满足至少一条）：

| ✅ 有信息密度 | ❌ 零信息密度 |
|--------------|--------------|
| 含具体数据（数字、百分比、排名、时间线） | "XX是一个重要的概念/领域" |
| 含具体人名、机构名、产品名 | "XX近年来发展迅速" |
| 含因果关系（A→B→C） | "XX引起了广泛关注" |
| 含对比（X比Y高N%，关键区别是Z） | "XX被认为是最强的/最好的" |

## 流程

```
Phase 0: 快速判定     → 单一事实直接答 / 爬取任务直接爬 / 深度调研走下面
Phase 1: 本地优先     → skill目录 → 项目目录 → memory（命中可短路）
Phase 2: 头脑风暴     → 6角度主题（含💡灵感）→ 🔒确认
Phase 3: 并行搜索     → 读MCP缓存 → 分配agent(sonnet) → 搜索 → 🔴检查点 → 可选追挖
Phase 4: 综合+持久化  → 去重 → 报告(含灵感) → 🔴深度检查点 → 🔒确认 → 拆分保存 + memory
```

---

## Phase 0: 快速判定

| 信号 | 路径 | 输出 |
|------|------|------|
| 单一事实（定价、版本号、API参数） | 搜1次 → 提取1次 | 答案 + 来源URL |
| 爬取任务（"爬取XX文档站"） | crawl4ai crawl_site/crawl | 跳 Phase 4.4 保存 |
| 对比/分析/多角度/方案选型 | 进 Phase 1 | — |

---

## Phase 1: 本地优先

1. **Skill 目录**: `glob("{skill_dir}/data/**/*.md")` + `grep(关键词)`
2. **项目目录**: `glob("{project_root}/docs/**/*.md")` + `grep(关键词)`
3. **Memory**: `mcp__memory__memory_search(query=主题, limit=10)`

命中时展示：匹配路径 + 覆盖范围 + 来源数。
🔒询问：**复用** / **增量更新**（已有+补充） / **重新开始**（全新搜索）。

---

## Phase 2: 搜索策略规划

### 2.1 Query 构造方法

**禁止**百科级 query（`"{topic} 是什么"` / `"{topic} 最新趋势"` / `"{topic} 核心概念"`）。
每个 query 必须包含**具体约束**，让搜索引擎返回有信息密度的结果。

构造规则（每个主题至少覆盖 2 条）：

| 策略 | 模板 | 示例 |
|------|------|------|
| **具体+数据** | `{topic} {具体方面} {数据类型}` | `"Rust web framework benchmark throughput 2024"` |
| **人名/机构+理论** | `{人名} {理论/方法} evidence` | `"Piketty r>g empirical evidence"` |
| **对比+维度** | `{A} vs {B} {具体维度} {year}` | `"Axum vs Actix memory usage production 2025"` |
| **学术+关键词** | `{topic} {术语} paper/study {year}` | `"RAG chunking strategy academic study 2024"` |
| **跨领域** | `{领域A} {方法} applied to {领域B}` | `"game theory open source contribution"` |
| **实战+踩坑** | `{topic} {具体场景} problem/issue/lesson` | `"SQLite high concurrency WAL bottleneck production"` |

**每个主题产出 3 个 query**：1 个中文、1 个英文、1 个跨领域或灵感型。
深度调研覆盖 5-6 个主题；中等调研选 3-4 个。

💡灵感主题：主动搜索反常识、跨领域连接、被忽视的声音。

输出格式：
```
1. **{主题}** [{策略标签}] — {期望找到什么具体信息}
   query-zh: {中文 query}
   query-en: {英文 query}
   query-alt: {跨领域/灵感 query}
```

### 2.2 🔒 确认

展示：主题列表 + 每个主题的 3 个 query + 预估调用数（`主题数 × 3 ≈ 总调用`）。确认后进 Phase 3。

---

## Phase 3: 并行搜索

### 3.1 MCP缓存（零 token）

```
Bash('bash {skill_dir}/scripts/mcp-probe.sh --tool "claude"')  → 缓存命中则跳过
Read('{skill_dir}/data/.mcp-cache-claude.json')                → 获取 available/unavailable 列表
```

### 3.2 模式选择

| ctx 可用 | 模式 | Token 效率 |
|----------|------|-----------|
| ✅ | **索引模式**（推荐）：orchestrator 预索引 → agent 查索引 | ~30KB（省 85%） |
| ❌ | **直搜模式**（降级）：agent 各自搜索提取 | ~200KB |

### 3.3 索引模式（ctx 可用时）

#### 3.3.1 Orchestrator 预搜索

为 Phase 2 的每个主题执行 3 个 query，**orchestrator 自己搜**：
1. 用搜索工具执行 Phase 2 构造的 query
2. 从结果中筛选 URL（每个主题 3-5 个高相关 URL）
3. URL 自动去重
4. **URL 质量过滤**：
   - 🔴 跳过：URL 含 `shop|cart|video|porn|buy|login|signup`
   - 🟢 优先：URL 含 `edu|arxiv|paper|blog|docs|github|medium|dev.to`
   - 🟡 中性：其他 URL 按搜索排名和摘要相关性判断

#### 3.3.2 批量索引（含自动 fallback + 补搜）

```
步骤1: ctx_fetch_and_index(requests=[...], concurrency=5)
  → 记录每个 source 的成功/失败状态

步骤2: 识别失败 URL → failed_urls[]

步骤3: 逐个降级重试
  FOR url IN failed_urls[]:
    web_url_read(url) → 失败 → webReader(url) → 失败 → crawl4ai_scrape(url) → 失败
    → 标记 ⚠️提取失败，记入 failed_final[]

步骤4: 补搜触发
  IF 成功率 < 50%:
    → 每个失败主题: WebSearch("{topic} site:medium.com OR site:dev.to OR site:arxiv.org")
    → 取 top-1 URL → 降级链提取 → ctx_index
    → 报告标注: "⚠️ {N}个来源提取失败，已补充{M}个"

步骤5: 写入 raw/sources-index.md（URL级状态表）
  | URL | 状态 | 工具 | 主题 |

步骤6: 生成手动抓取报告（仅 failed_final[] 非空时）
  IF failed_final[] 非空:
    → 写入 raw/manual-fetch-needed.md，格式：
    ```
    # 🔧 MCP 无法访问的页面 — 需手动获取

    > 共 {N} 个页面 MCP 工具无法提取内容。请手动访问以下 URL，
    > 复制页面内容后粘贴给模型，模型会自动索引并纳入调研。

    | # | URL | 标题/描述 | 所属主题 | 失败原因 |
    |---|-----|----------|---------|---------|
    | 1 | {url} | {搜索结果标题或摘要} | {主题} | {403/timeout/DNS等} |

    ## 使用方法

    1. 点击上表中的 URL，在浏览器中打开
    2. 复制页面正文内容（不需要导航栏/广告/评论区）
    3. 在 Claude Code 中输入：
       ```
       /web-research-continue
       请处理以下手动获取的内容：{粘贴内容}
       来源URL: {对应的URL}
       ```
    4. 模型会自动将内容索引进知识库，继续调研流程
    ```
    → 向用户展示报告摘要：`⚠️ {N} 个页面 MCP 无法访问，已生成 raw/manual-fetch-needed.md，可手动获取后继续`
```

#### 3.3.3 Agent 分配与执行

**🔴 强制规则**：

- **主题数 ≤ 2**：orchestrator 直接执行，不 spawn
- **主题数 ≥ 3**：🔴 **必须** spawn 子 agent

| 主题数 | Agent数 | 模型 |
|--------|---------|------|
| 3-4 | 2 | sonnet |
| 5-6 | 3 | sonnet |

每个 agent 的 prompt 注入：

```
你是调研子 agent。研究主题：{主题列表}

**执行步骤**：
1. 用 ctx_search(queries=["{关键词1}", "{关键词2}"]) 搜索索引
2. 每个主题提取 3-5 条核心要点。🔴 每条要点必须含 [数据/人名/机构/结论/时间] 中至少2项：
   ❌ "XX是一个重要的概念"、"XX值得关注"
   ✅ "Axum 在 TechEmpower benchmark QPS 1.2M 排名前3（来源：techempower.com）"
3. 如果索引中信息不足，用 WebSearch 补充（最多 {N/2} 次）
4. 🔴 信息密度检查：去掉某段后不影响理解→必须删除
5. 标记 💡灵感
6. 按标准格式输出

**约束**：
- 🔴 调用上限: {N} 次
- 🔴 每条结果必须有真实 URL（从 ctx_search 的 source 字段获取）
- 🔴 中文输出（标题、要点、结论必须中文；专有名词可保留英文）
```

#### 3.3.4 收集与写入

1. 收集所有 agent 结果
2. 验证 URL/来源/摘要完整性
3. **🔴 立即写入 raw/**：
   ```
   ## Agent {N} — 主题: {分配主题}
   ### 搜索 Query
   - {query1}
   ### 搜索结果
   - [{标题}]({URL}) — {摘要}
   ### 提取要点
   1. {要点1} [来源: {URL}]
   ### 💡灵感
   - {灵感描述}
   ```
4. **深度检查**（逐主题）：行数≥80？来源≥3？要点≥2项证据？零密度段落已清？
5. 不达标 → 进入 3.5a 二次深挖
6. 筛选 💡灵感 → ≥2 条高价值 → 进入 3.5 追挖

### 3.4 直搜模式（ctx 不可用时的降级）

回退到 v2 流程：spawn agent，每个 agent 自行搜索+提取。读取 `references/agent-prompt.md`。

🔴 直搜模式同样适用 R1（中文输出）、R2（≥3主题必须 spawn）、R4（raw 写入）。

### 3.5 深度追挖

触发：≥2 条高价值灵感。用 1 个 sonnet agent 追挖，预算 5-8 次。

### 3.5a 二次深挖（深度补足机制）

**触发**：3.3.4 深度检查中任一主题不达标。

1. 识别不达标指标（行数不足/来源不足/证据不足）
2. 针对性构造 1 个追加 query：
   - 行数不足 → 更细粒度子主题 query
   - 来源不足 → 换语言/加学术限定
   - 证据不足 → 加 "statistics/benchmark/data/evidence"
3. 用剩余预算执行（最多 3 次调用）
4. 合并到原结果，重新检查深度
5. 仍不达标 → 标注 `⚠️ 深度不足: {具体指标}`，不阻塞

### 3.6 🔒 执行计划确认

仅多 agent 时展示：使用模式、可用工具、每个 agent 的主题+模型+预算。

### 3.7 🔴 Phase 3 检查点（执行纪律验证）

进入 Phase 4 前，**必须**逐项验证：

| 检查项 | 验证内容 | 不通过处理 |
|--------|---------|-----------|
| C1: Raw 写入 | `raw/agent-{N}.md` 存在且非空？ | 立即补写 |
| C2: 语言一致性 | 抽查 agent 输出，标题和结论是否中文？ | 退回改写 |
| C3: Agent 分配 | ≥3 主题时是否使用了子 agent？ | 标注违规，继续 |
| C4: 降级日志 | 所有 MCP 失败已记录？ | 补记录 |
| C5: 降级链完整性 | 每次失败沿降级链执行完毕？ | 补执行 |
| C6: 手动抓取报告 | failed_final 非空时 `raw/manual-fetch-needed.md` 已生成？ | 立即补写 |

### 3.8 预算

| 模式 | 预算分配 |
|------|---------|
| 索引模式 | orchestrator 预搜索≤15次 + agent 查索引≤5次/个 |
| 直搜模式 | 总额 30 次（所有 agent + orchestrator） |

---

## Phase 4: 综合 + 持久化

### 4.1 去重

1. URL 去重（相同 URL 合并）
2. 内容去重（不同 URL 同内容 → `[来源#A,#B]`）
3. 过滤：低相关性、无真实 URL 不纳入
4. 标记格式不完整但内容有价值的结果

### 4.2 综合报告

1. **信息提取**：从 agent 原始输出提取具体事实。去掉某段后不影响理解→删掉
2. **交叉验证**：多源确认 `[✅ A,B确认]`；单源 `[⚠️ 单源: A]`；矛盾 `[⚡ A说X, B说Y]`
3. **可信度排序**：一手数据 > 二手分析 > 观点/评论
4. **知识空白识别**：`⚠️ 知识空白:` 标注搜索无结果的问题
5. **灵感筛选**：💡按意外性排序
6. **撰写报告**

**报告结构**:
1. **背景与目标**（2-3句）
2. **核心发现**（每条 `[来源#N]`，含具体数据，标注可信度）
3. **方案对比**（仅对比型，表格，每格有数据支撑）
4. **💡 意外发现**
5. **⚠️ 知识空白**
6. **结论与建议**（3-5条，每条有来源支撑）
7. **信息源列表**（编号 + URL + 可信度 + 提取状态）

### 4.3 🔴 深度检查点（R5 验证）

展示报告前，**必须**验证：

| 检查项 | 标准 | 不通过处理 |
|--------|------|-----------|
| D1: 主题文件行数 | 每个 ≥80 行 | 补充内容至达标 |
| D2: 要点深度 | 每条含 [数据/人名/机构/结论/时间] ≥2 项 | 退回补充 |
| D3: 语言一致性 | 标题、章节名、结论段落为中文 | 改写不合格部分 |
| D4: 来源完整性 | 每条发现有可追溯 URL | 补充或标注 [⚠️ 来源缺失] |

### 4.4 🔒 确认

展示报告 + 检查点结果。选项：✅确认 / 🔄补充搜索 / ✏️修改 / ❌放弃

### 4.5 持久化

```
{skill_dir}/data/{YYYYMMDD}-{slug}/
├── 研报告.md          # 索引+结论（≤100行）
├── 01-{主题1}.md      # 按主题拆分（每个≥80行，🔴 R5）
├── 02-{主题2}.md
├── sources.md         # 信息源+知识空白+降级日志
└── raw/
    ├── agent-1.md     # 🔴 R4: 必须存在
    ├── agent-2.md
    ├── sources-index.md      # 🔴 R3: 降级日志
    └── manual-fetch-needed.md # MCP 无法访问的页面列表（可选，仅失败时生成）
```

>150行时按主题拆分。Memory: `{主题}研究: {关键发现}。详情: {路径}`, tags: `global,reference`

---

## 异常处理

| 异常 | 处理 |
|------|------|
| MCP 全不可用 | 降级 WebSearch + WebFetch，记入降级日志 |
| 搜索无结果 | 放宽 query → 换工具重试 → 仍无则报告 |
| 提取失败 | 🔴 按降级链自动重试（最多1次），记入降级日志 |
| Agent 超时/API错误 | 收集已完成结果，重试继承剩余预算 |
| AI生成内容（无URL） | 不纳入综合 |
| 预算超支 | 标注 `⚠️ 预算超支: {实际}/{预算}` |
| 目录不存在 | `mkdir -p` 创建 |
| 🔴 中文输出违规 | Phase 3/4 检查点拦截，退回改写 |
| 🔴 Agent 未 spawn | Phase 3 检查点拦截 |
| 🔴 Raw 未写入 | Phase 3 检查点拦截，立即补写 |
| 用户手动提交内容 | 用 `ctx_index(content=用户内容, source="{url}")` 索引 → 告知用户内容已纳入，可继续调研或重新触发 Phase 3 |
