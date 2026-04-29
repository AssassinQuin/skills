# 工具调用规范

> 本文件定义 web-research skill 可用搜索工具的参数和用法。
> **原则：优先非智普 MCP 服务。** 三链工具体系 + 智普工具降级为最后 fallback。

## 工具优先级总览

```
Tier 1（主力）: SearXNG → Exa → GitHub API → webfetch
Tier 2（fallback）: web-search-prime（智普）, zread（智普）
```

| 服务商 | 工具 | 优先级 | 最佳场景 |
|--------|------|--------|---------|
| **SearXNG** (开源聚合) | `searxng_searxng_web_search`, `searxng_web_url_read` | ⭐ 主力 | 通用搜索、中文搜索、时效性搜索、URL 内容提取 |
| **Exa** (语义搜索) | `exa_web_search_exa`, `exa_web_fetch_exa` | ⭐ 主力 | 英文技术/学术语义搜索、批量全文提取 |
| **GitHub** (官方API) | `github_search_repositories`, `github_search_code`, `github_get_file_contents` | ⭐ 主力 | 开源项目发现、代码模式搜索、仓库文档深挖 |
| **内置** | `webfetch` | 通用兜底 | 页面内容提取、llms.txt 探测 |
| 智普 prime | `web-search-prime_web_search_prime` | ❌ 最后 fallback | 仅当 Tier 1 全部不可用时 |
| 智普 zread | `zread_search_doc`, `zread_read_file` | ❌ 最后 fallback | 仅当 GitHub API 不可用时 |

---

## 通用规则

### Query 构造

| 原则 | 说明 |
|------|------|
| 描述理想页面 | `"production-ready WebSocket scaling with Redis pub/sub"` > `"websocket"` |
| 语言匹配内容 | 中文搜中文 query，英文搜英文 query |
| 渐进式搜索 | 先广搜定位 → 再精准搜索 |
| SearXNG 用关键词 | SearXNG 是传统搜索引擎聚合，用关键词而非自然语言 |
| Exa 用自然语言 | Exa 是语义搜索，用描述性自然语言效果最佳 |

### 结果处理

```
搜索 → 取 top 5-10 → 标记相关性(高/中/低) → 仅"高"提取全文 → 结构化笔记
```

### 统一输出格式

```markdown
### 来源 {N}: {标题}
- **URL**: {url} | **工具**: {工具名} | **Query**: {query}
- **相关性**: 高/中/低
- **摘要**: {2-3句}
- **全文要点**: {仅全文提取时}
```

---

## 链 A：SearXNG 通用搜索（主力，中文/通用/时效性）

适合：中文内容、通用搜索、时效性搜索、新闻、多引擎聚合。

### A1. searxng_searxng_web_search — 聚合搜索

```json
{ "query": "关键词 query", "language": "zh", "pageno": 1,
  "time_range": "month", "safesearch": 0 }
```

| 参数 | 必填 | 说明 |
|------|------|------|
| query | ✅ | 关键词，非自然语言（SearXNG 聚合 Google/Bing/DuckDuckGo 等） |
| language | — | `"zh"` 中文 / `"en"` 英文 / `"all"` 全部（默认） |
| pageno | — | 页码，从 1 开始 |
| time_range | — | `"day"` / `"month"` / `"year"` / 留空不限 |
| safesearch | — | `0` 无过滤 / `1` 适中 / `2` 严格 |

**优势**：一次 query 聚合多个搜索引擎结果，覆盖面广，中文效果好。

### A2. searxng_web_url_read — URL 内容提取

```json
{ "url": "https://...", "startChar": 0, "maxLength": 5000 }
```

| 参数 | 必填 | 说明 |
|------|------|------|
| url | ✅ | 要提取内容的 URL |
| startChar | — | 起始字符位置（分页读取长文时用） |
| maxLength | — | 最大字符数 |
| section | — | 提取指定标题下的内容 |
| readHeadings | — | `true` 只返回标题列表（快速判断内容结构） |

**优势**：支持分段读取、按 section 提取、标题扫描，适合长文深度提取。

### A3. webfetch — 兜底内容提取

```json
{ "url": "https://...", "format": "markdown", "extract_main": true,
  "prefer_llms_txt": "auto", "include_metadata": true, "save_binary": false }
```

| 参数 | 必填 | 说明 |
|------|------|------|
| url | ✅ | 要提取的页面 |
| format | — | `"markdown"` / `"text"` / `"html"` |
| prefer_llms_txt | — | `"auto"` / `"always"` / `"never"`（自动探测 llms.txt） |
| prompt | — | 可选：指定提取什么内容 |

**使用顺序**：A1 搜索 → A2 提取高价值 URL → A3 处理 A2 失败的 URL 或需要 llms.txt 的场景。

---

## 链 B：Exa 语义搜索（英文/技术/学术）

适合：英文技术调研、学术论文、高质量博客、深度分析。

### B1. exa_web_search_exa — 语义搜索

```json
{ "query": "自然语言描述理想页面内容，20-70字符", "numResults": 10 }
```

| 参数 | 必填 | 说明 |
|------|------|------|
| query | ✅ | 20-70 字符自然语言，描述理想页面内容 |
| numResults | — | 默认 10，不超 100 |

**与 SearXNG 区别**：Exa 用自然语言描述（语义匹配），SearXNG 用关键词（聚合多引擎）。

### B2. exa_web_fetch_exa — 批量全文提取

```json
{ "urls": ["https://...", "https://..."], "maxCharacters": 5000 }
```

| 参数 | 必填 | 说明 |
|------|------|------|
| urls | ✅ | URL 数组，批量提取 |
| maxCharacters | — | 每页最大字符，5000 足够提取要点 |

---

## 链 C：GitHub 代码搜索（开源项目/代码实现）

适合：开源项目发现、代码模式搜索、仓库文档阅读。

### C1. github_search_repositories — 项目发现

```json
{ "query": "topic:mcts language:python stars:>100", "sort": "stars", "perPage": 10 }
```

| 参数 | 说明 |
|------|------|
| query | 支持 `topic:` `language:` `stars:>` `user:` 等，空格=AND |
| sort | `"stars"` / `"updated"` / `"forks"` / `"help-wanted-issues"` |

### C2. github_search_code — 代码模式

```json
{ "query": "content:MCTSNode language:python", "perPage": 10 }
```

| 参数 | 说明 |
|------|------|
| query | `content:` 搜索代码内容，`language:` 限定语言，`repo:` 限定仓库 |

### C3. github_get_file_contents — 仓库文档深挖

```json
{ "owner": "user", "repo": "project", "path": "README.md", "ref": "refs/heads/main" }
```

| 参数 | 说明 |
|------|------|
| path | 文件或目录路径，`"/"` 列出根目录 |
| ref | git ref（分支/tag/commit） |

**前提**：先用 C1/C2 发现项目，再用 C3 深挖文档。替代 zread 的完整功能。

### C4. github_list_commits — 仓库活动检查

```json
{ "owner": "user", "repo": "project", "perPage": 5, "sha": "main" }
```

用于判断仓库是否活跃、最近更新内容。

---

## 搜索模式速查

| 场景 | 推荐链 | 工具链 |
|------|--------|--------|
| 中文内容调研 | A | searxng(zh) → searxng_url_read → webfetch |
| 英文技术调研 | B+A | exa_search → exa_fetch → searxng 交叉验证 |
| 代码实现查找 | C+A | github_repos → github_code → github_file_contents |
| 时效性新闻/更新 | A | searxng(time_range=day/week) → searxng_url_read |
| 综合调研（默认） | A+B+C | Agent1: searxng+exa · Agent2: github · Agent3: searxng交叉 |
| 快速单一事实 | A | searxng 搜1-2次，直接返回答案+来源 |
| 仓库文档深挖 | C | github_file_contents（逐目录浏览）→ webfetch 读渲染页面 |

---

## 降级与 Fallback 链

```
搜索降级: SearXNG 不可用 → Exa → web-search-prime（智普，最后手段）
内容提取降级: searxng_url_read → exa_fetch → webfetch → 报告无法提取
仓库文档降级: github_file_contents → webfetch 读 GitHub 页面 → zread（智普，最后手段）
```

| 错误 | 处理 |
|------|------|
| SearXNG 超时/无响应 | 降级到 Exa 搜索 |
| Exa 限流 | 降级到 SearXNG，或 web-search-prime（智普） |
| GitHub search 无结果 | 放宽条件（去掉 stars/language 过滤），或用 SearXNG 搜 `site:github.com` |
| searxng_url_read 解析失败 | 试用 webfetch，标注"无法提取全文" |
| Tier 1 全部不可用 | 使用 web-search-prime + zread（智普 fallback），标注来源工具 |
