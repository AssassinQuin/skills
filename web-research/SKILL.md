---
name: web-research
description: >
  Multi-source research skill using parallel sub-agents with exa, searxng, web-search-prime,
  zread, and local code search. Triggers: 'research', '调研', '搜索研究', 'web research',
  'search and analyze', '查找资料', '搜集信息', 'investigate', 'study'.
  Workflow: load memory → brainstorm topics → design search plan → dispatch ≤3 sub-agents →
  collect & save raw results → summarize → store to memory + project docs.
  Output: structured research report with source citations in docs/research-{topic}/.
---

# Web Research Skill

Multi-source parallel research: brainstorm → search → collect → synthesize → persist.

**语言：面向用户一律中文。每个发现必须可追溯到真实来源。**

## 概览

```
Phase 1: 上下文加载  → memory 检索 + 本地 skill 文件扫描
Phase 2: 头脑风暴    → 生成搜索主题 + 设计搜索方案 + 🔒用户确认
Phase 3: 并行搜索    → ≤3 子agent 分工搜索
Phase 4: 收集整理    → 原始结果归档 + 去重去噪
Phase 5: 综合总结    → @oracle 子agent 生成研究报告 + 🔒用户确认
Phase 6: 持久化      → memory 存储 + 项目 docs/ 保存
```

---

## Phase 1: 上下文加载

### 1.1 Memory 检索

遵循 [memory skill 标签体系](../memory/SKILL.md)，并行 3 个检索：

```
memory_search(query="{研究主题} 研究 调研", tags=["global", "reference"], limit=20)
memory_search(query="{研究主题}", tags=["project", "context"], limit=20)
memory_search(query="{研究主题}", mode="hybrid", quality_boost=0.3, limit=10)
```

### 1.2 本地 Skill 文件扫描

扫描 skill 目录中是否有相关已有研究：

```
glob(pattern="**/*.md", path=/Users/ganjie/skills/)
grep(pattern="{研究主题关键词}", path=/Users/ganjie/skills/)
```

若有匹配 → 读取相关文件内容，纳入 Phase 2 头脑风暴上下文。

**输出**：已有的记忆摘要 + 本地相关文件列表（如有）。

### 1.3 已有研究复用判定

若 Phase 1.1 memory 返回相关结果（质量 ≥0.5）：

| 情况 | 处理 |
|------|------|
| 高度相关（≥3条，直接覆盖主题） | 展示摘要 → 🔒询问："复用已有研究 / 增量更新 / 重新开始" |
| 部分相关（1-2条） | 展示摘要 → 纳入 Phase 2 头脑风暴上下文，标记为"已有基础" |
| 无相关 | 直接进 Phase 2 |

复用时跳过已覆盖的主题，仅搜索新增方向。

---

## Phase 2: 头脑风暴与搜索方案

### 2.1 头脑风暴

基于 Phase 1 上下文 + 用户研究需求，生成 3-7 个**搜索主题**：

```markdown
## 搜索主题

1. **{主题A}** — {为什么相关，期望找到什么}
2. **{主题B}** — {为什么相关，期望找到什么}
3. **{主题C}** — {为什么相关，期望找到什么}
...
```

### 2.2 搜索工具分配

为每个搜索主题选择最适合的工具组合。**每个工具的精确参数规范见 [references/tool-specs.md](references/tool-specs.md)。**

| 工具 | 适用场景 | 搜索类型 |
|------|---------|---------|
| `searxng_web_search` | 广泛搜索、多源聚合、中英文均适用 | 关键词/自然语言 query |
| `exa_web_search_exa` | 语义搜索、高质量内容、学术/技术 | 自然语言 query（≤70字符） |
| `github_search_code` | 代码实现模式、具体用法 | `content:` 代码搜索 |
| `github_search_repositories` | 发现相关开源项目 | `topic:`, `language:`, `stars:` |
| `exa_web_fetch_exa` | 批量提取 exa 结果页面全文 | URL[]（≤5/次） |
| `webfetch` | 单页面提取全文 | 单 URL |
| `web-search-prime` | ⚠️ 仅当 searxng 不可用且需中文内容时 | 中文 query |
| `zread_search_doc` | ⚠️ 仅当需读取特定 GitHub repo 文档时 | repo_name + query |

**分配原则**：

| 原则 | 说明 |
|------|------|
| 互补覆盖 | 每个主题至少用 2 种不同工具交叉验证 |
| 优先 exa/searxng | 默认使用 `exa` + `searxng`，避免依赖单一服务商 |
| 语言匹配 | 中文 → `searxng(language=zh)`；英文 → `exa` + `searxng` |
| 深度优先 | 广搜找到 URL → 深读提取全文（exa 结果用 `exa_web_fetch`，其他用 `webfetch`） |
| 代码相关 | 涉及实现 → `github_search_code` + `github_search_repositories` |
| 降级使用 | `web-search-prime` 仅当 searxng 不可用时；`zread` 仅当需特定 repo 文档时 |

**搜索模式**（详见 [references/tool-specs.md#工具组合模式](references/tool-specs.md)）：

| 模式 | 触发条件 | 工具组合 |
|------|---------|---------|
| A 技术方案 | 英文技术调研 | exa → exa_fetch → github_repos → github_code |
| B 中文内容 | 中文主题调研 | searxng(zh) → webfetch → exa 交叉验证 |
| C 代码实现 | 查实现模式 | github_repos → github_code → exa 理论 |
| D 综合 | 默认 | Agent A(exa) + Agent B(searxng) + Agent C(github) |

### 2.3 搜索预算控制

**默认预算：30 次工具调用**（3 agents × 平均 10 次/agent）。

预算分配规则：

| 搜索主题数 | 预算/主题 | 深度阅读/主题 | Agent 分配 |
|-----------|----------|-------------|-----------|
| ≤3 | 10 次 | 2-3 URL | 每个 agent 1 个主题 |
| 4-6 | 5-6 次 | 1-2 URL | 每个 agent 2 个主题 |
| 7+ | 建议→精简到 ≤6（🔒提示用户） | — | — |

预算超限时：停止搜索 → 标注"未完成主题" → 进入 Phase 4。

### 2.4 Agent 分工算法

按搜索模式分配（而非简单按主题数量平分）：

```
主题分组 → 确定主搜索模式 → 按模式分配 agent

Agent A: 模式A(技术方案) 或 模式B(中文) 的主题集合
Agent B: 模式D(综合搜索, searxng 为主) 的主题集合
Agent C: 模式C(代码实现, github 为主) 的主题集合

规则:
- 同一 agent 处理的主题使用相同的主要工具集（减少工具切换开销）
- 若只有1-2个主题 → 只启动 1-2 个 agent，不强制凑满 3 个
- 若某模式无对应主题 → 该 agent 不启动
```

### 2.5 🔒 用户确认

展示：搜索主题列表 + 工具分配方案 + 预估搜索量。

**等用户确认或调整后才进 Phase 3。**

---

## Phase 3: 并行搜索

### 3.1 子 Agent 编排

最多 **3 个子 agent** 并行。按搜索主题分组：

```
Agent A (@librarian): {主题A} + {主题D}
Agent B (@librarian): {主题B} + {主题E}
Agent C (@librarian): {主题C} + {主题F}
```

**Agent 指令模板**（每个 agent 必须先读取 [references/tool-specs.md](references/tool-specs.md) 获取精确参数规范）：

```
研究主题: {主题名}
搜索工具: {分配的工具列表，含具体 query 和参数}
工具规范: 读取 /Users/ganjie/skills/web-research/references/tool-specs.md
项目根目录: {project_root}

任务:
1. 按工具规范中的精确参数调用搜索工具，每个 query 取 top 5-10 结果
2. 对高相关性结果(2-3个)，用 exa_web_fetch_exa 或 webfetch 提取全文
3. 按统一输出格式整理为结构化笔记

统一输出格式（每个来源）:
### 来源 {N}: {标题}
- **URL**: {url}
- **工具**: {工具名}
- **Query**: {使用的搜索 query}
- **相关性**: 高/中/低
- **摘要**: {2-3 句关键发现}
- **全文要点**: {仅全文提取时填写}

约束:
- 只返回与主题直接相关的结果
- 记录每个来源的 URL、工具名、query
- exa query ≤70字符；searxng 支持布尔 AND/OR
- 优先使用 exa/searxng，避免使用 web-search-prime（仅降级用）
- 中文输出
```

### 3.2 搜索执行规范

| 规范 | 说明 |
|------|------|
| 每主题搜索量 | 3-5 个 query，每个取 top 5-10 结果 |
| 深度阅读 | 每主题取最有价值的 2-3 个 URL 提取全文 |
| 超时 | 单个 agent >8min → 终止，返回已有结果 |
| 失败降级 | 工具报错 → 换备选工具继续 |

---

## Phase 4: 收集整理

### 4.1 原始结果归档

将 3 个子 agent 的搜索结果合并，保存到 skill 工作目录：

```
/Users/ganjie/skills/web-research/data/{YYYYMMDD}-{topic-slug}/
├── raw-agent-a.md        # Agent A 原始搜索结果
├── raw-agent-b.md        # Agent B 原始搜索结果
├── raw-agent-c.md        # Agent C 原始搜索结果
└── sources-index.md      # 去重后的来源索引
```

### 4.2 去重去噪

- URL 去重（同一 URL 只保留最详细的记录）
- 内容去重（同一发现来自多来源 → 合并标注）
- 噪音过滤（广告、无关页面 → 移除）
- 生成 `sources-index.md`：`| # | 标题 | URL | 工具 | 质量评级 |`

---

## Phase 5: 综合总结

### 5.1 @oracle 子 Agent 总结

```
你是研究总结专家。请根据以下搜索结果，生成结构化研究报告。

研究主题: {主题}
搜索结果: {Phase 4 整理后的全部内容}

输出要求:
1. 中文
2. 结构: 背景目标 → 核心发现(按子主题分组) → 方案对比(如有) → 结论建议 → 信息源列表
3. 每个发现标注来源 [来源#]
4. 发现之间有交叉验证的特别标注
5. 识别知识空白，标注 "⚠️ 需进一步研究"
```

### 5.2 🔒 用户确认

展示研究报告 → 用户可选择：
- ✅ 确认 → 进 Phase 6
- 🔄 补充搜索 → 回 Phase 2 增加主题
- ✏️ 修改 → 调整报告后重新确认

---

## Phase 6: 持久化

### 6.1 Memory 存储

遵循 [memory skill 标签体系](../memory/SKILL.md)：

| 内容 | tags | type |
|------|------|------|
| 研究概述 | `["global", "reference"]` | reference |
| 关键发现 | `["global", "reference"]` | reference |
| 方案决策 | `["project", "decision"]` | decision |

**存储格式**：

```
content: "{研究主题} 研究: {概述，含关键发现和结论}。本地详细文件: /Users/ganjie/skills/web-research/data/{slug}/"
tags: "global,reference"
type: "reference"
```

**原则**：
- Memory 中存概述（可定位），本地文件存详情（可获取）
- 所有研究内容在 memory 中都有概述条目
- 若 memory 已有相关研究 → 追加更新而非重复存储

### 6.2 项目文档保存

在用户项目目录创建文档：

```
{project_root}/docs/research-{YYYYMMDD}-{topic-slug}/
├── 研究报告.md            # Phase 5 最终报告
├── 搜索资料/              # 原始搜索结果（从 skill data 目录复制）
│   ├── 来源索引.md
│   └── raw-*.md
└── (其他主题文档)
```

---

## 异常处理

| 异常 | 处理 |
|------|------|
| Memory 不可用 | 跳过 Phase 1/6 的 memory 操作，继续搜索流程 |
| 搜索工具全部失败 | 报告用户，建议更换搜索主题或检查网络 |
| 子 agent 超时 | 收集已完成结果，标注"部分搜索" |
| 无搜索结果 | 调整搜索 query，重试一次 → 仍无则报告 |
| 本地无项目目录 | Phase 6.2 跳过项目文档保存 |
| 用户中断 | 保存已有结果到 skill data 目录，不丢失 |
