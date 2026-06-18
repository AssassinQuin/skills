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

## Scout-GH（search_repositories 主力 + git mcp 4 调用做质量门数据）

### 发现阶段（P2）

```
search_repositories(query="{功能词} skill", sort="stars", order="desc", perPage=15)
search_repositories(query="{同义词} skill", sort="stars", order="desc", perPage=15)
search_repositories(query="{上下游词} skill", sort="stars", order="desc", perPage=15)
search_repositories(query="{功能词} SKILL.md", perPage=10)
```

禁止用 `search_code` 做发现（返回数十万噪音），只在 P4 验证候选是否有 SKILL.md 时使用。

L2 fallback 时用 ctx_batch_execute 批量发起 4 个 search_repositories。

### 质量门数据采集（P3，每个候选强制 4 调用）

```
# 对每个候选 {owner}/{repo}：
mcp__github__search_repositories(query="repo:{owner}/{repo}")         # stars/forks/created_at/updated_at
mcp__github__list_commits(owner, repo, perPage=5)                     # 最近 commit 时间 + message 质量
mcp__github__list_releases(owner, repo, perPage=3)                    # 最新 release 时间
mcp__github__list_tags(owner, repo, perPage=5)                        # 版本 tag 数
```

输出 4 位 signature：`✓✓⚠✗` (install/source/stars/activity)。

### P4 验证 SKILL.md 存在（用 search_code，不用 get_file_contents）

```
mcp__github__search_code(query="repo:{owner}/{repo} filename:SKILL.md")
# 返回 0 结果 → 多 Skill 仓库，需要 get_repo_structure 找子目录
# 返回 ≥1 结果 → 提取 path，用 zread_read_file 读
```

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

## Scout-Community（主语言优先 → 英文 → 中文，主力用 searxng mcp）

**主力工具：`mcp__searxng__searxng_web_search`**（轻量，直接进主上下文可控）。
深读才用 `web_url_read` 或 spawn agent（节省 token）。

**三层降级**（按 P1 检测的主语言，详见 [language-strategy.md](language-strategy.md)）：

### 第 1 层：主语言源（强制）

```
# 韩文仓库
mcp__searxng__searxng_web_search(query="site:blog.naver.com {功能词韩文}")
mcp__searxng__searxng_web_search(query="site:tistory.com {功能词韩文}")
mcp__searxng__searxng_web_search(query="{功能词韩文} skill 리뷰 OR 추천")

# 日文仓库
mcp__searxng__searxng_web_search(query="site:qiita.com {功能词日文}")
mcp__searxng__searxng_web_search(query="site:zenn.dev {功能词日文}")

# 中文仓库
mcp__searxng__searxng_web_search(query="site:zhihu.com {功能词中文} skill")
mcp__searxng__searxng_web_search(query="site:v2ex.com {功能词中文}")
mcp__searxng__searxng_web_search(query="{功能词中文} skill 推荐 OR 评测 OR 踩坑")

# 英文仓库
mcp__searxng__searxng_web_search(query="site:reddit.com {功能词英文} skill")
mcp__searxng__searxng_web_search(query="site:news.ycombinator.com {功能词英文}")
mcp__searxng__searxng_web_search(query="site:medium.com {功能词英文} skill review")
```

### 第 2 层：英文补充（强制）

```
"{功能词英文}" skill review OR feedback OR experience
"{功能词英文}" skill pros cons OR comparison OR alternative
site:reddit.com "{功能词英文}" skill OR agent
site:dev.to "{功能词英文}" claude skill
```

### 第 3 层：中文补充（强制）

```
"{功能词中文}" skill 推荐 OR 评测 OR 体验 OR 踩坑
site:juejin.cn "{功能词中文}" skill
site:csdn.net "{功能词中文}" skill 评测
```

**每条结果标注**：来源语言（主语言/EN/CN）+ 平台 + 日期 + 一句话观点。

**三层差异必须指出**（如"主语言热门但国际冷门"、"中文零讨论说明本土未译介"）。

### 关键词扩展（P1 阶段）

```
mcp__searxng__searxng_search_suggestions(query="{功能词}")  # 拿同义词
mcp__searxng__searxng_search_suggestions(query="{功能词} skill")  # 拿组合词
```

## Scout-Expand（已发现→扩展）

对 Top 3 候选执行：
1. 用 `mcp__zread__read_file` 读 README 的 credits/links/related 部分
2. 检查 GitHub topics → 作为新搜索词
3. `search_repositories(query="fork:{仓库名}")` 找改进版
4. `"{仓库名}" alternative OR similar OR "better than"`
5. 用 `mcp__zread__get_repo_structure` 检查仓库的 `references/` / `docs/` 中的关联项目

## Token 节省策略（硬约束 #14）

长文档强制走 ctx 工具，避免全文进主上下文：

### 长 SKILL.md（> 300 行，特别是韩文/日文）

```
# 不直接 zread_read_file 全文，而是：
mcp__plugin_context-mode_context-mode__ctx_index(
  content="{fetch raw content via WebFetch}",
  source="{owner}-{repo}-SKILL-md"
)
# 然后 ctx_search 取关键段
mcp__plugin_context-mode_context-mode__ctx_search(
  queries=["frontmatter description", "workflow phases", "hard constraints"]
)
```

### 长 Issue body（> 2000 字）

```
# 用 ctx_execute_file 过滤
mcp__plugin_context-mode_context-mode__ctx_execute_file(
  path="{downloaded-issue-body.md}",
  language="python",
  code="""
import re
# 提取标题 + label + 前 500 字 + 链接
text = FILE_CONTENT
lines = text.split('\\n')
print('Title:', lines[0][:200])
print('Labels:', [l for l in lines if l.startswith('### Labels')])
print('Body preview:', text[:500])
print('Links:', re.findall(r'https?://\\S+', text)[:5])
"""
)
```

### 批量 list_issues 用 ctx_batch_execute

```
# 拿到 open + closed issues 后自动索引，主上下文只看查询摘要
mcp__plugin_context-mode_context-mode__ctx_batch_execute(
  commands=[
    {label: "issues-open", command: "gh issue list -R {owner}/{repo} --state open --json number,title,labels,createdAt"},
    {label: "issues-closed", command: "gh issue list -R {owner}/{repo} --state closed --json number,title,labels,createdAt"}
  ],
  queries=["{功能词}", "bug", "feature request", "security"]
)
```

## 主语言策略（硬约束 #9）

详见 [language-strategy.md](language-strategy.md)。简版决策树：

```
检测主语言：
  GitHub metadata.language → 编程语言（HTML/Python/Rust/...）
  README 前 100 行 → 文档语言（en/zh/ko/ja/...）
  SKILL.md description → 触发器语言

按文档语言调整 Scout-Community 源：
  en → Reddit/HN/Medium 优先
  zh → 知乎/V2EX/掘金 优先
  ko → Naver/Tistory/Namuwiki 优先
  ja → Qiita/Zenn/Hatena 优先

三层降级：主语言源（强制）→ 英文补充（强制）→ 中文补充（强制）
```

