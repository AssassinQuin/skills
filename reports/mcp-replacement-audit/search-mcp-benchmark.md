# 当前搜索 MCP 实测评估报告

**日期**：2026-10-26
**方法**：两个真实查询（①2026 黄金储备前 50 国家变化 ②俄乌 / 美伊以战争最新局势）× 多通道 × 多语言交叉实测
**测试查询数**：15 次（含 2 次失败通道复验）

---

## 一、当前搜索通道清单

| 通道 | 类型 | 能力 |
|---|---|---|
| **web_search_prime** | MCP 聚合搜索 | cn/us 双区定位、oneDay/oneWeek/oneMonth/oneYear 时效过滤、摘要生成 |
| **websearch_cn** | MCP 多引擎搜索 | 10 引擎：Baidu/Sogou/Bing/Startpage/DuckDuckGo/Brave/HackerNews/CSDN/掘金/LinuxDo |
| **web_reader** | MCP 正文抓取 | URL→全文 Markdown，配合搜索做二段式 |
| context7 | MCP 文档搜索 | 仅编程库文档，不参与通用搜索 |
| playwright | 浏览器 | 手工兜底 |
| global-search / zhihu-search（skill） | CLI | ⚠️ `ZHIHU_ACCESS_SECRET` 未配置，当前不可用 |

---

## 二、实测结果矩阵

### 查询 1：黄金储备前 50 国家 2026 年变化

| 通道×参数 | 结果 | 证据 |
|---|---|---|
| web_search_prime cn + 1Y | ✅ **优** | WGC 中文站（3-03 韩央行购金 ETF）、21 财经（5-07 中国 7464 万盎司 16 个月新高）、财经杂志专题；日期全部标注 |
| web_search_prime us + 1Y | ✅ **极优** | **直接命中 gold.org 官方数据页 + Wikipedia 摘要内嵌 Top50 表（Q2/Aug 2026）+ visualcapitalist 8 月排名**；摘要自带数字 |
| websearch_cn Bing 中文 | ❌ **完全跑偏** | 返回"2026 年节假日/两会/日历"，语义检索对专业财经长尾查询失效 |
| websearch_cn DuckDuckGo 英文 | ✅ 良 | gold.org 官方页 + 4 个 2026 排名站，但多为 SEO 内容站（davemanuel/statranker），权威性中等 |
| websearch_cn Brave | ❌ **429 限流** | 通道不可用 |

**工作流验证**：web_search_prime(us) 定位 → web_reader 抓 Wikipedia → **完整 Top50 表（Q2/August 2026）拿到手**，含 2026 新增情报：荷兰央行 3-8 月从美国/加拿大运回 86 吨至伦敦；俄罗斯 NWF 黄金已从 405.7 吨卖至仅剩 173.1 吨（2025-11 起内部市场抛售）。

### 查询 2：战争最新局势（6 种语言）

| 通道×语言 | 结果 | 关键信源与时点 |
|---|---|---|
| web_search_prime us + 1W（俄乌英） | ✅ **极优** | ISW 每日战报 10-21→10-25（**4 小时前**），NPR 10-23，NZZ 前线地图 10-22；时效过滤真实生效、摘要带相对时间 |
| web_search_prime us + 1W（中东英） | ❌ **空结果** | 过滤条件过严时返回空数组，无降级 |
| websearch_cn DuckDuckGo 英（俄乌） | ✅ 优 | RBC-Ukraine 10-25、russiamatters 10-21、ISW 10-11/20 |
| websearch_cn DuckDuckGo **俄语** | ✅ 优 | ru.wikipedia 10 月编年史、BBC 俄语、**俄方军事博主 podolyaka 26.10**、telegraf 第 1706 天汇总 |
| websearch_cn DuckDuckGo 英（中东） | ✅ 优 | Times of Israel 10-25（美以起草恢复打击计划）、JPost 10-23（伊朗海底电缆计划）、globalsecurity 第 239 天 |
| websearch_cn DuckDuckGo **希伯来语** | ✅ 优 | ynet/Maariv 伊朗战争专题、newsnow.co.il（内塔尼亚胡"灭国警告"）、**伊朗 Tasnim 通讯社希伯来语频道 10-23** |
| websearch_cn DuckDuckGo **波斯语** | ✅ 优 | BBC Persian 10-21、fa.wikipedia 开战条目（1404/9 اسفند 开战）、**伊朗本土 eghtesadnews（以 10-10 曾备袭被 Trump 叫停的内幕）** |
| websearch_cn Bing 中文（俄乌） | ❌ **完全跑偏** | 返回"俄 字典/百度百科/汉典" |
| websearch_cn Bing 中文（中东） | ❌ 大部分跑偏 | 百科词条 + 泛话题页；仅知乎 3 月旧帖略有信息量 |
| websearch_cn Startpage 乌克兰语 | ❌ **token 提取失败** | 反爬 token 失效，通道不稳定 |

---

## 三、多维度评分（10 分制）

| 维度 | web_search_prime us | web_search_prime cn | websearch_cn DuckDuckGo | websearch_cn Bing | websearch_cn Brave | websearch_cn Startpage | web_reader |
|---|---|---|---|---|---|---|---|
| **时效性** | **9.5**（1W 过滤+相对时间，4h 内信源） | 8.5（1Y 过滤有效） | 7.5（结果新鲜但无过滤参数） | 4（结果无日期/陈旧） | N/A（429） | N/A（故障） | —（跟随页面） |
| **信源权威性** | **9.5**（gold.org/ISW/IMF 直达） | 8.5（WGC 中文/主流财经） | 8（官方+主流媒体，混 SEO 站） | 2（百科/词典为主） | — | — | 9（全文+脚注） |
| **多语言覆盖** | 7（中英优，未验小语种） | 6（中文优） | **9.5**（英俄乌希波全通，含本土信源） | 3（仅中文泛查询） | — | — | 语言无关 |
| **数据类查询** | **9.5**（摘要内嵌表格数据） | 8.5 | 7.5 | 1 | — | — | 9.5（结构化表格） |
| **稳定性** | 8（1W 过严会空结果） | 9 | 9.5（15 次调用 0 失败） | 9（稳定地返回劣质结果） | 3（429） | 3（token 失效） | 9 |
| **中文能力** | 8.5（cn 区专业查询好） | 8.5 | 6（中文非强项） | 4（泛查询尚可，专业失效） | — | — | 8 |

---

## 四、结论与推荐路由

**总排名：web_search_prime（us 区+时效过滤）≥ websearch_cn DuckDuckGo > web_search_prime cn > Bing ≈ Brave/Startpage（故障）**

### 推荐路由策略

1. **结构化数据/排行榜/研究类** → `web_search_prime us + oneYear`（摘要直接带数据）→ 命中后 `web_reader` 抓全文表格
2. **突发新闻/战况追踪** → `web_search_prime us + oneWeek/oneDay`；空结果时降级 `websearch_cn duckduckgo` 英文（无过滤但结果新鲜）
3. **多语言地缘政治（俄/乌/希/波视角）** → `websearch_cn duckduckgo` + 对应语言查询——**这是独有价值**：能拿到俄方军事博主、伊朗 Tasnim、以色列 ynet 等本土叙事，英文/中文通道拿不到
4. **中文财经** → `web_search_prime cn`（Bing 中文通道对专业查询已不可用，弃用）
5. **Brave/Startpage 通道**：实测 429/token 失效，暂不作为依赖，仅作冗余

### 已识别问题

- `web_search_prime` 时效过滤为硬过滤：`oneWeek` 无匹配直接返回空，不会自动放宽 → 需要在提示词层做降级逻辑
- Bing 中文通道语义检索严重劣化（专业长尾查询全部跑偏为词典/百科），与上轮审计结论一致
- websearch_cn 的 Brave（429）与 Startpage（token 失效）两条通道当前不可用
- global-search / zhihu-search CLI 因缺 `ZHIHU_ACCESS_SECRET` 未启用，如需知乎通道需配置密钥

---

## 附：两个查询的答案速览（实测副产品）

**① 黄金储备 Top5（Q2/August 2026，世界黄金协会/IMF 口径）**
美国 8,133.5 吨（83.8%）｜德国 3,350.3｜IMF 2,814.0｜意大利 2,451.8｜法国 2,437.0｜中国第 5 位 2,409.6 吨（9.5%）
2026 年变化要点：上半年全球央行净购金，波兰（+82t）领跑，乌兹别克/中国/哈萨克跟进；荷兰央行从美国运回 86 吨；俄罗斯 NWF 黄金仅剩 173.1 吨持续抛售；中国央行连续 18 个月增持（4 月末 7,464 万盎司）。

**② 战争状态（截至 10-26）**
- **俄乌**：全面战争第 1,706 天。过去四周俄净推进仅约 3 平方英里（DeepState OSINT）；乌军持续远程打击俄能源/军工设施；10-21 能源停火谈判（Witkoff 会谈）后俄 10-21/22 夜大规模导弹无人机报复；10-23 双方交换战俘。
- **美伊以**：2026 年初开战，已第 239 天。10-25 报道美以起草中期选举后恢复对伊打击计划；伊朗拟定打击海湾海底电缆的反制预案；内塔尼亚胡警告"以色列处于被毁灭危险"；伊朗本土媒体披露以军 10-10 曾备袭被特朗普叫停；Trump 10-23 集会称可能再发动一次打击行动。
