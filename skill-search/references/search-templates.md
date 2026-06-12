# 搜索模板

P2 阶段各子 Agent 的搜索词模板。按需替换 `{功能词}` / `{同义词}` / `{上下游词}`。

## MCP 降级策略

当 MCP 工具不可用（超时/报错/未配置）时，按以下链路降级：

| 工具不可用 | 降级方案 |
|-----------|---------|
| `mcp__github__search_repositories` | → `WebSearch: site:github.com "{功能词}" skill` |
| `mcp__searxng__searxng_web_search` | → `WebSearch` 或 `mcp__web-search-prime__web_search_prime` |
| `mcp__github__get_file_contents` | → `WebFetch: raw.githubusercontent.com/...` |
| `mcp__web-reader__webReader` | → `WebFetch` |

降级后标注来源为 `{工具名}-fallback`，不影响后续流程。

## Scout-GH（只用 search_repositories）

```
search_repositories: "{功能词} skill", sort: stars
search_repositories: "{同义词} skill", sort: stars
search_repositories: "{上下游词} skill", sort: stars
search_repositories: "{功能词} SKILL.md"
```

禁止用 `search_code` 做发现（返回数十万噪音），只在 P4 验证候选是否有 SKILL.md 时使用。

## Scout-BuiltIn（三层）

### 第一层：本地
```bash
ls ~/.claude/skills/  # 扫描目录
grep -l "{功能词}" ~/.claude/skills/*/SKILL.md  # 匹配 description
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
1. 读 README/文档的 credits/links/related 部分
2. 检查 GitHub topics → 作为新搜索词
3. `search_repositories: "fork:{仓库名}"` 找改进版
4. `"{仓库名}" alternative OR similar OR "better than"`
5. 检查仓库的 `references/` / `docs/` 中的关联项目
