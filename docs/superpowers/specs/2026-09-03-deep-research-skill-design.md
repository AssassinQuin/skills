# deep-research skill 设计文档

- 日期：2026-09-03
- 状态：已与用户逐节确认
- 前置调研：`reports/2026-08-21-local-mcp-retrieval-report.md`、`reports/2026-09-03-search-mcp-benchmark.md`、外部三实现（见「设计依据」）

## 1. 定位与目标

通用深度调研服务：用户丢一个问题（或零散需求），skill 自主判断、拆分子主题，按「本地记忆 → 搜索缓存 → 网页实时搜索」三层信息源递进搜集，多子 agent 并行协作 + 对抗核实，最终整理成详尽报告落盘，并把结论固化进长期记忆，下次同题不重搜。

不做什么：不替代单次轻量搜索（直接用 MCP 工具即可）；不面向单一领域（投研只是其中一类场景）。

## 2. 已确认的需求决策

| 决策点 | 结论 |
|---|---|
| 定位 | 通用深度调研 |
| 迭代深度 | 双档：quick（默认单轮）/ deep（显式触发，迭代补搜 max 1 轮） |
| Agent 分工 | 按 lane 分搜索员 + 对抗核实员 |
| 产出 | 报告 md + findings.json 双产物，主题目录落盘 |
| 实现形态 | 混合式：SKILL.md 编排 + 轻脚本做确定性环节 |
| 搜索员 model | sonnet |
| 核实员 model | opus（hec-ovi 实证：contrarian/综合用小模型会跳过或变浅） |
| 长期记忆 | 两级：查询级缓存注册表（脚本查表）+ 内容级 ctx 索引/auto-memory |
| 人工投喂 | inbox/ 通道：搜索被墙/内容有问题时用户手动放入，重跑吸收 |

## 3. 设计依据（外部成熟实现调研）

| 来源 | 吸收的设计 |
|---|---|
| jasonm4130 `RESEARCH_what_gives_best_deep_research.md`（tier-2 验证的设计研究） | plan-first 显式子问题枚举；子问题分 core/background，core 覆盖率=质量门；独立子问题并行；研究与写作分离；每层验证必须碰外部证据；停止规则用低效用信号而非固定预算；强模型编排+便宜模型执行 |
| kimsb2429 `deep-dive`（Claude-native DAG） | 子问题 DAG 4-8 节点 cap 12、每节点 1-3 搜索；子 agent 统一返回 Findings/Gaps/Sources；gap iteration 硬限 1 轮；引用持久化到文件防 context 压缩丢失；打印计划后直接执行不等确认 |
| hec-ovi `research-skill`（DeepResearch Bench II 实测） | 载荷论断 ≥2 独立来源（不同域名），琐碎事实 1 个可接受；contrarian pass 强制、输出「最强反驳」栏；brief 注入真实日期+年份钉死；主 agent 独占结论文件写；调研必须以落盘结束否则=失败运行；INDEX.md dispatcher 模式 |

本地特有分层来自 9/3 基准测试：prime 质量/时效最强但最贵（2-3k token/查询）；ows 双实例便宜且 14/14 满分；zhihu lane 深度最强；searxng 搜索退役留读取。

## 4. 端到端流程（六阶段）

主会话 = 编排者，全程自动推进、不等用户确认。

### Phase 0 感知判定
1. 判模式：quick（默认）/ deep（用户措辞「深挖/深度调研」触发；「快查」强制 quick——措辞永远覆盖启发式）
2. spawn 可用性检查：已在子 agent 内 → 降级 solo（主会话串行跑 lane）
3. 长期记忆感知，由近及远四层：
   - auto-memory recall 过往调研结论（一句话+报告路径）
   - `reports/research/INDEX.md` 任务级复用（旧报告能否直接回答）
   - ctx_search 语义召回历史 Findings/raw 信源
   - `<topic>/inbox/` 扫描用户人工投喂的未吸收资料
4. 旧资料已能回答 → 直接引用输出+按需小补充，收工；否则进 Phase 1

### Phase 1 需求拆分（主会话自主判断）
1. 零散需求 → 子主题清单（quick 3-5 个 / deep 4-8 个，cap 12，可带依赖构成 DAG）
2. 每个子主题分级 core / background（core 覆盖率是质量门）
3. 每个子主题标信息源路由：
   - 本地可答（记忆/旧报告/raw 引用即可，零网络）
   - 需网页（cn / glb / zhihu；deep 加 prime）
   - 预期搜不到（登录墙/被墙）→ 标记「待 inbox 投喂」
4. `search-memory.json` 查表：命中的查询剔除，只搜未命中的
5. 分配去重：归一化合并同义查询，每条查询唯一归属一个 lane；各搜索员的 prompt 只包含分给它的查询清单（边界划清，清单外的发现记入 Gaps 留给 Phase 3）
6. 初始化 `<topic>/queries.json` 任务内查询登记表（缓存复用的查询一并登记）
7. 打印子主题×lane 矩阵，直接开跑

### Phase 2 并行搜集
- 无限额 lane 并行：cn 搜索员 ∥ glb 搜索员；zhihu 搜索员独立成 agent 串行控速（≤4 次/任务）
- 限额 lane 收归主会话：prime 仅 deep 模式直调 ≤3 次
- 每个搜索员 prompt 自包含：真实日期字面量（先跑 `date +%Y-%m-%d`）+ 年份钉死规则 + 分到的子主题清单 + 本 lane 工具用法 + 搜索上限（quick 3 / deep 6）+ 统一返回格式
- 读取员（haiku）：对高价值信源抓正文 → Write `raw/S*.md`，只回报元数据（编号/标题/字节数）
- 任务内去重感知：搜索员每次搜索前读 `<topic>/queries.json`，发现查询已被其他员登记 → 跳过该查询（在 Gaps 说明）；每次实际执行的搜索立刻 append 登记一行（query/lane/agent/wave）
- wave 间：主会话把已登记查询清单 + 依赖子主题摘要注入下一 wave 各员 prompt
- 搜索员返回全文 → 主会话 `ctx_index` 索引，上下文只留摘要

### Phase 3 缺口补搜（仅 deep，max 1 轮）
汇总各员 Gaps + core 未覆盖项 → 只补「会改变结论」的 gap，1-3 个定向子问题作为最后一波。连续低效用（新结果全重复）→ 提前停。

### Phase 4 对抗核实（opus，1 个）
1. 载荷论断独立来源计数（不同域名才算独立；<2 → confidence: low）
2. contrarian 定向搜索（「X 错了/批评/过时/反面证据」，用无限额 lane）→ 输出「最强反驳」，找不到也必须写「未发现」
3. factored 验证：不带草稿直接回答验证问题，再与草稿比对（防复制自己的幻觉）

### Phase 5 整理成文 + 记忆固化（主会话独占写）
1. `report.md`：摘要 / 按主题重组的发现（综合非粘贴，数字/日期/引用齐全）/ 最强反驳 / Open Questions / 全量引用 / Meta（Requested/Effective Mode、lane 健康、reused/fresh 查询数）
2. `findings.json` + `sources.json`
3. 写回三层记忆：INDEX.md 一行摘要 + search-memory.json（query→results）+ auto-memory 一句话结论
4. `validate-findings.sh` 校验 JSON；失败 = 失败运行，不静默
5. 会话内只回：报告摘要 + 路径 + reused/fresh 统计

## 5. 目录结构

```
reports/research/
├── INDEX.md                      # 全局索引：一行一主题（跨任务检索）
└── <topic-slug>/                 # 一个调研任务 = 一个目录
    ├── meta.json                 # 问题/模式/状态/lane健康/子主题分级清单
    ├── report.md                 # 最终报告
    ├── findings.json             # 结构化产物（下游 skill 消费）
    ├── sources.json              # 引用登记表（citation persistence）
    ├── queries.json              # 任务内查询登记表（agent 间去重感知）
    ├── raw/                      # 原始信源正文，每源一文件 S01-<slug>.md
    ├── inbox/                    # 人工投喂通道（含 README 说明格式）
    └── parts/                    # deep 模式报告分节草稿
datastore/search-memory.json      # 全局查询级缓存注册表
```

skill 本体：

```
deep-research/
├── SKILL.md                      # 流程编排+触发词+降级规则+agent prompt 模板（内嵌）
├── scripts/
│   ├── route-lane.sh             # lane 路由表：查询特征→引擎/MCP 工具（确定性）
│   └── validate-findings.sh      # jq 校验 findings.json schema，失败显式报错
└── templates/
    └── report.md                 # 报告骨架
```

## 6. Lane 路由表（脚本查表，模型不猜）

| lane | 引擎（按序） | 限额 | 适用 |
|---|---|---|---|
| cn | websearch-cn（sogou 优先，baidu 间歇挂） | 无 | 中文事实/新闻 |
| glb | websearch-global（startpage/ddg，含外语查询翻译） | 无 | 外文事实/技术文档 |
| zhihu | zhihu MCP（count 2-3）→ zhihu-global | ≤4 次/任务 | 观点/体验/中文争议 |
| prime | web-search-prime | deep only，≤3 次，主会话直调 | 高价值查询 |
| 读取 | web-reader / searxng web_url_read | 无 | 抓正文到 raw/ |
| 降级 | CLI：global-search.py / zhihu-search.py | — | MCP 不可用时 |

## 7. Agent 设计（R5.1 显式 model，职责单一）

| Agent | model | 工具 | 写权限 |
|---|---|---|---|
| cn / glb / zhihu 搜索员 | sonnet | 仅本 lane 一套 | 无（只返回文本） |
| 读取员 | haiku（机械抓取） | web-reader / searxng-read | 仅 raw/ |
| 核实员 | opus | ows（无限额 lane） | 无 |
| prime | 主会话直调 | web-search-prime | — |

统一返回 schema（搜索员）：

```
## Findings   事实+日期+数字，内联引用 [S1]
## Gaps       没答上的/矛盾/follow-up，无则 "None"
## Sources    S1: title — url — lane — published_date
```

## 8. findings.json schema

```json
{
  "topic": "...", "date": "YYYY-MM-DD", "mode": "quick|deep",
  "sub_questions": [{"id": "q1", "question": "...", "tier": "core|background", "status": "answered|partial|unanswered"}],
  "findings": [{"claim": "...", "sub_question": "q1", "confidence": "high|medium|low",
                "evidence": [{"url": "...", "title": "...", "lane": "cn|glb|zhihu|prime|human", "quote": "...", "published": "..."}]}],
  "strongest_objection": "...",
  "gaps": ["..."],
  "meta": {"requested_mode": "...", "effective_mode": "...", "lane_health": {...},
           "reused_queries": 0, "fresh_queries": 0, "contrarian_run": true}
}
```

## 9. 长期搜索记忆（两级）

**精确层：查询级缓存** `datastore/search-memory.json`

- key = `规范化查询|lane`，value = `{fetched_at, ttl_class, results[{title,url,snippet}], task}`
- Phase 1 查表剔除命中查询；Phase 5 写回；同任务内 wave 2 也先查不重复 wave 1

**语义层：内容级召回** — ctx 持久索引（Findings/raw 全量 ctx_index，跨会话 ctx_search）+ auto-memory（结论级）

**新鲜度规则**：short（新闻/行情，3-7 天）/ long（版本号/财报数字/方法论，90 天）/ 永久（历史事件/观点存档）。用户措辞「刷新/要最新」→ 强制 bypass 并更新条目。

## 10. 大文件 IO 策略

核心原则：数据在生产者处直接落盘，上下文只过元数据。

- 信源正文：读取员 Write raw/，只回报元数据
- deep 报告分节：各节写 parts/，`cat parts/*.md > report.md` 确定性合并
- findings.json（<10KB）主会话 Write；大文件读用 ctx_execute_file / ctx_search / Read(offset)
- 写权限边界：raw/ + parts/ 子 agent 可写；meta/report/findings/sources/INDEX/search-memory 主会话独占

## 11. 质量门与停止规则（R6/R12）

- core 子问题覆盖率：未覆盖必须进 Open Questions，不许静默
- contrarian pass 必跑（无反驳也写「未发现」）
- 报告未落盘 = 失败运行；JSON 校验失败 = 失败运行
- reused/fresh 查询数必须显式标注（防「以为查了其实全是缓存」）
- 任务内查询登记表查重：搜索员必须先查登记再搜索，同查询不重复执行
- 停止：quick 单 wave 硬停；deep ≤2 wave + 1 gap 轮；连续低效用提前停
- 某 lane 全挂 → 报告标注 lane 缺席 + 其余发现置信度降级说明 + 提示 inbox 投喂

## 12. 降级链

spawn 不可用 → solo（主会话串行跑 lane）；MCP 挂 → CLI 脚本（global-search.py / zhihu-search.py）；prime 挂 → ows-glb 兜底；zhihu 超限 → 缓存/旧报告兜底。报告标注 Requested/Effective Mode。

## 13. 验收标准

1. 三个真实问题端到端：①中文投研类 ②技术选型类 ③混合语言类
2. core 覆盖率 100%（或显式列出未覆盖原因）
3. findings.json 过 validate-findings.sh
4. 复用 `scripts/search-mcp-benchmark.sh` 标准查询集做 lane 冒烟
5. 同题重跑：第二次 reused_queries > 0（验证缓存生效）
6. inbox 投喂一次：文件被吸收进 raw/ 并标注 lane: human

## 14. 与现有资产关系

- `global-search` / `zhihu-search` skill：降级为 CLI fallback，保持不动
- `scripts/search-mcp-benchmark.sh`：验收工具复用
- auto-memory：结论级记忆复用现有体系
- 本设计对齐 feedback 记忆：research-freshness（日期钉死+强制刷新通道）、macro 交叉验证精神（多源独立）
