# cc-switch 管理方案替代品与原生配置审计（alternatives）

- 调研日期：2026-10-26
- 调研方式：网页/GitHub 只读调研；搜索查询使用 6/6 次，其后停止扩展检索。本文件基于已经获取的 README、官方文档与当前任务内已有本机审计材料综合。
- 结论等级：`High` = 官方文档/仓库 README 直接支持；`Medium` = 仓库自述或需从机制推导；`Local` = 本机审计发现，不代表所有用户。

---

## 1. 执行摘要

没有一个候选方案适合同时成为 **Claude Code + Codex + Trae 的 provider、MCP、skills、凭据、备份和上下文优化唯一管理者**。更稳的方案是分层：

1. **Skills / 项目 MCP 用 GitOps 或项目原生配置作为权威**：可版本化、可审查、可回滚，跨 Claude/Codex/Trae 生成 adapter。
2. **Provider 频繁切换/failover 交给 cc-switch 桌面版或 CLI**：这是 cc-switch 的强项，但应限定“唯一写者”边界，避免与手写配置双写。
3. **Claude MCP 上下文优化交给 Claude Code MCP Server Selector**：单用途、直接解决启用 MCP 过多导致的工具描述膨胀。
4. **cc-switch-web 只用于受控 headless/服务器场景**：攻击面和误操作面明显大于本机桌面/CLI。
5. **Trae 不能交给 cc-switch 系列管理**：当前证据显示 cc-switch、cc-switch-web、cc-switch-cli 均未内置 Trae adapter；Trae 应使用原生 `.trae/mcp.json`、`.trae/skills/`、`.agents/skills/`，或由自写 GitOps 转换脚本生成。

一句话建议：**“GitOps 管 skills/项目 MCP，cc-switch 管 provider，selector 管 Claude 会话 MCP 瘦身”**。如果不愿维护自写脚本，则退回“各工具原生项目配置 + cc-switch 只做 provider”，不要追求单一全家桶。

---

## 2. 候选矩阵

图例：

- ✅：直接支持且适合作为主要方案
- ⚠️：可做但有边界、需脚本补齐或安全约束
- ❌：不适合/未发现支持
- N/A：维度不适用

| 方案 | 跨 Claude/Codex/Trae | Provider 切换 | MCP 按项目启用 | Skills 版本化 | 凭据安全 | 原子写入/备份/回滚 | 维护成本 | 上下文窗口优化 | 主要证据 |
|---|---|---|---|---|---|---|---:|---|---|
| **cc-switch 桌面版** | ⚠️ Claude ✅、Codex ✅、Trae ❌；还支持 Gemini/Grok/OpenCode 等 | ✅ 强：一键切换、Direct/Routing/Aggregation、failover、账号与 provider presets | ⚠️ 有按 app 和项目 profile，但主机制是同步用户层 live config，不是天然 cwd 项目 scope | ⚠️ 有 marketplace、更新、SSOT、skill backup；但非 Git lockfile 式可复现版本化 | ⚠️ 集中保存 API key/OAuth，写入各工具配置；集中度高，需 0600/0700、keychain/最小备份 | ✅ 官方自述 atomic writes、自动备份、首次写入前备份、skill backup | 中 | ⚠️ 有用量统计与 MCP/Skills 开关，但不解决“当前任务只启用 1–3 个 MCP” | [GitHub](https://github.com/farion1231/cc-switch) |
| **Claude Code MCP Server Selector** | ❌ 仅 Claude Code | ❌ | ✅ Claude local/project/user scope、3 态开关、可迁移到 `.mcp.json` | ❌ 主要管 MCP/plugin，不管 skills | ⚠️ 不解决凭据存储；应配合 Claude local scope/env expansion | ✅ 自述 atomic updates、automatic backups、file locking、global change consent、lockdown | 低 | ✅ 最强：按任务启用 1–3 个 server，`context-report`，自述每 server 15k–25k tokens | [GitHub](https://github.com/henkisdabro/Claude-Code-MCP-Server-Selector) |
| **cc-switch-web / cc-switch CLI** | ⚠️ Claude ✅、Codex ✅、Trae ❌；web 支持 Claude/Codex/Gemini/OpenCode/OpenClaw/OMO，CLI 支持 Claude/Codex/Gemini/OpenCode/Hermes/OpenClaw/Pi | ✅：web 一键切换；CLI provider switch、OAuth account、本地代理/failover | ⚠️ 主要是按 app/host 同步，不是按 repo 自动生效 | ⚠️ CLI 有 SSOT skills、repo branch、更新、多 app enable/disable；web 较偏安装/marketplace；仍非 Git manifest | ⚠️ CLI 集中凭据；web 额外暴露 server host 文件/进程，虽有 Basic Auth、CSRF、CORS/HSTS 仍需 TLS 反代与 0600 password file | ✅ CLI：atomic writes、备份保留 10、restore、WebDAV；web：SQLite backup/restore、integrity、rollback、checksum | 中高 | ⚠️ 有 usage dashboard/token 统计，无 selector 式任务级 MCP 瘦身 | [cc-switch-web](https://github.com/Laliet/cc-switch-web), [cc-switch-cli](https://github.com/saladday/cc-switch-cli) |
| **dotfiles/GitOps + 自写转换脚本** | ✅ 可覆盖 Claude/Codex/Trae，但 Trae/Codex adapter 需自己维护 | ⚠️ 可声明 profile 并生成用户层配置；Codex 明确禁止 project-local provider/auth 覆盖；无内置 failover | ✅ 最强：一个 manifest 生成 `.mcp.json`、`.codex/config.toml`、`.trae/mcp.json` | ✅ 最强：Git commit/tag/submodule/lockfile，可审查、测试、复现 | ✅ 若用 env/keychain/SOPS 引用可最优；若把 secret 写进 dotfiles 则最差 | ⚠️ 非天然；必须自己实现 temp+rename、schema validate、pre/post hash、备份与 git revert | 高初期，低中期 | ✅ 可生成项目最小 MCP baseline；上下文报告仍需外接 | 依据各工具官方配置模型推导 |
| **各工具原生项目级配置** | ⚠️ 各自为政：Claude ✅、Codex ✅但 provider/auth 限制、Trae ✅ | ❌/N/A：provider 多在用户层或 IDE 账号；Codex project-local 明确忽略 provider/auth | ✅ Claude `.mcp.json`；Codex `.codex/config.toml`；Trae `.trae/mcp.json` 需开启 Project MCP | ✅ Claude `.claude/skills`、Codex `.agents/skills`、Trae `.trae/skills` 与 `.agents/skills` 可入 Git；但无统一版本策略 | ⚠️ Claude 支持 env expansion；Codex 有 env/bearer helper；Trae 文档示例偏向写入真实 token，需谨慎 | ⚠️ 项目文件可 git revert；用户层 live config 无统一备份 | 低 | ⚠️ 三者 skills 均有按需加载；MCP 仍靠人工少启用或 selector | [Claude MCP](https://code.claude.com/docs/en/mcp), [Codex config](https://learn.chatgpt.com/docs/config-file/config-reference), [Trae MCP](https://docs.trae.ai/ide/add-mcp-servers) |

---

## 3. 关键事实与证据

### 3.1 cc-switch 桌面版

仓库：<https://github.com/farion1231/cc-switch>

- 官方 README 定位为 Claude Code、Claude Desktop、Codex、Gemini CLI、Grok Build、OpenCode、OpenClaw、Hermes、Pi、MiniMax Code、Kimi Code、Oh My Pi 的 all-in-one 管理器；**未列 Trae**。
- Provider 能力：
  - 一键切换 provider，仅替换 endpoint/key/model 等连接信息，声明保留用户自加 plugins/hooks/MCP/comments。
  - 支持 Direct、Routing、Aggregation；Routing 做本机 API 格式转换和自动 failover。
  - Claude Code 切换后无需重启；Codex/Gemini/Grok 需重启终端或 CLI。
  - 支持 provider presets、GitHub Copilot/ChatGPT/xAI/Kimi 账号。
- MCP/Skills/Prompts：
  - 统一 MCP 面板，可按工具同步。
  - Skills 可从 skills.sh/GitHub/ZIP 安装、更新、同步 symlink/copy。
  - 项目切换器可保存 Claude Code/Claude Desktop/Codex 的当前配置，但这是显式 profile，不等价于按 cwd 自动加载 `.mcp.json`。
- 数据安全：
  - SQLite 保存 providers、MCP、prompts、skills、projects、usage。
  - 默认备份 24 小时一次、保留 10 份；skill 更新/卸载前另有备份，保留 20 份；首次改写 live config 前保存原文件。
  - README 明确 atomic writes。
- 凭据风险：
  - `.cc-switch` 下存在 OAuth login credentials 文件；provider API key 也进入统一状态库。
  - 文档未给出“静态加密”承诺，应按敏感明文对待：目录 `0700`、文件 `0600`、备份加密、避免把敏感 DB 放云盘同步。
- 适用判断：
  - 适合作为 **provider/proxy/failover 管理器**。
  - 不适合作为唯一 skills authority，尤其在已有 Git skills 仓库时，容易形成 SQLite DB 与 Git repo 双源漂移。
  - 不适合 Trae。

### 3.2 Claude Code MCP Server Selector

仓库：<https://github.com/henkisdabro/Claude-Code-MCP-Server-Selector>

- 只面向 Claude Code。
- 核心价值是上下文窗口瘦身：
  - README 自述平均 MCP server 20–30 tools、15k–25k tokens；
  - 大 server 可到 50k–85k tokens；
  - 10 个 server 可达 200k–250k tokens；
  - 推荐每次仅启用 1–3 个。
- 支持发现/合并多配置源，显示 local/project/user scope。
- 3 态：
  - RED：完全禁用；
  - GREEN：启用并启动；
  - ORANGE：配置保留但 runtime disabled。
- 支持 `mcp enable/disable`、`--context-report`、`--export-disabled`、`--sync-check`，适合脚本化。
- 安全/一致性自述：
  - atomic updates；
  - automatic backups；
  - file locking；
  - global change explicit consent；
  - lockdown mode。
- 边界：
  - 不管理 provider。
  - 不管理 Codex/Trae。
  - 不解决 API key 存储和轮换。
  - 只应在退出 Claude 后做配置刷新，运行中修改需重启/下个 session 生效。
- 适用判断：
  - Claude Code MCP 瘦身的最佳单用途工具。
  - 可与 GitOps/cc-switch 并存：GitOps/cc-switch 维护 inventory，selector 做当前任务临时启用/停用。

### 3.3 cc-switch-web 与 cc-switch CLI

两者是不同社区分支，不应视为同一个产品。

#### cc-switch-web

仓库：<https://github.com/Laliet/cc-switch-web>

- 支持 Claude Code、Codex、Gemini CLI、OpenCode、OpenClaw、OMO；**未列 Trae**。
- 特性：
  - 一键 provider 切换；
  - Claude/Codex/Gemini/OpenCode 的统一 MCP；
  - skills marketplace；
  - prompts；
  - 配置备份/恢复与历史；
  - Web server mode，适合 headless/cloud；
  - server host 上的 sessions/usage/local routing。
- 安全边界：
  - Web mode 管理的是 **服务器主机上的文件和进程**，不是浏览器本机。
  - API 要求 Basic Auth；非 GET 自动注入并校验 CSRF。
  - 默认 `HOST=127.0.0.1`，CORS same-origin，`CORS_ALLOW_CREDENTIALS=false`。
  - 有 HSTS、X-Frame-Options DENY、nosniff、Referrer-Policy。
  - README 要求生产部署走 TLS reverse proxy，`web_password` mode 0600。
- 数据安全：
  - SQLite 是 providers/MCP/prompts/skills/proxy/health/logs/failover 的 authoritative store。
  - v0.19 自述 SQLite SQL backup/restore、integrity validation、rollback、retention；WebDAV v2 有 manifest/db.sql/skills.zip/checksums/rollback。
- 边界：
  - 远程 Web 管理面拿的是主机级配置和进程控制权，一旦暴露或弱密码，影响面大于桌面版。
  - 不适合公网裸奔；仅应部署在 VPN/TLS 反代/受控内网。
  - 不支持 Trae。

#### cc-switch CLI

仓库：<https://github.com/saladday/cc-switch-cli>

- CLI fork of cc-switch，支持 Claude Code、Codex、Gemini、OpenCode、Hermes、OpenClaw、Pi；**未列 Trae**。
- Provider：
  - `provider switch/use/add/edit/delete`；
  - managed ChatGPT/Codex OAuth accounts；
  - provider 绑定，不复制 long-lived token 到每个 provider；
  - speedtest、stream check、fetch models；
  - 本地 proxy 支持 Claude/Codex/Gemini，转换 OpenAI Responses/Chat Completions、让 Codex 用 Anthropic Messages-compatible provider。
- MCP：
  - 跨 Claude/Codex/Gemini/OpenCode/Hermes；
  - stdio/http/sse；
  - authenticated remote headers；
  - TOML/JSON live-config adapters；
  - `mcp enable/disable --app`、sync/import。
- Skills：
  - SSOT store；
  - 多 app enable/disable；
  - repo 可 `owner/name[@branch]`；
  - update/update all；
  - symlink/copy sync；
  - unmanaged scan/import。
- 安全/一致性：
  - SQLite-backed state；
  - atomic writes：temp file + rename；
  - RwLock；
  - backups 保留 10，可 restore/import/export/WebDAV。
- 边界：
  - 主要是用户层 live config，不是项目 manifest 生成器。
  - 与桌面版共享 `~/.cc-switch` 时存在数据库版本滞后风险。
  - 无 Trae adapter。
- 适用判断：
  - 没有 GUI 的 macOS/Linux/Windows 环境中，比桌面版更适合 provider/failover 管理。
  - 如果重点是可审计的项目配置，仍不如 Git manifest。

### 3.4 dotfiles/GitOps + 自写转换脚本

这不是现成工具，而是可控架构。推荐的数据模型：

```text
private config repo / project repo
  ├── agents.yaml 或 mcp-manifest.yaml   # 非 secret：server id、transport、args、scope、enabled profiles
  ├── skills repo / submodule / lockfile  # commit/tag/hash
  ├── profiles/*.yaml                    # provider profile，仅 secret 引用
  └── generator
        ├── validate schema
        ├── render:
        │     Claude -> .mcp.json / user local config
        │     Codex  -> .codex/config.toml / user config
        │     Trae   -> .trae/mcp.json / generated skills mirror
        ├── check no literal secret
        ├── backup current files
        ├── temp file + atomic rename
        └── print structural diff + hashes
```

优点：

- 唯一能同时覆盖 Claude/Codex/Trae 的方案。
- Skills 可以真正 commit/tag/审查/回滚。
- MCP 可以按 repo/project/profile 最小化生成。
- Secret 可完全外置到 keychain/SOPS/environment injection。
- 不被单一第三方工具的 schema/UI 发行节奏绑定。

必要实现要求：

- 单一写者：generator 或 cc-switch 二选一，不得同时写同一 live config。
- Schema 版本化。
- 渲染前 JSON Schema/TOML schema 校验。
- Secret 扫描，配置中只允许引用。
- temp + rename 原子写。
- 变更前快照、变更后结构 diff、hash ledger。
- 对 Codex 明确区分 project 允许字段与 user-only provider/auth 字段。
- 对 Trae 输出 `.trae/mcp.json`、`.trae/skills/`，并处理 `.agents/skills` 优先级。
- 恢复演练：至少验证 Claude/Codex/Trae 能列出 MCP、skills symlink/mirror 正确。

缺点：

- 初期工程成本最高。
- 上游配置格式变化时需要维护 adapter。
- 没有 cc-switch 的现成 provider marketplace/failover。
- 如果只是写 shell 脚本拼接 JSON/TOML，容易变成新的漂移来源。

### 3.5 原生项目级配置

#### Claude Code

文档：

- MCP：<https://code.claude.com/docs/en/mcp>
- Quickstart：<https://code.claude.com/docs/en/mcp-quickstart>
- Skills：<https://code.claude.com/docs/en/skills>
- `.claude` 目录：<https://code.claude.com/docs/en/claude-directory>

关键事实：

- MCP scopes：
  - Local：当前项目，私有，`~/.claude.json`；
  - Project：当前项目，团队共享，repo 根 `.mcp.json`；
  - User：所有项目，私有，`~/.claude.json`。
- Project `.mcp.json` 会进入版本控制，但首次使用需要用户批准，防止 clone 的 repo 自动启动本机进程。
- 支持 `enabledMcpjsonServers`、`disabledMcpjsonServers`、per-project disabled runtime override。
- `.mcp.json` 支持 environment variable expansion，可用于机器路径和敏感值。
- `.claude` 中项目文件可入 Git；`~/.claude` 是个人全局配置。
- Skills 使用 `SKILL.md`，项目 skills 位于 `.claude/skills/`；skill body 只有使用时加载，适合把长参考从 `CLAUDE.md` 移出。

边界：

- 原生 scope 很好，但没有跨工具转换。
- 如果启用过多 MCP，仍会膨胀上下文；selector 是运行时/会话层补齐。

#### Codex

文档：

- Configuration Reference：<https://learn.chatgpt.com/docs/config-file/config-reference>
- Build skills：<https://learn.chatgpt.com/docs/build-skills>
- Repo docs：<https://github.com/openai/codex/blob/main/docs/config.md>

关键事实：

- 用户配置在 `~/.codex/config.toml`。
- 项目覆盖可在 `.codex/config.toml`，但只在信任项目后加载。
- **Project-local config 不能覆盖 machine-local provider、auth、notification、profile selection、telemetry routing**；`model_provider`、`model_providers`、`openai_base_url`、`chatgpt_base_url` 等在 project-local 中被忽略，应放在 user-level。
- MCP 支持：
  - stdio `command/args/env/env_vars`；
  - HTTP headers、OAuth；
  - `bearer_token_env_var` 从环境变量读取 bearer token；
  - `http_headers_helper` 可用命令生成 headers；
  - `mcp_optional_startup_grace_ms` 控制初始 tool catalog 等待。
- Skills：
  - repo 范围从 CWD 向上扫描 `.agents/skills`，root 为 `$REPO_ROOT/.agents/skills`；
  - user 为 `$HOME/.agents/skills`；
  - admin 为 `/etc/codex/skills`；
  - 初始 skills catalog 默认最多占模型 context window 的 2%，可用 `skills.max_context_tokens` 调整，最高 10000 tokens；
  - skill 被选中后才读取完整 `SKILL.md`。

边界：

- 项目配置适合 MCP/skills/权限等，不适合 provider/auth。
- Provider 切换应由 user config、cc-switch 或脚本写入用户层。
- 自写转换器必须尊重 Codex 的字段层级，不能把 provider profile 写进 project `.codex/config.toml` 后误以为生效。

#### Trae

文档：

- MCP overview：<https://docs.trae.ai/ide/model-context-protocol>
- Add MCP servers：<https://docs.trae.ai/ide/add-mcp-servers>
- Use MCP servers in agents：<https://docs.trae.ai/ide/use-mcp-servers-in-agents>
- Skills：<https://docs.trae.ai/ide/skills>

关键事实：

- 支持 stdio、SSE、Streamable HTTP。
- 全局 MCP 在 Settings > MCP 中配置，可从 marketplace 或手工 JSON 添加。
- 项目 MCP：
  1. Settings > MCP 开启 Project MCP；
  2. 项目根 `.trae/mcp.json` 写入 `mcpServers`；
  3. 需要能力时 Trae 自动加载。
- `${workspaceFolder}` 可解析为当前项目根。
- Agent 使用：
  - 内置 Agent 默认加入全部 configured MCP servers，可在编辑页启用/禁用；
  - custom agent 可选择 MCP servers 和其中 tools。
- Skills：
  - 项目 skills：`.trae/skills/`；
  - 全局 skills：`~/.trae/skills`；
  - 也支持 `.agents/skills/`，但 `.trae/skills/` 同名优先；
  - skills 按需加载，避免全部注入 context。

安全边界：

- 官方示例把 `Authorization: Bearer xxxx` 写入 HTTP headers，并提示“将 API key/token/access key 替换为真实信息”。
- 文档只确认 `${workspaceFolder}` 变量，未确认通用 `${ENV_VAR}` secret 引用。
- 因此 **不要默认把带 token 的 `.trae/mcp.json` 提交到 Git**；项目文件应尽量只包含非 secret，敏感值留在本机全局受控配置、keychain 注入或由部署脚本在 ignored 文件中生成。
- 官方提醒 workspace 项目文件需来自可信来源，避免恶意 MCP 配置。

---

## 4. 维度深评

### 4.1 跨 Claude/Codex/Trae

- **cc-switch 系列**：Claude/Codex 强，Trae 均未支持。若强行使用，只能外挂脚本把 cc-switch DB 导出成 Trae JSON，但这会引入第二套状态。
- **MCP selector**：只适合 Claude，不应作为跨工具方案。
- **GitOps**：唯一可原生覆盖三者，代价是维护 generator。
- **原生配置**：每个工具都能做自己该做的事，但没有统一 inventory，容易漂移。

### 4.2 Provider 切换

- cc-switch 桌面版功能最完整：preset、Routing、Aggregation、failover、账号、托盘。
- cc-switch CLI 适合 headless 和脚本化。
- cc-switch-web 适合远程主机，但安全边界更大。
- GitOps 可管理 profile 定义，但动态切换/failover 需要额外实现。
- Codex 项目配置明确不能接管 provider/auth，这决定了 provider writer 必须在用户层。

### 4.3 MCP 按项目启用

- Claude 的 `.mcp.json` 与 disabled lists 最成熟。
- Codex 的 `.codex/config.toml` 可做项目 override，但必须信任项目且不能放 provider/auth。
- Trae 的 `.trae/mcp.json` 明确支持 project MCP。
- cc-switch 系列是 app-level live sync，不是 repo manifest；若目标是“打开这个 repo 自动只有这些 MCP”，GitOps/原生项目配置更正确。
- selector 在 Claude 上提供最佳任务级临时开关。

### 4.4 Skills 版本化

- Git repo 是最可信版本化方式。
- Claude/Codex/Trae 都支持项目 skills 或 `.agents/skills`，因此可以统一入 Git。
- cc-switch 的 marketplace/SSOT 适合发现、安装、更新，但缺少 lockfile/hash/manifest 的可复现性；与已有 skills repo 并存时必须明确唯一权威。
- 当前本机审计也发现 cc-switch skill DB 与 `/Users/ganjie/skills` 实际目录基本不相交，说明双源漂移不是理论风险。

### 4.5 凭据安全

排序（在正确实现下）：

1. **GitOps + keychain/SOPS/env injection**：配置仅存引用，最佳。
2. **原生项目配置 + local/env helper**：Claude/Codex 有较清楚的引用机制；Trae 需谨慎。
3. **MCP selector**：不改变凭据存储模型，安全取决于原 Claude 配置。
4. **cc-switch 桌面/CLI**：集中方便，但集中库和备份成为高价值目标。
5. **cc-switch-web**：能力最强、暴露面也最大；必须 TLS/VPN/强口令/主机隔离。

强制要求：

- `.cc-switch` 目录 `0700`，数据库、OAuth、备份 `0600`。
- 云同步/备份必须加密，敏感 auth 优先不进普通备份。
- `.trae/mcp.json`、`.mcp.json`、`.codex/config.toml` 入 Git 前必须 secret scan。
- Web 服务不要 `0.0.0.0` 裸露；默认保持 `127.0.0.1`，远程访问走 VPN/TLS 反代。
- routing proxy 能看到请求流量和认证材料，只有信任该本机进程时才启用。

### 4.6 原子写入、备份与回滚

- cc-switch 桌面/CLI/web 都有明确 atomic/backup/restore 能力，适合非 Git 的用户层配置。
- MCP selector 对 Claude 配置有 atomic/backup/locking。
- GitOps 的项目文件天然可 git revert，但用户层配置仍需脚本做快照和原子写。
- 自写脚本最低标准：
  1. render 到 temp；
  2. validate；
  3. backup；
  4. fsync/rename；
  5. post-validate；
  6. 写入 hash ledger；
  7. 支持 `apply --check` 和 `rollback`。

### 4.7 维护成本

| 方案 | 成本 | 说明 |
|---|---:|---|
| 原生项目配置 | 低 | 无新工具，但手动维护三套格式 |
| MCP selector | 低 | 单用途， npm/npx 即用 |
| cc-switch 桌面 | 中 | UI 降低门槛，但要跟踪 schema/UI/release 和权限 |
| cc-switch CLI/web | 中高 | CLI 稳定些；web 还有服务安全和升级 |
| GitOps generator | 高初期 | 需要写 schema、renderer、验证、备份、恢复演练 |

### 4.8 上下文窗口优化

- **MCP selector**：唯一以“少启用 MCP”为核心目标，直接降低工具定义 token。
- **原生 skills**：三者均按需加载 skill 内容，应把长参考移入 skills，避免全部塞进全局 rules。
- **Codex**：可用 `skills.max_context_tokens` 限制初始 catalog，最高 10000 tokens。
- **GitOps**：按项目只生成必要 MCP，是最结构化的长期优化。
- **cc-switch**：usage dashboard 只观测消耗，不自动减少 MCP 工具描述；MCP 开关也偏 inventory，而非当前任务最小集。

---

## 5. 明确适用边界

### 5.1 cc-switch 桌面版：适用

适合当：

- 主要痛点是 Claude/Codex/Gemini/Grok 等 provider 频繁切换；
- 需要 Routing/Aggregation/failover；
- 需要 GUI、托盘、provider presets、账号和用量观测；
- 不需要管理 Trae；
- 愿意把 `.cc-switch` 当敏感权限域保护。

不适合当：

- Trae 是第一等公民；
- skills 已有 Git 权威仓库；
- 目标是每个 repo 自动加载最小 MCP 集；
- 无法接受第三方 GUI 持续改写用户层配置；
- 需要完全可审计的 lockfile/hash 复现。

### 5.2 MCP Server Selector：适用

适合当：

- Claude Code 启用了很多 MCP；
- 每个任务只需要 1–3 个 server；
- 需要 context report 和脚本化 enable/disable；
- 愿意退出 Claude 后刷新配置，或在会话中接受下个 session 生效。

不适合当：

- 需要跨 Claude/Codex/Trae；
- 需要 provider 切换；
- 需要集中凭据轮换；
- Codex/Trae 是主要痛点。

### 5.3 cc-switch-web：适用

适合当：

- headless 服务器/远程开发机；
- 只在 VPN/TLS 反代/受控内网暴露；
- 需要管理 server host 上的 Claude/Codex/Gemini/OpenCode 配置；
- 有明确备份/恢复和主机隔离策略。

不适合当：

- 公网直接暴露；
- 个人桌面本机能满足需求；
- 需要管理 Trae；
- secret 权限和 TLS 反代无法保证。

### 5.4 cc-switch CLI：适用

适合当：

- SSH/headless 场景需要 provider switch；
- 希望脚本化 provider/MCP/skills 操作；
- 需要 managed OAuth 或本地代理；
- 不需要 GUI。

不适合当：

- 需要管理 Trae；
- 需要项目 manifest 的强 Git 语义；
- 与新版桌面 DB 共享时无法接受 CLI schema 滞后；
- 希望零维护。

### 5.5 dotfiles/GitOps + 自写转换：适用

适合当：

- Claude/Codex/Trae 三端都必须一致；
- skills/MCP 需要代码审查、tag、hash、可复现部署；
- 项目需要最小 MCP baseline；
- 有时间维护 schema/renderer/restore drill。

不适合当：

-只想快速切换 API provider；
- 不愿写和维护转换脚本；
- 需要 cc-switch 级动态 failover；
- 配置只有自己一台机器、一个项目，原生配置已够。

### 5.6 原生项目级配置：适用

适合当：

- 单项目团队共享 MCP/skills；
- 不需要跨工具同步；
- 想最小化第三方依赖；
- 能接受手动维护三套格式。

不适合当：

- 多机器、多客户端、多 provider 高频切换；
- 需要集中备份/恢复；
- 需要防止三端 inventory 漂移；
- 需要自动 context 优化。

---

## 6. 对当前环境的推荐架构

结合本任务已有本机审计：Claude/Codex 实际通过 `/Users/ganjie/skills` symlink 消费 skills，Trae 独立管理；cc-switch DB 中 MCP/skills 状态与实际配置存在漂移。推荐：

1. **冻结双写，先定权威**
   - Skills authority：`/Users/ganjie/skills` Git repo。
   - Provider/proxy authority：若继续使用 cc-switch，只允许 cc-switch 写 provider 相关用户层配置。
   - MCP authority：建议独立 manifest，或明确交给 GitOps；当前不建议让 cc-switch DB 继续充当未对账权威。

2. **Skills 数据流**
   ```text
   /Users/ganjie/skills commit/tag
     -> Claude  .claude/skills 或 ~/.claude/skills symlink
     -> Codex  .agents/skills 或 ~/.agents/skills/symlink
     -> Trae   generated .trae/skills mirror（不要手改）
     -> audit script: SKILL.md、重复名、断链、权限、Git clean
   ```
   cc-switch 的 skill marketplace 可以作为发现/导入来源，但导入后应进入 Git repo，不应继续双写。

3. **MCP 数据流**
   ```text
   mcp-manifest.yaml (secret-free)
     -> render Claude .mcp.json / user local config
     -> render Codex  .codex/config.toml
     -> render Trae   .trae/mcp.json
     -> secret references via env/keychain
     -> validate + atomic apply + structural diff
   ```
   Claude 侧再用 MCP Selector 做任务级最小启用。

4. **Provider 数据流**
   - 高频切换：cc-switch 桌面/CLI 作为唯一 provider writer。
   - 低频切换：原生用户层配置 + 手动备份即可。
   - 不把 provider key 写入项目 repo；不把 Codex provider/auth 放 project-local config。

5. **备份**
   - Skills：Git commit/tag/remote。
   - MCP manifest：Git private config repo。
   - cc-switch DB：本地 snapshot + 加密远端，`0600/0700`。
   - Live configs：变更前 snapshot + hash，恢复演练必须验证三端 MCP/skills 可列举。

---

## 7. 不确定性与未解问题

1. **cc-switch 的项目 profile 粒度**
   - README 证明存在 Claude/Claude Desktop/Codex 的 project switcher，可保存当前配置并切换整套 setup。
   - 未看到其等价于“根据 cwd 自动加载 repo 内 `.mcp.json`/`.codex/config.toml`”的完整行为说明。因此矩阵中仅给 ⚠️，不假定完全项目化。

2. **cc-switch 凭据加密**
   - README 列出 OAuth credential 文件，未承诺静态加密。
   - 需要源码/本机验证才能确认当前版本字段级加密、备份加密与权限默认值。安全上应按敏感明文处理。

3. **cc-switch 与最新上游的 schema 兼容**
   - cc-switch CLI README 提到与桌面版共享 DB，但 CLI 支持的 DB 版本可能滞后。
   - 升级顺序和 rollback 需实测。

4. **MCP Selector token 估算**
   - 15k–25k tokens/server 是项目 README 自述，不是独立 benchmark。
   - 应以 `context-report` 在本机 MCP 集合上实测为准。

5. **Trae secret 引用能力**
   - 官方文档确认 `${workspaceFolder}`，未确认通用环境变量 secret 引用。
   - 在确认前，不应把 token 写入可提交的 `.trae/mcp.json`。

6. **WebDAV/S3 同步中的敏感数据**
   - cc-switch 支持 WebDAV/S3；文档说明部分 runtime logs/usage 不上传，但未完全确认 provider auth、OAuth、MCP headers 的排除范围。
   - 使用前应做备份内容审查。

7. **Claude/Codex/Trae 原生格式的演进**
   - 本报告日期为 2026-10-26。Claude/Codex/Trae 的 project config、skills scope 和安全策略都可能随版本变化；实施 generator 前应锁定版本并加 schema tests。

---

## 8. 最终候选决策表

| 场景 | 首选 | 次选 | 不选 |
|---|---|---|---|
| 只想快速切换 Claude/Codex provider | cc-switch 桌面版 | cc-switch CLI | MCP Selector |
| SSH/headless provider 管理 | cc-switch CLI | 受控 cc-switch-web | 桌面版 |
| Claude MCP 上下文爆炸 | MCP Server Selector | 原生 project `.mcp.json` + 手动禁用 | 只靠 cc-switch usage dashboard |
| 三端 skills 同步和版本化 | GitOps + `/Users/ganjie/skills` | 各工具原生项目 skills | 让 cc-switch skill DB 成为第二权威 |
| 三端项目 MCP manifest | GitOps generator | 各工具手写项目配置 | cc-switch（无 Trae） |
| 团队共享项目 MCP，无跨工具需求 | 原生 Claude/Codex/Trae 项目配置 | GitOps | cc-switch-web |
| 动态 failover/API 格式转换 | cc-switch Routing | 自建 gateway | MCP Selector |
| 远程服务器集中管理 | TLS/VPN 后的 cc-switch-web | cc-switch CLI | 公网 cc-switch-web |
| 最少维护、单机单项目 | 原生配置 | MCP Selector | 自写 GitOps |

---

## 9. 来源清单

### 工具仓库

1. cc-switch：<https://github.com/farion1231/cc-switch>
2. Claude Code MCP Server Selector：<https://github.com/henkisdabro/Claude-Code-MCP-Server-Selector>
3. cc-switch-web：<https://github.com/Laliet/cc-switch-web>
4. cc-switch-cli：<https://github.com/saladday/cc-switch-cli>

### Claude Code 官方文档

5. MCP reference：<https://code.claude.com/docs/en/mcp>
6. MCP quickstart：<https://code.claude.com/docs/en/mcp-quickstart>
7. Skills：<https://code.claude.com/docs/en/skills>
8. `.claude` directory：<https://code.claude.com/docs/en/claude-directory>

### Codex 官方文档

9. Configuration Reference：<https://learn.chatgpt.com/docs/config-file/config-reference>
10. Build skills：<https://learn.chatgpt.com/docs/build-skills>
11. OpenAI Codex repo config docs：<https://github.com/openai/codex/blob/main/docs/config.md>

### Trae 官方文档

12. MCP overview：<https://docs.trae.ai/ide/model-context-protocol>
13. Add MCP servers：<https://docs.trae.ai/ide/add-mcp-servers>
14. Use MCP servers in agents：<https://docs.trae.ai/ide/use-mcp-servers-in-agents>
15. Skills：<https://docs.trae.ai/ide/skills>

### 本任务内已有本机审计

16. `/Users/ganjie/skills/reports/research/cc-switch-management-audit/raw/local-environment.md`
17. `/Users/ganjie/skills/reports/research/cc-switch-management-audit/raw/community-feedback.md`
18. `/Users/ganjie/skills/reports/research/cc-switch-management-audit/raw/3.1-mcp.md`
