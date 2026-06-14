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
  - ToolSearch
  - Task
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - WebSearch
  - WebFetch
  - AskUserQuestion
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
  - mcp__zread__get_repo_structure
  - mcp__zread__read_file
  - mcp__zread__search_doc
  - mcp__plugin_context-mode_context-mode__ctx_batch_execute
  - mcp__plugin_context-mode_context-mode__ctx_execute
  - mcp__plugin_context-mode_context-mode__ctx_search
  - mcp__plugin_context-mode_context-mode__ctx_index
user-invocable: true
metadata:
  version: "3.1"
---

# Skill Search — 搜索·筛选·评估·推荐

根据用户需求，多源搜索候选 Skill，按 exit-checklist 驱动的流程筛选评估，输出结构化推荐报告。

**每个 Phase 有 exit-checklist，全部通过才能进入下一阶段。** 见 [execution-gates.md](references/execution-gates.md)。

工具调用规范集中维护在 [tool-usage.md](references/tool-usage.md) — 修改工具调用方式时只改该文件。

## 流程

```
P0 工具加载 → P1 需求解析 → P2 多源搜索 → P3 粗筛 → P4 深读 → P5 社区口碑 → P6 报告
   ↓            ↓              ↓             ↓          ↓          ↓
[AskUser]    [AskUser]      [AskUser]    [AskUser]  [AskUser]  [AskUser]
```

每个 Phase 结束必须调用 `AskUserQuestion` 强制确认。未收到确认禁止进入下一 Phase。

---

## P0: 工具加载前置（强制，不可跳过）

Claude Code 中以下工具是 **deferred**（懒加载），不预先加载会导致后续调用反复失败：

```bash
# 在 P0 入口必须执行的 Bash 命令（一次完成所有加载）
# 注意：ToolSearch select 命中后只是"注册"，不保证返回 schema。
# 即使返回空，工具也已可用——直接尝试调用即可。
```

调用顺序：

```
ToolSearch query="select:Task,Bash,WebFetch,AskUserQuestion" max_results=5
ToolSearch query="select:mcp__github__search_repositories,mcp__github__get_file_contents,mcp__github__get_repo_structure" max_results=5
ToolSearch query="select:mcp__web-search-prime__web_search_prime,mcp__web-reader__webReader,WebSearch" max_results=5
ToolSearch query="select:mcp__zread__get_repo_structure,mcp__zread__read_file" max_results=5
ToolSearch query="select:mcp__plugin_context-mode_context-mode__ctx_batch_execute,mcp__plugin_context-mode_context-mode__ctx_search" max_results=5
```

加载验证（调用一次确保 schema 可用）：

```
Bash: echo "tools loaded"
```

如果加载失败：在 P6 报告中标注 `[TOOL-LOAD-FAIL]` 并降级到 WebSearch-only 模式。

---

## P1: 需求解析

提取四组搜索词，各准备中英双语：

| 组 | 作用 | 举例（code review） |
|---|---|---|
| 功能词 | 核心能力 | code review / 代码审查 |
| 同义词 | 等价说法 | PR review, diff review, code audit, adversarial review |
| 上下游 | 相关领域 | static analysis, lint, security audit |
| 生态词 | 知名合集 | superpowers, pm-skills, best-skills |

模糊输入判断：缺少功能关键词（只说"帮我找个 skill"无任何领域信息）→ 用 `AskUserQuestion` 追问一次"你主要想解决什么场景？"，不超过 2 次。明确输入直接开始 P2。

### P1 Exit Checklist + AskUser 确认点

```
□ 四组搜索词已生成（中英双语）
□ AskUserQuestion 确认搜索词范围
   - 选项 A：使用当前搜索词进入 P2
   - 选项 B：用户补充/调整搜索词
   - 选项 C：限定技术栈/平台
```

---

## P2: 多源并行搜索

### 主路径：Agent() 并行（推荐）

启动 5 个子 Agent 并行执行（必须在单个 tool_calls 块中并行调用）：

| 子 Agent | subagent_type | model | 搜索源 | 核心规则 |
|----------|--------------|-------|--------|---------|
| Scout-GH | `scout-gh` | sonnet | GitHub | 只用 `search_repositories`，禁止 `search_code` |
| Scout-BuiltIn | `scout-builtin` | sonnet | 本地 + Marketplace | 三层全执行，不允许跳过 |
| Scout-Market | `scout-market` | sonnet | 垂直平台 | 直接访问 skillsmp.com 等，不依赖 SearXNG |
| Scout-Community | `scout-community` | sonnet | 社区 | 中英文分别搜索，标记 `EN`/`CN` |
| Scout-Expand | `scout-expand` | sonnet | 已发现→扩展 | Top 3 候选的 fork、credits、topics、关联项目 |

**Agent() 调用模板**（完整代码示例，详见 [tool-usage.md#agent-template](references/tool-usage.md#agent-template)）：

```
Task(
  subagent_type="scout-gh",
  model="sonnet",
  description="Scout-GH: GitHub 仓库搜索",
  prompt="你是 Scout-GH 子 agent。任务：用 mcp__github__search_repositories 搜索 {功能词}/{同义词}/{上下游词}。每个搜索词独立调用，sort=stars。返回 JSON 数组：[{full_name, stars, forks, open_issues, html_url, description, topics}]，至少 5 个候选。禁止用 search_code 做发现。"
)
```

5 个子 Agent 必须在**同一个 tool_calls 块**中并行调用。等待全部返回后聚合结果。

### Fallback 路径：主 Agent 串行（L2 降级）

**触发条件**：尝试 `ToolSearch select:Task` 后调用 `Task()` 报错，或连续 2 次返回空 schema。

**降级流程**：
1. 在 P6 报告附录标注 `[L2-FALLBACK] 子 Agent 无法 spawn，主 Agent 串行执行`
2. 主 Agent 串行执行 Scout-GH → Scout-BuiltIn → Scout-Market → Scout-Community（顺序固定）
3. 每步用 `ctx_batch_execute(commands=[...], queries=[...])` 一次性批量执行多个搜索 + 自动索引
4. Scout-Expand 在 Top 3 确定后单独执行

### ctx_batch_execute 正确签名（关键）

```
mcp__plugin_context-mode_context-mode__ctx_batch_execute(
  commands=[
    {label: "gh-search-1", command: "shell 命令或 MCP 调用描述"},
    {label: "gh-search-2", command: "..."}
  ],
  queries=["FTS5 检索词1", "FTS5 检索词2"]  # 可选，自动索引后检索
)
```

**两个参数都是必需**（缺 queries 会报 `Invalid arguments: queries required`）：
- `commands`: 要执行的命令数组（每项是 `{label, command}` 对象）
- `queries`: FTS5 全文检索查询数组（即使为空也要传 `[]`）

### MCP 降级策略

当主 MCP 工具不可用时，按 [search-templates.md#mcp-降级策略](references/search-templates.md#mcp-降级策略) 表降级。

### P2 Exit Checklist + AskUser 确认点

```
□ Scout-GH: search_repositories 返回 >= 5 个候选
   → 不足：用同义词/上下游词扩展搜索词重试
□ Scout-BuiltIn 第一层：~/.claude/skills/ 已扫描（用 ctx_batch_execute）
□ Scout-BuiltIn 第二层：marketplaces.json 已读取
□ Scout-BuiltIn 第三层：Web 搜索已执行
□ Scout-Market：至少 2 个垂直平台已搜索
□ Scout-Community：英文和中文信息源分别搜索，分开记录
□ Scout-Expand：Top 3 候选的关联网络已追踪
□ 总候选数 >= 10
□ AskUserQuestion 确认候选池（选项：继续 P3 / 补充搜索词 / 跳过某 Scout）
```

**子 Agent 实际 spawn 数**：必须在确认点展示（如"5/5 spawn 成功"或"L2 fallback，0 spawn"）。

---

## P3: 粗筛（数字门控）

| 指标 | 阈值 |
|------|------|
| Stars | ≥ 10（优选 ≥ 100） |
| 有 SKILL.md | 必须有 |
| Open/Close Issue 比 | open < 2× closed |

保留 **min(候选数, 5)** 个（不足 5 全部保留）。淘汰的记录原因（一行）。

P3 必须用 `ctx_batch_execute` 批量获取 stars/issues/forks（一条命令调多个 `mcp__github__search_repositories` 等价查询）。

### P3 Exit Checklist + AskUser 确认点

```
□ 每个候选的 stars/issues/forks 已获取
□ 有 SKILL.md 的候选 >= 5 个
□ 淘汰记录已生成（每个一行原因）
□ AskUserQuestion 确认 Top 5 进入深读
```

---

## P4: 深读（内容分析）

### 文件读取策略（关键，避免 token 浪费）

GitHub MCP `get_file_contents` 在 Claude Code 中**只返回 SHA，不展示文件内容到 conversation**。所以 P4 优先用以下顺序：

| 优先级 | 工具 | 用法 |
|--------|------|------|
| 1 | `mcp__zread__read_file` | 专为读 GitHub 文件设计，返回完整内容到 conversation |
| 2 | `WebFetch` raw URL | `WebFetch url="https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}"` |
| 3 | `mcp__web-reader__webReader` | 同 raw URL，返回 markdown |
| 4 | `mcp__github__get_file_contents` | **仅用于 P4 验证文件存在性**（确认有 SKILL.md 即可，不读内容） |

**禁止**：用 `get_file_contents` 拉取 README/SKILL.md 内容后用 webReader 再拉一次（双倍 token）。

### 必须先 `get_repo_structure`

处理多 Skill 仓库（SKILL.md 可能在 `skills/` 子目录）：

```
mcp__zread__get_repo_structure(repo="owner/name")
→ 返回完整目录树，定位 SKILL.md 路径
```

### 必读文件

`SKILL.md` → `README.md` → `examples/`（如有）。评分见 [evaluation-rubric.md](references/evaluation-rubric.md)。

### 自检

P4 开始前确认 P2 未使用 `search_code` 做发现。若发现使用了，丢弃其结果并用 `search_repositories` 重搜。

### P4 Exit Checklist + AskUser 确认点

```
□ P2 未使用 search_code 做发现
□ 每个候选先 get_repo_structure 检查目录（不做根目录假设）
□ 多 Skill 仓库已识别（SKILL.md 在 skills/ 子目录）
□ SKILL.md + README.md 已用 zread/read_file 读取（非 get_file_contents）
□ examples/ 或 test-prompts.json 已检查（没有则标记"缺失"）
□ 每个候选已按 evaluation-rubric.md 打分（8 维 40 分制）
□ AskUserQuestion 确认深读报告
```

---

## P5: 社区口碑（中英文分别采集）

英文源（Reddit/HN/Medium/Dev.to）和中文源（知乎/V2EX/掘金/CSDN）各自独立搜索、独立记录。每条标注来源语言 + 日期。两边的差异必须指出。

同时读 GitHub Issues：长期未解 bug、feature request、维护者回复速度、Issue 语言分布。

P5 推荐用 `mcp__searxng__searxng_web_search` 批量检索 + `mcp__web-search-prime__web_search_prime` 双源验证。

### P5 Exit Checklist + AskUser 确认点

```
□ Top 3-5 候选的 GitHub Issues 已读取
□ 英文社区反馈已搜索（Reddit/HN/Medium/Dev.to）
□ 中文社区反馈已搜索（知乎/V2EX/掘金/CSDN）
□ 每条反馈标注来源 + 日期
□ 中英文反馈差异已标注
□ AskUserQuestion 确认口碑采集完成
```

---

## P6: 综合报告

输出到用户指定位置或当前目录。每个候选包含：

来源 / Stars / 一句话定位 / 优缺点（附证据链接）/ 典型 Issue / 社区反馈—英文源 / 社区反馈—中文源 / 安装建议 / 适合谁

报告末尾**必须包含**：
- 淘汰记录（每个一行原因）
- 搜索覆盖统计（GitHub / Marketplace / 内置 / 英文社区 / 中文社区）
- 搜索查询记录（中文/英文分开）
- **执行透明度声明**：
  - 子 Agent 实际 spawn 数（如 `5/5 spawn 成功` 或 `L2 fallback，0 spawn`）
  - MCP 工具调用统计（`search_repositories: 8 次, get_repo_structure: 5 次, zread: 4 次`）
  - Fallback 触发记录（哪些工具降级到了什么）

### P6 Exit Checklist + AskUser 确认点

```
□ 报告包含需求摘要
□ 每个候选有：来源/Stars/定位/优缺点/Issue/社区反馈(分中英文)/安装建议/适合谁
□ 淘汰记录在附录
□ 搜索覆盖统计
□ 搜索查询记录（中文/英文分开）
□ 执行透明度声明（spawn 数 + MCP 调用统计 + Fallback 记录）
□ AskUserQuestion 确认最终报告
```

---

## 多 Skill 仓库处理

部分仓库（如 `sanyuan-skills`、`alirezarezvani/claude-skills`）是 Skill 合集，SKILL.md 不在根目录。

处理步骤：
1. `mcp__zread__get_repo_structure` 查看目录树（优先于 `mcp__github__get_repo_structure`，因为返回结构更清晰）
2. 根目录无 SKILL.md → 检查 `skills/` 子目录
3. 找到匹配用户需求的子 Skill → 用 `mcp__zread__read_file` 读取其 SKILL.md
4. 在报告中注明"来自合集 {仓库名} 的 {子 Skill 名}"

---

## 硬约束

1. **P0 工具加载不可跳过** — 进入 P1 前必须完成 ToolSearch 加载
2. **Phase 间必须 AskUserQuestion 确认** — exit-checklist 配合强制确认点，未确认禁止进入下一 Phase
3. **Agent() 调用必须传 subagent_type + model** — 缺任一参数子 Agent 不启动；model 选择：搜索用 sonnet，分析评估用 opus
4. **`search_code` 禁用于 P2 发现** — 只用于 P4 验证候选是否有 SKILL.md
5. **垂直平台优先于 SearXNG** — SearXNG 对 Skill 生态理解差，英文搜索走 skillsmp.com / openagentskill.com
6. **P4 必须先检查目录结构** — 不假设 SKILL.md 在根目录
7. **P2 必须并行调用全部 5 个 Scout 子 Agent** — 至少 3 个 spawn 成功才能进入 P3；全部失败时按 L2 fallback 规则降级到主 Agent 串行（在 P6 标注）
8. **P4 文件读取禁用 get_file_contents 读内容** — 该工具在 Claude Code 中只返回 SHA；用 `mcp__zread__read_file` 或 `WebFetch raw URL` 替代
9. **ctx_batch_execute 必须双参数** — `commands` 数组 + `queries` 数组都必需，缺 queries 报错
10. **执行透明度声明强制** — P6 报告必须展示 spawn 数 + MCP 调用统计 + Fallback 记录
