---
name: deep-research
version: 0.1.0
description: 通用深度调研服务：自主拆分需求为子主题，本地记忆→搜索缓存→网页搜索三层递进，多子agent并行搜集+对抗核实，输出详尽报告并固化长期记忆。触发：/deep-research、「深度调研」「帮我调研」「全面了解一下」「收集资料写报告」「查一下XX的来龙去脉」。
metadata: {"openclaw":{"emoji":"🔬","requires":{"bins":["bash","jq"]}}}
---

# Deep Research 深度调研服务

主会话 = 编排者，全程自动推进、不等用户确认。六阶段如下；任何失败按「降级链」处理并显式记录在报告 Meta。

## 模式判定

- 默认 quick；用户说「深挖 / 深度调研 / 详尽」→ deep；「快查 / 简单看下」→ 强制 quick
- 用户措辞永远覆盖启发式，双向都成立

## 硬约束（违反任何一条 = 失败运行）

1. core 子问题覆盖率 100%：未覆盖项必须进报告「未解问题」并给原因，不许静默
2. contrarian pass 必跑：无反驳也必须写「未发现」
3. 报告未落盘 = 失败运行；findings.json 过不了 validate-findings.sh = 失败运行
4. 报告必须标注 Requested/Effective Mode、lane 健康、reused/fresh 查询数
5. 查询去重：任何搜索执行前先查任务登记表与路由缓存，已登记/已缓存的跳过
6. 子 agent 必须显式指定 model（R5.1）：搜索员 sonnet / 读取员 haiku / 核实员 opus
7. 限额：prime ≤3 次且仅 deep、主会话直调；zhihu MCP ≤4 次/任务；github MCP ≤8 次/任务；deep ≤2 主 wave + 1 gap 轮

## Phase 0 感知判定

1. 判模式（见上）
2. spawn 可用性：已在子 agent 内执行 → 全程 solo（主会话串行扮演各员，保格式），Effective Mode 加 `+solo`
3. 长期记忆感知（由近及远）：
   - recall auto-memory 中过往调研结论（关键词匹配主题）
   - 读 `reports/research/INDEX.md`：旧报告能直接回答 → 引用输出 + 按需小补充，收工
   - ctx_search 召回历史 Findings/raw（无 ctx 工具的框架跳过）
   - 扫描任务目录 `inbox/`：有人工投喂 → 列为高优先证据源（lane: human）
4. 旧资料足以回答 → 输出并收工；否则 Phase 1

## Phase 1 需求拆分

1. 建任务目录 `{TASK}`（slug：主题的短横线小写拼音或英文）：
   ```bash
   mkdir -p {TASK}/raw {TASK}/parts {TASK}/inbox {TASK}/cache
   cp {baseDir}/templates/inbox-README.md {TASK}/inbox/README.md
   touch {TASK}/queries.jsonl
   ```
   写 `{TASK}/meta.json`：`{"topic","date","requested_mode","sub_questions":[{id,question,tier,source_route}]}`
2. 拆子主题：quick 3-5 个 / deep 4-8 个（cap 12）；每个标 `tier: core|background`；deep 可带依赖（DAG，wave 按拓扑序）
3. 每个子主题标源路由：
   - 本地可答（记忆/旧报告/raw 已有）→ 不进搜索清单
   - 需网页 → 分配 lane（cn=中文事实 / glb=外文 / zhihu=观点争议 / prime=deep 高价值 / github=仓库指标与代码检索）
   - 预期搜不到（登录墙/被墙）→ 标「待 inbox 投喂」
4. 生成查询清单（每子主题 1-2 条查询），逐条路由：
   ```bash
   bash {baseDir}/scripts/route-lane.sh "<query>" --lane <lane>
   ```
   - `action=reuse` → 直接采用缓存结果，append 登记 `{query,lane,agent:"orchestrator",wave:0,reused:true}` 到 queries.jsonl
   - `action=search` → 进待搜清单，记录输出的 tool/tool_params
5. 分配去重：归一化合并同义查询（大小写/空白/同义词），每条查询唯一归属一个 lane；每个搜索员的 prompt **只包含分给它的查询清单**，边界划清
6. 打印「子主题×lane×查询」矩阵表格，然后直接开跑

## Phase 2 并行搜集

spawn 搜索员（Agent 工具，general-purpose，**显式 model**，并行发出）：

| 员 | model | 工具（只用这些） | 搜索上限 |
|---|---|---|---|
| cn 搜索员 | sonnet | mcp__websearch-cn__search | quick 3 / deep 6 |
| glb 搜索员 | sonnet | mcp__websearch-global__search | quick 3 / deep 6 |
| zhihu 搜索员 | sonnet | mcp__zhihu__zhihu_search、mcp__zhihu-global__global_search | ≤4 次，串行调用 |
| github 搜索员 | sonnet | mcp__github__*（search_repositories / search_issues / search_code / get_file_contents / list_commits） | ≤8 次调用 |

搜索员 prompt 模板（`{LANE}`/`{DATE}`/`{TASK}`/`{QUERY_LIST}`/`{TOOL_DOC}`/`{WAVE}` 运行时填充）：

```
你是{LANE}通道的搜索员，只负责这一个通道。今天日期：{DATE}（一切以它为准；构造搜索词必须带年份，不依赖你对当前日期的先验）。

任务目录：{TASK}
你只搜以下查询，不要搜清单外的内容（过程中发现的新线索记入 Gaps，不要自己扩展搜索）：
{QUERY_LIST}

工具与参数（照此调用，失败时改用 fallback）：
{TOOL_DOC}

去重纪律（重要）：
- 每次搜索前先 cat {TASK}/queries.jsonl；若该查询已被任何 agent 登记 → 跳过，并在 Gaps 里说明「查询已由他人覆盖」
- 每次实际执行的搜索，完成后立刻追加登记一行（保持文件是逐行 JSON）：
  printf '%s\n' '{"query":"<该次查询>","lane":"{LANE}","agent":"{LANE}-1","wave":{WAVE}}' >> {TASK}/queries.jsonl
- 每次搜索完成后，把该查询的结果数组（[{"title","url","snippet","published"}]）写入 {TASK}/cache/<编号>-{LANE}.json（编号用查询清单里该查询的序号，如 q3）；若 Write 被拒绝，不要绕过——在 Gaps 里标注该编号，编排者会补写

严格按以下格式返回，不要输出其他内容：
## Findings
（事实+日期+数字，内联引用标记 [S1][S2]…，每条标明来源）
## Gaps
（没答上的/发现的矛盾/值得 follow-up 的问题；无则写 None）
## Sources
（每行：S1: title — url — {LANE} — published_date）
```

读取员（高价值信源抓正文，model: haiku）：

```
你是读取员。用 mcp__web-reader__webReader 依次抓取以下 URL 的正文：
{URL_LIST}
每个来源写入 {TASK}/raw/S{n}-{短slug}.md，文件首三行固定为：
# {title}
- url: {url}
- fetched: {DATE}
只返回每源的元数据清单（编号/标题/大致字节数），绝对不要返回正文内容。
```

prime：deep 模式且存在高价值查询 → **主会话直调** mcp__web-search-prime__web_search_prime（≤3 次），结果同样登记 queries.jsonl（agent:"orchestrator-prime"）。

每个 agent 返回后：
- 全文 `ctx_index`（source: `<topic-slug>`；无 ctx 工具跳过），主会话上下文只留摘要
- wave 间：把已登记查询清单 + 依赖子主题的发现摘要，注入下一 wave 各员 prompt
- deep 模式主 wave 硬上限 2 个：依赖更深的节点不单开 wave，合并进第 2 批执行（R6 预算纪律）
- 结果回收纪律：所有子 agent 一律前台等待（run_in_background: false）；若平台强制转后台，Phase 5 前必须逐一确认其输出已到手（读其返回文本或 cache/queries.jsonl 痕迹），迟到的结果要么并入 findings、要么在「未解问题」显式记录——严禁静默丢弃

## Phase 3 缺口补搜（仅 deep，max 1 轮）

汇总各员 Gaps + core 未覆盖项 → 只补「会改变结论」的 gap（1-3 条定向查询，照常走 route-lane.sh + queries.jsonl 登记）→ 作为最后一波。若新结果全部与已有发现重复（低效用）→ 提前停。

## Phase 4 对抗核实（spawn 1 个，model: opus）

输入：主会话综合后的载荷论断清单 + 全部 Sources。prompt 模板：

```
你是对抗核实员。任务目录 {TASK}，今天 {DATE}。
1. 独立来源计数：下列每个载荷论断，数一数独立来源数（域名不同才算独立；同一域名多篇=1）。<2 个的标 low：
{载荷论断清单 + 各自现有来源域名}
2. contrarian 搜索：用 mcp__websearch-cn__search（中文）或 mcp__websearch-global__search（外文）搜每个核心结论的反面证据（构造「<结论关键词> 错了/批评/翻车/反面/风险」类查询），搜索上限 ≤6 次、优先攻击证据最少的结论。输出每个结论的「最强反驳」；找不到写「未发现」。每次搜索后登记：
  printf '%s\n' '{"query":"...","lane":"cn|glb","agent":"verifier","wave":9}' >> {TASK}/queries.jsonl
3. factored 验证：不看草稿，仅凭下列 URL 用 mcp__web-reader__webReader 直接回答验证题，再与草稿说法比对，列出不一致处：
{验证题清单（如「S3 中提到的营收数字是多少？」）+ 草稿对应说法}

返回格式：
## 独立来源计数
（论断 → 来源数 → high/low）
## 最强反驳
（结论 → 反驳内容 或 未发现）
## 验证不一致
（无则写 无）
## Sources
（contrarian 搜索新引入的每行：S1: title — url — lane — published_date；无新源写 无）
```

## Phase 5 整理成文 + 记忆固化（主会话独占写盘）

1. `{TASK}/report.md`：按 `{baseDir}/templates/report.md` 骨架填充；按子主题**重组**发现（综合而非粘贴），数字/日期/[S1] 引用齐全；含最强反驳、未解问题、Meta
2. `{TASK}/findings.json`：schema 见 `scripts/validate-findings.sh` 内注释（topic/date/mode/sub_questions/findings/strongest_objection/gaps/meta）
3. `{TASK}/sources.json`：`[{"id":"S1","title","url","lane","published"}]`；核实员 ## Sources 的新源一并编入
4. 校验（失败必须修复重校，不许跳过）：
   ```bash
   bash {baseDir}/scripts/validate-findings.sh {TASK}/findings.json
   ```
   - 计数以工件为准：reused_queries/fresh_queries 必须从 queries.jsonl 实际行数与 save-memory.sh 成功输出条数核对得出，禁止采用 agent 自报数字；不一致时以工件为准并在 Meta 降级记录标注
5. 写回记忆：
   - 每条 fresh 查询：搜索员已把结果数组写入 `{TASK}/cache/<编号>-<lane>.json`（缺失或被拒时主会话补写，仍被拒则该查询不写回缓存并在 Meta 降级记录标注），然后
     ```bash
     bash {baseDir}/scripts/save-memory.sh "<query>" --lane <lane> --ttl <short|long|permanent> --task {TASK相对路径} --results {TASK}/cache/q{n}-{lane}.json
     ```
     ttl 选择：新闻/行情=short，版本号/数据/方法论=long，历史事实=permanent
   - `reports/research/INDEX.md` 追加一行（不存在则先建表头 `| 日期 | slug | 一句话结论 |`）
   - auto-memory 写一条：结论一句话 + 报告路径
   - ctx_index 全量 Findings/raw（source: `<topic-slug>`）
6. 会话内只回：报告摘要 + 路径 + reused/fresh 统计 + inbox 提示（若有「待投喂」项，给出建议文件名）

## 降级链

- spawn 不可用 → solo：主会话串行扮演各员，保持返回格式不变
- 指定 model 不可用（如嵌套 spawn 报 400/modelCode 不存在）→ 该 agent 回退 sonnet（核实员也不例外），并在报告 Meta 降级记录标注「<角色> model 回退」
- Write 工具被守卫拦截（如文件名被误判）→ 依次改用备选文件名 report.md → research-report.md → 调研报告.md，把最终文件名记入 meta.json 的 report_file 字段（INDEX 与会话回复引用实际文件名）；禁止绕过权限拒绝，无备选可用时在 Meta 降级记录标注并继续
- MCP 工具失败 → 用 route-lane.sh 输出的 fallback 配置 → 仍失败 → CLI 兜底：`python3 $(dirname {baseDir})/global-search/scripts/global-search.py '{"query":"...","count":5}'` 或 `python3 $(dirname {baseDir})/zhihu-search/scripts/zhihu-search.py '{"query":"...","count":3}'`
- prime 失败 → glb lane（ows）兜底
- github MCP 失败 → glb lane 网页搜索兜底（查询加 site:github.com）
- zhihu 超限 → search-memory 缓存 / 旧报告引用
- 某 lane 全挂 → 报告标注 lane 缺席 + 其余发现置信度降级说明 + 提示「可放入 {TASK}/inbox/ 后重跑」

## inbox 吸收

Phase 0 扫描到 inbox/ 有未吸收文件（不在 meta.json 的 absorbed_inbox 列表中）→ 读取并转存 `{TASK}/raw/S{n}-inbox.md`（保留原文件，首行补来源信息），标 `lane: human`，作为高优先证据源；吸收后把文件名记入 meta.json。
