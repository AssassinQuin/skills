# 2026-09-03 Agent 网页搜索开源方案调研

> 方法：GitHub MCP 仓库搜索（`stars:>800 pushed:>2026-06-01`，多角度查询）+ 7 份 README 深读入库（ctx_fetch_and_index）。
> 基线：[2026-08-21 本地/联网 MCP 检索调研](./2026-08-21-local-mcp-retrieval-report.md)——当时结论为 playwright-mcp + open-webSearch 路线，SearXNG 保底，博查/Tavily 付费兜底。
> 本文回答：8 月之后有哪些新的、更好的开源方案。

## 一、全景：2026-08 调研后冒头/爆发的新玩家

| 项目 | Stars | 创建 | 形态 | API Key | 中文 | 一句话 |
|---|---|---|---|---|---|---|
| [mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill) | 61k | 2026-01 | Skill (Python) | 无 | 部分贡献 | 搜"人"不搜"编辑"：并行抓社交平台+互动信号排序 |
| [Jesseovo/last30days-skill-cn](https://github.com/Jesseovo/last30days-skill-cn) | 1.7k | 2026-03 | Skill fork | 可无 | ✅ 8 大 CN 平台 | 上者的中国版：微博/小红书/B站/知乎/抖音/百度/头条/微信 |
| [KnockOutEZ/wigolo](https://github.com/KnockOutEZ/wigolo) | 4.9k | 2026-04 | MCP (TS) | 无 | 未明 | 本地一体化 search+fetch+crawl+cache+research，$0/query |
| [StarTrail-org/PixelRAG](https://github.com/StarTrail-org/PixelRAG) | 9.9k | 2026-05 | CLI + Claude plugin | 无（需 VLM） | 页面无关 | 截图分块+VLM 检索，"Web Screenshots Beat Text for RAG" |
| [anysearch-ai/anysearch](https://github.com/anysearch-ai/anysearch-skill) | 6k(+1.8k) | 2026-04 | Skill + MCP | 免费注册 | 待验证 | 托管统一搜索 API：通用+垂直+批量+全文抽取 |
| [us/crw](https://github.com/us/crw) | 0.9k | 2026-03 | Rust 单二进制 + MCP | 无 | - | Firecrawl 兼容 /scrape /crawl /search，6MB 内存 |
| [virattt/dexter](https://github.com/virattt/dexter) | 27.5k | 2025-10 | 独立 agent | LLM key | - | "Claude Code for 金融研究"：规划/自省/实时行情 |

仍在第一梯队的老玩家（均为 48h 内有 push）：firecrawl 175k、SurfSense 16k（NotebookLM 替代+MCP）、MiroThinker 8.4k（BrowseComp 74.0 深研模型）、exa-mcp-server 5k（付费 API）、mcp-searxng 1.2k（现用）、open-webSearch 1.78k（现用）。

## 二、重点深评

### 1. last30days / last30days-cn —— 中文情报层最大增量 ⭐推荐

**机制**：并行抓取 Reddit/X/YouTube/TikTok/Polymarket/HN + 通用网页 → 按真实互动量（upvotes/likes/真金白银的 Polymarket 赔率）评分 → agent judge 合成一份简报。与"搜索引擎"是互补关系：它搜的是**人的注意力**，不是索引。

**与 8 月结论的关系**：完全是当时 playwright 路线的**产品化升级**——
- Chromium 全家桶（Brave/Edge/Vivaldi/Opera/Arc）cookie 提取 + macOS Keychain / Linux pass 凭证源
- CJK 分词已合入（中文源支持有真实贡献者在做）
- uv 自动配 Python 3.12，`claude plugin marketplace add` 即装
- 有 watchlist deltas（两次运行间的增量）、`--as-of` 历史回看

**CN fork 关键细节**（README 实证）：
- 8 平台：微博/小红书/B站/知乎/抖音/微信/百度API/头条
- **playwright 爬虫模式下，微博/小红书/抖音/B站/知乎可无需 API Key**（README 原文）
- 已知短板：抖音/头条原生接口需签名参数、常被风控 → 失败时降级为公开搜索引擎兜底（只拿链接，无互动数据）
- `LAST30DAYS_DISABLE_BROWSER=1` 可无浏览器降级运行

### 2. wigolo —— 通用搜索层统一者 ⭐值得试点

本地 MCP，10 个工具一套_surface：search / fetch / crawl / extract / cache / find-similar / **research（自主 gather 循环）**。无 key、无云、数据不出 `~/.wigolo/`。

对 8 月报告痛点的针对性设计：
- 自带结果质量评分（junk scorer）
- **失败引擎显式上报、过期缓存显式标记**——正是 SearXNG google 高频挂（searx#6171）时最缺的可观测性
- 可选挂 LLM 做合成（gemini 免费额度够用 / anthropic / groq / ollama keyless）
- `npx wigolo init --agents=claude-code` 一条命令接入

**保留意见**：public beta、61 个 open issue、引擎清单在 docs/tools.md 未入 README、中文覆盖未声明 → 试用期 SearXNG 保底不动。

### 3. PixelRAG —— 解析层的范式转换

arXiv 2606.28344（2026-06）：把网页渲染成截图分块、用 VLM 做检索，表格/布局/上下文不再丢。解决的是 readability/plain-fetch 解析不了的 JS 重页面与结构化内容，**不替代搜索**。

安装即用：`uv tool install pixelrag`（pixelshot CLI）+ `claude plugin marketplace add StarTrail-org/PixelRAG`。3 个月 9.9k star，研究代码出身（论文配套），Apache-2.0。

### 4. anysearch —— 免费托管层（观察）

开源 skill + MCP 客户端，闭源托管后端（anysearch.com）。免费注册拿 `as_sk_` key，`rate_limit: 100`、`quota_limit: 0`。能力面（通用+垂直域+并行批量+全文抽取）接近 Tavily。**定位**：可作博查/Tavily 之前的免费第三保底；闭源后端 + 2026-04 才出生 → 勿重仓依赖（与 codebase-memory-mcp 当年同款顾虑）。

### 5. crw —— Firecrawl 自部署议题的新候选

Rust 单二进制、6MB 内存、Firecrawl 兼容 API + 内置 MCP。8 月排除 Firecrawl 自部署的原因（反爬内核 withheld，#2317）在此不适用——但反爬能力上限也待实测。

### 6. dexter —— 领域 agent（与投研 skills 直接相关）

27.5k star 的自主金融研究 agent：任务规划 + 自省 + 实时行情 + LangSmith LLM-as-judge 评测套件。多 LLM provider。对位本仓库的 earnings-review / investment-research / news-pulse 等 skill——是"换个壳的竞品"，值得拆其评测集与 prompt 设计。

## 三、整合建议（对现有栈）

| 层 | 现状 (2026-08) | 建议 (2026-09) |
|---|---|---|
| 中文社区情报 | 无（只有 baidu/sogou 网页搜索） | **+last30days-cn**（增量最大，playwright 免 key 覆盖微博/知乎/小红书/B站） |
| 通用搜索 | SearXNG + mcp-searxng | 保留保底；**试点 wigolo** 做统一入口（可观测性更好） |
| 登录墙 | playwright-mcp + 持久 profile | 不变；last30days 的 cookie 提取与之同思路 |
| 网页解析 | plain fetch + readability | **+PixelRAG** 补 JS 重/表格密集页 |
| 付费兜底 | 博查(中) / Tavily(英) | 之间插入 anysearch 免费层试试 |
| 爬取自部署 | 已排除 Firecrawl | 若重启议题 → crw |

## 四、风险注记

1. **星标增速异常**：last30days 7 个月 61k、PixelRAG 3 个月 9.9k。功能真实（README 细节扎实、贡献者名单具体），但维护持续性未知。Skill 形态（纯脚本+提示词）可审计性最好，风险可控。
2. last30days-cn 是社区 fork（1.7k），需跟随上游 rebase；抖音/头条风控问题依旧。
3. wigolo public beta；anysearch 闭源后端。
4. 本调研为 README 级实证，未做安装级验证；试点顺序建议：last30days-cn → wigolo → PixelRAG。

## 五、追加：2026-09-03 同题实测（CLI 级）

同一查询「赛力斯 财报」，三路对比：

| 通道 | 前几条结果 | 判定 |
|---|---|---|
| SearXNG（bing，唯一活口） | 百度百科"赛（汉语文字）"、汉典"赛 sài" | ❌ 垃圾（拆字） |
| open-webSearch `--engine baidu` | 赛力斯(601127)财报、集团官网季度年报、"2025年报营收1650.5亿净利59.6亿" | ✅ 精准 |
| open-webSearch `--engine sogou` | 知乎"从Q1财报分析问界毛利率、华为合作分成"、新浪"赛力斯大败局" | ✅ 高质量深度内容 |

英文查询 "claude code web search 2026"（bing+ddg）：返回 Claude 官网/下载页，比 SearXNG 的"Windows 分屏教程"好但不算精准——**英文主力仍是 web-search-prime / 内置 WebSearch**。

源码级补充（GitHub code search）：wigolo 引擎为 `src/search/engines/{bing,brave,mdn,arxiv,...}.ts`，**无中文引擎模块**——其价值在 fetch/crawl/cache/research 工具面，不在中文搜索。

**结论**：中文场景「比 SearXNG 更好的 MCP」= **open-webSearch**（直连爬 baidu/sogou 原生结果，国内 IP 天然友好，绕开了 SearXNG 的两头死穴：国内引擎池废 + 海外引擎被风控）。8 月选型路线正确，落地部署即可。

## 六、追加：多语言实测（USE_PROXY 分路）2026-09-03

挂代理（ClashX 7890）后用 `USE_PROXY=true` 实测 open-webSearch 海外通道（ddg/startpage/brave）：

| 语种 | 查询 | 结果质量 |
|---|---|---|
| 英文 | anthropic claude code release notes | ✅ Claude Code 官方 changelog + GitHub Releases，精准 |
| 日文 | トヨタ 2026年3月期 決算 | ✅ 丰田官方决算说明会/决算要旨 PDF/売上50.68兆円，精准 |
| 德文 | Bundesbank Leitzins 2026 | ✅ 德国央行官方页 + ECB 利率 + Trading Economics，精准 |

**但回归测试**：`USE_PROXY=true` + baidu 引擎 = 空结果（海外 IP 触发百度风控）。配置表实证只有全局 `USE_PROXY`/`PROXY_URL`，**无按引擎/域名 bypass**。

**结论**：USE_PROXY 是全局开关，中文引擎必须直连、海外引擎必须走代理（GFW 反向），二者互斥 → **多语言最优解 = open-webSearch 双实例部署**（同一包，一个直连管中文、一个挂代理管海外），确定性路由靠配置不靠模型猜。
