# 本机 cc-switch 与多客户端管理审计（2026-10-26）

## 0. 审计边界与脱敏规则

- 本审计只读取本机状态；除写入本报告文件外，未修改任何配置或数据。
- 未记录任何 token、API key、Authorization/header、auth.json 内容、provider settings_config 内容、endpoint URL 或数据库敏感字段值。
- 报告仅包含：路径、字段名、安全状态值、计数、时间、文件权限和校验结果。
- SQLite 一律以 `mode=ro` 打开；主库 `integrity_check = ok`，`journal_mode = delete`。

## 1. `~/.cc-switch` 现状

### 1.1 顶层状态

| 路径/对象 | 状态 |
|---|---:|
| `/Users/ganjie/.cc-switch` | 目录，`0755`，owner `ganjie:staff` |
| `settings.json` | 文件，1,479 B，`0600` |
| `live-state.json` | 文件，220 B，`0600` |
| `cc-switch.db` | 文件，约 4.55 MB，`0644` |
| `backups/` | 目录，`0755`，10 个 DB 快照 + 1 个 `live-first-write/` 子目录 |
| `skills/` | 目录，条目数为 0 |
| `logs/` | 目录，条目数为 1 |
| LaunchAgent/crontab 线索 | 未发现 cc-switch/skills 相关条目 |

### 1.2 `settings.json` 字段清单与安全状态

顶层字段名：

- UI/启动：`showInTray`, `minimizeToTrayOnClose`, `useAppWindowControls`, `launchOnStartup`, `silentStartup`, `showProfileSwitcher`
- 集成/同步：`enableClaudePluginIntegration`, `sessionAutoSyncEnabled`, `skillSyncMethod`, `skillStorageLocation`
- 代理/故障转移：`enableLocalProxy`, `enableStackMode`, `enableFailoverToggle`
- Codex 行为：`preserveCodexOfficialAuthOnSwitch`, `unifyCodexSessionHistory`
- 当前选择：`currentProviderClaude`, `currentProviderCodex`
- 可见应用：`visibleApps`
- 迁移/提示/语言：`localMigrations`, `checkToolUpdatesOnStartup`, `commonConfigConfirmed`, `usageConfirmed`, `firstRunNoticeConfirmed`, `newLayoutNoticeConfirmed`, `whatsNewSeenVersion`, `language`, `skipClaudeOnboarding`

安全状态值：

- `enableClaudePluginIntegration = true`
- `sessionAutoSyncEnabled = true`
- `enableLocalProxy = false`
- `enableStackMode = false`
- `enableFailoverToggle = false`
- `preserveCodexOfficialAuthOnSwitch = false`
- `unifyCodexSessionHistory = false`
- `skillSyncMethod = auto`
- `skillStorageLocation = cc_switch`
- `visibleApps` 中 true 的应用：`claude`, `codex`, `grokbuild`, `opencode`, `pi`, `mcode`
- `visibleApps` 中 false 的应用：`claude-desktop`, `gemini`, `openclaw`, `hermes`
- `currentProviderClaude` / `currentProviderCodex`：仅确认存在 provider 标识字段；值按规则不输出。

### 1.3 `live-state.json`

字段结构：

- 顶层：`version`, `apps`
- `apps.claude.mode`
- `apps.codex.mode`
- `apps.gemini.mode`
- `apps.grokbuild.mode`

状态：

- `version = 1`
- 四个已记录 app 的 `mode = direct`
- 没有 Trae 条目。

### 1.4 SQLite 主库 schema 与行数

库：`/Users/ganjie/.cc-switch/cc-switch.db`

| 表 | 行数 | 关键列 |
|---|---:|---|
| `mcp_servers` | 9 | `id`, `name`, `server_config`, `description`, `homepage`, `docs`, `tags`, `enabled_claude`, `enabled_codex`, `enabled_gemini`, `enabled_opencode`, `enabled_hermes`, `enabled_grokbuild`, `enabled_mcode`, `enabled_pi` |
| `model_pricing` | 231 | 模型计费字段 |
| `profiles` | 0 | profile payload/排序/时间字段 |
| `prompts` | 1 | app/name/content/enabled 等字段 |
| `provider_endpoints` | 2 | provider/app/URL/时间字段 |
| `provider_health` | 2 | 健康、失败计数、最近成功/失败字段 |
| `providers` | 8 | provider 配置、分类、当前、故障转移等字段 |
| `proxy_config` | 4 | app、代理开关、监听、超时、熔断、live takeover 字段 |
| `proxy_live_backup` | 0 | 原配置备份字段 |
| `proxy_request_logs` | 5,283 | 请求、token、费用、延迟、状态、session 字段 |
| `session_log_sync` | 4,193 | 文件路径、mtime、行偏移、同步时间字段 |
| `session_usage_dedup` | 0 | 去重键字段 |
| `settings` | 7 | `key`, `value` |
| `skill_repos` | 4 | owner/name/branch/enabled |
| `skills` | 30 | skill 元数据、repo 字段、多客户端 enabled 字段 |
| `stream_check_logs` | 0 | 连通性检测字段 |
| `usage_daily_rollups` | 426 | 日度用量/费用/延迟字段 |

`settings` 表仅列字段名，不列值：

- `common_config_claude`
- `common_config_codex`
- `common_config_legacy_migrated_v1`
- `common_config_opencode`
- `default_skill_repos_initialized`
- `gemini_common_config_credentials_scrubbed_v1`
- `official_providers_seeded`

Provider 状态聚合（不含名称/URL/配置值）：

- Claude：3 个 provider，1 个 current；分类含 `official` 与 `cn_official`
- Codex：2 个 provider，1 个 current；分类含 `official` 与 `cn_official`
- Gemini：1 个 provider，0 个 current
- OpenCode：2 个 provider，1 个 current
- 所有 provider 的 `in_failover_queue = false`
- 四条 `proxy_config`（Claude/Codex/Gemini/GrokBuild）均为：proxy disabled、auto-failover disabled、live takeover inactive。

cc-switch 内部 MCP 目录：

- 名称：`context-mode`, `context7`, `github`, `memory`, `searxng`, `web-reader`, `web-search-prime`, `zai-mcp-server`, `zread`
- enabled 聚合：9/9 Claude；Codex/Gemini/OpenCode/Hermes/GrokBuild/MCode/Pi 均为 0。

cc-switch 内部 skill 目录：

- `skill_repos = 4`，均 enabled：`ComposioHQ/awesome-claude-skills`, `JimLiu/baoyu-skills`, `anthropics/skills`, `cexll/myclaude`
- `skills = 30`
- enabled 聚合：Claude 30、OpenCode 30、Codex/Gemini/Hermes/GrokBuild/MCode 0。
- 这些 skill 行的 repo 字段均为空；当前 `/Users/ganjie/skills` 顶层 `SKILL.md` 只有 24 个，二者仅重合 1 个，基本是两套目录。

### 1.5 备份现状

数据库快照（均为本地文件，未发现远端或调度证据）：

- 2026-09-18，37,834,752 B，`0644`
- 2026-09-24，37,830,656 B，`0644`
- 2026-10-01，37,826,560 B，`0644`
- 2026-10-03，37,818,368 B，`0644`
- 2026-10-08 11:03，37,814,272 B，`0644`
- 2026-10-08 11:07，37,814,272 B，`0600`
- 2026-10-13，4,435,968 B，`0600`
- 2026-10-16，4,313,088 B，`0600`
- 2026-10-21，4,202,496 B，`0600`
- 2026-10-26，4,390,912 B，`0600`

`backups/live-first-write/` 有 7 个文件，字段/文件类型线索为：

- 2 个 auth/login-stash 相关命名文件
- 2 个 Codex config backup 命名文件
- 3 个 model-catalog backup 命名文件

备份判断：

- 存在周期性/触发式 DB 快照，但时间间隔不规则，无法确认固定调度。
- 未发现 LaunchAgent、crontab 或远端备份线索。
- 未发现显式 retention 策略文件。
- `sessionAutoSyncEnabled` 是会话同步设置，不能等同数据库备份策略。
- 主库和部分旧备份为 `0644`；备份目录为 `0755`。考虑到用户主目录为 `0750`、`staff` 组，风险主要是同机同组可读，而不是匿名网络可读。

## 2. Claude / Codex / Trae 关键路径与差异

### 2.1 Claude

| 关注点 | 当前路径/状态 |
|---|---|
| Claude Code 全局状态/MCP | `/Users/ganjie/.claude.json`，`0600`，顶层含 `mcpServers`、`projects`、`skillUsage`、`oauthAccount` 等字段 |
| MCP 数量 | 7 |
| MCP 名称 | `codebase-memory-mcp`, `context-mode`, `context7`, `mem0`, `web-reader`, `web-search-prime`, `websearch-cn` |
| 项目状态 | `projects = 21`；未发现 project 级 MCP 覆盖项 |
| MCP cache | `/Users/ganjie/.claude/agents/.mcp-cache.json`：available 65、unavailable 2、server_status 11 |
| 全局设置 | `/Users/ganjie/.claude/settings.json`，`0644`，含 `env`, `permissions`, `hooks`, `statusLine`, `enabledPlugins`, `extraKnownMarketplaces`, model/theme/effort 字段 |
| 插件 | enabledPlugins 中 6 个 true |
| Skills | `/Users/ganjie/.claude/skills -> /Users/ganjie/skills`（symlink） |
| Claude Desktop | `/Users/ganjie/Library/Application Support/Claude/claude_desktop_config.json` 仅顶层 `preferences`，未发现 MCP 字段 |
| 其他 | `/Users/ganjie/.claude/config.json` 仅有 `primaryApiKey` 字段名；值不输出 |

### 2.2 Codex

| 关注点 | 当前路径/状态 |
|---|---|
| 主配置 | `/Users/ganjie/.codex/config.toml`，`0600` |
| Provider | 顶层有 `model_provider`、`model_providers.custom`；`model_provider = custom`（仅状态，不含凭证） |
| MCP 数量 | 8 |
| MCP 名称 | `node_repl`, `codebase-memory-mcp`, `context-mode`, `context7`, `web-reader`, `web-search-prime`, `websearch-cn`, `mem0` |
| Plugins | `plugins` 配置节 16 个 |
| Skills | `/Users/ganjie/.codex/skills -> /Users/ganjie/skills`（symlink） |
| 项目信任 | `projects` 配置节含 `/Users/ganjie`, `/Users/ganjie/skills`, `/Users/ganjie/study/study-note` |
| 其他 | `shell_environment_policy`, `hooks.state`, `marketplaces`, `sandbox_workspace_write`, `memories` 等节存在；凭证类字段名包括 `experimental_bearer_token`, `CONTEXT7_API_KEY`, `Authorization`, `ANTHROPIC_AUTH_TOKEN`，值均不输出 |

### 2.3 Trae

| 关注点 | 当前路径/状态 |
|---|---|
| MCP 配置 | `/Users/ganjie/Library/Application Support/Trae/User/mcp.json`，`0644` |
| MCP 数量 | 7 |
| MCP 名称 | 与 Claude 相同的 7 个：`codebase-memory-mcp`, `context-mode`, `context7`, `mem0`, `web-reader`, `web-search-prime`, `websearch-cn` |
| MCP 字段 | 每项有 `type`/`command`/`args` 或 `url`/`headers`；header 字段名含 `Authorization`、`CONTEXT7_API_KEY`，值不输出 |
| Skill 配置 | `/Users/ganjie/.trae/skill-config.json`，`0600` |
| Skill 状态 | `disabledSkills = 22`, `managedSkills = 0`, `deletedSkills = 0`；含 `builtinSkillStatus`, `remoteSkillInstallHistoryByContext` 字段 |
| Builtins | `~/.trae/builtin/**/skills/` 存在多套内置 skills |
| Trae CN | `/Users/ganjie/.trae-cn/skill-config.json` 存在；`disabledSkills = 0`, `managedSkills = 0` |
| 编辑器设置 | `/Users/ganjie/Library/Application Support/Trae/User/settings.json` 为非严格 JSON/JSONC 状态，109 行；可见 `AI.rules.importClaudeMd`, `AI.toolcall.*`, `claudeCode.preferredLocation`, terminal/env/proxy 等字段名 |
| 与全局 skills repo 的关系 | 未发现 `/Users/ganjie/skills` symlink；Trae skills 是独立 builtin/managed 模型 |

### 2.4 客户端差异摘要

- Provider 管理：cc-switch 记录 Claude/Codex/Gemini/OpenCode provider；live-state 只有 Claude/Codex/Gemini/GrokBuild，且 direct。未见 Trae provider 状态。
- MCP：
  - Claude 与 Trae 均为同一组 7 个 server。
  - Codex 是同组 7 个 + `node_repl`，共 8 个。
  - cc-switch DB 是另一套 9 个旧目录，且只有 Claude enable 标记为 true。
- Skills：
  - Claude、Codex 都用 symlink 消费 `/Users/ganjie/skills`。
  - Trae 不消费该 symlink，`managedSkills = 0`，主要使用 builtin skill 体系。
  - cc-switch DB 记录 30 个 Claude/OpenCode skills，但 Codex enable 为 0，且与当前 repo 顶层目录基本不重合。
- 配置格式：
  - Claude 主要是 JSON；Codex 是 TOML；Trae 是 JSON + JSONC/内置配置，双目录 `~/.trae` 与 Application Support。
- 权限：
  - 敏感主配置 `.claude.json`、Codex TOML、Trae skill config 为 `0600`。
  - Trae MCP JSON 为 `0644`，其中含认证类 header 字段名；风险取决于值来源和值是否长期保存。
  - cc-switch 主库与部分备份为 `0644`。

## 3. `/Users/ganjie/skills` 状态与备份线索

### 3.1 Git 状态

- Branch：`main`
- Local HEAD = `origin/main` = `5bf52ef9be2d416f7be3cb53a1ab6b07290e2913`
- 最新提交：2026-09-04 14:43:49 +0800，主题为全局 skill 仓库大整理。
- Remote：`origin` 指向 GitHub SSH 形式的 `AssassinQuin/skills.git`。
- 状态：local 与 remote ref 无 ahead/behind，但工作区极脏：
  - `git status --porcelain` 15 modified、444 deleted、10 untracked entries、0 added
  - `git ls-files --others --exclude-standard` 展开为 71 个未跟踪文件
  - diff 汇总为 459 files changed, 402 insertions, 55,946 deletions
- 无 stash；`git worktree list` 只有主工作树。
- `.git/FETCH_HEAD` mtime 为 2026-05-27，说明本机最近没有通过 fetch 更新该文件；不能据此证明从未 push，但它是远端联系状态陈旧的线索。

### 3.2 规模

- Tracked files：925
- 当前文件系统（排除 `.git` 与 `node_modules`）：584 个文件，约 40.3 MB
- 全库 `SKILL.md`：44 个；顶层 `*/SKILL.md`：24 个
- 文件数最多的顶层目录：
  - `huashu-nuwa`: 159
  - `reports`: 152
  - `datastore`: 109
  - `.system`: 49
  - `.superpowers`: 23
  - `deep-research`: 11
  - `mcp-replacement-audit`: 11
  - `data`: 9

### 3.3 已有同步/备份/治理线索

- README 明确 `/Users/ganjie/skills` 是全局启用 skill 的实体源；`~/.claude/skills` 应为 symlink。
- `scripts/deploy.sh`：
  - 审计实体源与 `~/.claude/skills` symlink；
  - 检查 repo 内外部 symlink、哑目录、SKILL.md 完整性；
  - 本次执行 exit 1：`/Users/ganjie/skills/mcp-replacement-audit/` 缺 `SKILL.md`。
- 当前 symlink 实测：
  - `~/.claude/skills -> /Users/ganjie/skills`
  - `~/.codex/skills -> /Users/ganjie/skills`
- `scripts/setup-agents.sh` 保存了 Claude agents 反向 symlink 同步模型。
- `docs/agent-skill-mcp-management.md` 记录了既有三层模型：Active catalog / Vendor pool / Runtime adapter，并要求 MCP 变更同时维护 Codex TOML 与 Claude JSON。
- 备份线索：
  - Git remote + local Git 历史是主要恢复机制；
  - 未发现技能仓库专用的外部备份/调度配置；
  - 未发现 skill manifest 与 cc-switch skill DB 的自动转换/对账流程。

## 4. 与 cc-switch 集中管理的冲突点

### 4.1 Skill 源头双轨，且目录基本不相交

事实：

- cc-switch：`skillStorageLocation = cc_switch`、`skillSyncMethod = auto`、DB 30 skills、Claude/OpenCode enabled、`~/.cc-switch/skills` 为空。
- 实际运行：Claude/Codex 都 symlink 到 `/Users/ganjie/skills`；repo 顶层只有 24 个 `SKILL.md`；两套目录仅 1 个重合。

风险：

- cc-switch 和 skills repo 各自宣称/承担 skill 源职责，后续安装、禁用、更新时容易写到不同位置。
- 若 cc-switch 尝试向 `~/.claude/skills` 写入，而该路径是 repo symlink，可能把变更混入 Git 工作区或因目录已由 Git 管理而失败。
- cc-switch DB 的 enable 状态不能描述当前 Codex 实际可见性；Codex 通过 symlink 实际消费 repo。

### 4.2 MCP 目录三套状态

事实：

- 实际 Claude/Trae/Codex 配置基本一致：共同 7 个，Codex 另有 `node_repl`。
- cc-switch DB 是 9 个旧/候选名称，只有 Claude enabled，Codex/Trae 无有效对账状态。
- cc-switch DB 缺 `codebase-memory-mcp` 与 `websearch-cn`，却含 `github`, `searxng`, `zai-mcp-server`, `zread` 等当前主配置未见名称。

风险：

- cc-switch UI 的 MCP 开关可能只反映 Claude 旧目录，不反映 Codex/Trae 实况。
- 手工修改 TOML/JSON 后，cc-switch 没有可靠 inventory，回滚或切换 provider 时可能覆盖旧配置。
- 现有配置中认证字段分散在 Claude/Codex/Trae 与 cc-switch DB，凭证生命周期难以统一轮换。

### 4.3 Provider 写入权不清晰

事实：

- cc-switch 记录 Claude/Codex/OpenCode 当前 provider；live mode 是 direct，本地 proxy/failover 关闭。
- Codex TOML 同时有 `model_provider = custom` 和 `model_providers.custom`。
- Claude settings 有 env/provider 相关字段；cc-switch settings 表有 common config。
- `preserveCodexOfficialAuthOnSwitch = false`。

风险：

- cc-switch、客户端自身、用户手工脚本同时可能写 adapter 文件，缺少单写者边界。
- direct 模式下的切换更依赖改写真实配置文件；一旦 cc-switch 版本或格式兼容性出错，影响面直接落在 Claude/Codex 运行配置。
- Codex official auth 保留策略为 false，切换回官方 provider 时可能需要重新登录或从备份恢复。

### 4.4 文档与脚本落后于真实拓扑

事实：

- 旧文档写“Codex 使用 runtime mirror”，但实测 Codex skills 是 symlink。
- `deploy.sh` 只审计 `~/.claude/skills`，不检查 `~/.codex/skills` 或 Trae。
- 文档中的 MCP 默认表与当前实际配置存在差异。

风险：

- 审计结果给人“部署健康”的错觉；本次实际扩展检查发现 Codex symlink 正常，但脚本不能持续保证。
- Trae 完全在部署审计之外。

### 4.5 备份与权限风险

事实：

- cc-switch 主库 `0644`；5 个早期 DB 备份 `0644`；备份目录 `0755`。
- DB/备份包含 provider 配置、请求日志、session 同步路径和 auth 命名的 live-first-write 文件。
- 未发现远端备份、调度、恢复测试或 retention。
- Git 工作区当前有 444 个删除和 71 个未跟踪文件；HEAD 停留 2026-09-04，FETCH_HEAD 线索较旧。

风险：

- 同机 `staff` 组用户可读部分敏感数据库/备份。
- 本地磁盘故障或误删会同时影响主库与本地备份。
- `proxy_request_logs`/rollups 含使用轨迹，长期保留有隐私和容量风险。
- skills repo 当前状态不可作为可靠恢复点；大量删除尚未提交，误操作 `git reset`/clean 会扩大损失。
- `mcp-replacement-audit/` 缺 `SKILL.md`，当前部署审计失败。

### 4.6 Skill 目录设计失焦

事实：

- 全库 44 个 `SKILL.md`，顶层 24 个；README/设计文档倾向“一个能力一个入口”。
- cc-switch DB 另有 30 个几乎不相交的 skill。

风险：

- agent 扫描面和路由噪音变大；
- 生命周期、启用状态、更新来源难以判断；
- cc-switch 安装的外部 skill 与本地 active catalog 可能重复或互相覆盖。

## 5. 建议数据流

### 5.1 先确定唯一权威

建议按当前实际和既有文档选择：

1. Skill Active Catalog 权威：`/Users/ganjie/skills`
2. Provider/Proxy/切换状态权威：`~/.cc-switch/cc-switch.db`
3. MCP Inventory 权威：先选择一个（推荐独立 manifest 或 cc-switch），再生成各客户端 adapter
4. Runtime adapter：只消费，不手写实体

### 5.2 Skill 数据流（推荐）

```text
Git clean worktree
  -> /Users/ganjie/skills 审核与测试
  -> commit / tag
  -> client adapters:
       Claude  ~/.claude/skills -> repo
       Codex   ~/.codex/skills  -> repo
       Trae    generated mirror 或 wrapper（从 manifest 生成，不手改）
  -> deploy/ledger 全客户端审计
```

具体要求：

- cc-switch 不作为 active catalog 的第二实体源；若继续使用其 skill 安装功能，应先做“DB -> manifest/repo”的一次性导入，再关闭双写。
- 扩展 `deploy.sh`：检查 Claude/Codex symlink、Trae generated state、断链、缺 `SKILL.md`、重复能力入口。
- 修复合法性：`mcp-replacement-audit` 应补入口、改成非 skill 功能目录，或移出扫描根。
- 对 44 个嵌套 `SKILL.md` 做复判，保留 wrapper/实体分层，避免上游整棵树进入全局扫描。

### 5.3 Provider / MCP 数据流（推荐）

```text
cc-switch UI/DB（唯一写者）
  -> transactional export:
       Claude JSON/TOML 字段子集
       Codex TOML 字段子集
       Trae MCP JSON（如 cc-switch 后续支持）
  -> pre/post structural diff + permission check
  -> client reload
```

具体要求：

- Provider 配置、common config、MCP server 定义要有 schema 版本号。
- 客户端文件写入前先做本地原子备份，成功后再提交状态；备份记录 hash 与时间，不记录 secret。
- 保留 direct/proxy 两种模式，但同一时间只允许一个写者。
- 对 cc-switch DB 中 `github`, `searxng`, `zai-mcp-server`, `zread` 等旧 MCP 目录做废弃确认；确认后从 active inventory 移除，保留历史快照。
- 将认证值迁出明文 adapter/DB 备份，优先使用系统 keychain或受控环境注入；配置文件只保留字段引用。

### 5.4 备份与恢复数据流（推荐）

```text
变更前：
  SQLite snapshot + adapter config snapshot
变更后：
  integrity check + row/schema count + structural diff
每日/每周：
  encrypted external backup
季度：
  restore test + permission audit
skills repo：
  clean commit -> fetch/rebase/push -> tag/release
```

具体建议：

- 立即把 `cc-switch.db` 和所有 DB 备份权限收紧到 `0600`，目录至少 `0700`。
- 为备份定义保留策略（例如 7 daily、4 weekly、6 monthly）并做加密远端副本。
- 备份内容分层：可重建 catalog、必须恢复 DB、敏感 auth；auth 优先走 keychain，不进普通备份。
- skills repo 先冻结变更、审查 444 个删除和 71 个 untracked，再提交或分支化；不要在当前脏工作区直接切换 provider 或批量安装 skill。
- 恢复演练至少验证：cc-switch DB integrity、settings/live-state 可解析、Claude/Codex/Trae MCP 可列举、skills symlink 拓扑正确。

## 6. 风险清单（按优先级）

| 级别 | 风险 | 证据 | 建议 |
|---|---|---|---|
| P0 | skills repo 当前不可作为可靠恢复点 | 444 deleted、15 modified、71 untracked files | 先冻结并审计，再提交/分支/推送 |
| P0 | cc-switch 主库与早期备份权限过宽 | 主库/旧备份 `0644`；目录 `0755`；DB 含 provider/MCP/session 数据 | 收紧 `0600/0700`，做访问审计 |
| P1 | Skill 源双轨且基本不相交 | cc-switch 30 skills vs repo 24 top-level，重合 1；`~/.cc-switch/skills` 为空 | 定权威，导入/清理后禁双写 |
| P1 | MCP 三套目录漂移 | 实际 7/8 个 vs cc-switch 9 个旧目录，Codex enable=0 | 建 manifest，统一生成/对账 |
| P1 | Provider direct 写入缺单写者边界 | live direct、proxy disabled、Codex custom provider、cc-switch current provider 并存 | cc-switch 作为唯一写者，手工只应急 |
| P1 | 本地备份无远端/调度/恢复测试证据 | 仅本地 snapshots；无 LaunchAgent/crontab | 加密远端 + retention + restore drill |
| P2 | deploy 审计覆盖不足 | 只查 Claude；文档仍称 Codex mirror | 扩展到 Codex/Trae，更新文档 |
| P2 | 当前部署审计失败 | `mcp-replacement-audit/` 缺 `SKILL.md` | 补入口、改功能目录或移出扫描 |
| P2 | 嵌套 SKILL.md 过多 | 全库 44、顶层 24 | 恢复 wrapper/vendor 分层 |
| P2 | Trae 完全独立管理 | no repo symlink；managedSkills=0；独立 MCP JSON | 纳入 manifest 生成或明确排除 |
| P3 | Git 远端接触线索陈旧 | FETCH_HEAD 2026-05-27；HEAD 2026-09-04 | 固定 fetch/push/verify 周期 |

## 7. 一句话结论

当前机器不是“cc-switch 统一管理多客户端”，而是“cc-switch 管理 provider 状态并保存一套未完全落地的 skill/MCP 目录；Claude/Codex 实际由 `/Users/ganjie/skills` symlink 分发；Trae 独立管理”。三者之间缺少唯一 inventory、事务性导出和恢复流程，且当前 Git 工作区与备份权限风险较高。
