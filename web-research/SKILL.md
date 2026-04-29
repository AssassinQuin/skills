---
name: web-research
description: >
  Multi-source research skill. Triggers: 'research', '调研', '研究', '搜索研究',
  'web research', 'search and analyze', '查找资料', '搜集信息', 'investigate',
  'study', '调研报告', '技术调研', '方案调研', '文献', 'literature review',
  'deep dive', '研究报告', '技术调研报告'.
  Workflow: local-first scan → brainstorm → search → summarize → persist.
  Output: structured research report in {skill_dir}/data/.
---

# Web Research Skill

多源并行调研：本地优先 → 头脑风暴 → 搜索 → 综合 → 持久化。

**语言：面向用户中文。每个发现必须可追溯真实来源。**

## 核心原则

```
搜索优先级：skill目录已有 → 项目目录已有 → memory已有 → 网络搜索
保存策略：原始数据+最终报告统一存 {skill_dir}/data/（跨项目复用）
Token效率：工具参数详见 references/tool-specs.md，SKILL.md 只定义流程
```

## 流程概览

```
Phase 0: 快速判定    → 小查询直接答 / 深度调研走完整流程
Phase 1: 本地优先    → skill目录 → 项目目录 → memory（任一命中可短路）
Phase 2: 头脑风暴    → 搜索主题 + 工具方案 + 🔒确认
Phase 3: 并行搜索    → ≤3 子agent 分工搜索
Phase 4: 综合+持久化 → 去重 → @oracle总结 → 🔒确认 → 保存到skill目录 + memory
```

---

## Phase 0: 快速判定

评估用户请求规模：

| 信号 | 判定 | 路径 |
|------|------|------|
| 单一事实（"Exa pricing是什么"） | 快速查询 | 直接用 exa/tavily 搜1-2次，返回答案+来源，不进完整流程 |
| 对比/分析/多角度 | 深度调研 | 进 Phase 1 |

---

## Phase 1: 本地优先扫描

**目标**：复用已有研究，避免重复搜索。按优先级依次扫描，任一级命中可短路。

### 1.1 Skill 目录扫描（最高优先级）

```
glob(pattern="{skill_dir}/data/**/*.md")
grep(pattern="{研究主题关键词}", path="{skill_dir}/data/")
```

**命中判定**：
- 找到相关文件 → 读取内容 → 展示摘要 → 🔒询问："直接复用 / 增量更新 / 重新开始"
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
memory_search(query="{研究主题}", tags=["project","context"], limit=10)
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

### 2.2 工具分配

工具参数规范见 **[references/tool-specs.md](references/tool-specs.md)**。

**分配原则**（简表）：

| 原则 | 说明 |
|------|------|
| 每主题≥2工具交叉验证 | exa/tavily + duckduckgo/brave |
| 优先 tavily/exa | 默认主力 |
| 免费降级 | tavily不可用 → duckduckgo → web-search-prime |
| 中文→tavily(cn)/duckduckgo(cn-zh) | 英文→exa+tavily |
| 涉及代码→github_search | 查实现模式 |

**搜索模式**：

| 模式 | 场景 | 工具 |
|------|------|------|
| A 技术方案 | 英文技术 | exa→tavily→fetch→github |
| B 中文内容 | 中文主题 | tavily(cn)/duckduckgo(cn-zh)→webfetch→exa交叉 |
| C 代码实现 | 实现模式 | github_repos→github_code→exa理论 |
| D 综合 | 默认 | A+B+C混合，≤3 agent分工 |

### 2.3 预算

默认 30 次工具调用（3 agents × 10次/agent）。超限停止→标注"未完成"→进 Phase 4。

### 2.4 🔒 用户确认

展示：主题列表 + 工具方案 + 预估调用数。确认后进 Phase 3。

---

## Phase 3: 并行搜索

最多 **3 个 @librarian 子agent** 并行。按 2.2 模式分组。

**Agent 指令**（精简模板）：

```
研究主题: {主题名}
工具: {工具列表+具体query}
工具规范: 读取 {skill_dir}/references/tool-specs.md

任务:
1. 按规范调用搜索工具，每query取top 5-10结果
2. 高相关结果(2-3个)提取全文
3. 按统一格式输出

输出格式（每个来源）:
### 来源 {N}: {标题}
- **URL**: {url} | **工具**: {工具名} | **Query**: {query}
- **相关性**: 高/中/低
- **摘要**: {2-3句}
- **全文要点**: {仅全文提取时}

约束: 中文输出 | 只返回相关结果 | 记录URL+工具+query
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

**项目 docs 软链接**（可选，仅当用户需要项目内可见时）：
```
{project_root}/docs/research-{slug} → {skill_dir}/data/{slug}/研究报告.md
```
> 不复制，只写一个简短的 README.md 指向 skill 目录中的完整报告。

---

## 异常处理

| 异常 | 处理 |
|------|------|
| Memory不可用 | 跳过memory操作，继续搜索 |
| 搜索工具全部失败 | 报告用户，建议换主题或检查网络 |
| 子agent超时 | 收集已完成结果，标注"部分搜索" |
| 无搜索结果 | 调整query重试一次→仍无则报告 |
| 用户中断 | 保存已有结果到skill目录 |
| skill_dir不存在 | 用mkdir -p创建 |
