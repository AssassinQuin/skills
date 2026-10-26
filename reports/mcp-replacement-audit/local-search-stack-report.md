# 本地部署开源搜索方案全景调研报告

**日期**：2026-10-26
**数据**：GitHub API 实测（stars / issues / 30d commits / release / Dockerfile）+ 中英文社区交叉验证
**需求**：开源、本地部署、Docker 优先、服务 agent（MCP）场景

---

## 一、总架构：四层本地搜索栈

```
┌─ MCP 接入层 ── mcp-searxng（agent 调用入口）───────────────┐
├─ 搜索层      ── SearXNG 元搜索（核心底座，必装）             │
├─ AI 答案层   ── Morphic（活跃）/ Vane·Perplexica（成熟放缓） │ ← 可选
├─ 抓取层      ── crawl4ai / crw（全文获取增强）               │ ← 可选
└─ 自建索引层  ── Fess（垂直/内网爬取索引）                    │ ← 可选
```

**核心结论：`SearXNG + mcp-searxng` 两个容器就是"本地搜索打底"的最优解**（上轮已论证），本轮把它扩展成完整技术栈。

---

## 二、各层候选多维对比（2026-10-26 实测）

### 2.1 搜索层（元搜索）

| 项目 | ★ | 30d commits | issues | 最近 release | License | Docker | 判定 |
|---|---|---|---|---|---|---|---|
| **searxng/searxng** | 38,847 | **45** | 205 | rolling（无固定版） | AGPL-3.0 | ✅ 官方镜像 | ✅ **必装底座** |
| benbusby/whoogle-search | 11,559 | **0**（2 个月未推） | 1 | v1.2.4 (04-15) | MIT | ✅ | 单引擎代理（仅 Google），功能弱于 SearXNG，放缓 |
| mwmbl/mwmbl | 1,879 | 活跃 | 121 | — | AGPL-3.0 | ✅ | 自建索引实验性，生态小 |
| yacy/yacy_search_server | 4,079 | **0** | 245 | 无 | GPL 系 | ✅ | P2P 去中心化理念独特，但维护停滞 |

**结论**：SearXNG 无争议第一——社区所有 AI 搜索方案（Vane/Morphic/OpenWebUI/searcharvester）都默认以它为后端，中文社区（知乎 5 月调研）同样结论："搜索基础设施/元搜索后端 → SearXNG（被广泛依赖）"。

### 2.2 AI 答案层（Perplexity 开源替代）

| 项目 | ★ | 30d commits | 最近 release | 状态 | Docker |
|---|---|---|---|---|---|
| ItzCrazyKns/**Vane**（原 Perplexica） | **37,742** | **0** | v1.12.2 (2026-04-10) | ⚠️ 停滞半年（最后 push 09-01） | ✅ Dockerfile+compose |
| miurla/**morphic** | 9,199 | **38** | v1.8.0 (10-17) | ✅ 活跃 | ✅ |
| rashadphz/farfalle | 3,542 | — | — | ❌ 2024-09 停更，淘汰 | — |

- **Vane/Perplexica**：功能最成熟（SearXNG 集成 + 本地模型 + 引用答案），社区仍公认为"最全"，但半年无 release。可以装（成熟度换活跃度），锁定当前版本用问题不大
- **Morphic**：generative UI 风格，维护活跃，是当下更有生命力的选择
- 建议：二选一即可，这个层优先级最低——你的 agent（Codex）本身就是答案层，搜索层直连 MCP 已够用

### 2.3 抓取层（搜索之后取全文）

| 项目 | ★ | 30d commits | 最近 release | License | 判定 |
|---|---|---|---|---|---|
| **unclecode/crawl4ai** | **86,274** | 74 | v0.9.5 (10-14) | Apache-2.0 | ✅ **首选**：LLM 专用输出，Docker 一键 |
| firecrawl/firecrawl | 195,382 | 100+ | 持续发版 | AGPL-3.0 | 功能最全但全栈重（多容器），个人本地略过度 |
| fastcrw/crw | 1,176 | 100+ | v0.39.0 (10-21) | **AGPL-3.0** | Rust 单二进制最轻量，自托管抓取替代 |

### 2.4 自建索引层（垂直场景可选）

| 项目 | ★ | 30d commits | 定位 |
|---|---|---|---|
| **codelibs/fess** | 1,142 | **100+**（fess-15.9.0, 10-15） | 企业级自建索引：爬 web/文件/DB，基于 OpenSearch，极活跃 |
| yacy | 4,079 | 0 | P2P 联合索引，停滞 |
| Meilisearch / Typesense | — | — | 仅做自建数据的搜索索引，不爬外网 |

**适用判断**：只有当你需要"固定监控一批网站/内网文档库"时才装 Fess；通用 web 搜索用 SearXNG 即可，不要自建全网索引（mwmbl/YaCy 的路线在个人场景性价比低）。

### 2.5 MCP 接入层

| 项目 | ★ | 30d commits | License | 镜像 |
|---|---|---|---|---|
| **ihor-sokoliuk/mcp-searxng** | 1,329 | **52** | MIT | Docker Hub `isokoliuk/mcp-searxng` |
| Aas-ee/open-webSearch | 1,874 | 7 | Apache-2.0 | ✅ compose，多引擎免 key（不依赖 SearXNG） |
| vakovalskii/searcharvester | 282 | 活跃(09-30) | — | SearXNG + FastAPI + markdown 输出，agent 专用，值得关注 |
| NetLops/SoSearch | 133 | 活跃(10-16) | — | 三引擎 + HTTP API/MCP，早期 |

**结论**：mcp-searxng 保持首选（上轮已验证：issue 率 0.15% 全场最佳）。

---

## 三、推荐落地（Mac + Docker）

### 阶段 1：核心打底（今天就上，2 个容器）

```yaml
# docker-compose.yml
services:
  searxng:
    image: searxng/searxng:latest
    ports: ["8080:8080"]
    volumes: ["./searxng:/etc/searxng"]
    environment: [SEARXNG_BASE_URL=http://localhost:8080/]
    # settings.yml 里启用 json 格式（agent 需要）：formats: [html, json]
  mcp-searxng:
    image: isokoliuk/mcp-searxng:latest
    environment: [SEARXNG_URL=http://searxng:8080/search]
    # MCP 配置：stdio 或 SSE 均支持
```

- Codex MCP 配置指向 mcp-searxng；不用时 `docker compose down` 全部关闭，零残留
- 国内引擎优化：SearXNG settings 里可加 Bing CN/百度等引擎改善中文

### 阶段 2：抓取增强（需要全文时）

```yaml
  crawl4ai:
    image: unclecode/crawl4ai:latest   # LLM-friendly markdown 输出
    ports: ["11235:11235"]
```

### 阶段 3（可选）：AI 答案层

- 选 **Morphic**（活跃）或 **Vane/Perplexica**（功能全），连同一个 SearXNG 实例
- 你已有 Codex agent 答案能力，此层优先级最低

### 混合架构（本地 + 云端）

```
本地 SearXNG（免费无限量打底，隐私，可关）
  + websearch_cn（中文引擎独有价值，保留）
  + web_search_prime（质量兜底/时效过滤，保留）
```

上轮实测已证明 SearXNG 类聚合（DuckDuckGo 通道）在多语言地缘查询上有独家价值；本地化后进一步解决 Brave 429 / Startpage token 失效 / Bing 劣化这些云端通道不稳定问题。

---

## 四、淘汰/风险名单

| 项目 | 原因 |
|---|---|
| farfalle | 2024-09 停更 2 年 |
| whoogle-search | 2 个月未更新，单引擎（仅 Google），被 SearXNG 全面覆盖 |
| YaCy / mwmbl | 理念有价值但个人场景性价比低，维护放缓 |
| firecrawl 自托管（个人场景） | 全栈容器过重；用 crawl4ai 或 crw 替代，或直接用其云 API |

## 五、数据口径

- ★/issues/commits/release：GitHub API 2026-10-26 实测；`100+` 表示达到 per_page 上限
- Vane 与 Perplexica 为同一仓库（API 重定向确认），改名后 30 天 0 commit
- 社区验证：知乎《开源 AI Agent 搜索/检索方案调研报告》(2026-05)、r/LocalLLaMA 2026 讨论
