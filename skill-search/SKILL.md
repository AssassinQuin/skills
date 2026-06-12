---
name: skill-search
description: >
  Skill 搜索与评估引擎。根据用户需求，在 GitHub、Plugin Marketplace、Skill 垂直平台、社区中搜索、筛选、
  深度分析候选 Skill，输出带评分的排序推荐报告。
  覆盖：多语言搜索、内置/商城/垂直平台/社区四源并行、同义词与关联词扩展、exit-checklist 强制门控、
  中英文社区反馈分别采集。
  触发词：找 skill、搜索 skill、skill 推荐、skill 选型、找 X skill、有没有 X 的 skill、
  skill search、find skill、recommend skill、skill comparison、skill 选哪个、
  哪个 skill 好、skill 横评、skill 对比、帮我找一个 skill、有什么好的 X skill。
  不用于：创建 skill（用 skill-creator）、进化 skill（用 skill-evolver）、写代码（用 coder）。
allowed-tools:
  - mcp__github__search_repositories
  - mcp__github__search_code
  - mcp__github__get_file_contents
  - mcp__github__get_repo_structure
  - mcp__github__list_issues
  - mcp__github__search_issues
  - mcp__github__list_commits
  - mcp__searxng__searxng_web_search
  - mcp__searxng__web_url_read
  - mcp__web-search-prime__web_search_prime
  - mcp__web-reader__webReader
  - WebSearch
  - WebFetch
  - Agent
  - Read
  - Write
  - Bash
  - Grep
  - Glob
user-invocable: true
metadata:
  version: "3.0"
---

# Skill Search — 搜索·筛选·评估·推荐

根据用户需求，多源搜索候选 Skill，按 exit-checklist 驱动的流程筛选评估，输出结构化推荐报告。

**每个 Phase 有 exit-checklist，全部通过才能进入下一阶段。** 见 [execution-gates.md](references/execution-gates.md)。

## 输入

- 功能需求："找一个代码审查的 skill"
- 场景描述："我想让 Agent 帮我做 TDD"
- 已有候选："skill-evolver 和 darwin-skill 哪个好"
- 技术栈限定："Go 项目的 skill" / "兼容 OpenCode 的 skill"

模糊输入判断：缺少功能关键词（只说"帮我找个 skill"无任何领域信息）→ 追问一次"你主要想解决什么场景？"，不超过 2 次。明确输入（含功能词/技术栈/已有候选名）直接开始 P1。

## 流程

```
P1 需求 → P2 多源搜索 → P3 粗筛 → P4 深读 → P5 社区口碑 → P6 报告
              ↓              ↓          ↓          ↓
         [exit-check]   [exit-check] [exit-check] [exit-check]
```

### P1: 需求解析

提取四组搜索词，各准备中英双语：

| 组 | 作用 | 举例（code review） |
|---|---|---|
| 功能词 | 核心能力 | code review / 代码审查 |
| 同义词 | 等价说法 | PR review, diff review, code audit, adversarial review |
| 上下游 | 相关领域 | static analysis, lint, security audit |
| 生态词 | 知名合集 | superpowers, pm-skills, best-skills |

### P2: 多源并行搜索（强制 Agent 并行）

**必须使用 `Agent()` 并行调用 ≥ 3 个子 Agent。禁止主 Agent 串行替代。**

5 个子 Agent，搜索模板见 [search-templates.md](references/search-templates.md)：

| 子 Agent | subagent_type | model | 搜索源 | 核心规则 |
|----------|--------------|-------|--------|---------|
| Scout-GH | `scout-gh` | sonnet | GitHub | 只用 `search_repositories`，禁止 `search_code` |
| Scout-BuiltIn | `scout-builtin` | sonnet | 本地 + Marketplace | 三层全执行，不允许跳过 |
| Scout-Market | `scout-market` | sonnet | 垂直平台 | 直接访问 skillsmp.com 等，不依赖 SearXNG |
| Scout-Community | `scout-community` | sonnet | 社区 | 中英文分别搜索，标记 `EN`/`CN` |
| Scout-Expand | `scout-expand` | sonnet | 已发现→扩展 | Top 3 候选的关联网络 |

**调用结构**（P2 入口必须执行）：

```
并行调用 Agent()（在单个 tool_calls 块中）：
  1. Scout-GH：用功能词+同义词+上下游词搜索 GitHub 仓库
  2. Scout-BuiltIn：三层扫描（本地 → marketplace → Web）
  3. Scout-Market：垂直平台直接访问
  4. Scout-Community（可选，与 1-3 并行）：社区搜索

收到结果后：
  5. Scout-Expand：对 Top 3 候选执行扩展搜索
```

**exit-checklist 不通过 → 停在 P2 补完，不进入 P3。**

### P3: 粗筛（数字门控）

| 指标 | 阈值 |
|------|------|
| Stars | ≥ 10（优选 ≥ 100） |
| 有 SKILL.md | 必须有 |
| Open/Close Issue 比 | open < 2× closed |

保留 **min(候选数, 5)** 个。淘汰的记录原因（一行）。

### P4: 深读（内容分析）

**必须先 `get_repo_structure`**，处理多 Skill 仓库（SKILL.md 可能在 `skills/` 子目录）。

必读：`SKILL.md` → `README.md` → `examples/`。评分见 [evaluation-rubric.md](references/evaluation-rubric.md)。

**自检**：P4 开始前确认 P2 未使用 `search_code` 做发现。若发现使用了，丢弃其结果并用 `search_repositories` 重搜。

### P5: 社区口碑（中英文分别采集）

英文源（Reddit/HN/Medium/Dev.to）和中文源（知乎/V2EX/掘金/CSDN）各自独立搜索、独立记录。每条标注来源语言 + 日期。两边的差异必须指出。

同时读 GitHub Issues：长期未解 bug、feature request、维护者回复速度、Issue 语言分布。

### P6: 综合报告

输出到用户指定位置或当前目录。每个候选包含：

来源 / Stars / 一句话定位 / 优缺点（附证据链接）/ 典型 Issue / 社区反馈—英文源 / 社区反馈—中文源 / 安装建议 / 适合谁

报告末尾：淘汰记录 + 搜索覆盖统计（GitHub/Marketplace/内置/英文社区/中文社区）+ 搜索查询记录（中英文分开）。

## 硬约束

1. **exit-checklist 不可跳过** — 每个 Phase 结束执行对应清单，未通过就停在当前阶段
2. **`search_code` 禁用于 P2 发现** — 只用于 P4 验证候选是否有 SKILL.md
3. **垂直平台优先于 SearXNG** — SearXNG 对 Skill 生态理解差，英文搜索走 skillsmp.com / openagentskill.com
4. **P4 必须先检查目录结构** — 不假设 SKILL.md 在根目录
5. **P2 必须并行调用 ≥ 3 个子 Agent** — 禁止主 Agent 串行执行 Scout 任务
6. **子 Agent 必须指定 model** — 搜索用 sonnet，分析评估用 opus
