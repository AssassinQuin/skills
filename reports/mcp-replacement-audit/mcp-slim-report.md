# MCP 精简与 Token 优化报告

**日期**：2026-10-26
**现状**：11 个 MCP server + 2 内置组 = **118 个工具 schema 常驻上下文，估算 18-25K tokens/轮**

---

## 一、常驻 Token 账本（实测盘点）

| Server | 工具数 | 估算 tokens/轮 | 本会话使用 | 判定 |
|---|---|---|---|---|
| playwright | 25 | ~4,000 | 2 次（演示） | 🟡 按需启用 |
| codex_app（内置插件） | 30 | ~4,500 | 0 | 🟡 可禁（牺牲 app 集成） |
| codebase-memory-mcp | 17 | ~2,500 | **0（项目无索引）** | 🔴 **已禁用** |
| memory | 17 | ~2,500 | **0** | 🔴 **已禁用** |
| context-mode | 11 | ~1,600 | 1 次（审批失败） | 🟢 保留（省 token 工具本体） |
| websearch-cn | 6 | ~900 | 8 次（主力） | 🟢 保留 |
| multi_agent_v1（内置） | 5 | ~800 | 0 | 不可禁 |
| node_repl | 3 | ~500 | 0 | ⚠️ computer-use/browser 插件依赖，慎禁 |
| context7 | 2 | ~350 | 0（审计确认保留） | 🟢 保留 |
| web-reader | 1 | ~150 | 1 次 | 🟢 保留 |
| web-search-prime | 1 | ~150 | 4 次（主力） | 🟢 保留 |
| **合计** | **118** | **~18,000-25,000** | | |

---

## 二、已执行（零风险，可回滚）

**备份**：`~/.codex/config.toml.bak-20261026`

| 动作 | 省省 tokens/轮 | 理由 |
|---|---|---|
| 注释 `codebase-memory-mcp` | ~2,500 | skills 写作仓库无代码图需求，项目从未建索引 |
| 注释 `memory` | ~2,500 | 本会话零调用；审计已标记 Mem0 为升级候选，需要持久记忆时再换更好的 |

**小计：-34 工具，约 -5,000 tokens/轮（↓ ~25%）**
**回滚**：`cp ~/.codex/config.toml.bak-20261026 ~/.codex/config.toml`（重启 Codex 生效）

---

## 三、可选进一步（按你的取舍执行）

### 3.1 playwright 按需化（-25 工具，-4K tokens/轮）⭐ 最大单项
浏览器操控是间歇需求（上轮已论证搜索场景不用它）：
```bash
# 需要浏览器操作时临时启用（不改配置）：
codex --config mcp_servers.playwright.command=npx ...
# 或注释 config.toml 中 [mcp_servers.playwright] 段，用时取消注释
```
代价：需要时多一步手动操作。

### 3.2 codex-app-tools 插件（-30 工具，-4.5K tokens/轮）
`[plugins."codex-app-tools@openai-bundled"] enabled = false`
代价：失去 open_in_codex/thread 管理/worktree 集成/latex 工具。**建议保留**（app 深度集成价值 > 4.5K tokens）。

### 3.3 websearch-cn 工具过滤（-4 工具，-0.6K）
4 个专用 fetch（CSDN/掘金/LinuxDo/GitHubReadme）与 web-reader 功能重叠。config.toml 支持 per-tool 段（已有 approval_mode 先例）：
```toml
[mcp_servers.websearch-cn.tools.fetchCsdnArticle]
enabled = false
# 同理 fetchJuejinArticle / fetchLinuxDoArticle / fetchGithubReadme
```
代价：中文社区文章改用 web-reader 抓（需手动给 URL）。

### 3.4 Skills 目录清理（-15K+ tokens，独立大头）
本会话 skill 描述目录 ~200 条 ≈ 15-20K tokens，**比所有 MCP 加起来还大**。执行既有审计结论：98 → ≤30（Naval 系 19 个、perspective 系 15 个降维合并）。

---

## 四、使用习惯层省 token（不改配置）

| 技巧 | 说明 | 本会话实证 |
|---|---|---|
| **结构化提取** | browser_evaluate 只取需要的字段，不拉全页 snapshot | 演示时只取 5 条标题 |
| **snapshot 限深** | `depth`/`target` 参数替代全页快照 | — |
| **大输出入沙箱** | 输出>100 行的命令 → ctx_execute 处理，只回摘要 | 数据采集轮（15 仓库统计只回 20 行） |
| **结果写文件** | 报告写文件返回路径，不贴正文 | 全部调研报告均此模式 |
| **搜索限流** | limit=5 而非 10；摘要用 medium 不用 high | 全程 limit=5 |
| **避免重复工具** | 同一信息多通道查证 ≤3 源，超出即止损 | 搜索实测矩阵一次成型 |

---

## 五、执行后预估

| 状态 | 工具数 | 常驻 tokens |
|---|---|---|
| 优化前 | 118 | ~20-25K |
| **已执行（保守集）** | **84** | **~15-20K** |
| + playwright 按需 | 59 | ~11-16K |
| + skills 98→30 | 59 | **~0-4K（目录层）** |

**全部落地后每轮上下文开销约降 55-70%**，且按智谱缓存价（重复前缀 ~10% 价）实际账单影响放大 5-10 倍。
