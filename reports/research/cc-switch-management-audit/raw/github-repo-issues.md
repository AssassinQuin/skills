# farion1231/cc-switch 仓库与 Issue/发布史调研原始摘要

- 调研日期：2026-10-26（GitHub API 返回时点约为当日 UTC 上午）
- 范围：仅 `farion1231/cc-switch` 仓库本体、issues、releases、默认分支 commit history / Git tree
- 方法：只读 `gh` CLI。共发起 8 次 `gh` 调用：1 次成功聚合查询、1 次轻量 issue 搜索、1 次递归 Git tree、1 次失败的重量级搜索（只可靠使用总命中数）、1 次超时的 tarball 下载（未解包）、3 次早期失败/校正调用。此后没有再用 `gh`。
- 证据基础：仓库元数据、语言统计、README、`package.json`、`src-tauri/Cargo.toml`、`src-tauri/tauri.conf.json`、最近 100 条 issues 及评论、最近 100 条 commits、全部 76 个 releases、完整 Git tree 的路径信息。没有在报告中复制任何密钥/token。

## 1. 仓库定位、技术栈与支持工具

### 定位

- 仓库描述：跨平台桌面 All-in-One 管理器，面向 Claude Code、Codex、OpenCode、OpenClaw、Grok Build、Hermes Agent 等 AI 编码工具；README 进一步列出 13 个受管工具：Claude Code、Claude Desktop、Codex、Gemini CLI、Grok Build、OpenCode、OpenClaw、Hermes、Pi、MiniMax Code、Kimi Code、Oh My Pi。见 [README](https://github.com/farion1231/cc-switch#why-cc-switch)。
- 核心能力是供应商一键切换、统一 MCP/Skills/Prompts、会话阅读/恢复、用量与额度统计、工具安装升级。供应商模式包括 Direct、本地 Routing、Aggregation；README 称有 90+ 供应商预设。见 [README Features](https://github.com/farion1231/cc-switch#features)。
- 平台：Windows 10+、macOS 12+、Linux x86_64/ARM64；支持把部分工具的配置目录指向 WSL 路径。见 [README Installation/FAQ](https://github.com/farion1231/cc-switch#download--installation)。

### 技术栈

- 后端/桌面壳：Tauri 2 + Rust；数据库 SQLite；代理/路由相关代码使用 axum、hyper、reqwest、rustls；`Cargo.toml` 还包含 `rusqlite`、`toml_edit`、`serde_yaml`、压缩库等。见 [Cargo.toml](https://github.com/farion1231/cc-switch/blob/main/src-tauri/Cargo.toml)。
- 前端：React 18 + TypeScript + Vite；主要库包括 Radix UI、TanStack Query/Virtual、CodeMirror、Recharts、Zod、Tailwind。见 [package.json](https://github.com/farion1231/cc-switch/blob/main/package.json)。
- 当前仓库 manifest 版本为 `4.0.20`；Tauri 配置同样是 `4.0.20`，启用 updater。见 [tauri.conf.json](https://github.com/farion1231/cc-switch/blob/main/src-tauri/tauri.conf.json)。
- 语言统计：Rust 约 12.20 MB、TypeScript 约 7.34 MB，另有 HTML/CSS/JavaScript/Python。仓库 primary language 是 Rust。

### 支持工具与功能边界

README 的矩阵显示：

- 完整或接近完整：Claude Code、Codex、Gemini CLI、Grok Build（Gemini/Grok 无聚合模式）。
- Claude Desktop：供应商切换、Model Mapping/本地路由、托盘；不支持 MCP/Skills/会话/常规用量。
- Coexist 模式工具：OpenCode、OpenClaw、Hermes、Pi、MiniMax Code、Kimi Code、Oh My Pi。多数支持 MCP/Skills/Prompts/会话，OpenClaw 不支持 MCP/Skills/用量。
- 差异本身是风险来源：不同工具的 JSON/TOML/YAML/.env schema、模型字段和 MCP 字段并非同构。

## 2. 数据存储与备份/恢复设计

README “Where is my data stored?” 和 Git tree 均确认以下设计：

- 默认目录：用户 home 下的 `.cc-switch`。
- 主数据：`cc-switch.db`，SQLite，存储 providers、MCP、prompts、Skills、projects、usage records 等。见 [README FAQ](https://github.com/farion1231/cc-switch#where-is-my-data-stored) 与 [database/mod.rs](https://github.com/farion1231/cc-switch/blob/main/src-tauri/src/database/mod.rs)。
- 设备级数据：`settings.json`，保存各工具配置目录、备份策略、云同步连接等，设计上留在本机、不进云同步。见 [README FAQ](https://github.com/farion1231/cc-switch#where-is-my-data-stored)。
- 定期备份：`backups/`，默认每 24 小时自动备份、保留最近 10 份，可在设置调整；另有备份位置/大小/分类清理界面。见 [README FAQ](https://github.com/farion1231/cc-switch#where-is-my-data-stored) 与 [backup_storage.rs](https://github.com/farion1231/cc-switch/blob/main/src-tauri/src/services/backup_storage.rs)。
- Skills：默认在 `skills/`，可改到 `~/.agents/skills`；默认用 symlink 同步到各工具，失败则回退复制；更新/卸载前自动进入 `skill-backups/`，保留 20 份。见 [skill.rs](https://github.com/farion1231/cc-switch/blob/main/src-tauri/src/services/skill.rs)。
- 首次改写保护：每个工具配置文件第一次被 CC Switch 改写前，原始文件保存在 `backups/live-first-write/`。见 [README FAQ](https://github.com/farion1231/cc-switch#will-switching-providers-change-my-plugins-hooks-or-other-settings)。
- 运行态与 OAuth：`live-state.json` 保存 Direct/Routing/Aggregation 状态；`codex-login-stash.json` 暂存官方 Codex 登录；另有 Copilot/Codex/xAI OAuth JSON 文件。设计上设备状态与原始配置不进云同步。
- 云同步：README 宣称支持 WebDAV（坚果云、Nextcloud、Synology 等）和 S3 兼容存储（AWS S3、R2、OSS、COS 等），也可把配置目录放进 Dropbox/OneDrive/iCloud。Git tree 有 [webdav_sync.rs](https://github.com/farion1231/cc-switch/blob/main/src-tauri/src/services/webdav_sync.rs)、[s3_sync.rs](https://github.com/farion1231/cc-switch/blob/main/src-tauri/src/services/s3_sync.rs)、[sync_protocol.rs](https://github.com/farion1231/cc-switch/blob/main/src-tauri/src/services/sync_protocol.rs)。
- v4.0 的配置写入设计从“整文件快照重写”改为“关键字段替换”，README 称只替换 endpoint/key/model/API protocol 等连接字段，保留 hooks、permissions、MCP、注释、格式等；v4.0.0 release 还称写前检查外部改动。见 [v4.0.0](https://github.com/farion1231/cc-switch/releases/tag/v4.0.0)。

架构演进中的存储/备份要点：

- v3.1.0：v1→v2 迁移前备份。
- v3.2.0：SSOT、原子写入与回滚。见 [v3.2.0](https://github.com/farion1231/cc-switch/releases/tag/v3.2.0)。
- v3.5.0：MCP 管理、导入导出、导入前备份、备份轮转。见 [v3.5.0](https://github.com/farion1231/cc-switch/releases/tag/v3.5.0)。
- v3.8.0：单 JSON 迁移到 SQLite + JSON 双层架构：SQLite 保存可同步数据，JSON 保存设备级数据；支持 schema migration、事务、SQL dump/binary snapshot。见 [v3.8.0](https://github.com/farion1231/cc-switch/releases/tag/v3.8.0) 与 [backup.rs](https://github.com/farion1231/cc-switch/blob/main/src-tauri/src/database/backup.rs)。
- v3.20.0/v4.0.18-v4.0.20：多次数据库 schema migration，release 明确升级前自动备份、降级需还原备份。见 [v3.20.0](https://github.com/farion1231/cc-switch/releases/tag/v3.20.0)、[v4.0.20](https://github.com/farion1231/cc-switch/releases/tag/v4.0.20)。

## 3. 活跃度快照

| 指标 | 数值/结论 | 备注 |
|---|---:|---|
| Stars | 148,736 | GraphQL snapshot |
| Forks | 9,784 | GraphQL snapshot |
| Issues（不含 PR 的 issues connection 总数） | 5,916 | 未取得全量 open/closed 分母 |
| Releases | 76 | 从 v2.0.3 到 v4.0.20 |
| 默认分支 commits | 3,275 | `main` history totalCount |
| 创建时间 | 2025-08-04 | 约 14.8 个月后仍高度活跃 |
| 最近 push | 2026-10-26T06:45:44Z | 查询当日 |
| 最近 100 issues | #8697–#8897，2026-10-22 至 10-26；54 open / 46 closed | 说明 issue 量和维护吞吐都很高 |
| 最近 100 commits | 2026-10-23 至 10-26，4 个自然日 | 10-24 为 39 commits，10-23 为 38；farion1231 占 84/100 |
| v4.0 发布节奏 | v4.0.0 10-04，v4.0.20 10-24，共 21 个 release | 21 天内高频修补/扩展 |

结论：项目增长和迭代极快，但提交作者高度集中，且 v4.0 系列几乎每日发布，功能扩张与兼容性修补并行。

## 4. Issue 风险画像

### 4.1 关键词命中（全量 issue search 的总命中数）

这些是全文关键词命中，非互斥分类，不能直接当作“严重 bug 数”：

- provider：1,812
- 同步/sync：1,290
- 覆盖（中文）：859
- MCP：481
- Skills：393
- 丢失（中文）：336
- 备份（中文）：304
- 权限（中文）：171
- "data loss"：22

解释：供应商/模型兼容、同步/覆盖、MCP/Skills 是最大议题簇。`provider` 与 `同步` 命中极高也符合产品定位——它长期改写多个外部工具的配置并转换多家 API 协议。

### 4.2 数据丢失 / 配置覆盖

仍存在或近期仍存在的模式：

- [#8797](https://github.com/farion1231/cc-switch/issues/8797)（OPEN，v4.0.19）：Codex 路由/聚合模式会丢 `http_headers`。维护者 farion1231 在评论中确认当前写入的是本地代理 provider，不带原供应商 `http_headers`，并称已有 PR 待审。这说明“关键字段替换”的字段白名单仍不完整。
- [#8861](https://github.com/farion1231/cc-switch/issues/8861)（OPEN，main/4.0.20）：Gemini `.env` 中带 `export` 的 key 未被导入为 default provider，切换回 default 后该 key 行被删除。维护者称等待 PR #8862 审核。
- [#8780](https://github.com/farion1231/cc-switch/issues/8780)（OPEN）：OpenCode model/SDK option 重命名时可静默覆盖既有条目。
- [#8605](https://github.com/farion1231/cc-switch/issues/8605)（OPEN）：重复实际模型时保存静默丢行、旧显示名残留。
- [#8502](https://github.com/farion1231/cc-switch/issues/8502)（OPEN）：WebDAV 同步未下发写回 Pi `models.json`，且本地旧配置反向覆写抹除。标题已指向“云同步 + 本地旧状态回写”的组合风险。
- [#8783](https://github.com/farion1231/cc-switch/issues/8783)（OPEN）：SQL import 显示完全成功，但 backend post-import synchronization 失败，存在“导入成功”与“落盘/同步成功”不一致。

已修复的代表性问题：

- [v4.0.0](https://github.com/farion1231/cc-switch/releases/tag/v4.0.0) 明确承认旧版整文件快照重写导致 hooks、插件、权限、MCP 等在切换时丢失或被冻结进某一个供应商；v4.0 改为关键字段替换并首次写前备份。
- [v4.0.15](https://github.com/farion1231/cc-switch/releases/tag/v4.0.15) 修复 Windows 更新后 settings 被重置：此前直接覆盖写 `settings.json`，内容变短时旧尾巴未截掉、解析失败后又读默认值并写回；现改为临时文件替换、BOM/尾部处理、解析失败先备份 `settings.json.broken-*`。
- [v4.0.12](https://github.com/farion1231/cc-switch/releases/tag/v4.0.12) 修复 #8153：Windows 云同步恢复 Skills 遇到文件占用后留下 `skills.bak`，之后每次恢复失败；现改为完整复制到独立目录再整体替换，替换和回滚都失败时保留原完整副本并告知位置。
- [v3.17.0](https://github.com/farion1231/cc-switch/releases/tag/v3.17.0) 修复“删掉的 MCP 服务器复活”等正确性问题。

### 4.3 同步 / 云备份

高频且尚未完全闭环：

- [#8019](https://github.com/farion1231/cc-switch/issues/8019)（OPEN）：多设备 WebDAV 同步看起来未成功。
- [#2569](https://github.com/farion1231/cc-switch/issues/2569)（OPEN）：WebDAV 云同步无法正常使用。
- [#8502](https://github.com/farion1231/cc-switch/issues/8502)（OPEN）：远端未写回、本地旧配置反向覆写。
- [#6079](https://github.com/farion1231/cc-switch/issues/6079)（OPEN）：请求云同步支持不同设备间会话同步。
- [#7835](https://github.com/farion1231/cc-switch/issues/7835)（OPEN）：请求云同步自定义路径，覆盖 `~/.claude` 下任意目录/文件。
- [#8188](https://github.com/farion1231/cc-switch/issues/8188)（OPEN）：请求备份到远程数据库，说明当前备份仍主要面向本地/文件型云同步。

已修复/改进：

- v3.12.0 为 WebDAV 引入 dual-layer versioning；v4.0.12 修复 Skills 恢复的 staging/rollback；v4.0.15 修复 WebDAV/S3 慢速传输 300 秒被掐断。
- 数据库迁移前自动备份已经是 release 明确承诺。

### 4.4 权限 / 安全 / ACL

- [#8353](https://github.com/farion1231/cc-switch/issues/8353)（OPEN，security）：标题称 Windows 未收紧 ACL，`~/.cc-switch` 与 `cc-switch.db` 对继承组可读/可改，且与 #3265 的 “Windows is not affected” 结论不符。由于 8 次 `gh` 调用上限，本次没有取得该 issue 正文和 #3265 详情，只能确认当前标题/状态，不能核实复现结论。
- [v3.19.0](https://github.com/farion1231/cc-switch/releases/tag/v3.19.0) 做了集中安全加固：Skill 安装、`ccswitch://` 导入确认、SQL 备份导入、通用配置合并、终端启动收紧；并披露 Gemini 通用配置密钥泄漏已修复、升级后自动清洗但要求轮换密钥；MCP 深链确认框此前可能显示不出将写入的命令。
- [#8843](https://github.com/farion1231/cc-switch/issues/8843)（OPEN）：Codex MCP 同步仍写入 `timeout` / `autoApprove`，触发未知配置警告；`codex app-server --strict-config` 会失败。维护者确认是通用 JSON→TOML 透传导致，修复会只从 Codex 写路径剔除这两个字段，但不自动换算 timeout 单位。
- [#8882](https://github.com/farion1231/cc-switch/issues/8882)（OPEN）：UI 允许给 Codex 添加 SSE MCP，但 Codex 实际不支持 SSE/只按 HTTP 生效，缺少提示。

### 4.5 模型供应商 / API 兼容

这是最大议题簇，典型模式是协议转换、模型目录、OAuth/订阅账号、额度查询与客户端版本变化：

- OPEN：[#8890](https://github.com/farion1231/cc-switch/issues/8890) 旧对话找不到 `cc-switch-official` provider；[#8888](https://github.com/farion1231/cc-switch/issues/8888) Claude Desktop 经 Codex 路由 502；[#8728](https://github.com/farion1231/cc-switch/issues/8728) Codex 聚合模式官方模型显示不完全；[#8760](https://github.com/farion1231/cc-switch/issues/8760) OpenCode Go Responses 延迟高、Chat Completions 缓存命中率低；[#8749](https://github.com/farion1231/cc-switch/issues/8749) 非接管切换保留官方登录时 remote 请求仍走官方并报错。
- CLOSED：[#8832](https://github.com/farion1231/cc-switch/issues/8832) 供应商已切换但实际模型残留；[#8746](https://github.com/farion1231/cc-switch/issues/8746) 请求模型已改但实际请求仍错；[#8735](https://github.com/farion1231/cc-switch/issues/8735) 官方登录时 `model_provider=custom` 导致新版 Codex 官方功能消失。
- v4.0.16/v4.0.17 连续修复 Codex OAuth、Chat 工具历史 400、聚合会话压缩失败、重启后重新登录等问题；v4.0.20 修复 Pi 环境变量引用导致的用量查询 401、DeepSeek 余额显示、Kimi 子代理统计、Skills 429。
- 结论：供应商兼容不是边缘问题，而是主战场；每次新增工具/协议/模型目录都会带来新的回归面。

### 4.6 MCP

- OPEN：[#8560](https://github.com/farion1231/cc-switch/issues/8560) MCP 编辑器保存时删除显式空命令参数；[#8673](https://github.com/farion1231/cc-switch/issues/8673) 要求托管 MCP/Skills 完整性校验；[#8246](https://github.com/farion1231/cc-switch/issues/8246) 请求导入 VS Code user-level `mcp.json`；[#8566](https://github.com/farion1231/cc-switch/issues/8566) 请求发现未纳管本地 MCP 并保留平铺列表。
- [#8843](https://github.com/farion1231/cc-switch/issues/8843) 是典型“统一模型 vs 客户端专属 schema”问题：共享字段被无差别透传到 Codex。
- v4.0.17 修复同时勾选多个 MCP 服务器时部分丢失；v3.17 修复删除后复活。说明 MCP 同步已有多次数据完整性修复。

### 4.7 Skills

- OPEN：[#8000](https://github.com/farion1231/cc-switch/issues/8000) Pi 有额外技能扫描机制（settings 数组 / `~/.agents/skills`），CC Switch 未感知，导致状态失真与冗余投影；[#6559](https://github.com/farion1231/cc-switch/issues/6559) 要求安装前展示兼容要求；[#8673](https://github.com/farion1231/cc-switch/issues/8673) 要求完整性校验；[#7624](https://github.com/farion1231/cc-switch/issues/7624) 要求 Local Skills 云仓库；[#8651](https://github.com/farion1231/cc-switch/issues/8651) 请求外部所有权的本地原件以链接方式纳管而非复制导入。
- CLOSED：[#8813](https://github.com/farion1231/cc-switch/issues/8813) Skills 更新持续 HTTP 429，疑与 User-Agent 有关；v4.0.20 release 明确修复。
- v4.0.12 的云同步恢复修复说明 Skills 已被当作需要独立 staging/rollback 的文件树，而不是普通单文件配置。

## 5. 版本演进要点

1. 2025-08 v2.0.3：起点是 Claude Code 供应商切换工具。
2. v3.0.1：从 Electron 迁移到 Tauri 2，重做供应商编辑窗口。
3. v3.1.0：加入 Codex，并开始 v1→v2 迁移前备份。
4. v3.2.0：SSOT、统一 `config.json`、托盘、内置更新器、原子写入/回滚。见 [v3.2.0](https://github.com/farion1231/cc-switch/releases/tag/v3.2.0)。
5. v3.5.0：MCP 管理、配置导入导出、导入前备份和 10 份轮转备份。见 [v3.5.0](https://github.com/farion1231/cc-switch/releases/tag/v3.5.0)。
6. v3.7.0：Gemini CLI 成为第三应用。见 [v3.7.0](https://github.com/farion1231/cc-switch/releases/tag/v3.7.0)。
7. v3.8.0：SQLite + JSON 双层持久化，为云同步奠基。见 [v3.8.0](https://github.com/farion1231/cc-switch/releases/tag/v3.8.0)。
8. v3.9.0：本地 API proxy、自动 failover、universal provider。见 [v3.9.0](https://github.com/farion1231/cc-switch/releases/tag/v3.9.0)。
9. v3.10.0-v3.20.0：快速扩展 OpenCode、OpenClaw、Hermes、Claude Desktop、Grok Build、Pi；加入 Session Manager、Backup Management、项目切换、模型定价、账号中心。见 [v3.10.0](https://github.com/farion1231/cc-switch/releases/tag/v3.10.0)、[v3.11.0](https://github.com/farion1231/cc-switch/releases/tag/v3.11.0)、[v3.14.0](https://github.com/farion1231/cc-switch/releases/tag/v3.14.0)、[v3.15.0](https://github.com/farion1231/cc-switch/releases/tag/v3.15.0)、[v3.18.0](https://github.com/farion1231/cc-switch/releases/tag/v3.18.0)、[v3.20.0](https://github.com/farion1231/cc-switch/releases/tag/v3.20.0)。
10. v3.19.0：安全加固和密钥泄漏修复。见 [v3.19.0](https://github.com/farion1231/cc-switch/releases/tag/v3.19.0)。
11. v4.0.0：规模最大更新；新 UI、聚合模式、会话重写、配置写入从整文件重写改为关键字段替换。见 [v4.0.0](https://github.com/farion1231/cc-switch/releases/tag/v4.0.0)。
12. v4.0.18-v4.0.20：三天内连续加入 Antigravity、Kimi Code、Oh My Pi，并连续升级数据库 schema（20→23），每次迁移前自动备份。见 [v4.0.18](https://github.com/farion1231/cc-switch/releases/tag/v4.0.18)、[v4.0.19](https://github.com/farion1231/cc-switch/releases/tag/v4.0.19)、[v4.0.20](https://github.com/farion1231/cc-switch/releases/tag/v4.0.20)。

## 6. 已修复 vs 仍存在

### 已修复/显著改进

- 整文件快照重写导致的用户自有配置丢失 → v4.0 关键字段替换、外部改动检查、首次写前备份。
- v1/v2/JSON→SQLite 迁移风险 → 迁移前备份、schema migration、事务。
- Windows settings 覆盖/尾部残留导致默认值回写 → v4.0.15 临时文件替换和 broken backup。
- 云同步 Skills 恢复失败后不可恢复 → v4.0.12 staging、整体替换、失败保留原副本。
- Gemini 通用配置密钥泄漏、深链导入确认不足 → v3.19.0 安全加固。
- 多个具体模型/OAuth/MCP 回归 → v3.17、v4.0.15-4.0.20 持续修补。

### 仍存在/截至快照仍未关闭

- 字段白名单不完整：`http_headers` 丢失、Gemini `export .env` key 丢失、OpenCode 条目静默覆盖。
- WebDAV/S3 多设备同步一致性：未同步、旧配置反向覆写、会话同步范围不足。
- Windows ACL/数据库文件权限争议：#8353 尚 OPEN，需更高优先级核实。
- MCP per-tool schema 差异：Codex 不识别字段仍被写入、SSE 支持提示不足、空参数保存丢失、托管完整性检查缺失。
- Skills 与外部工具的扫描/所有权模型不一致：状态失真、兼容提示、完整性校验、外部原件纳管仍是 feature/bug。
- 供应商/API 兼容持续长尾：模型残留、官方模型目录、OAuth、代理格式转换、订阅账号与额度查询。
- 快速扩展 13 个工具 + 每日 release + 高频 schema migration，使回归风险结构性偏高。

## 7. 不确定性与证据限制

1. GraphQL 只取最近 100 条 issues 和 commits；5,916 个 issues / 3,275 个 commits 的全历史分布无法完整聚类。
2. 未取得全仓库 issues 的 open/closed 总分母；只能给出最近 100 条的 54 open / 46 closed。
3. 关键词 search 返回的是全文命中数且高度重叠，不能当严重级别或独立分类。
4. 重量级搜索触发 GraphQL resource limits，节点为空；轻量搜索可靠返回每路前 15 条与总命中数，但没有逐条取回所有正文。
5. #8353、#8502、#8605、#8560、#8673、#8000 等只从 search/标题或最近 issue 元数据确认状态，未能逐条取回完整正文；引用时以标题和链接为限。
6. tarball 下载超时，只得到 4.6 MB 部分文件且未解包；存储/模块结论主要来自 README、manifest、Git tree 路径和 release 说明，未审计实现代码。
7. “自动备份/外部改动检查”的行为是否在所有路径成立，需要代码级审计和本机复现；本报告只确认文档承诺、模块存在与相关 release 修复。
8. 仓库规模增长极快，本次快照截至 v4.0.20 / 2026-10-26；后续 release 可能已修复部分 OPEN issue。
