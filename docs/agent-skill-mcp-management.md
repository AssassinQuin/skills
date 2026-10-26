# 多 Agent 的 Skill / MCP 管理模型

目标：同一套能力可以被 Claude Code、Codex 和后续 agent 复用，但避免每个 agent 各自复制、各自漂移、各自保存凭证。

## 推荐架构：三层分离

```text
/Users/ganjie/skills              Active catalog：真正暴露给全局 agent 的 SKILL.md
/Users/ganjie/skill-vendors       Vendor pool：外部上游完整源码，不进全局扫描
~/.codex / ~/.claude              Runtime adapters：各自配置、symlink、mirror；不在这里维护实体
```

### 1. Active catalog：`/Users/ganjie/skills`

只放四类文件：

1. 自建且当前启用的 skill
2. 外部上游的最小 wrapper
3. 管理脚本、审计报告、manifest
4. 运行数据（stats / datastore）

规则：

- 一个能力一个入口；不把上游仓库整棵树放进扫描根
- 不直接修改 `.agents` / runtime mirror；只修改本 repo，然后由部署入口消费
- 新增或移除 skill 后运行：
  ```bash
  bash scripts/deploy.sh
  bash scripts/ledger.sh
  ```
- 外部上游更新只替换 `/Users/ganjie/skill-vendors/<name>`，wrapper 继续指向绝对路径

### 2. Vendor pool：`/Users/ganjie/skill-vendors`

用于保留完整上游和可恢复能力，但不参与路由：

- `cangjie-skill/`：完整上游；本 repo 只暴露 wrapper
- `huashu-nuwa/`：暂不启用；需要时新建 wrapper，不复制整棵树

好处：

- 保留升级能力
- 避免 74+ 个嵌套 `SKILL.md` 常驻 agent 路由层
- 外部 skill 的瘦身 / 超 5K 问题交还给上游

### 3. Runtime adapters

Claude 通过 `~/.claude/skills -> /Users/ganjie/skills` 消费；Codex 使用自己的 runtime mirror。都不作为实体源编辑。

## 当前合理的 Skill 分层

| 层级 | Skill | 处理 |
|---|---|---|
| 管理层 | `skill-stats` | 保留 |
| 决策审查 | `find-better-path` | 保留 |
| 调研层 | `deep-research` | 保留；搜索路由已收敛 |
| 检索兜底 | `global-search`, `zhihu-search` | 保留为 deep-research / MCP fallback |
| 拆书入口 | `cangjie-skill` wrapper | 保留；实体在 vendor |
| 小说提纲 | `novel-outline-pipeline` + 原子工序 | 保留至 60 天复判；可再合并成一个 pipeline |
| 暂不启用 | `huashu-nuwa` | 留在 vendor，需要时恢复 wrapper |

## MCP 管理原则

原则：**CLI 优先、MCP 分层、凭证不进 Git、配置有唯一 inventory**。

### 当前默认 MCP

| Server | 层级 | 理由 |
|---|---|---|
| `context7` | 常驻 | 库文档检索，schema 小、价值稳定 |
| `memory` | 常驻 | 跨会话语义记忆 |
| `websearch-cn` | 常驻 | 中文/外文免费搜索统一入口 |
| `web-reader` | 常驻 | URL 正文读取 |
| `web-search-prime` | 调研增强 | 高价值搜索；注意成本与限额 |
| `codebase-memory-mcp` | 编码增强 | 代码图 / caller / dependency |
| `context-mode` | 观察期 | 会话上下文索引；与 memory 分工仍需使用数据验证 |
| `playwright` | 按需候选 | 登录态 / 复杂渲染 / 自动化验证 |

### 已移除

| Server / 能力 | 替代 |
|---|---|
| GitHub MCP | `gh` CLI + macOS keyring；deep-research 使用 `github-search.sh`（repos/issues/code 已验收） |
| `zai-mcp-server` | BigModel 其它 MCP + CLI |
| `zread` | `web-reader` / Playwright / gh |

### 能力路由

```text
库文档        → context7
普通网页搜索  → websearch-cn
高价值搜索    → web-search-prime
网页正文      → web-reader
知乎          → zhihu-search CLI → websearch-cn fallback
GitHub        → gh CLI
浏览器自动化  → Playwright / 内建 Browser（按需）
长期记忆      → mem0
代码结构      → codebase-memory-mcp
```

## 多 Agent 同步流程

### Skill 变更

1. 在 `/Users/ganjie/skills` 修改或新增
2. 更新 README / manifest / 审计报告
3. 跑：
   ```bash
   bash scripts/deploy.sh
   bash scripts/ledger.sh
   ```
4. 重启 Claude / Codex 会话，让 runtime mirror 重建

### MCP 变更（2026-10-26 起生效）

1. 只改 `config/mcp/inventory.json`；不要直接手改三端 MCP adapter。
2. 如新增 HTTP header，先在 inventory 写 `credential_ref`，再从 live config 引导本地 secrets：
   ```bash
   python scripts/sync_mcp.py --bootstrap-secrets
   ```
3. 比较和写入：
   ```bash
   python scripts/sync_mcp.py --check
   python scripts/sync_mcp.py --apply
   ```
4. CC Switch 的 MCP 同步开关保持关闭；它只负责 provider/proxy/usage。
5. Codex 宿主专属未管理项（如 `node_repl`）不会被 generator 删除。
6. 最后跑统一门禁：
   ```bash
   bash scripts/audit-agent-stack.sh
   ```

### 凭证

- GitHub：只用 gh keyring，不再保留 MCP PAT
- Context7/BigModel 的本地值在 `~/.config/agent-stack/mcp-secrets.json`，权限 0600，不入 Git
- inventory 只记录 `credential_ref`，绝不复制 token

## 判据

- Skill：60 天 0 使用进入复判；能合并成 pipeline 的不保留多个原子入口
- MCP：CLI 能可靠完成的能力不保留 MCP；schema 大且低频的 server 改按需
- 外部上游：不本地修改；只维护 wrapper
- 多 agent：Active catalog 唯一，runtime 只做 adapter
