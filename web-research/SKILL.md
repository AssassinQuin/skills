---
name: web-research
description: >
  Multi-source research skill. Triggers: 'research', '调研', '研究', '搜索研究',
  'web research', 'search and analyze', '查找资料', '搜集信息', 'investigate',
  'study', '调研报告', '技术调研', '方案调研', '文献', 'literature review',
  'deep dive', '研究报告', '技术调研报告'.
  Workflow: local-first scan → brainstorm → parallel search → summarize → persist.
  Output: structured research report in {skill_dir}/data/.
allowed-tools:
  - searxng_searxng_web_search
  - searxng_web_url_read
  - exa_web_search_exa
  - exa_web_fetch_exa
  - websearch_web_search_exa
  - webfetch
  - github_search_repositories
  - github_search_code
  - github_get_file_contents
  - github_list_commits
  - web-search-prime_web_search_prime
  - zread_search_doc
  - zread_read_file
  - zread_get_repo_structure
  - memory_memory_search
  - memory_memory_store
---

# Web Research Skill

多源并行调研：本地优先 → 头脑风暴 → 搜索 → 综合 → 持久化。

**语言：面向用户中文。每个发现必须可追溯真实来源。**
**工具原则：优先非智普 MCP 服务（SearXNG > Exa > GitHub），智普工具仅作最后 fallback。**

## 核心原则

```
搜索优先级：skill目录已有 → 项目目录已有 → memory已有 → 网络搜索
工具优先级：SearXNG(开源聚合) → Exa(语义搜索) → GitHub(API) → webfetch(兜底) → 智普(fallback)
保存策略：原始数据+最终报告统一存 {skill_dir}/data/（跨项目复用）
Token效率：工具参数详见 references/tool-specs.md，SKILL.md 只定义流程
```

## 三链工具体系

| 链 | 主工具 | 最佳场景 |
|----|--------|---------|
| **A SearXNG** | `searxng_web_search` + `searxng_web_url_read` | 通用搜索、中文、时效性、URL内容提取 |
| **B Exa** | `exa_web_search_exa` + `exa_web_fetch_exa` | 英文技术/学术语义搜索、批量全文提取 |
| **C GitHub** | `github_search_*` + `github_get_file_contents` | 开源项目发现、代码搜索、仓库文档深挖 |
| 兜底 | `webfetch` | 页面提取、llms.txt 探测 |
| 智普fallback | `web-search-prime`, `zread_*` | 仅当 Tier 1 全部不可用时 |

## 流程概览

```
Phase 0: 快速判定    → 小查询直接答 / 深度调研走完整流程
Phase 1: 本地优先    → skill目录 → 项目目录 → memory（任一命中可短路）
Phase 2: 头脑风暴    → 搜索主题 + 工具链分配 + 🔒确认
Phase 3: 并行搜索    → ≤3 子agent 分工搜索（按链分工）
Phase 4: 综合+持久化 → 去重 → @oracle总结 → 🔒确认 → 保存到skill目录 + memory
```

---

## Phase 0: 快速判定

评估用户请求规模：

| 信号 | 判定 | 路径 |
|------|------|------|
| 单一事实（"Exa pricing是什么"） | 快速查询 | 直接用 searxng/exa 搜1-2次，返回答案+来源，不进完整流程 |
| 对比/分析/多角度 | 深度调研 | 进 Phase 1 |

---

## Phase 1: 本地优先扫描

**目标**：复用已有研究，避免重复搜索。按优先级依次扫描，任一级命中可短路。

### 1.1 Skill 目录扫描（最高优先级）

**Step 1 关键词匹配**：
```
glob(pattern="{skill_dir}/data/**/*.md")
grep(pattern="{研究主题关键词}", path="{skill_dir}/data/")
```

**Step 2 语义补充**（关键词未命中时）：
```
memory_search(query="{研究主题}", mode="semantic", limit=5)
```

**命中判定**：
- 任一步找到相关内容 → 读取 → 展示摘要 → 🔒询问："直接复用 / 增量更新 / 重新开始"
- 选择"直接复用" → 跳到 Phase 4 仅做总结
- 选择"增量更新" → Phase 2 仅搜索已有研究未覆盖的方向

### 1.2 项目目录扫描

```
glob(pattern="{project_root}/docs/**/*.md")
grep(pattern="{研究主题关键词}", path="{project_root}/docs/")
```

**命中处理**：同 1.1，纳入 Phase 2 头脑风暴上下文。

### 1.3 Memory 检索

```
memory_search(query="{研究主题} 研究 调研", tags=["global","reference"], limit=10)
```

**命中处理**：展示摘要 → 纳入 Phase 2 上下文。

### 1.4 无命中

直接进 Phase 2。

---

## Phase 2: 头脑风暴与搜索方案

### 2.1 搜索主题

基于 Phase 1 上下文 + 用户需求，生成 3-6 个搜索主题：

```markdown
1. **{主题A}** — {为什么相关，期望找到什么}
2. **{主题B}** — ...
```

### 2.2 工具链分配

工具参数规范见 **[references/tool-specs.md](references/tool-specs.md)**。

**分配规则**（按语言和内容类型选链）：

| 主题类型 | 主链 | 交叉验证链 |
|----------|------|-----------|
| 中文内容 | A (SearXNG, language=zh) | B (Exa 英文交叉) |
| 英文技术/学术 | B (Exa 语义搜索) | A (SearXNG 交叉) |
| 代码/开源实现 | C (GitHub) | A (SearXNG 搜 site:github.com) |
| 时效性新闻 | A (SearXNG, time_range=day/week) | — |
| 综合调研 | A+B+C 混合 | 交叉验证 |

**每主题至少 2 个工具交叉验证**（如 SearXNG + Exa，或 Exa + GitHub）。

**智普工具使用条件**：仅在 SearXNG 和 Exa 均不可用时，才能使用 `web-search-prime` 或 `zread_*`，且必须在输出中标注 `⚠️ 智普fallback`。

### 2.3 预算

默认 30 次工具调用（3 agents × 10次/agent）。超限停止→标注"未完成"→进 Phase 4。

### 2.4 🔒 用户确认

展示：主题列表 + 工具方案 + 预估调用数。确认后进 Phase 3。

---

## Phase 3: 并行搜索

最多 **3 个子agent** 并行。按工具链分工，非按主题分工。

> **角色要求**：优先使用 @librarian（擅长文档检索）。若环境无 @librarian 角色，直接用通用 @explorer 或 @fixer 替代。

**典型 Agent 分工**（综合调研）：

```
Agent 1 (链A+B): SearXNG 通用搜索 + Exa 语义搜索
  工具: searxng_web_search, searxng_web_url_read,
        exa_web_search_exa, exa_web_fetch_exa
  职责: 主搜索 + 内容提取 + 交叉验证

Agent 2 (链C): GitHub 代码搜索
  工具: github_search_repositories, github_search_code,
        github_get_file_contents, github_list_commits
  职责: 开源项目发现 + 代码模式 + 仓库文档深挖

Agent 3 (交叉验证): 对前两个 agent 的高价值发现做补充搜索
  工具: searxng_web_search, webfetch
  职责: 补充搜索 + 验证关键结论 + 提取遗漏内容
```

**Agent 指令模板**：

```
研究主题: {主题名}
工具链: {链标识 + 具体工具}
工具规范: 读取 {skill_dir}/references/tool-specs.md

任务:
1. 按规范调用搜索工具，每query取top 5-10结果
2. 高相关结果(2-3个)提取全文（用 searxng_web_url_read 或 exa_web_fetch_exa）
3. 按统一格式输出

输出格式（每个来源）:
### 来源 {N}: {标题}
- **URL**: {url} | **工具**: {工具名} | **Query**: {query}
- **相关性**: 高/中/低
- **摘要**: {2-3句}
- **全文要点**: {仅全文提取时}

约束:
- 中文输出
- 只返回相关结果
- 记录URL+工具+query（必须可追溯）
- 优先使用 SearXNG/Exa/GitHub，避免使用智普工具
- 如果智普工具被使用，标注 ⚠️ 智普fallback
```

---

## Phase 4: 综合 + 持久化

### 4.1 去重去噪

- URL去重 | 内容去重（多来源合并标注） | 噪音过滤

### 4.2 @oracle 综合报告

```
你是研究总结专家。根据搜索结果生成结构化报告。

主题: {主题}
数据: {Phase 4.1整理结果}

结构: 背景与目标 → 核心发现(标注[来源#]) → 方案对比(仅对比型) → 结论与建议 → 信息源列表
规则: 中文 | 交叉验证标注[来源A,B验证] | 知识空白标⚠️ | 不编造
```

### 4.3 🔒 用户确认

展示报告。选项：✅确认 / 🔄补充搜索(回Phase 2) / ✏️修改 / ❌放弃

### 4.4 持久化

**保存到 skill 目录**（权威位置，跨项目复用）：

```
{skill_dir}/data/{YYYYMMDD}-{topic-slug}/
├── 研究报告.md
├── raw/
│   ├── agent-a.md
│   ├── agent-b.md
│   └── sources-index.md
```

**Memory 存储**（概述，可定位）：

```
content: "{主题}研究: {概述，含关键发现和结论}。详情: {skill_dir}/data/{slug}/"
tags: "global,reference"
```

---

## 异常处理

| 异常 | 处理 |
|------|------|
| Memory不可用 | 跳过memory操作，继续搜索 |
| SearXNG 不可用 | 降级到 Exa → 再不可用用 web-search-prime（智普fallback，标注⚠️） |
| Exa 限流/超时 | 降级到 SearXNG，重试1次 |
| GitHub search 无结果 | 放宽条件（去掉 stars/language 过滤），或 SearXNG 搜 `site:github.com` |
| 全文提取失败 | 保留搜索摘要，标注"无法提取全文" |
| 子agent超时 | 收集已完成结果，标注"部分搜索" |
| 无搜索结果 | 调整query重试一次→仍无则报告 |
| 用户中断 | 保存已有结果到skill目录 |
| skill_dir不存在 | 用mkdir -p创建 |
| Tier 1 全部不可用 | 使用智普工具（web-search-prime + zread），报告标注 `⚠️ 智普fallback模式` |
