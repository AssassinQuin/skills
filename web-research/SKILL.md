---
name: web-research
description: >
  多源并行调研元 skill（编排 + 综合）。覆盖三大核心场景：技术选型/方案决策、
  领域深度理解、查证声明+找材料。按主题类型路由到 5 个垂直子 agent：
  tech-compare / academic / product / policy / methodology。
  
  输出双模式（用户可选）：
  - 决策报告（默认）：含明确推荐 + 证据等级 + 风险
  - 知识地图：背景 + 关键概念 + 主流方案 + 灵感 + 知识空白
  
  与 huashu-nuwa 互不重叠：本 skill 专注主题/技术/产品/政策/方法论调研；
  人物思维蒸馏请用 huashu-nuwa。
  
  显式 trigger：调研、研究、搜索研究、web research、对比分析、方案选型、
  文献、literature review、deep dive、技术选型、深度调研、查证。
  隐式 trigger：
  - "X vs Y 哪个好" / "X 还是 Y" / "要不要换 X"  → tech-compare
  - "什么是 X" / "X 现在发展到" / "X 主流方案" / "X 学习路径" → academic / methodology
  - "听说 X 是不是真的" / "验证 X" / "X 的论据" → 视主题路由
  - "准备写 X" / "X 的背景材料" → 视主题路由
  DON'T：人物思维（用 huashu-nuwa）/ skill 评估（用 skill-search）/ 单一事实（直接 WebSearch）。
  
  Output: {skill_dir}/data/{date}-{slug}/
user-invocable: true
skill_type: research
metadata:
  version: "2.3"
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
  - mcp__github__list_releases
  - mcp__zread__search_doc
  - mcp__zread__read_file
  - mcp__zread__get_repo_structure
  - mcp__web-search-prime__web_search_prime
  - WebSearch
  - WebFetch
  - Agent
  - AskUserQuestion
  - Grep
  - Glob
  - Read
  - Bash
  - mcp__memory__memory_search
  - mcp__memory__memory_store
---

# Web Research — 多源并行调研元 skill

**架构**（类似 revfactory/harness）：本 skill 是**编排者**，按主题类型分发到 5 个垂直子 agent，每个 agent 独立解决一类问题。

```
用户请求 → Phase 0 快速判定
        → Phase 1 本地优先
        → Phase 2 意图澄清 + 主题分类
        → Phase 3 分发到垂直 agent（tech-compare/academic/product/policy/methodology）
        → Phase 4 综合 + 双模式输出
```

**MANDATORY**: 中文输出。每个发现必须可追溯真实来源（URL + 工具 + Query）。

## 核心原则（v2.3 用户硬约束）

1. **意图不清必问** — Phase 2 用户意图不明确时 AskUserQuestion（不超过 2 次）
2. **必须头脑风暴** — 每个 agent 内部都有专属 6 维度头脑风暴（见对应 agent 文件）
3. **多语言搜索** — 中英双语 + 主语言优先（详见各 agent "多语言搜索策略"）
4. **不单一信息源** — 每条结论 ≥ 2 独立源（详见各 agent "多源验证"）
5. **代码相关 git mcp 优先** — 代码/框架/库/政策工具相关**强制 git mcp 验证**

## 工具能力图谱

| 能力 | MCP 优先 | 降级链 |
|------|---------|--------|
| **搜索** | `searxng_web_search` | → `web_search_prime` → `WebSearch` |
| **提取** | `web_url_read` | → `webReader` → `WebFetch` |
| **爬取** | `crawl4ai scrape` | → `crawl` → `crawl_site` → `crawl_sitemap` |
| **代码** | `github search_repositories` | → `search_code` → `get_file_contents` → `zread` |

详细参数见 `references/tool-specs.md`。

---

## Phase 0: 快速判定 + 混合任务拆解

| 信号 | 路径 |
|------|------|
| 单一事实 | Phase 0 直接搜 1 次 + 提 1 次，输出答案 + URL |
| 爬取任务 | 直接 crawl4ai，跳 Phase 4.4 保存 |
| 对比/分析/多角度 | 进 Phase 1 |

**混合任务拆解矩阵**（详见 `references/deep-research-tactics.md` §1）。

---

## Phase 1: 本地优先

1. Skill 目录: `glob("{skill_dir}/data/**/*.md")` + grep
2. 项目目录: `glob("{project_root}/docs/**/*.md")` + grep
3. Memory: `mcp__memory__memory_search(query=主题, limit=10)`

命中时展示匹配 + 询问复用/增量/重来。**未命中进 Phase 2**。

---

## Phase 2: 意图澄清 + 主题分类（v2.3 重构核心）

### 2.0 意图不清判定（**必问**）

如果用户请求**不明确**以下任一项，AskUserQuestion（≤ 2 次）：

| 不明确项 | 问题模板 |
|---------|---------|
| 调研目的 | "你是想做技术选型决策？还是想理解领域现状？还是想查证某个声明？" |
| 输出形态 | "你需要决策报告（含推荐）？还是知识地图（无推荐）？" |
| 范围限定 | "有时间范围限制吗？有特定场景吗？排除哪些？" |

**禁止**：意图不清直接进 Phase 3（会产出泛泛报告）。

### 2.1 主题分类 + 路由

按用户意图信号路由到对应垂直 agent：

| 用户意图信号 | 路由到 |
|------------|--------|
| "X vs Y" / "X 还是 Y" / benchmark / 性能场景 | → [`agents/tech-compare.md`](agents/tech-compare.md) |
| "arxiv" / "论文" / "research" / 学术术语 | → [`agents/academic.md`](agents/academic.md) |
| "G2" / "用户评价" / "churn" / SaaS 产品名 | → [`agents/product.md`](agents/product.md) |
| "政策" / "法规" / "政府" / "合规" | → [`agents/policy.md`](agents/policy.md) |
| "方法论" / "原则" / "框架" / "怎么思考 X" | → [`agents/methodology.md`](agents/methodology.md) |

**多主题混合**：并行分发多个 agent + orchestrator 综合（如"X 框架 vs Y 框架的工程方法论" → tech-compare + methodology）。

### 2.2 头脑风暴（orchestrator 层）

每个 agent 内部有自己的 6 维度头脑风暴（见各 agent 文件"头脑风暴"段）。orchestrator 不重复头脑风暴，只协调多 agent 间的角度互补。

### 2.3 🔒 路由确认

展示：路由结果（哪个 agent / 哪几个）+ agent 各自的 query 草案 + 用户确认。

---

## Phase 3: 分发执行

### 3.1 MCP 可用性（运行时降级）

三级失败信号阈值（详见 `references/deep-research-tactics.md` 或 agent-prompt.md）。

### 3.2 Agent 分配

| 主题数 | Agent 数 | 模型 |
|-------|---------|------|
| 1 | 1（路由到的垂直 agent） | sonnet |
| 2 | 2（并行） | sonnet |
| 3-5 | 各 1（并行） | sonnet |

### 3.3 Prompt 注入

读取对应 `agents/{type}.md`，注入：
- 用户原始请求 + 澄清答案
- 可用工具 + 调用参数
- 预算（按桶分，详见 §3.7）

### 3.4 🔒 执行计划确认

展示：路由 agent 列表 + 模型 + 预算 + 用户确认。

### 3.5 执行流程

1. 读 MCP 缓存
2. 按路由 spawn 各 agent（model="sonnet"）
3. 每个 agent 内部按各自文件执行：多语言搜索 + 多源验证 + git mcp + 头脑风暴
4. 收集结果（agent 返回 JSON schema）
5. **跑偏检测**（详见 `references/deep-research-tactics.md` §4）
6. 写入 `raw/agent-{type}-{N}.md`
7. 灵感筛选（详见 §5）→ ≥ 2 条 ≥ 6 分 → 进 3.6 追挖

### 3.6 深度追挖（可选）

触发：≥ 2 条灵感 ≥ 6 分。1 个 sonnet agent 追挖，预算 5-8 次（从单 agent 剩余挪用）。

### 3.7 预算分桶（详见 `references/deep-research-tactics.md` §6）

| 桶 | 预算 |
|---|------|
| orchestrator 探测 | 3 |
| N 个 agent 各 | (24/N) × N |
| orchestrator 综合 | 3 |

超支降级：砍"前沿/趋势" → 砍"灵感" → 保"实战经验/方案对比"。

---

## Phase 4: 综合 + 双模式输出（v2.3 新增输出模式选择）

### 4.0 输出模式选择（已在 Phase 2.0 澄清，此处执行）

| 模式 | 内容 |
|------|------|
| **决策报告**（默认） | 推荐选项 + 理由 + 风险 + 证据等级 |
| **知识地图** | 背景 + 关键概念 + 主流方案 + 灵感 + 知识空白 |

### 4.1 去重 + 证据等级标注

详见 `references/deep-research-tactics.md` §4 证据等级（多源验证/权威单源/矛盾源/知识空白）。

### 4.2 综合报告结构

```
1. 背景与目标（2-3 句 + 用户选择的输出模式）
2. 核心发现（按 agent 输出 + 证据等级）
3. 方案对比（决策报告模式）/ 知识地图（知识地图模式）
4. 💡 意外发现（按灵感评分排序）
5. 结论与建议（决策报告必含推荐 + 风险；知识地图仅含现状）
6. 信息源列表（编号 + URL + 源质量 S/A/B/C/D）
7. ⚠️ 局限性（知识空白 / 单源风险 / 矛盾未解 / 预算超支影响）
```

规则：中文 | 多源交叉验证 | 知识空白标 ⚠️ | 不编造 | 证据等级必标。

### 4.3 🔒 确认

展示报告。选项：✅确认 / 🔄补充搜索 / ✏️修改 / ❌放弃。

### 4.4 持久化

```
{skill_dir}/data/{YYYYMMDD}-{slug}/
├── 研报告.md          # 索引+结论（≤ 150 行）
├── 01-{主题1}.md      # 按 agent 拆分
├── sources.md         # 信息源+知识空白
└── raw/
    ├── agent-{type}-1.md
    ├── agent-{type}-2.md
    └── sources-index.md
```

> 150 行时按 agent 拆。Memory: `{主题}研究: {关键发现}。详情: {路径}`, tags: `global,reference,{type}`。

---

## 异常处理

| 异常 | 处理 |
|------|------|
| 用户意图不清（Phase 2.0 触发） | AskUserQuestion ≤ 2 次 |
| MCP 全不可用 | 降级 WebSearch + WebFetch |
| 搜索无结果 | 放宽 query → 换工具重试 → 仍无则报告 ⚠️ |
| Agent 超时/API 错误 | 收集已完成结果，重试继承剩余预算 |
| AI 生成内容（无 URL） | 不纳入综合 |
| 预算超支 | 报告标注 ⚠️ + 触发降级协议 |
| 单一信息源 | 强制重搜（违反硬约束 #4） |
| 代码相关但未用 git mcp | 强制补 git mcp 验证（违反硬约束 #5） |

---

## 与垂直子 agent 的契约

每个 agent 文件含：
- 路由触发条件
- 多语言搜索策略（中英双语 + 主语言优先）
- 多源验证标准（≥ N 独立源 + 源质量分级）
- git mcp 优先协议（代码相关强制）
- 头脑风暴 6 维度（agent 专属）
- 输出 schema（JSON）
- 跑偏识别自查清单

orchestrator（本 SKILL.md）只做：意图澄清 → 路由 → 协调 → 综合。**不重复 agent 内部工作**。

---

## 相关文件

- 5 个垂直 agent: [`agents/tech-compare.md`](agents/tech-compare.md) / [`academic.md`](agents/academic.md) / [`product.md`](agents/product.md) / [`policy.md`](agents/policy.md) / [`methodology.md`](agents/methodology.md)
- 高级战术: [`references/deep-research-tactics.md`](references/deep-research-tactics.md)（信号矩阵 / 主题分类 / 跑偏信号 / 灵感评分 / 预算分桶）
- 子 agent prompt 基类: [`references/agent-prompt.md`](references/agent-prompt.md)
- MCP 工具规范: [`references/tool-specs.md`](references/tool-specs.md)
