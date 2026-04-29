# 工具调用规范

> 本文件定义 web-research skill 中每个搜索工具的精确参数、适用场景、调用模式和结果处理规范。

## 通用规则

### Query 构造原则

| 原则 | 说明 | 示例 |
|------|------|------|
| 具体优于模糊 | 描述理想页面而非堆关键词 | "Hearthstone card game MCTS algorithm implementation" > "MCTS" |
| 语言匹配内容 | 搜中文用中文 query，搜英文用英文 query | 中文技术：`"Redis 集群方案对比"`, 英文学术：`"comparison of distributed consensus algorithms"` |
| 主题+限定词 | 核心主题 + 范围/时间/场景限定 | `"React Server Components best practices 2024"` |
| 渐进式搜索 | 先广搜定位 → 再精准搜索 | 第一轮 `"MCTS algorithm"`, 第二轮 `"MCTS UCT implementation Python"` |

### 结果处理流水线

```
搜索 → 过滤(top N) → 评估相关性 → 提取全文(仅高价值) → 结构化笔记
```

- **过滤**：每个 query 取 top 5-10，丢弃明显不相关的
- **评估**：根据标题+摘要判断相关性（高/中/低），只对"高"提取全文
- **提取全文**：每主题最多提取 2-3 个 URL 的全文
- **结构化笔记**：统一格式记录

### 统一输出格式

每个搜索结果必须包含：

```markdown
### 来源 {N}: {标题}
- **URL**: {url}
- **工具**: {工具名}
- **Query**: {使用的搜索 query}
- **相关性**: 高/中/低
- **摘要**: {2-3 句关键发现}
- **全文要点**: {提取的核心内容，仅全文提取时填写}
```

### 工具可用性层级

| 层级 | 工具 | 条件 |
|------|------|------|
| 🟢 始终可用 | exa_web_search, exa_web_fetch, web-search-prime, webfetch, github_search_*, zread_* | 内置工具，无需额外配置 |
| 🟡 需启用 MCP | tavily_search, tavily_extract, tavily_crawl, tavily_map | 需 API key + `docker mcp server enable tavily` |
| 🟡 需启用 MCP | brave_web_search, brave_news_search | 需 API key + `docker mcp server enable brave` |
| 🟢 免费可用 | duckduckgo search, duckduckgo fetch_content | 无需 API key + `docker mcp server enable duckduckgo` |
| 🔴 不推荐 | searxng_web_search | 需自建 SearXNG 实例，复杂度高 |

**降级链**: tavily/brave → duckduckgo → web-search-prime → 仅用 exa

---

## 工具详细规范

### 1. exa_web_search_exa — 语义搜索

**适用**：学术/技术内容、高质量博客、深度分析。语义理解强，返回质量高。

```json
{
  "query": "自然语言描述理想页面的内容，20-70字符",
  "numResults": 10
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| query | ✅ | 20-70字符自然语言 | 描述理想页面内容，非关键词 |
| numResults | — | 10 | 默认即可，不超 20 |

**Query 模式**：

| 场景 | query 示例 |
|------|-----------|
| 学术论文 | `"Monte Carlo Tree Search algorithm for game AI, comparison with minimax"` |
| 技术方案 | `"production-ready WebSocket scaling architecture with Redis pub/sub"` |
| 最佳实践 | `"Python async performance optimization techniques for high throughput"` |

**结果处理**：每条结果含 `title` + `url` + `summary`(highlights)，质量通常较高。

**注意**：query 不超过 70 字符，超出会截断影响质量。

---

### 2. exa_web_fetch_exa — 全文提取

**适用**：从 exa 搜索结果中提取具体页面全文。支持批量。

```json
{
  "urls": ["https://example.com/page1", "https://example.com/page2"],
  "maxCharacters": 5000
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| urls | ✅ | string[], ≤5 个 | 从搜索结果中选取的 URL 列表 |
| maxCharacters | — | 5000 | 每页最大字符数，5000 足够提取要点 |

**调用时机**：仅在 exa 搜索结果中标记为"高相关性"的 URL 才提取。

**批量限制**：单次调用 ≤5 个 URL，超出分批。

---

### 3. tavily_search — AI 优化搜索

**适用**：LLM 优化搜索、AI 研究、生产环境使用。返回 AI 生成的答案摘要，搜索质量高，支持域名过滤和时间范围。

```json
{
  "query": "搜索关键词或自然语言描述，最多400字符/50词",
  "search_depth": "basic",
  "max_results": 5,
  "include_answer": true
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| query | ✅ | 最多 400 字符 / 50 词 | 搜索 query |
| search_depth | — | `"basic"` (1 credit) / `"advanced"` (2 credits) / `"fast"` / `"ultra-fast"` | basic 为默认，advanced 质量更高 |
| max_results | — | 5, 范围 5-20 | 返回结果数量 |
| include_domains | — | string[] | 白名单，仅搜索指定域名 |
| exclude_domains | — | string[] | 黑名单，排除指定域名 |
| time_range | — | `"day"` / `"week"` / `"month"` / `"year"` | 时效性过滤 |
| include_answer | — | boolean | 是否返回 LLM 生成的答案摘要 |
| country | — | string, 如 `"cn"` | 优先返回该国家的结果 |

**Query 模式**：

| 场景 | query 示例 |
|------|-----------|
| 技术调研 | `"Python WebSocket scaling architecture best practices"` |
| 中文内容 | `"Redis 集群方案对比 2024"`（配合 country="cn"） |
| 时效性 | `"React 19 new features"`（配合 time_range="month"） |

**注意**：每月 1000 次免费额度。basic 消耗 1 credit，advanced 消耗 2 credits。`include_answer=true` 可直接获得 AI 总结，适合快速调研。

---

### 4. tavily_extract — 智能内容提取

**适用**：从 URL 智能提取内容，支持分块和重排序。比 webfetch 更适合批量、需要结构化输出的场景。

```json
{
  "urls": ["https://example.com/page1", "https://example.com/page2"],
  "extract_depth": "basic",
  "format": "markdown"
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| urls | ✅ | string[] | 要提取的 URL 列表 |
| extract_depth | — | `"basic"` (10s 超时) / `"advanced"` (30s 超时) | advanced 提取更深但更慢 |
| query | — | string | 可选：用于对提取的 chunks 做重排序 |
| chunks_per_source | — | 1-5, 默认 3 | 每个 URL 返回的最大 chunk 数 |
| format | — | `"markdown"` / `"text"` | 输出格式 |

**调用时机**：tavily_search 结果中标记为"高相关性"的 URL，或需要从特定页面批量提取结构化内容时。

**与 exa_web_fetch 的分工**：

| 来源 | 用哪个工具 |
|------|-----------|
| exa 搜索结果的 URL | `exa_web_fetch_exa`（支持批量，无需 API key） |
| tavily 搜索结果的 URL | `tavily_extract`（支持重排序，结构化更好） |
| 其他工具的 URL | `webfetch` 或 `duckduckgo fetch_content` |

---

### 5. duckduckgo search — 免费搜索

**适用**：免费搜索，无需 API key。适合作为 tavily/brave 不可用时的降级方案，或日常快速搜索。

```json
{
  "query": "搜索关键词或短语",
  "max_results": 10,
  "region": "wt-wt"
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| query | ✅ | 关键词或短语 | 搜索 query |
| max_results | — | 10 | 返回结果数量 |
| region | — | string, 如 `"cn-zh"` / `"us-en"` / `"wt-wt"` | 地区代码，wt-wt 为无地区限制 |

**Query 模式**：

| 场景 | query 示例 |
|------|-----------|
| 中文搜索 | `"炉石传说 AI 算法 实现"`（配合 region="cn-zh"） |
| 英文搜索 | `"MCTS algorithm implementation Python"`（配合 region="us-en"） |
| 广泛搜索 | `"distributed cache comparison"`（配合 region="wt-wt"） |

**注意**：完全免费，无需 API key。速率限制 30 次/分钟。适合作为主力搜索的降级方案。

---

### 6. duckduckgo fetch_content — 免费内容提取

**适用**：免费提取网页内容，无需 API key。支持多种后端自动切换，适合作为 webfetch 的免费替代。

```json
{
  "url": "https://example.com/page",
  "start_index": 0,
  "max_length": 8000,
  "backend": "auto"
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| url | ✅ | 完整 URL | 要提取的页面 |
| start_index | — | 0 | 从页面内容的第几个字符开始 |
| max_length | — | 8000 | 最大提取字符数 |
| backend | — | `"httpx"` / `"curl"` / `"auto"` | auto 会先尝试 httpx，遇到 403/Cloudflare 时自动切换 curl |

**调用时机**：duckduckgo search 或其他搜索结果中需要提取全文，且不想消耗 API 额度时。

**注意**：完全免费，速率限制 20 次/分钟。`backend="auto"` 推荐用于有反爬保护的网站。

---

### 7. brave_web_search — 独立索引搜索

**适用**：拥有独立搜索索引的搜索引擎，隐私优先。搜索结果质量高，适合作为 tavily 的替代方案。

```json
{
  "query": "搜索关键词或自然语言描述，最多400字符/50词",
  "country": "US",
  "search_lang": "en",
  "count": 10
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| query | ✅ | 最多 400 字符 / 50 词 | 搜索 query |
| country | — | string, 默认 `"US"` | 优先返回该国家的结果 |
| search_lang | — | string, 默认 `"en"` | 搜索结果语言 |
| count | — | 1-20, 默认 10 | 返回结果数量 |
| freshness | — | `"pd"` (天) / `"pw"` (周) / `"pm"` (月) / `"py"` (年) | 时效性过滤 |
| result_filter | — | array, 默认 `["web", "query"]` | 结果类型过滤 |

**Query 模式**：

| 场景 | query 示例 |
|------|-----------|
| 技术调研 | `"Rust async runtime comparison tokio async-std"` |
| 时效性 | `"OpenAI GPT-5 release"`（配合 freshness="pm"） |
| 中文内容 | `"大语言模型 微调 方案"`（配合 search_lang="zh"） |

**注意**：需要 API key。拥有独立搜索索引，不依赖 Google/Bing。隐私优先，搜索结果通常质量较高。

---

### 8. web-search-prime — 中文优化搜索（⚠️ 降级使用）

**适用**：⚠️ **仅在 tavily/duckduckgo 均不可用且需要中文内容时使用**。优先使用 tavily(country="cn") 或 duckduckgo search(region="cn-zh")。

```json
{
  "search_query": "中文搜索 query，≤70字符",
  "location": "cn",
  "content_size": "high",
  "search_recency_filter": "noLimit"
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| search_query | ✅ | 中文 query, ≤70字符 | 中文效果最好 |
| location | — | `"cn"` | 固定 cn |
| content_size | — | `"medium"` / `"high"` | high 返回更详细摘要，重要搜索用 high |
| search_recency_filter | — | `"noLimit"` / `"oneMonth"` / `"oneWeek"` | 默认 noLimit |

**规则**：**只在搜中文内容且 tavily/duckduckgo 都不可用时使用**。英文内容用 exa/tavily。

---

### 9. zread_search_doc — GitHub 仓库文档搜索（⚠️ 降级使用）

**适用**：查找特定已知 repo 的文档。⚠️ **仅当已确认具体 repo 名称时使用**，优先用 github_search_code 搜索代码实现。

```json
{
  "repo_name": "owner/repo",
  "query": "搜索关键词或问题",
  "language": "zh"
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| repo_name | ✅ | `"owner/repo"` | 必须是 GitHub repo 格式 |
| query | ✅ | 关键词或自然语言 | 搜索该仓库的文档/issues/commits |
| language | — | `"zh"` / `"en"` | 按用户语言选 |

**前提**：必须知道具体 repo 名称。先通过 `github_search_repositories` 发现项目，再用 `zread` 深入。

---

### 10. github_search_repositories — 项目发现

**适用**：发现与主题相关的开源项目。

```json
{
  "query": "topic:algorithm language:python stars:>100",
  "sort": "stars",
  "order": "desc",
  "perPage": 10
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| query | ✅ | GitHub 搜索语法 | 支持 `topic:`, `language:`, `stars:>,` `user:` 等 |
| sort | — | `"stars"` / `"updated"` / `"forks"` | 推荐 stars |
| order | — | `"desc"` | 默认 desc |
| perPage | — | 10 | 不超 20 |

**Query 语法**：

| 语法 | 示例 | 说明 |
|------|------|------|
| `topic:X` | `topic:mcts` | 按话题 |
| `language:X` | `language:python` | 按语言 |
| `stars:>N` | `stars:>100` | 星标过滤 |
| 组合 | `mcts language:python stars:>50` | 空格 = AND |

---

### 11. github_search_code — 代码模式搜索

**适用**：查找具体代码实现模式、函数用法。

```json
{
  "query": "content:MCSTNode language:python",
  "perPage": 10
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| query | ✅ | GitHub 代码搜索语法 | `content:` 搜代码内容，`language:` 过滤语言 |
| perPage | — | 10 | 不超 20 |

**注意**：需要精确的代码关键词。模糊概念不适合代码搜索。

---

### 12. webfetch — 通用网页提取

**适用**：读取各种搜索结果中的具体页面。作为通用提取工具使用。

```json
{
  "url": "https://example.com/page",
  "format": "markdown",
  "extract_main": true,
  "prefer_llms_txt": "auto",
  "include_metadata": true,
  "save_binary": false
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| url | ✅ | 完整 URL | 要提取的页面 |
| format | — | `"markdown"` | 固定 markdown |
| extract_main | — | `true` | 提取正文 |
| prefer_llms_txt | — | `"auto"` | 优先找 llms.txt |
| include_metadata | — | `true` | 包含元数据 |
| save_binary | — | `false` | 固定 false |
| prompt | — | 自然语言 | 可选：指定提取什么内容 |

**与 exa_web_fetch / tavily_extract / duckduckgo fetch_content 的分工**：

| 来源 | 用哪个工具 |
|------|-----------|
| exa 搜索结果的 URL | `exa_web_fetch_exa`（支持批量，无需 API key） |
| tavily 搜索结果的 URL | `tavily_extract`（支持重排序，结构化更好） |
| duckduckgo / 其他免费场景 | `duckduckgo fetch_content`（免费，支持后端自动切换） |
| 其他所有场景 | `webfetch`（通用，内置工具） |

---

## 工具组合模式

### 模式 A：技术方案调研（英文技术调研）

```
1. exa_web_search(语义query) → top 10 高质量结果
2. tavily_search(关键词query, search_depth="advanced") → 补充结果 + 可选 AI answer
3. exa_web_fetch(top 2-3 URLs) 或 tavily_extract → 深度阅读
4. github_search_repositories(相关项目) → 发现开源实现
5. zread_search_doc(最佳项目) → 读取文档细节
```

**降级**：tavily 不可用 → duckduckgo search + webfetch

### 模式 B：中文内容调研

```
1. tavily_search(中文query, country="cn") 或 duckduckgo search(region="cn-zh") → 中文结果
2. exa_web_search(英文query) → 英文交叉验证
3. webfetch 或 duckduckgo fetch_content(top 2-3 URLs) → 深度阅读
```

**降级**：仅当 tavily/duckduckgo 都不可用时才用 web-search-prime

### 模式 C：代码实现调研

```
1. github_search_repositories(主题+语言) → 发现项目
2. github_search_code(关键函数名) → 找实现模式
3. exa_web_search(技术原理query) → 理论背景
4. webfetch(最佳项目README) → 读文档
```

### 模式 D：综合调研（默认）

```
Agent A: exa(主题A语义) + exa_fetch → 高质量英文
Agent B: tavily/duckduckgo(主题B, 中文/关键词) + tavily_extract/duckduckgo_fetch → 广泛搜索
Agent C: github_repos(主题C) + github_code → 开源实践
```

---

## 错误处理

| 错误 | 处理 |
|------|------|
| exa 超时/限流 | 降级到 tavily 或 duckduckgo |
| tavily 不可用/额度用尽 | 降级到 duckduckgo + exa |
| duckduckgo 限流（30次/分） | 等待或降级到 web-search-prime |
| brave 不可用 | 降级到 tavily 或 exa |
| web-search-prime 返回空 | 换 query 措辞或改用 tavily/duckduckgo |
| zread repo 不存在 | 确认 repo_name 格式，或先通过 github_search 确认 |
| webfetch 页面无法解析 | 记录 URL，标注"无法提取全文"，保留搜索摘要 |
| github_search 无结果 | 放宽搜索条件（去掉 stars/language 过滤） |
