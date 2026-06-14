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
  - mcp__github__get_file_contents
  - mcp__github__get_repo_structure
  - mcp__github__list_issues
  - mcp__searxng__searxng_web_search
  - mcp__searxng__web_url_read
  - mcp__web-search-prime__web_search_prime
  - mcp__web-reader__webReader
  - mcp__zread__get_repo_structure
  - mcp__zread__read_file
  - mcp__plugin_context-mode_context-mode__ctx_batch_execute
  - mcp__plugin_context-mode_context-mode__ctx_search
  - Agent
  - Bash
  - Read
  - Write
  - Grep
  - Glob
  - WebSearch
  - WebFetch
user-invocable: true
metadata:
  version: "4.0"
---

# Skill Search — 搜索·筛选·评估·推荐

根据用户需求，多源搜索候选 Skill，按 exit-checklist 驱动的流程筛选评估，输出结构化推荐报告并保存到本地。

**每个 Phase 有 exit-checklist，全部通过才能进入下一阶段。** 见 [execution-gates.md](references/execution-gates.md)。

## 输入

- 功能需求："找一个代码审查的 skill"
- 场景描述："我想让 Agent 帮我做 TDD"
- 已有候选："skill-evolver 和 darwin-skill 哪个好"
- 技术栈限定："Go 项目的 skill" / "兼容 OpenCode 的 skill"

模糊输入先追问一次（"你主要想解决什么场景？"），不超过 2 次。

## 流程

```
P1 需求 → P2 多源搜索 → P3 粗筛 → P4 深读 → P5 社区口碑 → P6 报告+保存
              ↓              ↓          ↓          ↓
         [exit-check]   [exit-check] [exit-check] [exit-check]
         不通过→补完      不通过→补完   不通过→补完  不通过→补完
```

### P1: 需求解析

提取四组搜索词，各准备中英双语：

| 组 | 作用 | 举例（code review） |
|---|---|---|
| 功能词 | 核心能力 | code review / 代码审查 |
| 同义词 | 等价说法 | PR review, diff review, code audit, adversarial review |
| 上下游 | 相关领域 | static analysis, lint, security audit |
| 生态词 | 知名合集 | superpowers, pm-skills, best-skills |

### P2: 多源并行搜索

5 个子 Agent（`subagent_type="general-purpose"`, `model="sonnet"`）并行，搜索词模板见 [search-templates.md](references/search-templates.md)：

| 子 Agent | 搜索源 | 核心规则 |
|----------|--------|---------|
| Scout-GH | GitHub | **只用 `search_repositories`**，禁止 `search_code` |
| Scout-BuiltIn | 本地 + Marketplace | 三层全执行（本地 ls + marketplaces.json + Web），不允许跳过 |
| Scout-Market | 垂直平台 | 直接访问 skillsmp.com/openagentskill.com，不依赖 SearXNG |
| Scout-Community | 社区 | 中英文分别搜索，分开记录，标记 `EN`/`CN` |
| Scout-Expand | 已发现→扩展 | Top 3 候选的关联网络、fork、credits、topics |

5 个 Scout 在同一个 tool_calls 块中并行 spawn；Spawn 失败时主 Agent 串行执行，P6 报告标注 `[L2-FALLBACK]`。

**exit-checklist 不通过 → 停在 P2 补完，不进入 P3。**

### P3: 粗筛（数字门控）

| 指标 | 阈值 |
|------|------|
| Stars | ≥ 10（优选 ≥ 100） |
| 有 SKILL.md | 必须有 |
| Open/Close Issue 比 | open < 2× closed |

保留 Top 5（不足 5 全部保留）。淘汰的记录原因（一行）。

### P4: 深读（内容分析）

**必须先 `mcp__zread__get_repo_structure`**，处理多 Skill 仓库（SKILL.md 可能在 `skills/` 子目录）。

文件读取优先用 `mcp__zread__read_file`（GitHub MCP `get_file_contents` 在 Claude Code 中只返回 SHA 不展示内容）。

必读：`SKILL.md` → `README.md` → `examples/`。评分见 [evaluation-rubric.md](references/evaluation-rubric.md)。

### P5: 社区口碑（中英文分别采集）

英文源（Reddit/HN/Medium/Dev.to）和中文源（知乎/V2EX/掘金/CSDN）各自独立搜索、独立记录。每条标注来源语言 + 日期。两边的差异必须指出。

同时读 GitHub Issues：长期未解 bug、feature request、维护者回复速度、Issue 语言分布。

### P6: 综合报告 + 本地保存

每个候选包含：来源 / Stars / 一句话定位 / 优缺点（附证据链接）/ 典型 Issue / 社区反馈—英文源 / 社区反馈—中文源 / 安装建议 / 适合谁

报告末尾：淘汰记录 + 搜索覆盖统计 + 搜索查询记录（中英文分开）+ 执行透明度声明（spawn 数 + L2 fallback 标注）。

**本地保存**（与 web-research 一致）：

```
{skill_dir}/data/{YYYYMMDD}-{slug}/
├── 搜索报告.md          # P6 综合报告
├── 候选-Top5.md         # Top 5 详细评分
├── 淘汰记录.md          # P3 粗筛淘汰原因
├── sources.md           # 搜索查询记录
└── raw/                 # 子 Agent 原始输出
    └── scout-{role}.json
```

下次相似需求先 `glob("{skill_dir}/data/**/*.md")` + `grep(关键词)` 查历史档案，避免重复搜索。

## 硬约束

1. **exit-checklist 不可跳过** — 每个 Phase 结束执行对应清单，未通过就停在当前阶段
2. **`search_code` 禁用于 P2 发现** — 只用于 P4 验证候选是否有 SKILL.md
3. **垂直平台优先于 SearXNG** — SearXNG 对 Skill 生态理解差，英文搜索走 skillsmp.com / openagentskill.com
4. **P4 必须先检查目录结构** — 不假设 SKILL.md 在根目录
5. **子 Agent 必须指定 model** — 启动子 Agent 用 `Agent` 工具（不是 `TaskCreate`），subagent_type 用 Claude Code 内置（`general-purpose`/`Explore`）或全局 `~/.claude/agents/` 已注册的；搜索用 sonnet，分析评估用 opus
6. **P4 文件读取禁用 get_file_contents 读内容** — 用 `mcp__zread__read_file` 或 `WebFetch raw URL` 替代
7. **本地保存强制** — P6 必须保存到 `{skill_dir}/data/{YYYYMMDD}-{slug}/`，下次相似需求先 grep 历史
