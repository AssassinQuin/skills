---
name: web-research
description: >
  多源并行调研。local-first → 6角度头脑风暴 → 并行agent搜索(sonnet) → 灵感追挖 → 综合报告。
  触发词：调研、研究、搜索研究、web research、对比分析、方案选型、文献、literature review、deep dive。
  Output: {skill_dir}/data/{date}-{slug}/
user-invocable: true
metadata:
  version: "2.1"
allowed-tools:
  - mcp__searxng__searxng_web_search
  - mcp__searxng__web_url_read
  - mcp__crawl4ai-mcp__scrape
  - mcp__crawl4ai-mcp__crawl
  - mcp__crawl4ai-mcp__crawl_site
  - mcp__crawl4ai-mcp__crawl_sitemap
  - mcp__web_reader__webReader
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

# Web Research Skill

多源并行调研：本地优先 → 结构化头脑风暴(6角度+灵感) → 并行搜索(sonnet) → 深度追挖 → 综合 → 持久化。

**MANDATORY**: 中文输出。每个发现必须可追溯真实来源（URL + 工具 + Query）。

## 核心原则

| 规则 | 说明 |
|------|------|
| 信息优先级 | skill已有 → 项目已有 → memory已有 → 网络搜索 |
| 工具选择 | 按能力图谱降级链选择，详细参数见 `references/tool-specs.md` |
| MCP可用性 | 运行时降级（工具失败沿降级链切换），可选手动 `scripts/mcp-probe.sh` 诊断 |
| 保存位置 | `{skill_dir}/data/{YYYYMMDD}-{slug}/` |

## 工具能力图谱

| 能力 | MCP工具（按优先级） | 内置兜底 |
|------|---------------------|---------|
| **搜索** | `searxng_web_search` → `web_search_prime` | `WebSearch` |
| **提取** | `web_url_read` → `webReader` | `WebFetch` |
| **爬取** | `crawl4ai scrape` → `crawl` → `crawl_site` → `crawl_sitemap` | — |
| **代码** | `github search_repositories` → `search_code` → `get_file_contents` | `zread` |

工具不可用时沿行内降级链切换。`WebSearch`/`WebFetch` 始终可用。

## 流程

```
Phase 0: 快速判定     → 单一事实直接答 / 爬取任务直接爬 / 深度调研走下面
Phase 1: 本地优先     → skill目录 → 项目目录 → memory（命中可短路）
Phase 2: 头脑风暴     → 6角度主题（含💡灵感）→ 🔒确认
Phase 3: 并行搜索     → 读MCP缓存 → 分配agent(sonnet) → 搜索 → 💡筛选灵感 → 可选追挖
Phase 4: 综合+持久化  → 去重 → 报告(含灵感) → 🔒确认 → 拆分保存 + memory
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

## Phase 2: 结构化头脑风暴

### 2.1 六角度搜索主题生成

深度调研覆盖全部6角度；中等调研选3-4个最相关角度。

| 角度 | 引导问题 | query 模式 |
|------|---------|-----------|
| **定义/概念** | 主流定义和核心术语？ | `"{topic} 是什么 核心概念"` |
| **方案/对比** | 主流方案及优缺点？ | `"{topic} vs {alt} 对比 优缺点"` |
| **实战经验** | 实践者踩过什么坑？ | `"{topic} 最佳实践 踩坑 经验"` |
| **工具/生态** | 现成工具/库/框架？ | `"{topic} 工具 框架 推荐 {year}"` |
| **前沿/趋势** | 最近6个月新进展？ | `"{topic} 最新 趋势 {year}"` |
| **💡灵感** | 反常识/跨领域/被忽视的发现？ | `"{topic} counterintuitive unexpected"` |

💡灵感角度：在其他5个角度搜索中主动捕捉意外发现（反常识、跨领域、被忽视声音、打破认知数据、未解问题），Phase 4独立成章。

输出格式：
```
1. **{主题}** [角度] — {为什么相关，期望找到什么}
   query: {2-3个具体query}
```

### 2.2 🔒 确认

展示：主题列表 + 预估调用数（`主题数 × 3 ≈ 总调用`）。确认后进 Phase 3。

---

## Phase 3: 并行搜索

### 3.1 MCP 可用性（运行时降级）

子 agent 直接尝试调用 MCP 工具，失败时沿 body 内降级链切换。仅在已知某 MCP 不可用时（如手动 `scripts/mcp-probe.sh` 确认），在 prompt 注入 `[MCP 状态] {tool}=down`。

### 3.2 Agent 分配

| 主题数 | Agent数 | 模型 |
|--------|---------|------|
| 1-2 | 0（orchestrator 直接搜） | 当前模型 |
| 3 | 2 | sonnet |
| 4-6 | 3（代码维度独立） | sonnet |

### 3.3 Prompt 注入

读取 `references/agent-prompt.md`，替换占位符后内联到每个 agent：

| 占位符 | 替换为 |
|--------|--------|
| `{研究主题}` | Phase 2 中该 agent 负责的主题 |
| `{可用工具}` | 缓存中可用的工具 + 调用参数 |
| `{N}` | `(30 - 探测调用) / agent数`，重试用剩余预算 |

### 3.4 🔒 执行计划确认

仅多 agent 时展示，含：可用/不可用工具、每个 agent 的主题+模型+预算。确认后并行 spawn。

### 3.5 执行流程

1. 读 MCP 缓存，按 3.2 分配 agent
2. 展示执行计划 → 用户确认
3. 读取 `references/agent-prompt.md`，替换占位符，spawn 所有 agent（`model: "sonnet"`）
4. 收集结果：验证 URL/工具/Query/摘要完整性
5. 写入 `{slug}/raw/agent-{1,2,3}.md`
6. 筛选 💡灵感 → 若 ≥2 条高价值 → 进入 3.6 追挖

### 3.6 深度追挖（可选）

触发：≥2 条高价值灵感。用 1 个 sonnet agent 追挖，预算 5-8 次。不足 5 次则跳过并标注。

### 3.7 预算

**总额 30 次**（所有 agent + orchestrator）。每个 agent 硬编码上限 `{N}` 次。
重试继承剩余预算（`原预算 - 已用`）。超限标注 `⚠️ 预算超支: {实际}/{预算}`。

---

## Phase 4: 综合 + 持久化

### 4.1 去重

1. URL 去重（相同 URL 合并）
2. 内容去重（不同 URL 同内容 → 标注 `[来源#A,#B]`）
3. 过滤：低相关性、无真实 URL（AI 生成内容）不纳入
4. 标记格式不完整但内容有价值的结果

### 4.2 综合报告

**步骤**:
1. 按主题归类 agent 原始输出
2. 每个主题提取 3-5 个核心发现，标注来源编号
3. 跨主题交叉验证 → `[来源A,B验证]`
4. 筛选 💡灵感，按意外性排序
5. 撰写报告

**报告结构**:
1. **背景与目标**（2-3句）
2. **核心发现**（每条 `[来源#N]`，含具体数据）
3. **方案对比**（仅对比型，表格）
4. **💡 意外发现**（按类型：反常识/跨领域/被忽视/打破认知/未解问题）
5. **结论与建议**（3-5条）
6. **信息源列表**（编号 + URL）

规则：中文 | 交叉验证 | 知识空白标 ⚠️ | 不编造

### 4.3 🔒 确认

展示报告。选项：✅确认 / 🔄补充搜索 / ✏️修改 / ❌放弃

### 4.4 持久化

```
{skill_dir}/data/{YYYYMMDD}-{slug}/
├── 研报告.md          # 索引+结论（≤100行）
├── 01-{主题1}.md      # 按主题拆分（每个≤100行）
├── 02-{主题2}.md
├── sources.md         # 信息源+知识空白
└── raw/
    ├── agent-1.md
    ├── agent-2.md
    └── sources-index.md
```

>150行时按主题拆分。Memory: `{主题}研究: {关键发现}。详情: {路径}`, tags: `global,reference`

---

## 异常处理

| 异常 | 处理 |
|------|------|
| MCP 全不可用 | 降级 WebSearch + WebFetch |
| 搜索无结果 | 放宽 query → 换工具重试 → 仍无则报告 |
| 提取失败 | 沿降级链切换工具（最多1次重试） |
| Agent 超时/API错误 | 收集已完成结果，重试继承剩余预算 |
| AI生成内容（无URL） | 不纳入综合 |
| 预算超支 | 报告标注 `⚠️ 预算超支: {实际}/{预算}` |
| 目录不存在 | `mkdir -p` 创建 |
