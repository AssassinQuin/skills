# 搜索模板

P2 阶段各子 Agent 的搜索词模板。按需替换 `{功能词}` / `{同义词}` / `{上下游词}`。

## MCP 降级策略

当 MCP 工具不可用（超时/报错/未配置）时，按以下链路降级：

| 工具不可用 | 降级方案 |
|-----------|---------|
| `mcp__github__search_repositories` | → `WebSearch: site:github.com "{功能词}" skill` |
| `mcp__searxng__searxng_web_search` | → `WebSearch` 或 `mcp__web-search-prime__web_search_prime` |
| `mcp__github__get_file_contents` | → `mcp__zread__read_file` → `WebFetch raw.githubusercontent.com/...` → `mcp__web-reader__webReader` |
| `mcp__web-reader__webReader` | → `WebFetch` |
| `mcp__zread__read_file` | → `WebFetch raw URL` 或 `mcp__web-reader__webReader` |
| `Task` (子 Agent 启动) | → 主 Agent 串行执行（L2 fallback），在 P6 标注 |

降级后标注来源为 `{工具名}-fallback`，并在 P6 报告"执行透明度声明"中记录，不影响后续流程。

## ctx_batch_execute 批量调用模式（L2 fallback 主力工具）

正确签名（关键）：

```
mcp__plugin_context-mode_context-mode__ctx_batch_execute(
  commands=[
    {label: "gh-search-feature",   command: "..."},
    {label: "gh-search-synonym",   command: "..."},
    {label: "gh-search-upstream",  command: "..."}
  ],
  queries=["{功能词}", "{同义词}"]  # FTS5 检索数组，可空数组 []
)
```

**陷阱**：缺 `queries` 参数会报 `Invalid arguments: queries required`。即使不需要检索也要传 `queries=[]`。

 Scout-BuiltIn 第一层批量扫描示例：

```
ctx_batch_execute(
  commands=[
    {label: "local-skills-list",  command: "ls ~/.claude/skills/"},
    {label: "local-skills-grep",  command: "grep -l '{功能词}' ~/.claude/skills/*/SKILL.md 2>/dev/null"},
    {label: "marketplace-list",   command: "cat ~/.claude/plugins/marketplaces.json 2>/dev/null"}
  ],
  queries=["{功能词} skill"]
)
```

执行后所有输出已自动索引到 context-mode，主 conversation 只看到 queries 匹配的摘要 — 节省 token。

## Scout-GH（只用 search_repositories）

```
search_repositories(query="{功能词} skill", sort="stars", order="desc", perPage=15)
search_repositories(query="{同义词} skill", sort="stars", order="desc", perPage=15)
search_repositories(query="{上下游词} skill", sort="stars", order="desc", perPage=15)
search_repositories(query="{功能词} SKILL.md", perPage=10)
```

禁止用 `search_code` 做发现（返回数十万噪音），只在 P4 验证候选是否有 SKILL.md 时使用。

L2 fallback 时用 ctx_batch_execute 批量发起 4 个 search_repositories。

## Scout-BuiltIn（三层）

### 第一层：本地（用 ctx_batch_execute 批量）

```bash
# 单条命令时直接 Bash
ls ~/.claude/skills/

# 多条命令时优先 ctx_batch_execute（自动索引，主 conversation 只看摘要）
ctx_batch_execute(
  commands=[
    {label: "local-skills-list", command: "ls ~/.claude/skills/"},
    {label: "local-skills-grep", command: "grep -l '{功能词}' ~/.claude/skills/*/SKILL.md 2>/dev/null"}
  ],
  queries=["{功能词}"]
)
```

### 第二层：Plugin Marketplace
读取 `~/.claude/plugins/marketplaces.json` → 对每个商城源读 `marketplace.json` registry → 按 name/description/keywords 匹配。

常见商城源（主动检查）：
- `anthropics/claude-plugins-official`
- `jeremylongshore/claude-code-plugins-plus-skills`（2,810 skills）
- `Lap-Platform/claude-marketplace`（1,500+ API skills）
- `daymade/claude-code-skills`
- `alirezarezvani/claude-skills`（533 scripts）

### 第三层：Web 搜索新商城

```
"claude code plugin marketplace" "{功能词}"
site:github.com "claude-code-plugins" OR "claude-marketplace" "{功能词}"
```

## Scout-Market（垂直平台优先）

```
# 直接访问（用 WebFetch 或 web_url_read）
https://skillsmp.com/search?q={功能词}
https://www.openagentskill.com/skills?q={功能词}
https://skills.sh/search?q={功能词}

# SearXNG 补充（不依赖它做主要发现）
site:skillsmp.com "{功能词}"
site:openagentskill.com "{功能词}"
site:skills.sh "{功能词}"
site:clawhub.ai "{功能词}"
```

## Scout-Community（中英文分别搜索）

### 英文信息源
```
"{功能词}" skill review OR feedback OR experience
"{功能词}" skill pros cons OR comparison OR alternative
site:reddit.com "{功能词}" skill OR agent
site:news.ycombinator.com "{功能词}"
site:medium.com "{功能词}" skill review
site:dev.to "{功能词}" claude skill
```

### 中文信息源
```
"{功能词}" skill 推荐 OR 评测 OR 体验 OR 踩坑
site:zhihu.com "{功能词}" skill
site:v2ex.com "{功能词}" skill
site:juejin.cn "{功能词}" skill
site:csdn.net "{功能词}" skill 评测
```

## Scout-Expand（已发现→扩展）

对 Top 3 候选执行：
1. 用 `mcp__zread__read_file` 读 README 的 credits/links/related 部分
2. 检查 GitHub topics → 作为新搜索词
3. `search_repositories(query="fork:{仓库名}")` 找改进版
4. `"{仓库名}" alternative OR similar OR "better than"`
5. 用 `mcp__zread__get_repo_structure` 检查仓库的 `references/` / `docs/` 中的关联项目
