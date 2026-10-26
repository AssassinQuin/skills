# 2026-10-23 Skills / MCP 优化审计

## 结论

最大问题不是顶层 24 个 skill 太多，而是两个外部 skill 仓库被放在全局扫描目录下，导致递归扫描出 98 个 `SKILL.md`。其中 74 个是嵌套 manifest，约 4.6k tokens 的 description 常驻路由上下文；同时 17 个小说骨架顶层 skill 与 `cangjie-skill/books/novel-skeleton/` 完全重复。

MCP 的最大开销集中在 GitHub、Playwright、Memory、Codebase Memory 这类大 schema server。当前还有两个疑似无产出 server：`zai-mcp-server` 与 `zread`。

## 执行结果（2026-10-23）

已执行：

1. `cangjie-skill` 与 `huashu-nuwa` 完整上游已移动到 `/Users/ganjie/skill-vendors/`；对照 Git HEAD 校验，443 + 159 个 tracked 文件均无漂移。
2. 本 repo 仅保留 `cangjie-skill` 最小 wrapper，指向 vendor 绝对路径；`huashu-nuwa` 暂不启用。
3. 删除 `portfolio-rebalance` 与 `.playwright-mcp/` 运行痕迹。
4. Codex 与 Claude 配置均移除 `zai-mcp-server`、`zread`。
5. `websearch-cn` 升级为统一中英文 Open Websearch server；外文 lane 使用 Bing 优先，DuckDuckGo/Brave fallback。
6. `deep-research` 移除已不存在的 `websearch-global` / `zhihu-global` 首选路由：`glb` 走统一 Open Websearch，`zhihu` 走 `zhihu-search` CLI，Sogou 作为 fallback。
7. `gh` 已改用 macOS keyring 认证；新增 `deep-research/scripts/github-search.sh`，GitHub lane 迁移到 gh CLI，Codex/Claude 均移除 GitHub MCP。
8. README 与 MCP inventory 已更新。

验证结果：

- Active `SKILL.md`：98 → 22
- 常驻 description：约 6.1k tokens → 约 1.37k tokens
- `scripts/deploy.sh`：部署健康
- `deep-research` 3 组测试：22/22 通过
- Open Websearch Bing 外文搜索：可用，返回 2 条结果
- `zhihu-search` CLI：可用，返回 3 条知乎结果
- `gh auth status` 与 `gh api user` 验证通过；`github-search.sh` repos / issues / code 三类搜索均返回 2 条结果

## 后续执行补充（2026-10-23）

- GitHub MCP 已从 Codex / Claude 配置移除。
- `deep-research` GitHub lane 已改为 `gh` CLI：repos / issues / code 三类搜索。
- 当前用户配置 MCP：8 个。

## 事实快照

### Skills

- 当前可被扫描到的 `SKILL.md`：98 个
  - 顶层 skill：24 个
  - 嵌套在外部仓库内：74 个
- description 总量：24,510 chars（约 6.1k tokens）
  - 顶层：5,949 chars（约 1.5k tokens）
  - 嵌套：18,561 chars（约 4.6k tokens）
- `cangjie-skill` 内含 60 个 `SKILL.md`，其中 17 个与顶层小说骨架 skill 完全相同
- `huashu-nuwa/examples` 内含 15 个 perspective skill
- `ledger.sh` 结果：
  - 24 个顶层 skill，body 按需约 43,774 tokens，description 常驻约 1,470 tokens
  - ZOMBIE：4 个：`portfolio-rebalance`、`global-search`、`zhihu-search`、`huashu-nuwa`
  - 触发失败嫌疑：12 个（多为 2026-08-26 安装的小说骨架子 skill，至 2026-10-23 为 58 天，尚未过 60 天线）
  - 超 5k 建议：`huashu-nuwa`（外部上游，按仓库红线不做本地瘦身）

### MCP

当前用户配置 11 个 enabled MCP，另有 App 基础设施 `cua_repl` / `node_repl`；`codex_app` 为 disabled：

- 保留价值高：`codebase-memory-mcp`、`context7`、`memory`、`web-search-prime`、`web-reader`
- Deep Research 依赖：`websearch-cn`、`github`
- 需验证后处理：`context-mode`、`playwright`
- 疑似无产出/重复：`zai-mcp-server`、`zread`

### 已发现的功能性问题

`deep-research/scripts/route-lane.sh` 仍引用当前不存在的：

- `mcp__websearch-global__search`
- `mcp__zhihu-global__global_search`

这意味着 `glb` 与 `zhihu` lane 的首选路由已经漂移，实际只能靠 fallback 或 CLI。

## 建议分级

### P0：低风险立刻做

1. **把外部上游仓库移出全局 skill 扫描根**
   - 将 `cangjie-skill/` 与 `huashu-nuwa/` 的完整上游源码移到如 `/Users/ganjie/skill-vendors/`，不要放在 `~/.claude/skills` 指向的 `/Users/ganjie/skills` 内。
   - 顶层保留实际要用的入口 skill 与已摘出的小说骨架 skill。
   - 预期效果：98 个 active manifest 降到 24 个，节省约 4.6k tokens 常驻 description，并消除 17 个完全重复的小说 skill。
   - 注意：这是移动/归档，不是修改外部上游；符合“外部 skill 不做本地修改”的红线。

2. **删除顶层 `portfolio-rebalance`**
   - 102 天 0 使用，无其它 skill 依赖。

3. **清理 `.playwright-mcp/` 运行痕迹**
   - 316KB，全部是 2026-09-04 的 page/console 输出；只影响磁盘，不影响上下文。

4. **移除 MCP：`zai-mcp-server`、`zread`**
   - 当前工具列表中没有暴露可用 namespace，且与 BigModel 的 `web-search-prime` / `web-reader` / Playwright 重叠。

### P1：结构性优化

1. **将 GitHub MCP 改为按需使用 `gh` CLI**
   - GitHub MCP schema 最大，且 PAT 长期放配置里。
   - 删除或禁用前先改 `deep-research` 的 GitHub lane，使其优先走 `gh search repo` / `gh search issues` / `gh api`。
   - 这是 MCP 侧预期收益最大的单项。

2. **保留 `websearch-cn` 直到 deep-research 路由修复**
   - `cn` lane 和 `zhihu` fallback 依赖它。
   - 之后可测试 `web-search-prime` 对中文事实检索的覆盖率，再决定是否移除。

3. **修复 deep-research 路由漂移**
   - `glb` lane 可改为 `web-search-prime` + `global-search` CLI fallback。
   - `zhihu` lane 可改为 `websearch-cn` + `zhihu-search` CLI fallback，或恢复知乎 MCP 前先做限额测试。

4. **`huashu-nuwa` 归档而非本地瘦身**
   - 最后使用 2026-07-27，已过僵尸线。
   - 如果仍会创建人物 perspective skill，可保留入口；但必须把 `examples/` 移出扫描根。
   - `SKILL.md` 超 5k 属上游问题，不做本地修改。

### P2：观察后收敛

1. **小说骨架子 skill 到 2026-10-25 后复判**
   - 12 个 0 使用子 skill 目前 58 天，按既有判据还未过 60 天线。
   - 若届时仍 0 使用，可二选一：
     - 归档明显不需要的原子工序；
     - 更优：合并为单一 `novel-outline-pipeline` 入口，把 15 个原子 `SKILL.md` 改成 pipeline 的 references（不再作为独立 manifest 暴露）。

2. **Memory vs Context-mode 二选一或分层保留**
   - 两者不是完全等价：Memory 偏长期语义记忆，Context-mode 偏会话/ fetched content 索引。
   - 建议记录两周实际调用，再决定是否只保留一层。

3. **Playwright 改为按需启用**
   - App 内建 Browser / CUA 已覆盖多数页面控制场景。
   - 先禁用 Playwright 两周；遇到登录态、复杂渲染、自动化验证时再临时启用。

4. **插件去重**
   - `unified-computer-use` 已启用时，旧 `computer-use@openai-bundled` 可考虑禁用。
   - Office/PDF/template/visualization 插件若不常用于默认会话，也可改为按需启用。

## 保留清单（建议）

### Skills

- 继续保留：`deep-research`、`find-better-path`、`skill-stats`
- 暂保留但不新增入口：`global-search`、`zhihu-search`（deep-research fallback 依赖）
- 暂保留：`cangjie-skill`（如仍在拆书）、`novel-outline-pipeline` 及其子 skill（待 10-25 复判）
- 删除：`portfolio-rebalance`
- 归档：`huashu-nuwa`（若不再蒸馏人物 skill）

### MCP

- 基础保留：`codebase-memory-mcp`、`context7`、`memory`、`web-search-prime`、`web-reader`
- 暂保留：`websearch-cn`、`github`（等 deep-research 改造）
- 暂保留观察：`context-mode`
- 按需：`playwright`
- 移除：`zai-mcp-server`、`zread`
- 不要动：`cua_repl`、`node_repl`（App 基础设施）
