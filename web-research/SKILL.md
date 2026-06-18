---
name: web-research
description: >
  多源并行调研。local-first → 6角度头脑风暴 → 并行agent搜索(sonnet) → 灵感追挖 → 综合报告。
  显式 trigger：调研、研究、搜索研究、web research、对比分析、方案选型、文献、literature review、deep dive。
  隐式 trigger（能力缺口识别）："听说 X 但不确定"/"X 哪个版本好"/"X 怎么选"/"有没有人做过 X"/"X 的最新进展是什么"。
  DO：多源交叉验证 / 标证据等级 / 区分权威单源 vs 矛盾源 / 灵感按意外度×可验证性×行动启示度评分。
  DON'T：单一来源下结论 / 跳过本地优先直接搜索 / 混淆 SEO 内容农场与权威源。
  Output: {skill_dir}/data/{date}-{slug}/
user-invocable: true
skill_type: research
metadata:
  version: "2.2"
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

### 0.1 混合任务拆解（v2.2 新增，来自 P2 反推）

**当任务同时含"对比分析"和"具体数据"信号时**（如"对比 {A} vs {B} 在 {场景} 下，含 benchmark 数据"），按以下矩阵拆解：

| 任务类型 | 处理方式 |
|---------|---------|
| **混合任务**（分析骨架 + 数据支点） | 拆两条线并行：骨架走 Phase 1-4，支点穿插 Phase 0 微查询 |
| **纯单一事实** | 仅 Phase 0，跳过 Phase 1-4 |
| **纯对比分析** | 直接 Phase 1，不做 Phase 0 |

**专家视角（Modeling）**：先识别"分析骨架"（用户想得到对比结论）与"数据支点"（具体数字/版本支撑结论），再决定是否并行。例：`"{A} vs {B} 在 {场景} 对比 + benchmark"` → 骨架 Phase 1-4 + 支点 Phase 0 查权威 benchmark 站点。

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

### 2.2 主题类型分类 + query 深度策略（v2.2 新增，来自 P2 反推 gap #2）

通用模板只能生成新闻级 query。Expert 先分类主题类型，每类用不同深度策略：

| 主题类型 | query 深度策略 | 关键源 |
|---------|--------------|-------|
| **技术对比** | benchmark 数据 + 源码 + incident postmortem + 工程博客 | 官方 benchmark / 知名公司工程博客 / postmortem 集 |
| **学术调研** | arxiv + 引用网络 + 同行评议 + 作者访谈 | arxiv.org / scholar / openreview |
| **产品调研** | G2 / user review / churn 数据 / 拉新数字 | G2 / ProductHunt / crunchbase |
| **人物调研** | 访谈 + 论文 + 对立场观点 + 时间线 | 个人博客 / 对比博客 / 知乎人物页 |
| **政策调研** | 官方文件 + 利益相关方 + 实施案例 + 反对意见 | 政府公告 / industry reports / 反对联盟 |
| **方法论调研** | 论文 + 实战案例 + 反例 + 边界条件 | paper + 实战 blog + 反对案例 |

**专家视角（Modeling）**：含场景限定词时"对比优缺点"是新闻级 query，expert 会展开为子维度（如性能类：latency / throughput / memory / GC pause / P99；如架构类：服务边界 / 通信开销 / observability）。

### 2.3 场景限定词 → 子维度展开规则（v2.2 新增）

当 query 含场景限定词（"在 X 场景"、"针对 X 用法"），按规则展开子维度：

| 限定词类型 | 子维度展开 |
|----------|----------|
| 性能场景（"高并发"/"低延迟"） | latency / throughput / memory / GC pause / P99 |
| 规模场景（"微服务"/"单体"/"分布式"） | 服务边界 / 通信开销 / observability / 部署复杂度 |
| 团队场景（"小团队"/"创业"/"大厂"） | 招聘成本 / 学习曲线 / 工具成熟度 / 长期维护 |
| 领域场景（"金融"/"游戏"/"AI"） | 合规 / 实时性 / 数据量 / 计算密度 |

输出格式：
```
1. **{主题}** [角度] — {为什么相关，期望找到什么}
   类型: {2.2 分类}
   query: {2-3 个具体 query，按类型深度策略 + 子维度展开}
```

### 2.2 🔒 确认

展示：主题列表 + 预估调用数（`主题数 × 3 ≈ 总调用`）。确认后进 Phase 3。

---

## Phase 3: 并行搜索

### 3.1 MCP 可用性（运行时降级）

子 agent 直接尝试调用 MCP 工具，失败时沿 body 内降级链切换。仅在已知某 MCP 不可用时（如手动 `scripts/mcp-probe.sh` 确认），在 prompt 注入 `[MCP 状态] {tool}=down`。

#### 3.1.1 三级失败信号阈值（v2.2 新增，来自 P2 反推 gap #6）

| 级别 | 触发条件 | 处理 |
|------|---------|------|
| **L1 单次错误** | 单次 429 / 超时 / 网络抖动 | agent 内重试 1 次（沿用 agent-prompt.md L74） |
| **L2 同工具连续失败** | 同工具连续 2 次同类错 | orchestrator 标记该 MCP 退化 → 注入降级提示给所有 agent + 切换降级链 |
| **L3 整体不可用** | 探测脚本预先验证失败 OR 工具失败率 > 50% | orchestrator 主动注入 `[MCP down]` + 全量切 WebSearch/WebFetch |

**健康表共享**：每个 agent body 末尾输出本次工具调用健康度（成功/失败/降级次数），orchestrator 汇总维护全局工具健康表，超 50% 强制降级。

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
5. **跑偏检测（v2.2 新增）**：见 3.5.1
6. 写入 `{slug}/raw/agent-{1,2,3}.md`
7. 筛选 💡灵感（按 3.5.2 评分矩阵）→ 若 ≥2 条 ≥6 分 → 进入 3.6 追挖

#### 3.5.1 跑偏信号清单 + 源质量分级（v2.2 新增，来自 P2 反推 gap #3）

**跑偏信号**（任一命中即触发纠错）：
- 结果集中在单一 SEO 域名（如全是 medium.com）
- 摘要高度同质化（5 条结果用同一说法）
- 无 primary source（无官方/论文/repo）
- query 命中率 < 30%（搜了 10 次只有 3 次相关）

**源质量分级**（决定保留优先级）：

| 等级 | 源类型 | 例 |
|------|-------|-----|
| S | academic / official benchmark / peer-reviewed | arxiv / 官方 benchmark 站 / RFC |
| A | official doc / 知名工程博客 / authoritative book | 语言官方 doc / 知名公司工程博客 |
| B | 知名个人博客 / 知名 medium / high-reputation SO | 高 reputation 个人技术博客 |
| C | 普通 medium / dev.to / 个人博客 | 一般内容创作者 |
| D | content farm / SEO 站 / 未署名 | 自动生成内容 |

**纠错协议**：
1. 检测跑偏 → orchestrator 标记问题 agent
2. 改写 query（加 `site:` 或 `filetype:pdf` 或具体人名/版本号）
3. 重 spawn 该 agent（用其剩余预算）
4. 仍跑偏 → 降级该角度到"已知不充分"，标 ⚠️ 进报告

#### 3.5.2 灵感评分矩阵（v2.2 新增，来自 P2 反推 gap #4）

每条灵感按三维评分（0-3 分每维，总分 0-9）：

| 维度 | 0 分 | 3 分 |
|------|------|------|
| **意外度** | 与主流认知一致 | 颠覆主流认知 |
| **可验证性** | 无独立来源 | 多个独立来源支撑 |
| **行动启示度** | 不改变决策 | 直接改变决策方向 |

**追挖阈值**：总分 ≥ 6 进追挖；≥ 7 入报告高亮；< 6 不纳入。

**反例 vs 正例**：
- ❌ "AI 写代码比人快"（不算灵感，主流认知）
- ✅ "某语言在 P99 latency 上因 GC 表现不及另一语言，但某公司切换后降 50ms"（意外 + 可验证 + 改决策）

### 3.6 深度追挖（可选）

触发：≥2 条灵感 ≥ 6 分（3.5.2 矩阵）。用 1 个 sonnet agent 追挖，预算 5-8 次（**从该 agent 剩余预算挪用，不从主 30 扣**——v2.2 澄清）。不足 5 次则跳过并标注。

### 3.7 预算分桶模板（v2.2 新增，来自 P2 反推 gap #5）

**总额 30 次**按桶分配：

| 桶 | 预算 | 用途 |
|---|------|------|
| orchestrator 探测 | 3 | Phase 0-1 + MCP 健康检查 |
| 3 个 agent 各 | 8 × 3 = 24 | Phase 3 主体搜索 |
| orchestrator 综合 | 3 | Phase 4 去重 + 报告 |

**超支降级协议**（按优先级砍）：
1. 砍 "前沿/趋势"（时效低，可后续补）
2. 砍 "💡灵感"（非核心决策依据）
3. 保 "实战经验" + "方案对比"（核心决策依据）

**追挖预算**：从单 agent 剩余挪用，不从主 30 扣。

重试继承剩余预算（`原预算 - 已用`）。超限标注 `⚠️ 预算超支: {实际}/{预算}` + 触发降级协议。

---

## Phase 4: 综合 + 持久化

### 4.1 去重 + 证据等级标注（v2.2 加证据等级，来自 P2 反推 gap #7）

1. URL 去重（相同 URL 合并）
2. 内容去重（不同 URL 同内容 → 标注 `[来源#A,#B]`）
3. 过滤：低相关性、无真实 URL（AI 生成内容）不纳入
4. 标记格式不完整但内容有价值的结果
5. **证据等级标注（v2.2 新增）**：

| 等级 | 标签 | 适用 |
|------|------|------|
| 多源验证 | `[来源A,B验证]` | 观点/趋势（≥2 独立源） |
| 权威单源 | `[权威单源]` | 官方 benchmark / version / 单方声明 |
| 矛盾源 | `[⚠️矛盾]` | A 说 X，B 说非 X（列条件差异） |
| 知识空白 | `[⚠️空白]` | 搜不到 / 全低质 / 矛盾不可解 |

### 4.2 综合报告

**步骤**:
1. 按主题归类 agent 原始输出
2. 每个主题提取 3-5 个核心发现，标注来源编号 + 证据等级（v2.2）
3. 跨主题交叉验证 → `[来源A,B验证]`
4. 矛盾源处理：列条件差异（数据集/版本/场景）→ `[⚠️矛盾]`
5. 筛选 💡灵感（按 3.5.2 评分矩阵，≥6 入报告，≥7 高亮）
6. 撰写报告

**报告结构**:
1. **背景与目标**（2-3句）
2. **核心发现**（每条 `[来源#N]` + 证据等级 + 具体数据）
3. **方案对比**（仅对比型，表格）
4. **💡 意外发现**（按意外度排序 + 评分依据）
5. **结论与建议**（3-5条）
6. **信息源列表**（编号 + URL + 源质量等级 S/A/B/C/D）
7. **⚠️ 局限性**（v2.2 新增）：知识空白 / 单源风险 / 矛盾未解 / 预算超支影响

规则：中文 | 交叉验证 | 知识空白标 ⚠️ | 不编造 | 证据等级必标

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
