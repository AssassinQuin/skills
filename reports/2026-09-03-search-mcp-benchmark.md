# 2026-09-03 搜索 MCP 全维度基准测试报告

> **一句话结论**：**智谱 web-search-prime 综合最强（质量/时效/信息量满分，代价是 token 最贵）**；**open-webSearch 双实例是免费无 key 最优（精准度同样满分、token 最省）**；SearXNG 搜索层实测 5/12 不及格，建议退役搜索、保留读取。
>
> 前序：选型调研见 [2026-09-03-agent-web-search-oss-survey.md](./2026-09-03-agent-web-search-oss-survey.md)；SearXNG 双断层诊断见其中第五节。

## 一、测试环境与方法

- **日期**：2026-09-03
- **网络**：家庭宽带（国内 IP）+ ClashX 代理 `127.0.0.1:7890`
- **SearXNG**：本地 Docker 实例 `localhost:8888`（v2026.4.29），经 API 直连测试（其 MCP 层因 `NO_PROXY` 丢失处于断连状态，与搜索质量无关，另行修复）
- **open-webSearch**：`npx open-websearch@latest` CLI 单发；海外路 `USE_PROXY=true`
- **web-search-prime / 内置 WebSearch**：MCP 工具直调
- **查询集**（6 条，覆盖语种 × 类型）：

| # | 语种 | 类型 | 查询 |
|---|---|---|---|
| Q1 | 中文 | 财经+时效 | 赛力斯 2026 半年报 亏损 |
| Q2 | 中文 | 技术 | Claude Code MCP server 配置教程 |
| Q3 | 英文 | 技术 | MCP model context protocol vs function calling |
| Q4 | 英文 | 时效 | OpenAI latest model release September 2026 |
| Q5 | 日文 | 财经 | トヨタ 2026年3月期 決算 |
| Q6 | 德文 | 财经 | Bundesbank Leitzins Prognose 2026 |

- **评分规则**：2 = 前 4 条全部高度相关；1 = 部分相关或混入明显噪音；0 = 无关/空结果。评分者为本机模型（主观评分，局限见文末）。
- **公平性说明**：open-webSearch 中文路只测中文查询、海外路只测海外查询（分路为其设计形态）；Q1z 为附加测试（中文查询走海外路）。

## 二、意外发现：内置 WebSearch 不是独立基线

实测中内置 WebSearch 的输出自带 `🌐 Z.ai Built-in Tool: web_search_prime` 标识——**Claude Code 的内置 WebSearch 在本环境由智谱 web_search_prime 同一后端驱动**，且在其上追加 LLM 合成摘要、对英文查询自动附加 oneMonth 时效过滤（行为不完全可控）。故不作为独立参赛者，作为 prime 的"重加工版"参与 token 维度对比。

## 三、精准性明细（核心矩阵）

| 查询 | SearXNG | ows-中文路(baidu直连) | ows-海外路(startpage+ddg走代理) | prime(智谱) |
|---|---|---|---|---|
| Q1 中/财经 | **1** 混入 IQTest 垃圾，仅 1 条相关 | **2** 半年报由盈转亏/亏17亿/央广网 | **2**（仅 2 条：东方财富+雪球，均准） | **2** 10 条全中，含具体财务数据 |
| Q2 中/技术 | **0** 返回 Claude 官网导航页×4 | **2** VSCode三件套/CSDN/博客园教程 | — | **2** 官方文档+datawhale+知乎 |
| Q3 英/技术 | **2** 知乎+Reddit+descope | — | **2** 四篇 MCP vs FC 专文 | **2** Reddit/Medium/Portkey 全对题 |
| Q4 英/时效 | **1** 混入 GPT-4 旧页 | — | **2** OpenAI Help Center 官方 Release Notes | **2** 含 2026-09-01 条目 |
| Q5 日/财经 | **1** 丰田官网首页/车型库，非决算 | — | **2** 決算短信 IFRS/決算説明会/投資家情報 | **2** 官方决算+日经+50.68兆円数据 |
| Q6 德/财经 | **0** 返回"西雅图日出日落"×4 | — | **2** Bundesbank 官方+Morningstar+LBBW | **2** 央行官方×2+2026-07 决议 |
| **总分** | **5/12 (42%)** | **4/4 (100%)** | **10/10 (100%)** | **12/12 (100%)** |

**关键观察**：SearXNG 的失败模式是"引擎风控后 bing 独木难支"——bing 对中文分词灾难（Q1/Q2）、对长尾查询返回泛导航页（Q2）、对德文直接错乱（Q6 西雅图日出）。三个可用引擎的全部满贯，差距不在"能不能搜"而在引擎池健康度。

## 四、五维度对比总表

| 维度 | SearXNG | ows 双实例 | prime(智谱) | WebSearch(=prime重加工) |
|---|---|---|---|---|
| **精准性** | ★★ 5/12 | ★★★★★ 满分 | ★★★★★ 满分 | 同 prime |
| **时效性** | ★★ 混入旧页(GPT-4) | ★★★★ 命中当月页 | ★★★★★ 含 9/1、9/2 条目 | ★★★★★ 自动 recency 过滤 |
| **信息量** | ★★★ 标题+snippet | ★★★ 标题+URL+描述(偶缺) | ★★★★★ 每条带 50-100 字摘要 | ★★★★★★ 摘要+合成结论 |
| **token 消耗/查询** | 中（API 原始 22KB，MCP compact 后≈ows） | **★最省 ≈2.3KB（实测 envelope）** | 中高 ≈3-5KB（中文密） | **最贵** 原始+合成双层 |
| **延迟** | 1-3s | CLI 冷启 3-5s；MCP 常驻后预估 1-3s | 2-5s | 2-5s |
| **成本/依赖** | 免费自托管 | 免费、无 key | 智谱免费额度，托管 | 同 prime |
| **可靠性风险** | 引擎池 5/6 风控（结构性）+ MCP 层断连 | 爬虫固有风险（引擎改版/频控） | 供应商依赖 | 同 prime + 行为黑盒 |

### token 维度展开（用户重点）

实测单查询返回体积：ows envelope **2.3KB** vs SearXNG 原始 API **22KB**（字段冗余：category/positions/score/template 等，MCP 层 compact 化后可压到 ows 量级）。prime 返回 10 条含摘要 ≈3-5KB。

按 token 估算（中文 ≈1.2-1.5 字/词符每 token）：
- ows：≈600-900 tokens/查询
- SearXNG(MCP compact)：≈800-1,500
- prime：≈2,000-3,000
- WebSearch：≈2,500-3,500

**但净效率要算总账**：prime 的摘要让 agent 免去二次抓取全文（一次 `fetch-web` 动辄 10-50KB）。若任务需要内容（写报告/下判断），prime 一次调用 = ows「搜索+抓 3 页」的 1/3-1/5 token；若只需要链接（导航/去重/扫标题），ows 最省。**结论：按用途分流，不存在单一最优。**

### 时效性证据

- prime Q4 返回 [OpenAI Model Release Notes](https://help.openai.com/en/articles/9624314-model-release-notes)（含 2026-08-18 更新）、[ChatGPT Release Notes](https://help.openai.com/en/articles/6825453-chatgpt-release-notes)（**2026-09-01** 条目）、[GPT-5.6 官方发布页](https://openai.com/index/gpt-5-6/)、以及 2026-09-02 的 Meta Muse Spark 1.3 线索
- prime Q1 返回华尔街见闻对赛力斯半年报的摘要（亏 17.17 亿/营收 574.93 亿/Q2 亏 24.71 亿/减值 18.62 亿）——直接可用的事实密度
- SearXNG Q4 同题混入 `GPT-4 | OpenAI` 旧页——bing 缓存倾向

## 五、结论与部署建议

**排名**：
1. **prime（智谱）**：质量+时效+信息量全满分，主力不动摇。重任务（投研/写报告）首选。
2. **open-webSearch 双实例**：精准度同满分、token 最省、免费无 key。轻任务（要链接/高频调用）与免费兜底。
3. **SearXNG**：搜索层退役；修复 `NO_PROXY` 后保留 `web_url_read`+FlareSolverr 读取层（CF 过盾独有价值）。
4. 内置 WebSearch：与 prime 同源，多用一层合成摘要，token 最贵——让位给 prime 直调。

**部署**（退出 Claude Code 后执行）：

```bash
jq '.mcpServers.searxng.env.NO_PROXY = "localhost,127.0.0.1" |
    .mcpServers.searxng.env.FLARESOLVERR_URL = "http://localhost:8191" |
    .mcpServers["websearch-cn"] = {
      type: "stdio", command: "npx", args: ["-y", "open-websearch@latest"],
      env: { MODE: "stdio", DEFAULT_SEARCH_ENGINE: "baidu",
             ALLOWED_SEARCH_ENGINES: "baidu,sogou,csdn,juejin,linuxdo" }
    } |
    .mcpServers["websearch-global"] = {
      type: "stdio", command: "npx", args: ["-y", "open-websearch@latest"],
      env: { MODE: "stdio", DEFAULT_SEARCH_ENGINE: "startpage",
             ALLOWED_SEARCH_ENGINES: "startpage,duckduckgo,brave,bing,hackernews",
             USE_PROXY: "true", PROXY_URL: "http://127.0.0.1:7890" }
    }' ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
```

## 七、追加：知乎 lane 实测（2026-09-03 下午）

新增两台本地 skill 参赛（均为 repo 内 Python 脚本，知乎体查询）：

| 引擎 | ZQ1 赛力斯半年报 | ZQ2 Claude Code MCP | 时效 | 返回体积/5条 |
|---|---|---|---|---|
| **zhihu-search**（开放平台 API） | **2** 五条全是高赞深度回答，带赞数+作者+完整摘要 | **2** 实测教程/源码分析全对题 | edit_time 至 8 月底 | **10-14KB ⚠️最大** |
| **global-search**（多源聚合） | **2** 新闻+知乎混合，**含今日（9/3）新浪深度稿** | **2** 知乎干货密集 | **今日** ★最强 | 11-23KB ⚠️最大 |
| ows-cn（sogou 直连） | **2** 4/4 相关（含界面新闻/BT 财报） | **1-2** 大部分相关 | 好 | 3.2-3.4KB ★最省 |
| prime（智谱） | **2** 但知乎内容停留在"问题页+通稿摘要"，深度最浅、重复高 | **2** | 好 | 3-5KB |

**知乎场景结论**：
1. **要深度观点 → zhihu-search**：独有 `vote_up_count` 质量信号（57/41/22 赞排序）+ 回答级完整摘要（毛利率拆解、现金流分析、华为分成模式），这是爬虫和通用搜索都拿不到的。**代价：摘要极长，5 条 10-14KB ≈ 5-8k tokens——高频使用建议 `count:2-3`**。
2. **要今日新闻+知乎混合 → global-search**：唯一返回当日文章的选手（9/3 新浪稿）。**时效显式开关：`search_db:"realtime"`**（实测返回 9/3 今日+8 月末混合；`all`=全库，`static`=静态库）。
3. **要省 token 只要链接 → ows-cn(sogou)**：知乎内容照样能搜到，envelope 仅 3.2KB。
4. prime 搜知乎内容能中题但深度最浅（同一句 36氪通稿开头重复 3 次）。

**依赖关系澄清（能否合并/删除？）**——源码实证：两个 skill 调的是知乎开放平台**两个不同的 API**，不是参数差异：
- `zhihu-search` → `/api/v1/content/zhihu_search`（**站内**搜索：回答级、带 vote_up_count/comment_count）
- `global-search` → `/api/v1/content/global_search`（**全网**搜索：新闻+全网、search_db=all/realtime/static）
- 合并假设已证伪：① `filter: host=="zhihu.com"` 试图用 global_search 滤纯知乎 → **0 结果**；② global_search 输出无赞数字段
- **结论：两者不可互相替代，均保留**。可选优化：两脚本约 90% 代码同构（同 auth/模板/输出 schema），可合并为单脚本 + `scope:site|web` 参数——但按"不动能用的东西"原则，仅在想减少 skill 数量时再做。

**追加：官方 MCP (SSE) 实测**（2026-09-03，curl 完整握手验证通过）：

知乎开放平台提供原生 MCP over SSE：`https://developer.zhihu.com/api/mcp/zhihu_search/v1/sse`（Bearer 鉴权，用 .env 的 `zhihu_token`）。实测 initialize→tools/call 全流程 202 + SSE 异步回包，返回与站内脚本同一批内容，但**信号字段不同**：

| 字段 | 脚本 zhihu-search | 官方 MCP |
|---|---|---|
| 质量信号 | `vote_up_count`（赞数 57/41/22）、`comment_count` | `authority_level`（权威等级）、`author_badge_text`（知势榜答主）、`ranking_score` |
| 内容类型 | 无 | `content_type`（Answer/Article） |
| 形态 | JSON（可 shell 预裁剪再进 context） | XML 原文直进 context |
| 接入 | 需知道脚本路径，shell 调用 | 任何 MCP client 原生发现（含 opencode 子代理） |
| 连接 | 无状态子进程 | SSE 长连接（需维护） |

**建议**：加官方 MCP 为知乎站内主力（信号更官方、多 client 免配置）；global-search（全网）无 MCP 版保留脚本；zhihu-search 脚本试运行两周——若 authority_level 信号够用则删，不够（仍依赖赞数）则留作按需补充。

**追加：开放平台全工具盘点**（2026-09-03 SSE 端点扫描 + 端到端实测）：

按 `/api/mcp/<tool>/v1/sse` 命名规律探测 12 个候选名，**仅 3 个真实存在且鉴权通过**（direct_answer/zhida/knowledge_base/rag/question/answer/article/user_profile 等均 404，站内 keywords 宣传的"直答/知识库/RAG"未以独立工具形态开放）：

| MCP 工具 | 实测结果 | 独有价值 |
|---|---|---|
| `zhihu_search` | ✅ 站内深度回答，authority_level/知势榜徽章/ranking_score | 深度观点+权威信号 |
| `global_search` | ✅ **MCP 版存在（推翻"全网无 MCP"旧结论）**，返回每经网新闻+ranking_score | 今日新闻（脚本版另有 search_db:realtime 开关） |
| `hot_list` | ✅ 30 条热榜，rank/title/url/缩略图/**200 字摘要**，免参数 | **新能力**：事件/情绪/选题雷达 |

**安装建议：三个全装**——同一 token 免费、每个 server 仅 1 个工具（context 开销极小）、三条 SSE 连接可接受。hot_list 对接场景：news-pulse（股价异动的事件面输入）、story-short-scan（知乎热榜=社情题材雷达）。两个本地 skill 脚本（zhihu-search/global-search）保留：benchmark 采集器依赖 + 赞数信号 fallback，生产流量切 MCP。

## 八、标准测试流程（固化）

基准已固化为可复用脚本：**`scripts/search-mcp-benchmark.sh`**（已实测验证）。

```bash
./scripts/search-mcp-benchmark.sh                     # 内置标准查询集（8 条：cn×2 glb×4 zhihu×2）
./scripts/search-mcp-benchmark.sh my-queries.txt      # 自定义查询集（每行 "lane|query"）
BENCH_LANES="zhihu,cn" ./scripts/search-mcp-benchmark.sh   # 只跑指定 lane
```

- **lane 路由**：`cn`=searxng+ows-cn+gsearch；`glb`=searxng+ows-glb；`zhihu`=zhihu+gsearch+ows-cn(sogou)；`any`=全引擎
- **采集维度**：top-4 标题、耗时、返回字节数（token 实测基础）、失败显式 `[FAIL]` 记录
- **评分**：脚本不评分（相关性判断是语言任务才交给模型）——输出到 `reports/benchmarks/bench-<ts>.md`，评审按 0/1/2 规则填分
- **MCP 类引擎**（prime/WebSearch）shell 无法直调：报告自动生成补测清单，在会话内用同一查询集调用后填分
- **环境变量**：`PROXY_URL`（默认 7890）、`SEARXNG_URL`（默认 localhost:8888）、`BENCH_LANES`

复测建议节奏：引擎池变动 / 换代理节点 / 月度例行。查询集演进时保持旧查询不删（纵向可比），只追加。

## 九、最终 MCP 配置清单（2026-09-03 定稿）

基于全部实测结论的增删决定（当前用户级 10 个 MCP：prime/zread/searxng/codebase-memory/context7/github/context-mode/zai/web-reader/memory）：

| 动作 | MCP | 理由 |
|---|---|---|
| **➕ 安装 ×5** | `websearch-cn`、`websearch-global` | open-webSearch 双实例：中文直连 + 海外走代理，精准满分+token 最省+免费无 key |
| | `zhihu`、`zhihu-global`、`zhihu-hot` | 知乎官方三件套：站内深度（权威信号）/ 全网新闻 / 热榜雷达（news-pulse+选题场景） |
| **🔧 修复保留 ×1** | `searxng` | 补回 NO_PROXY+FLARESOLVERR_URL，**只作 web_url_read 读取层+CF 过盾**，搜索层退役（5/12 不及格） |
| **➖ 删除 ×0** | — | 当前配置无冗余搜索 MCP（one-search-mcp 早已移除）；"删"体现在 SearXNG 搜索层退役而非删服务；内置 WebSearch 非配置项，仅使用策略让位 prime |
| **✋ 不动 ×9** | prime/web-reader/zread/github/context7/codebase-memory/context-mode/zai/memory | 非搜索类或已是最优（prime 基准满分主力；web-reader 被墙域名读取） |

装后路由全景：**重任务要内容→prime；中文链接/高频→websearch-cn；海外多语言→websearch-global 或 prime；知乎深度→zhihu；今日新闻→zhihu-global(realtime)；热榜/选题→zhihu-hot；CF 盾读取→searxng web_url_read；登录墙→playwright-mcp**。

## 十、局限性（必读）

1. 每格单次运行，无重复试验——爬虫类引擎（ows/SearXNG）结果有波动性；本次 ows 表现好不保证日常 100%，频控风险随使用量上升。
2. 评分为单一评审（模型）主观 0-2 分，非人工标注。
3. 查询集仅 6 条，偏财经/技术；未覆盖小语种长尾、购物、本地意图等。
4. prime 返回的 content 为搜索引擎摘要，内容以源页为准（本报告引用的财务数字来自搜索摘要，未逐一回查原文）。
5. ows 延迟含 npx 冷启动（CLI 形态）；MCP stdio 常驻形态的稳态延迟未测。
6. 内置 WebSearch 的 auto-recency 行为基于本次两条例观察。
