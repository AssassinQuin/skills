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

为每个搜索主题选择最适合的工具组合：

| 工具 | 适用场景 | 搜索类型 |
|------|---------|---------|
| `exa_web_search` | 语义搜索、高质量内容、学术/技术 | 自然语言 query |
| `searxng_web_search` | 广泛搜索、多源聚合、新闻/博客 | 关键词 query |
| `web-search-prime` | 中文内容、国内信息 | 中文 query |
| `zread_search_doc` | GitHub 仓库文档、开源项目 | repo_name + query |
| `github_search_code` | 代码实现模式、具体用法 | 代码片段搜索 |
| `github_search_repositories` | 发现相关开源项目 | repo 搜索 |
| `exa_web_fetch` | 读取搜索结果中的具体页面 | URL 提取全文 |
| `@explorer` (本地) | 项目代码库中的相关实现 | glob + grep |

**分配原则**：

| 原则 | 说明 |
|------|------|
| 互补覆盖 | 每个主题至少用 2 种不同工具交叉验证 |
| 语言匹配 | 中文主题 → `web-search-prime` + `searxng`；英文主题 → `exa` + `searxng` |
| 深度优先 | 广搜（searxng/exa）找到 URL → 深读（exa_web_fetch/webfetch）提取全文 |
| 代码相关 | 涉及实现 → 额外加 `github_search_code` 或 `zread` |

### 2.3 🔒 用户确认

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

**Agent 指令模板**：

```
研究主题: {主题名}
搜索工具: {分配的工具列表，含具体 query}
项目根目录: {project_root}

任务:
1. 用指定工具搜索，每个 query 返回 top 5-10 结果
2. 对最有价值的 2-3 个结果，用 exa_web_fetch 或 webfetch 提取全文
3. 整理为结构化笔记

输出格式 (markdown):
## {主题名} 搜索结果

### 来源 1: {标题}
- URL: {url}
- 工具: {使用的搜索工具}
- 摘要: {2-3 句关键发现}
- 全文要点: {提取的核心内容}

### 来源 2: ...
---

约束:
- 只返回与主题直接相关的结果
- 记录每个来源的 URL 和搜索工具
- 如发现与主题不相关，跳过不记录
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
