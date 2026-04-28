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

### 3. searxng_web_search — 多源聚合搜索

**适用**：广泛搜索、多源对比、新闻/博客/论坛。结果来源多样。

```json
{
  "query": "搜索关键词或短语",
  "categories": ["general"],
  "language": "all",
  "result_count": 10,
  "result_format": "text"
}
```

**参数规范**：

| 参数 | 必填 | 值 | 说明 |
|------|------|-----|------|
| query | ✅ | 关键词 query | 支持布尔运算 `AND OR`，短语 `"exact match"` |
| categories | — | `["general"]` / `["news"]` / `["images"]` | 默认 general |
| language | — | `"all"` / `"en"` / `"zh"` | 按目标内容语言选 |
| result_count | — | 10 | 默认 10，不超 20 |
| result_format | ✅ | `"text"` | 固定用 text |
| time_range | — | `"day"` / `"week"` / `"month"` / `"year"` | 时效性搜索时使用 |

**Query 模式**：

| 场景 | query 示例 |
|------|-----------|
| 广泛调研 | `"MCTS algorithm implementation comparison"` |
| 中文内容 | `"炉石传说 AI 算法 实现 方案"` |
| 时效性 | `"React 19 new features 2025"`（配合 time_range="month"）|

**备选场景**：当 exa 结果不足时，用 searxng 补充搜索。

---

### 4. web-search-prime — 中文优化搜索（⚠️ 降级使用）

**适用**：⚠️ **仅在 searxng 不可用且需要中文内容时使用**。优先使用 searxng(language=zh)。

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

**规则**：**只在搜中文内容时使用**。英文内容用 exa/searxng。

---

### 5. zread_search_doc — GitHub 仓库文档搜索（⚠️ 降级使用）

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

### 6. github_search_repositories — 项目发现

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

### 7. github_search_code — 代码模式搜索

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

### 8. webfetch — 通用网页提取

**适用**：读取 searxng/web-search-prime 搜索结果中的具体页面。

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

**与 exa_web_fetch 的分工**：

| 来源 | 用哪个工具 |
|------|-----------|
| exa 搜索结果的 URL | `exa_web_fetch_exa`（支持批量） |
| searxng/web-search-prime 的 URL | `webfetch`（单页面） |

---

## 工具组合模式

### 模式 A：技术方案调研

```
1. exa_web_search(语义query) → top 10 高质量结果
2. searxng_web_search(关键词query) → 补充多样化结果
3. exa_web_fetch(top 2-3 URLs) → 深度阅读
4. github_search_repositories(相关项目) → 发现开源实现
5. zread_search_doc(最佳项目) → 读取文档细节
```

### 模式 B：中文内容调研

```
1. searxng_web_search(中文query, language=zh) → 中文结果
2. exa_web_search(英文query) → 英文交叉验证
3. webfetch(top 2-3 URLs) → 深度阅读
⚠️ 仅当 searxng 不可用时降级到 web-search-prime
```

### 模式 C：代码实现调研

```
1. github_search_repositories(主题+语言) → 发现项目
2. github_search_code(关键函数名) → 找实现模式
3. exa_web_search(技术原理 query) → 理论背景
4. webfetch(最佳项目README) → 读文档
```

### 模式 D：综合调研（默认）

```
Agent A: exa(主题A语义) + exa_fetch → 高质量英文
Agent B: searxng(主题B, language=zh/en) + webfetch → 广泛搜索
Agent C: github_repos(主题C) + github_code → 开源实践
```

---

## 错误处理

| 错误 | 处理 |
|------|------|
| exa 超时/限流 | 降级到 searxng，结果质量略低但可用 |
| searxng 连接失败 | 降级到 exa + web-search-prime |
| web-search-prime 返回空 | 换 query 措辞或改用 searxng |
| zread repo 不存在 | 确认 repo_name 格式，或先通过 github_search 确认 |
| webfetch 页面无法解析 | 记录 URL，标注"无法提取全文"，保留搜索摘要 |
| github_search 无结果 | 放宽搜索条件（去掉 stars/language 过滤） |
