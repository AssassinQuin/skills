# 工具调用规范（Tool Usage Reference）

skill-search 各 Phase 涉及的工具调用规范集中维护。修改工具调用方式时只改本文件。

## ToolSearch：deferred 工具加载

Claude Code 中以下工具是 deferred（懒加载），未预先加载会导致后续调用反复失败：

```
# 在 P0 入口必须执行（一次完成所有加载）
ToolSearch query="select:Agent,Bash,WebFetch,AskUserQuestion" max_results=5
ToolSearch query="select:mcp__github__search_repositories,mcp__github__get_file_contents,mcp__github__get_repo_structure" max_results=5
ToolSearch query="select:mcp__web-search-prime__web_search_prime,mcp__web-reader__webReader,WebSearch" max_results=5
ToolSearch query="select:mcp__zread__get_repo_structure,mcp__zread__read_file" max_results=5
ToolSearch query="select:mcp__plugin_context-mode_context-mode__ctx_batch_execute,mcp__plugin_context-mode_context-mode__ctx_search" max_results=5
```

**已知陷阱**：ToolSearch `select:` 命中后**不一定返回 schema**（可能返回空），但工具实际已注册。直接尝试调用即可，不要因为返回空就反复重试。

如果连续 2 次 `ToolSearch select:Agent` 后调用 `Agent()` 仍报错，触发 L2 fallback（异常路径）。

## Agent Template：启动子 Agent

**`Agent()` 是 Claude Code 中启动子 Agent 的工具**（不是 `TaskCreate` — TaskCreate 只是任务列表管理）。四个核心参数：

```
Agent(
  subagent_type="scout-gh",      # 必需：子 Agent 类型（来自 skill-local agents/ 或全局 ~/.claude/agents/）
  model="sonnet",                # 必需：模型选择（搜索用 sonnet，分析评估用 opus）
  description="Scout-GH: GitHub 仓库搜索",  # 必需：任务描述
  prompt="你是 Scout-GH 子 agent。..."      # 必需：详细指令
)
```

**Scout 子 Agent 定义位置**（skill-local，自包含）：
```
/Users/ganjie/.claude/skills/skill-search/agents/
├── claude-code.yaml          # 声明 5 个 Scout role + workflow
├── scout-gh.md               # GitHub 搜索 prompt 模板
├── scout-builtin.md          # 本地+Marketplace 扫描
├── scout-market.md           # 垂直平台搜索
├── scout-community.md        # 社区口碑
└── scout-expand.md           # 候选扩展
```

修改 Scout 行为时只改 `agents/scout-*.md`，不动 SKILL.md。

### 缺参数的失败模式

| 缺失参数 | 现象 |
|---------|------|
| `subagent_type` | 子 Agent 不启动，无错误提示 |
| `model` | 默认使用主 Agent 模型（成本高且违反 R5.1） |
| `description` | 启动但 Claude 不知道任务目标 |
| `prompt` | 启动但执行方向随机 |

### P2 5-子-Agent 并行调用模板

必须在**单个 tool_calls 块**中并行调用（5 个 Agent 同时发出）：

```
# 在一个 message 中并行调用
Agent(subagent_type="scout-gh", model="sonnet", description="...", prompt="...")
Agent(subagent_type="scout-builtin", model="sonnet", description="...", prompt="...")
Agent(subagent_type="scout-market", model="sonnet", description="...", prompt="...")
Agent(subagent_type="scout-community", model="sonnet", description="...", prompt="...")
Agent(subagent_type="scout-expand", model="sonnet", description="...", prompt="...")
```

子 Agent 类型来自 `agents/claude-code.yaml`，详细 prompt 在 `agents/scout-{role}.md`。等待全部返回后聚合结果。

### Scout 子 Agent prompt 模板

#### Scout-GH
```
你是 Scout-GH 子 agent。
任务：用 mcp__github__search_repositories 搜索 GitHub 仓库。
搜索词：{功能词} / {同义词} / {上下游词}。
每个搜索词独立调用，sort="stars", order="desc", perPage=15。
返回 JSON 数组（每项含 full_name, stars, forks, open_issues, html_url, description, topics），至少 5 个候选。
禁止用 search_code 做发现。
```

#### Scout-BuiltIn
```
你是 Scout-BuiltIn 子 agent。
任务：三层扫描本地和商城。
第一层：ls ~/.claude/skills/，grep 匹配 {功能词}。
第二层：读 ~/.claude/plugins/marketplaces.json，遍历 registry 匹配。
第三层：WebSearch 搜索 "claude code plugin marketplace {功能词}"。
返回 JSON 数组（每项含 name, source, description），合并三层结果去重。
```

#### Scout-Market
```
你是 Scout-Market 子 agent。
任务：直接访问垂直平台。
用 WebFetch 访问：
  - https://skillsmp.com/search?q={功能词}
  - https://www.openagentskill.com/skills?q={功能词}
  - https://skills.sh/search?q={功能词}
返回 JSON 数组（每项含 name, platform, url, description）。
不依赖 SearXNG 做主要发现。
```

#### Scout-Community
```
你是 Scout-Community 子 agent。
任务：中英文社区分别搜索。
英文：Reddit/HN/Medium/Dev.to，标记 [EN]。
中文：知乎/V2EX/掘金/CSDN，标记 [CN]。
用 mcp__web-search-prime__web_search_prime 双源验证。
返回 JSON 数组（每项含 source_lang, source, date, content_snippet）。
```

#### Scout-Expand
```
你是 Scout-Expand 子 agent。
任务：对 Top 3 候选扩展搜索。
对每个候选：
  1. 用 mcp__zread__read_file 读 README 的 credits/links
  2. 检查 GitHub topics → 作为新搜索词
  3. search_repositories(query="fork:{repo}")
  4. "{repo}" alternative OR similar
返回 JSON 数组（每项含 candidate, relation, target, evidence_url）。
```

### L2 Fallback：主 Agent 串行

触发条件：连续 2 次 `Agent()` 调用报错（如 subagent_type 不存在 / model 错误 / 网络超时）。

降级流程：
1. 在 P6 报告附录标注 `[L2-FALLBACK] 子 Agent 无法 spawn，主 Agent 串行执行`
2. 主 Agent 串行执行 Scout-GH → Scout-BuiltIn → Scout-Market → Scout-Community（顺序固定）
3. 每步用 `ctx_batch_execute(commands=[...], queries=[...])` 一次性批量执行多个搜索
4. Scout-Expand 在 Top 3 确定后单独执行

**注意**：L2 fallback 是异常路径，不是正常情况。如果触发频繁，应检查：
- `agents/claude-code.yaml` 中 role 是否定义
- `agents/scout-*.md` 是否存在
- `model` 参数是否合法（haiku/sonnet/opus）

## ctx_batch_execute：批量执行 + 索引

正确签名（关键 — 两参数都必需）：

```
mcp__plugin_context-mode_context-mode__ctx_batch_execute(
  commands=[
    {label: "section-1", command: "shell 命令或 MCP 调用描述"},
    {label: "section-2", command: "..."}
  ],
  queries=["FTS5 检索词1", "FTS5 检索词2"]
)
```

### 参数说明

| 参数 | 类型 | 必需 | 作用 |
|------|------|------|------|
| `commands` | `Array<{label, command}>` | 是 | 要执行的命令数组；`label` 是 FTS5 chunk 标题 |
| `queries` | `Array<string>` | 是 | FTS5 检索词数组；执行后按 queries 匹配返回摘要 |

### 已知陷阱

1. **缺 `queries` 报错**：`Invalid arguments: queries required`。即使不需要检索也要传 `queries=[]`
2. **label 影响 FTS5 精度**：label 越具体，后续 `ctx_search` 检索越精准
3. **commands 中 command 是字符串**：不是直接执行 shell，而是描述给 MCP；具体执行由 MCP server 处理

### 使用场景

- P2 多源搜索批量执行（4 个 search_repositories 合并为一次调用）
- P2 Scout-BuiltIn 三层扫描（ls + grep + cat marketplaces.json）
- P3 粗筛数据收集（一次性获取 Top 10 候选的 stars/issues）
- P5 社区口碑批量搜索（中英文各 5 条搜索合并）

### 与 ctx_search 配合

ctx_batch_execute 执行后输出自动索引到 context-mode。后续用 `ctx_search(queries=[...])` 可在主 conversation 只看摘要：

```
mcp__plugin_context-mode_context-mode__ctx_search(
  queries=["{功能词} skill", "{同义词} review"]
)
```

## zread MCP：GitHub 仓库读取

zread 是专为读取 GitHub 仓库设计的 MCP，比 `mcp__github__get_file_contents` 更适合 P4 深读。

### get_repo_structure（优先于 github MCP）

```
mcp__zread__get_repo_structure(repo="owner/name")
→ 返回完整目录树（含子目录），结构清晰
```

**优势**：返回格式比 `mcp__github__get_repo_structure` 更适合 LLM 消费，分支路径明确。

### read_file（优先于 github MCP 读内容）

```
mcp__zread__read_file(repo="owner/name", path="README.md", branch="main")
→ 返回完整文件内容到 conversation
```

**优势**：`mcp__github__get_file_contents` 在 Claude Code 中只返回 SHA 不展示内容；`mcp__zread__read_file` 直接返回内容。

### search_doc

```
mcp__zread__search_doc(repo="owner/name", query="{功能词}")
→ 在仓库内搜索文档
```

适用：P4 在大仓库中定位特定主题的文档。

## GitHub MCP fallback 矩阵（P4 深读专用）

`mcp__github__get_file_contents` 在 Claude Code 中**只返回 SHA，不展示内容到 conversation**（已知问题）。P4 深读阶段必须按以下优先级：

| 优先级 | 工具 | 用法 | 备注 |
|--------|------|------|------|
| 1 | `mcp__zread__read_file` | `read_file(repo, path, branch)` | 返回完整内容到 conversation |
| 2 | `WebFetch` raw URL | `WebFetch url="https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}"` | raw URL 通用 |
| 3 | `mcp__web-reader__webReader` | 同 raw URL | 返回 markdown |
| 4 | `mcp__github__get_file_contents` | **仅用于验证文件存在性** | 只看返回是否报错，不读 SHA |

**禁止**：用 `get_file_contents` 拉取 README/SKILL.md 内容后用 webReader 再拉一次（双倍 token，浪费 ~3K/文件）。

## AskUserQuestion：Phase 间强制确认

每个 Phase 结束必须调用 `AskUserQuestion` 等待用户确认。参数：

```
AskUserQuestion(
  questions=[{
    question: "P2 多源搜索完成。子 Agent spawn: 5/5。是否进入 P3 粗筛？",
    options: [
      {label: "继续 P3", value: "next"},
      {label: "补充搜索词", value: "refine"},
      {label: "跳过某 Scout", value: "skip"},
      {label: "查看候选池详情", value: "details"}
    ]
  }]
)
```

未收到确认禁止进入下一 Phase。如果用户选择"补充/调整"，回到当前 Phase 重做对应步骤。

## 子 Agent 实际 spawn 数统计（P6 必报）

在 P6 报告的"执行透明度声明"中必须包含：

```
## 执行透明度声明
### 子 Agent 统计
- 计划 spawn: 5 (Scout-GH/BuiltIn/Market/Community/Expand)
- 实际 spawn 成功: 5/5  OR  L2 fallback, 0 spawn
- 失败原因（如有）: Agent 调用报错（subagent_type 不存在 / model 错误 / 网络超时）

### MCP 调用统计
- mcp__github__search_repositories: 8 次
- mcp__zread__get_repo_structure: 5 次
- mcp__zread__read_file: 12 次
- mcp__web-search-prime__web_search_prime: 6 次
- mcp__plugin_context-mode__ctx_batch_execute: 3 次

### Fallback 触发记录
- mcp__github__get_file_contents 内容不展示 → 降级到 mcp__zread__read_file（4 次）
- mcp__searxng__searxng_web_search 超时 → 降级到 WebSearch（2 次）
```

无此项视为违反硬约束 10。
