---
name: skill-search
description: >
  Skill 搜索与评估引擎。根据用户需求，在 GitHub、Plugin Marketplace、Skill 垂直平台、社区中搜索、筛选、
  深度分析候选 Skill，输出"候选清单 + 来源链接 + 四维质量门数据 + D1-D8 启发式信号"的可审计报告。
  核心原则：不假装绝对评分，输出可追溯证据（借鉴 SkillsMP + vercel find-skills）。
  覆盖：主语言优先搜索（韩/日/中/英）、本地缓存命中、四维质量门硬阈值、内置/商城/垂直平台/社区四源、
  exit-checklist 强制门控、D1-D8 启发式信号、raw/ 完整留底。
  显式 trigger：找 skill、搜索 skill、skill 推荐、skill 选型、find skill、recommend skill、
  skill comparison、有什么好的 X skill、哪个 skill 好。
  隐式 trigger（能力缺口识别）：how do I do X / is there a skill that can X / can you do X /
  "扩展能力"、"wish I had help with X domain"、"如果能有个 X 的 skill 就好了"。
  不用于：创建 skill（用 skill-creator）、进化 skill（用 skill-evolver）、写代码（用 coder）。
allowed-tools:
  - mcp__github__search_repositories
  - mcp__github__search_code
  - mcp__github__get_file_contents
  - mcp__github__get_repo_structure
  - mcp__github__list_issues
  - mcp__github__list_commits
  - mcp__github__list_releases
  - mcp__github__list_tags
  - mcp__searxng__searxng_web_search
  - mcp__searxng__web_url_read
  - mcp__searxng__searxng_search_suggestions
  - mcp__web-search-prime__web_search_prime
  - mcp__web-reader__webReader
  - mcp__zread__get_repo_structure
  - mcp__zread__read_file
  - mcp__plugin_context-mode_context-mode__ctx_batch_execute
  - mcp__plugin_context-mode_context-mode__ctx_search
  - mcp__plugin_context-mode_context-mode__ctx_index
  - mcp__plugin_context-mode_context-mode__ctx_execute_file
  - Agent
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - WebSearch
  - WebFetch
user-invocable: true
metadata:
  version: "5.0"
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
P0 缓存查询 → P1 需求解析 → P2 多源搜索 → P3 四维质量门 → P4 深读 → P5 社区口碑（主语言优先）→ P6 报告+保存
                                  ↓              ↓            ↓          ↓
                             [exit-check]   [exit-check] [exit-check] [exit-check]
                             不通过→补完      不通过→补完   不通过→补完  不通过→补完
```

### P0: 本地缓存查询（Leaderboard 优先，避免昂贵 GitHub 搜索）

每次触发强制执行，即使未命中也要记录（见 [known-good-cache.md](references/known-good-cache.md)）：

```
1. 私有库：glob("/Users/ganjie/skills/*/SKILL.md") + grep("{功能词}")
2. 历史档案：glob("skill-search/data/**/*.md") + grep("{功能词}")
3. 排行榜：searxng_web_search("site:skills.sh ...") + searxng_web_search("site:skillsmp.com ...")
4. 全量 GitHub（仅在 1-3 都未命中时执行）
```

命中即跳过 P2/P3，直接进 P4 深读。P6 报告标注每层命中数。

### P1: 需求解析 + 主语言检测

提取四组搜索词（中英双语，**不歧视中文**）：

| 组 | 作用 | 举例（code review） |
|---|---|---|
| 功能词 | 核心能力 | code review / 代码审查 |
| 同义词 | 等价说法 | PR review, diff review, code audit, adversarial review |
| 上下游 | 相关领域 | static analysis, lint, security audit |
| 生态词 | 知名合集 | superpowers, pm-skills, best-skills |

**主语言检测**（用户方向 3，详见 [language-strategy.md](references/language-strategy.md)）：

如果用户已给具体仓库 URL，先获取 GitHub metadata `language` 字段 + README 前 100 行，判定主语言（en/zh/ko/ja/...）。后续 P5 社区源按主语言三层降级（主语言 → 英文 → 中文）。

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

### P3: 四维质量门（粗筛升级，详见 [quality-gates.md](references/quality-gates.md)）

每个候选在 P3 阶段强制执行 git mcp 4 调用，输出 4 位 signature：

| 维度 | 数据源（git mcp 强制） | 推荐阈值 |
|------|----------------------|---------|
| Install count | skills.sh / skillsmp.com / plugin marketplace | ≥1K（新仓库 < 6 个月豁免） |
| Source reputation | GitHub owner type + README 完整度 | 官方源 > 个人活跃 > 匿名 |
| GitHub stars | `mcp__github__search_repositories` | ≥100（新仓库豁免） |
| 维护活跃度 | `list_commits` + `list_releases` + `list_tags` | 6 个月内有 commit |

**单源不可推荐**：至少 2 个维度 ✓ 才能进入 P4。仅 1 个 ✓ 进"待观察"，0 个 ✓ 拒绝。

```
mcp__github__search_repositories(query="repo:{owner}/{name}")  # stars/created_at
mcp__github__list_commits(owner, repo, perPage=5)              # 最近 commit 时间
mcp__github__list_releases(owner, repo, perPage=3)             # 最新 release
mcp__github__list_tags(owner, repo, perPage=5)                 # 版本管理质量
mcp__github__search_code(query="repo:{owner}/{name} filename:SKILL.md")  # P4 验证 SKILL.md 存在
```

保留 Top 5（不足 5 全部保留）。淘汰的记录命中的 signature + 拒绝维度。

### P4: 深读（内容分析）

**必须先 `mcp__zread__get_repo_structure`**，处理多 Skill 仓库（SKILL.md 可能在 `skills/` 子目录）。

文件读取优先用 `mcp__zread__read_file`（GitHub MCP `get_file_contents` 在 Claude Code 中只返回 SHA 不展示内容）。

**必读**（4 类，缺一标注）：
1. `SKILL.md`
2. `README.md`
3. **references/ 至少深读 2 个**（被 SKILL.md 反复引用的优先）— **不允许只读目录列表**
4. `examples/` 或 `test-prompts.json` — 不存在则明确标记"缺失"

**评分**：按 [evaluation-rubric.md](references/evaluation-rubric.md) D1-D8 打分（**作为启发式信号，不是绝对真理**，详见谦逊化声明）。

**Token 策略**（长文档保护）：
- SKILL.md > 300 行 → 用 `ctx_index` + `ctx_search` 取关键段，不全文进上下文
- Issue body > 2000 字 → 用 `ctx_execute_file` 过滤标题+label+前 500 字
- 韩文/日文文档（token 效率差）→ 同上

### P5: 社区口碑（主语言优先 → 英文补充 → 中文补充）

**主力用 `searxng_web_search`**（轻量，直接进主上下文可控）；只在需要 `web_url_read` 深读时才 spawn agent（节省 token）。

按 P1 检测的主语言三层降级（详见 [language-strategy.md](references/language-strategy.md)）：

```
1. 主语言源（如韩文仓库 → Naver Blog / Tistory / Namuwiki）
2. 英文补充（Reddit / HN / Medium / Dev.to）
3. 中文补充（知乎 / V2EX / 掘金 / CSDN）
```

每条反馈标注：来源语言 + 平台 + 日期 + 一句话观点。三层差异必须指出（如"主语言热门但国际冷门"）。

同时用 git mcp 读 GitHub Issues：长期未解 bug、feature request、维护者回复速度、Issue 语言分布。

**关键词扩展**：P1 阶段用 `searxng_search_suggestions` 扩展同义词。

### P6: 综合报告 + 本地保存（评分谦逊化 + 可审计）

**核心原则**（借鉴 SkillsMP + vercel find-skills）：**不假装绝对评分，输出可追溯证据**。

每个候选必含字段：

```markdown
### {候选名}

**定位**：一句话
**四维质量门 signature**：✓✓⚠✗ (install=✓ 2.3K / source=✓ anthropics / stars=⚠ 87 / activity=✓ 最近 commit 2026-06-15)
**推荐理由（可审计）**：
- 命中质量门：≥2 维 ✓
- 命中 trigger：用户输入"X" → match description 关键词
- D1-D8 启发式信号：32/40 (B)
**优点**（附证据链接）：
**缺点**（附证据链接）：
**典型 Issue**：#29 反对 opus / #20 安装 bug
**社区反馈—主语言源**：Naver Blog 3 条（2026-04-15）
**社区反馈—英文源**：Reddit 0 条 / DEV.to 1 条教程（中性）
**社区反馈—中文源**：知乎 0 条
**安装建议**：
**适合谁**：
```

**报告末尾强制**：
- 淘汰记录（含 signature + 拒绝维度）
- 搜索覆盖统计（GitHub ×N / Marketplace / 主语言源 / 英文源 / 中文源）
- 搜索查询记录（按语言分开：主语言 / 英文 / 中文）
- **缓存命中统计**（私有库 X / 历史档案 X / 排行榜 X / 全量 GitHub X）
- **MCP 调用统计**（github ×N / searxng ×N / zread ×N / Agent ×N）
- **执行透明度声明**（spawn 数 + L2 fallback + token 消耗估算）

**本地保存**（强制结构，raw/ 不可省）：

```
{skill_dir}/data/{YYYYMMDD}-{slug}/
├── 评估报告.md          # P6 综合报告（含谦逊化声明）
├── 候选-Top5.md         # Top 5 D1-D8 评分 + signature
├── 淘汰记录.md          # P3 拒绝原因 + signature
├── sources.md           # 搜索查询记录（按语言分类）
└── raw/                 # ⚠️ 强制：所有 MCP 调用 + 子 Agent 原始输出
    ├── mcp-github-search-{timestamp}.json
    ├── mcp-github-list-issues-{timestamp}.json
    ├── mcp-github-list-commits-{timestamp}.json
    ├── mcp-zread-skill-md-{timestamp}.md
    ├── scout-community-{lang}-{timestamp}.json
    └── scout-researcher-{timestamp}.json
```

下次相似需求先 `glob("{skill_dir}/data/**/*.md")` + `grep(关键词)` 查历史档案，避免重复搜索。

## 评估模式 E1：单仓库深度评估

**触发**：用户明确给 GitHub URL（如 `https://github.com/owner/repo`）或 `repo:owner/name`。

**可省 Phase**：
- P0 缓存查询（仍执行但命中即用历史档案，避免重复）
- P2 多源发现（候选已确定为 1 个）
- P3 粗筛（候选只有 1 个，但四维质量门仍执行作为"健康检查"）

**不可省 Phase**：
- P1 主语言检测（强制，决定 P5 三层降级）
- P3 四维质量门 signature（输出但不过滤）
- P4 完整深读（SKILL.md + README + references ≥2 + examples 检查）
- P5 主语言优先 + 英文 + 中文三层社区源
- P6 全套保存（含 raw/ 完整留底 + MCP 调用统计）

**E1 Exit Checklist** 见 [execution-gates.md](references/execution-gates.md) E1 Exit。

## 硬约束

1. **exit-checklist 不可跳过** — 每个 Phase 结束执行对应清单，未通过就停在当前阶段补完
2. **`search_code` 禁用于 P2 发现** — 只用于 P3/P4 验证候选是否有 SKILL.md
3. **垂直平台优先于 SearXNG** — SearXNG 对 Skill 生态理解差，英文搜索走 skillsmp.com / openagentskill.com / skills.sh
4. **P4 必须先检查目录结构** — 不假设 SKILL.md 在根目录
5. **子 Agent 必须指定 model** — 启动子 Agent 用 `Agent` 工具（不是 `TaskCreate`），subagent_type 用 Claude Code 内置（`general-purpose`/`Explore`）或全局 `~/.claude/agents/` 已注册的；搜索用 sonnet，分析评估用 opus
6. **P4 文件读取禁用 get_file_contents 读内容** — 用 `mcp__zread__read_file` 或 `WebFetch raw URL` 替代
7. **本地保存强制 + raw/ 强制** — P6 必须保存到 `{skill_dir}/data/{YYYYMMDD}-{slug}/`，**raw/ 必须包含所有 MCP 调用原始返回**（不只是子 agent 输出）
8. **四维质量门 + 单源不可推荐** — P3 必须输出 signature，至少 2 维 ✓ 才能进入 P4。禁止"搜到即推荐"
9. **主语言优先 + 中英补充**（用户方向 3）— P1 必须检测主语言，P5 必须按主语言三层降级。禁止默认中英双语并行
10. **评分谦逊化**（Axis 14）— D1-D8 是启发式信号，不是绝对真理。报告核心输出"候选+来源+数据"，分数降为辅助参考。禁止把分数作为唯一决策依据
11. **git mcp 充分利用**（用户方向 2）— P3 必须执行 4 调用（search_repositories + list_commits + list_releases + list_tags），数据缺失时降级到 searxng 标注
12. **searxng mcp 主力化**（用户方向 2）— Scout-Community 主力用 `searxng_web_search`，深读才 spawn agent。节省 token
13. **本地缓存优先**（Axis 11）— P0 强制查询 4 层缓存（私有库 → 历史档案 → 排行榜 → 全量 GitHub），命中即跳过 P2/P3
14. **Token 预算** — 长文档（>300 行 / >2000 字）必须用 `ctx_index` + `ctx_search` 或 `ctx_execute_file`，不全文进主上下文

