# cc-switch 与 Skill / MCP / 配置管理方案调研报告

日期：2026-10-26  
模式：deep（仓库 + Issue/Release + 社区 + 本机只读审计）  
对象：`farion1231/cc-switch`，本机 CC Switch v4.0.4，Claude Code / Codex / Trae / `/Users/ganjie/skills`

## 摘要

**结论：不要把 cc-switch 当成唯一的 All-in-One SSOT；保留它作为 provider/proxy/用量的控制面，把 Skills 交给 Git 仓库，把 MCP 做成“一份脱敏 inventory + 生成器/审计器”，Trae 在官方支持合入前走独立 adapter。**

理由有四点：

1. cc-switch 的真实强项已被社区和本机使用证实：**供应商/模型切换、少手改 JSON、桌面 GUI、本地代理、用量统计**。
2. 它的 MCP/Skills 抽象仍在快速演进：同名字段会被 CC Switch 覆盖、各客户端专属 schema 有落差、Trae 尚未正式支持、历史上确实出现过配置字段丢失和云同步不一致。
3. 你的本机现状已经不是“cc-switch 统一管理”，而是三套源头并存：CC Switch SQLite 一套、`/Users/ganjie/skills` Git/symlink 一套、Claude/Codex/Trae live config 一套。
4. Skills 的正确治理需要代码审查、历史、回滚、用量账本，这天然是 Git 的优势；SQLite 二进制库不适合作为日常 diff/review 的实体源。

### 一句话推荐

**混合架构，而不是替换：**

```text
Provider / Proxy / Usage  -> cc-switch 继续管，但先备份、升级、收敛权限
Skills                    -> /Users/ganjie/skills 是唯一 Active Catalog，Git 审核后 symlink 分发
MCP                       -> 一份脱敏 inventory/manifest 作为设计源，生成 Claude/Codex/Trae adapter
Trae                      -> 暂用生成器，不等待也不依赖未合并的官方支持
Backup                    -> Git 远端 + 加密 SQLite/config 快照 + 定期恢复演练
```

## 1. cc-switch 仓库与项目定位

### 1.1 项目能力

cc-switch 已从供应商切换器扩展为多工具管理平台，README 宣称覆盖 Claude Code、Claude Desktop、Codex、Gemini CLI、Grok Build、OpenCode、OpenClaw、Hermes、Pi、MiniMax Code、Kimi Code、Oh My Pi 等工具，并统一管理 provider、MCP、Skills、Prompts、会话与用量。[S1]

技术栈为 Tauri 2 + Rust + React 18/TypeScript + SQLite；这使其能做本地代理、协议转换、请求日志与用量统计，但也意味着配置管理不再只是“写几个 JSON 文件”。[S2]

### 1.2 数据与备份模型

官方 FAQ 说明主数据存放在 `~/.cc-switch/cc-switch.db`（SQLite），包括 providers、MCP、prompts、Skills、projects、usage；`settings.json`、`live-state.json`、OAuth 凭据、日志和 live-first-write 原始配置属于设备侧。默认数据库每 24 小时备份一次，保留 10 份；Skills 卸载/更新有独立备份；首次改写工具配置前保存原文件。[S2]

官方 MCP 文档进一步明确了关键覆盖规则：**CC Switch 只管理数据库里存在的 server；各工具配置里未导入的手动 server 不会被改动；但与 CC Switch 同名的条目会被覆盖，以 CC Switch 数据库为准。**[S3]

这对你的环境非常重要：如果我们手工把 Codex 的 MCP 同步到 Claude，而 Claude 里同名字节又存在于 CC Switch 数据库，下次 CC Switch 同步时可能会把这部分改回旧配置。

### 1.3 维护活跃度

调研时 GitHub API 显示：约 148,740 stars、9,784 forks、609 issues、MIT License、Rust 主语言；默认分支约 3,275 commits，当天仍有 push。最近 100 个 issues 集中在 2026-10-22 至 10-26，其中 54 open / 46 closed；最近 100 commits 分布在 4 个自然日，owner 贡献 84/100。[S1][S8]

解读：

- 正面：不是弃坑项目，反馈响应和 release 节奏很快。
- 反面：版本和 schema 变化极快，且提交高度集中；对这种工具应采用“备份后升级、观察一版再跟进”的策略，而不是自动追新。

## 2. Issue 与风险画像

### 2.1 历史配置丢失问题已重大修复，但白名单仍有遗漏

v4.0.0 之前的重大问题是：切换 provider 时用整份快照重写配置，可能覆盖 hooks、插件、权限、MCP 等无关内容。v4.0.0 改为关键字段替换，并加入外部改动检查和首次写前备份。[S6]

但 v4.0.x 仍有字段抽象遗漏：

- #8797：Codex 路由/聚合场景丢失 `http_headers`。[S11]
- #8861：Gemini `.env` key 导入/切回默认时被删除。[S12]
- #8780：OpenCode 条目可能被静默覆盖。[S13]
- #8843：Codex 不支持的 `timeout` / `autoApprove` 被统一抽象透传，导致 strict config 失败。[S16]
- #8560：MCP 编辑器保存时移除显式空 command arguments。[S10]

这说明“跨工具统一 MCP schema”仍是高风险区，不适合把未审计的 live config 全部交给它自动治理。

### 2.2 云同步与多设备一致性仍有未闭环问题

相关 issue 包括：

- #8502：WebDAV 未写回 Pi `models.json`，本地旧配置反向覆写。[S14]
- #8019：多设备 WebDAV 同步未成功。[S15]
- #8783：SQL import 显示成功但后置同步失败。[S17]

v4.0.12 修复了 Skills 云恢复失败后的恢复问题，说明备份/恢复路径在补齐，但多设备场景仍应先做单机恢复演练，不应默认云同步等于可靠备份。[S7]

### 2.3 安全与权限

#8353 提出 `~/.cc-switch` 与数据库的继承组权限问题；历史 v3.19.0 曾披露并修复 Gemini 通用配置密钥泄漏，并要求轮换密钥。[S18][S19]

本机审计也发现同类问题：`cc-switch.db` 为 `0644`，早期若干备份也为 `0644`，备份目录 `0755`。数据库中含 provider、MCP header/env、请求日志、session 同步状态等敏感信息，应立即收紧到 `0600/0700`，并做加密远端备份。

### 2.4 Skills / MCP 完整性边界

维护者在 #8673 中说明：

- installed Skills 在安装时有 SHA-256 内容 hash，检查更新时与远端比较；
- MCP 只存启动配置，不启动/连接 server，因此看不到工具合约变化。[S9]

这是合理边界，但也意味着 CC Switch 当前不是完整的 MCP 供应链审计器。MCP tool schema 变化、危险工具、许可/来源变化仍需要外部审计器。

## 3. 用户使用情况与社区反馈

可辨认的一手/讨论参与者约 15–20 人，样本偏早期采用者，不是随机稳定性调查；但方向一致性较强。[S20]

### 3.1 最强真实场景：provider / 模型切换

社区反复出现的使用方式是：

- Claude Code 接 Minimax M2、Copilot API、DeepSeek、阿里云百炼等；
- 用户希望在多个 base URL / API key / 模型间切换；
- GUI 和托盘降低了新手门槛。

Linux.do、HN、Reddit、CSDN 均有实际使用或教程证据。[S20]

### 3.2 正面体验

- “少手改 JSON/env、图形化一键切换”是共识；
- 对新手尤其有价值；
- 衍生 CLI/fork 反证其核心价值，同时暴露远程场景短板。[S20]

### 3.3 负面体验

- 远程 SSH / 容器 / server 场景 GUI 不便；
- “切换不生效”常见原因是 shell 环境变量覆盖配置，例如 `ANTHROPIC_API_KEY` / `ANTHROPIC_BASE_URL`；
- 多协议、上游模型命名、本地代理叠加后，归因复杂；
- 官方 Codex / OAuth 登录态存在真实故障讨论；
- 配置隔离与多进程并发曾被用户视为不足。[S20]

### 3.4 MCP / Skills 使用证据弱于 provider 切换

社区对 MCP/Skills/Prompts 的描述多来自教程、推广或功能介绍；深度长期使用样本不足。对你来说，这部分不能只看 README 宣传，应按“小范围试点 + 审计”推进。

## 4. 本机现状诊断

本机审计是只读的，未改动配置。[S21]

### 4.1 CC Switch 状态

当前安装 CC Switch v4.0.4，调研时最新 release 为 v4.0.20；本机 SQLite `user_version=20`，`integrity_check=ok`。数据库大致包含：

- providers：8
- skills：30
- mcp_servers：9
- prompts：1
- model_pricing：231
- proxy_request_logs：约 5,336
- usage_daily_rollups：426
- session_log_sync：4,193

设置显示 Skills 主副本位置为 `cc_switch`、同步方式 `auto`，但 `~/.cc-switch/skills` 为空；实际 Claude/Codex/OpenCode 的 skills 入口又 symlink 到 `/Users/ganjie/skills`。这说明 CC Switch 的 skill 目录设计与真实部署链路已经分叉。

### 4.2 Skills 双轨

`/Users/ganjie/skills` 是现有架构文档指定的 Active Catalog，`~/.claude/skills`、`~/.codex/skills`、`~/.agents/skills` 都指向它；但：

- Git 工作区有 15 个修改、444 个删除、10 个未跟踪状态项（展开 71 个未跟踪文件）；
- diff 为 459 files changed / 55,946 deletions；
- `deploy.sh` 当前失败，因为 `mcp-replacement-audit/` 不是 skill 却缺少 `SKILL.md`；
- `ledger.sh` 识别 24 个全局 skill，其中 19 个被判为 ZOMBIE；
- CC Switch DB 的 30 个 skills 与 repo 顶层 24 个 skills 仅重合 1 个（`huashu-nuwa`）。

这是当前最高优先级：**Active Catalog 本身还没有一个干净、可回滚的 Git 恢复点。**

### 4.3 MCP 三套状态

当前大致状态：

- Codex live config：8 个 MCP（含 ChatGPT/Codex 宿主专用 `node_repl`，可迁移项 7 个）；
- Claude live config：7 个可迁移 MCP；
- Trae live config：7 个可迁移 MCP；
- CC Switch DB：9 个另一套 MCP 目录，且 `enabled_codex=0`。

CC Switch DB 中的 `context-mode`、`context7`、`web-reader`、`web-search-prime` 与 live config 同名；按官方文档规则，这些同名字段以后可能被 DB 版本覆盖。[S3]

### 4.4 Trae 支持状态

#8868 维护者回复说明：TRAE CLI 支持 PR #8759 正在处理；TRAE Work 尚无对应 PR。[S22]  
#8007 仍是 open feature request；PR #8759 为 open、91 files changed、review required、mergeable=CONFLICTING。[S23][S24]

因此短期不应把“CC Switch 将支持 Trae”当作已成立能力。Trae 应继续走独立 adapter，等官方支持合入并稳定后再切换。

## 5. 方案比较

| 方案 | 优点 | 缺点 | 适用边界 |
|---|---|---|---|
| cc-switch 全管 | GUI、provider 切换强、备份/用量/代理内建 | SQLite 不适合 review；MCP/Skills 抽象仍有 bug；Trae 未正式支持；云同步未完全闭环 | 适合 provider/proxy/用量，不适合作为 Skills 实体源 |
| CC Switch + Git skills + MCP generator | 各层用最合适工具；可审计；Trae 可先落地 | 需要维护少量脚本和规则 | 当前环境最合适 |
| 纯 dotfiles/GitOps | 历史清晰、可 review、跨机器 | 无 GUI、无健康检查、密钥处理要自建；provider 切换体验差 | 配置可全部声明式且不需要动态切换时 |
| Claude MCP Selector | 强在按会话减少 MCP 上下文浪费、Claude 侧 server toggle | Claude 生态为主，不解决定义源和跨客户端转换 | 作为 Claude MCP 按需启停工具，而非 SSOT |
| cc-switch-web / CLI fork | 补远程/headless 场景 | fork/版本滞后、安全边界需自审 | 服务器或无 GUI 环境试点 |
| 各工具原生项目级配置 | 爆炸半径最小 | 无统一 inventory，容易漂移 | 项目专属敏感配置 |

### 5.1 原生项目配置的关键事实

跨客户端方案还应利用各工具的原生 project scope，避免把所有东西都塞进用户级全局配置：[S27]

- Claude：项目 MCP 放 repo 根 `.mcp.json`，首次使用需批准；项目 skills 放 `.claude/skills/`；Claude MCP Selector 可在这个层面做按任务启停和 context report。[S25]
- Codex：项目覆盖可用 `.codex/config.toml`，但 provider/auth 这类安全字段应留在 user level；skills 从 `.agents/skills` 向上扫描，并可限制 skills catalog 初始 token。
- Trae：项目 MCP 是 `.trae/mcp.json`，项目 skills 是 `.trae/skills/`，也识别 `.agents/skills`，同名时 `.trae/skills/` 优先；确认 secret 引用机制前，带 token 的项目配置不能进 Git。

因此，全局层管“常用能力”，项目层管“这个 repo 需要的最小 MCP/skills”，这是降低上下文膨胀和爆炸半径的最低成本方式。

## 6. 推荐架构

### 6.1 数据流

```text
┌────────────────────────────┐
│ Provider / Proxy / Usage    │
│ Source: ~/.cc-switch/db     │
│ RULE: 只经 CC Switch UI 改  │
└──────────────┬─────────────┘
               ↓
    Claude / Codex live config
    （Trae provider 等官方支持后接入）


┌────────────────────────────┐
│ Skills Active Catalog       │
│ Source: /Users/ganjie/skills│
│ RULE: Git commit/tag 后部署 │
└──────────────┬─────────────┘
               ↓
  ~/.claude/skills  symlink
  ~/.codex/skills   symlink
  ~/.agents/skills  symlink
  Trae skills       generated mirror / wrappers


┌────────────────────────────┐
│ MCP Inventory               │
│ Source: mcp.inventory.json  │
│ RULE: 脱敏、可 diff、有版本 │
└──────────────┬─────────────┘
               ↓
  Generator / reconciler
  -> Claude JSON
  -> Codex TOML
  -> Trae JSON
  -> CC Switch DB（只通过 UI/import，不直写）
```

### 6.2 为什么 Skills 不交给 CC Switch

Skills 是“能力代码”，需要：

- review 历史和 rollback；
- frontmatter / trigger / token 账本审计；
- 僵尸清理；
- 上游 vendor 与 active wrapper 分离；
- 多机器同步。

这些是 Git 与脚本的优势。CC Switch 的 marketplace 和安装功能可以当“候选入口”，但外部 skill 应先进 `/Users/ganjie/skill-vendors`，审计后再在 Active Catalog 建 wrapper。

### 6.3 为什么 MCP 需要 manifest

MCP 定义是跨客户端的“部署代码”，但各客户端 schema 不同：

- Codex TOML 使用 `http_headers`；
- Claude/Trae JSON 常用 `headers`；
- 某些客户端有 timeout、autoApprove、disabled 等专属字段；
- HTTP/stdio/env/header 需要脱敏。

因此应维护一份规范化的 `mcp.inventory.json`：

- 不含 token；
- 每项包含 name、transport、capability、owner、enabled_by_default、risk、credential_ref；
- 生成器负责字段转换；
- 审计器比较 generated 与 live config；
- CC Switch 中同名的 MCP 要么以该 inventory 导入并唯一化，要么关闭 CC Switch MCP 管理，避免双写。

### 6.4 Provider 为什么继续用 CC Switch

Provider 配置包含 key、OAuth、模型名、协议转换、代理、健康状态和用量，动态性强，GUI 有真实价值。你的本机也在实际使用：Claude/Codex current provider 均为 Zhipu GLM，live mode 为 direct。

但需要加约束：

- 不要手改 CC Switch 管理的 provider 字段；
- 每次切换前后保留 live config 快照；
- 对 `ANTHROPIC_*` / provider 环境变量做冲突检查；
- 升级前完整备份 `~/.cc-switch`；
- 输出一份脱敏 provider manifest 进 Git，用于恢复顺序和审计。

## 7. 分阶段落地计划

### Phase 0：先停止扩大漂移（P0，立即）

1. 暂停继续手改 Claude/Codex/Trae 的 MCP 配置。
2. 退出 CC Switch 前先做完整快照：
   - `~/.cc-switch/cc-switch.db`
   - `settings.json`
   - `live-state.json`
   - `backups/`
   - Claude/Codex/Trae live config
3. 收紧权限：
   - `~/.cc-switch`：`0700`
   - DB、备份、settings、OAuth 文件：`0600`
   - 备份目录：`0700`
4. 不升级、不清数据库，先完成备份与权限修复。

### Phase 1：修复 Skills Git 恢复点（P0）

1. 审计 444 个删除是否全部符合“上游移入 vendor pool”的既定设计。
2. 三选一：
   - 如果删除是设计结果：确认后 commit；
   - 如果不确定：先建 reconciliation branch，不混入新功能；
   - 如果误删：从 Git/vendor pool 恢复。
3. 将 `mcp-replacement-audit/` 等研究报告移到 `reports/` 或在 `deploy.sh` 中声明为非 skill 目录。
4. 修复 `deploy.sh`：
   - 支持 Claude/Codex/OpenCode symlink；
   - 支持 Trae mirror；
   - 对非 skill 目录使用 manifest/allowlist；
   - secret scan；
   - exit code 必须真实反映健康度。
5. push 到远端并打 tag。

### Phase 2：收敛 CC Switch（P1）

1. 备份后升级 CC Switch v4.0.4 → v4.0.20；先观察 release notes 中与 Codex/MCP/Skills/备份相关修复。
2. 打开应用后确认数据库迁移成功、provider 可切换、`live-state` 正常。
3. 导出 DB 中 providers/skills/MCP 的脱敏 inventory，只留元数据，不进 token。
4. 对 Skills 页面采取“冻结/只读”策略：不要用“立即重新同步”覆盖现有 symlink，先完成 DB 30 个 skills 与 repo 的映射表。
5. Provider 页面继续作为唯一 provider 编辑入口。

### Phase 3：MCP 单源化（P1）

1. 从当前 7 个可迁移 MCP（不含 `node_repl`）确定最终清单：
   - `codebase-memory-mcp`
   - `context-mode`
   - `context7`
   - `web-reader`
   - `web-search-prime`
   - `websearch-cn`
   - `mem0`
2. 为每个 server 写 owner/risk/credential_ref/schema notes。
3. 建 `mcp.inventory.json`，不含 secret。
4. 写 `scripts/sync-mcp.py`：
   - `--dry-run`
   - atomic write
   - pre/post diff
   - `--check`
   - 只改 MCP 相关键，不重写整份 Claude/Codex config
5. 与 CC Switch 达成唯一权：
   - 方案 A：把 inventory 导入 CC Switch，用 CC Switch 管 Claude/Codex，Trae 从导出生成；
   - 方案 B：关闭/清空 CC Switch MCP 管理，用 generator 管三端。
   - 不建议 A/B 混用。
6. 废除 CC Switch DB 中确认过期的 `github`、`memory`、`searxng`、`zai-mcp-server`、`zread` 等旧项，或标记 disabled/archived，避免下次覆盖。

### Phase 4：Trae adapter（P1）

1. 不依赖 PR #8759，先继续维护 Trae JSON generator。
2. Skills 若 Trae 当前不支持全局 symlink，就生成最小 wrapper/mirror。
3. 每次部署后：
   - JSON parse；
   - server 名称/transport/URL/command 对账；
   - 不含 secret；
   - 重启 Trae。
4. 等 CC Switch 官方 Trae 支持稳定后，再评估是否把 Trae 从 generator 切到 CC Switch。

### Phase 5：备份与恢复演练（P1）

备份策略：

- Skills：Git branch/tag + GitHub private remote。
- CC Switch：SQLite online backup 或退出后冷快照 + 配置快照。
- 远端备份：restic/rclone 加密到私有存储。
- Retention：建议 7 daily / 4 weekly / 6 monthly。
- 敏感文件：不进 Git；Git 中只放 credential_ref。

恢复演练：

1. 在临时目录恢复 SQLite；
2. `integrity_check`；
3. 导出 providers/MCP/skills 数量；
4. 恢复 Claude/Codex/Trae config；
5. `claude mcp list` / Codex MCP list / Trae JSON parse；
6. 记录 RTO 和步骤失败点。

## 8. 审计门禁

建议一个命令完成：

```text
scripts/audit-agent-stack.sh
```

检查项：

1. Git clean/tag/push 状态；
2. skills symlink 拓扑；
3. skill frontmatter、description、token、usage ledger；
4. MCP inventory 与 Claude/Codex/Trae live config 一致；
5. CC Switch DB 与 MCP inventory 的同名冲突；
6. `node_repl` 不被迁移；
7. JSON/TOML parse；
8. secret scan；
9. 权限检查；
10. 备份新鲜度和恢复演练报告；
11. MCP health check；
12. provider 环境变量冲突。

任何一项失败，禁止执行批量 sync。

## 9. 最强反驳

**反驳：cc-switch 维护活跃、内建备份和 GUI，为什么不干脆全交给它？**

这是最强替代方案。若你只在一台桌面机上使用、以 provider 切换为主、不需要 Trae、不介意 SQLite 作为源头，那么 cc-switch 全管是复杂度最低的方案。

但你的实际条件不满足：

- 你需要 Trae，官方支持未合并；
- 你已有 `/Users/ganjie/skills` 分层设计和 vendor pool；
- 你的 Skill 有用量、僵尸清理和 token 账本需求；
- 本机已出现 DB skills 与 repo skills 几乎不相交的漂移；
- MCP 专属 schema 字段丢失/透传问题仍在 issue 中出现。

因此，全交给 cc-switch 会降低短期操作成本，但会提高长期审计与回滚成本。混合架构的维护成本主要是一两个脚本，换来的是明确的权责边界。

## 10. 未解问题

1. 444 个 Git 删除是否全部符合“上游移入 vendor pool”的既定清理？
2. CC Switch DB 中 30 个 skills 哪些需要保留为候选、哪些直接废弃？
3. 你是否需要各客户端不同 skill 子集，还是统一 active set？
4. Trae 指的是 Trae CLI、Trae Desktop 还是 TRAE SOLO CN？当前官方 PR 针对 Trae CLI。
5. Provider credentials 是否必须留在 CC Switch DB，还是可以逐步迁移到 Keychain/env_ref？
6. 是否需要远程/headless 使用？如果需要，后续可评估 cc-switch CLI/web fork，但仍应保持同一 inventory。

## 11. 优先级排序

| 优先级 | 动作 | 原因 |
|---|---|---|
| P0 | 备份并收紧 `~/.cc-switch` 权限 | DB 含敏感配置且当前权限过宽 |
| P0 | 清理并提交 `/Users/ganjie/skills` | Active Catalog 目前没有可靠恢复点 |
| P1 | 停止 MCP 双写，确定 CC Switch or inventory 权威 | 避免同名字段被覆盖 |
| P1 | 升级 CC Switch 到 v4.0.20 | 当前 v4.0.4 落后多个修复，但必须备份后升级 |
| P1 | 建 MCP inventory + generator + audit | 跨 Claude/Codex/Trae 的可审计路径 |
| P2 | Skills 账本和僵尸清理 | 当前 19/24 被 ledger 判为 ZOMBIE |
| P2 | 远端加密备份和恢复演练 | 本地备份不等于可恢复 |

## 12. 最终建议

**继续使用 cc-switch，但缩小它的职责边界：**

- 用它管 provider、proxy、用量：是。
- 用它作为 Skills 唯一实体源：否。
- 用它直接管三端 MCP，尤其 Trae：暂不。
- 用它作为 MCP/Provider 的运行时之一，配合脱敏 manifest 和外部审计：是。

这样你可以保留 GUI 和 provider 切换的价值，同时不把不可 review 的 SQLite 变成所有配置的唯一事实源。

## 引用

- [S1 cc-switch README](https://github.com/farion1231/cc-switch)
- [S2 cc-switch README FAQ / data storage](https://github.com/farion1231/cc-switch#where-is-my-data-stored)
- [S3 MCP 用户手册](https://github.com/farion1231/cc-switch/blob/main/docs/user-manual/zh/3-extensions/3.1-mcp.md)
- [S4 Skills 用户手册](https://github.com/farion1231/cc-switch/blob/main/docs/user-manual/zh/3-extensions/3.3-skills.md)
- [S5 配置文件说明](https://github.com/farion1231/cc-switch/blob/main/docs/user-manual/zh/5-faq/5.1-config-files.md)
- [S6 v4.0.0 release](https://github.com/farion1231/cc-switch/releases/tag/v4.0.0)
- [S7 v4.0.12 release](https://github.com/farion1231/cc-switch/releases/tag/v4.0.12)
- [S8 v4.0.20 release](https://github.com/farion1231/cc-switch/releases/tag/v4.0.20)
- [S9 Issue #8673 managed MCP/Skills integrity](https://github.com/farion1231/cc-switch/issues/8673)
- [S10 Issue #8560 empty command arguments](https://github.com/farion1231/cc-switch/issues/8560)
- [S11 Issue #8797 Codex http_headers](https://github.com/farion1231/cc-switch/issues/8797)
- [S12 Issue #8861 Gemini env key](https://github.com/farion1231/cc-switch/issues/8861)
- [S13 Issue #8780 OpenCode overwrite](https://github.com/farion1231/cc-switch/issues/8780)
- [S14 Issue #8502 WebDAV Pi models.json](https://github.com/farion1231/cc-switch/issues/8502)
- [S15 Issue #8019 WebDAV multi-device](https://github.com/farion1231/cc-switch/issues/8019)
- [S16 Issue #8843 Codex unsupported MCP fields](https://github.com/farion1231/cc-switch/issues/8843)
- [S17 Issue #8783 SQL import post-sync failure](https://github.com/farion1231/cc-switch/issues/8783)
- [S18 Issue #8353 permissions](https://github.com/farion1231/cc-switch/issues/8353)
- [S19 v3.19.0 security release](https://github.com/farion1231/cc-switch/releases/tag/v3.19.0)
- [S20 社区反馈原始报告](/Users/ganjie/skills/reports/research/cc-switch-management-audit/raw/community-feedback.md)
- [S21 本机只读审计](/Users/ganjie/skills/reports/research/cc-switch-management-audit/raw/local-environment.md)
- [S22 Issue #8868 Trae/tool support discussion](https://github.com/farion1231/cc-switch/issues/8868)
- [S23 Issue #8007 Trae support request](https://github.com/farion1231/cc-switch/issues/8007)
- [S24 PR #8759 Trae CLI support](https://github.com/farion1231/cc-switch/pull/8759)

## Meta

- Requested Mode：deep
- Effective Mode：deep + parallel research + local audit
- lane 健康：github:ok / cn:ok / glb:ok / zhihu:partial（社区覆盖为主，未获得大规模统计样本）
- 降级记录：仓库 tarball 下载超时，未做完整源码树本地审计；Issue 关键词命中数有重叠，不能当 bug 数；对抗核实子代理超时，主会话完成独立复核（findings/schema/引用/secret scan 均通过）。
- 任务目录：`/Users/ganjie/skills/reports/research/cc-switch-management-audit`
