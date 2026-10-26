# Git MCP 与搜索 MCP 开源方案调研报告

**日期**：2026-10-26
**数据来源**：GitHub API 实测（stars / open issues / 30d commits / release 时间 / Dockerfile 存在性）
**需求约束**：开源、活跃维护、优先 Docker 容器化（可按需启停）

---

## 一、总判断（先说结论）

| 需求 | 推荐 | 一句话理由 |
|---|---|---|
| GitHub 平台操作（issue/PR/repo） | **github/github-mcp-server** | 官方出品 34K★，v2.0.3（2026-10-21），官方 Docker 镜像，toolset 可裁剪 |
| 本地 git 仓库操作 | **mcp-server-git**（modelcontextprotocol/servers） | 官方参考实现，uvx 一行启动，根本不需要容器 |
| GitLab 自托管 | **zereight/gitlab-mcp** | 277 工具，30 天 100+ commits 全场最活跃，v2.3.11 |
| **搜索（Docker 自托管）** | **SearXNG + mcp-searxng** | 唯一 Docker 原生自托管搜索：无 API key、无配额、无月费，`compose down` 即关 |
| 搜索（API 质量补充） | Tavily（1000 免费/月）或 Exa（语义最强） | 托管 API，与 Docker 自托管互补 |
| 网页抓取增强 | firecrawl-mcp-server（可自托管全栈） | 搜索+抓取+爬站+map 一体 |

**"更好的搜索 MCP + docker 容器关了"的直接答案：SearXNG + mcp-searxng。**
这是候选中唯一"搜索引擎本体 + MCP 层"都能塞进容器、用完 `docker compose down` 就完全关闭的方案——无 key、无配额、无数据外泄，聚合 Google/Bing/DDG 等 70+ 引擎。

---

## 二、Git MCP 多维对比

### 2.1 数据总表（2026-10-26 实测）

| 仓库 | ★ | 月龄 | 月均★ | 增速评级 | open issues | issue/★ | 30d commits | 最近 push | 最近 release | License | Dockerfile |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **github/github-mcp-server** | 33,957 | 19.7m | 1,723 | S 级 | 405 | 1.19% | 40 | 10-23 | **v2.0.3 (10-21)** | MIT | ✅ 官方镜像 ghcr.io |
| modelcontextprotocol/servers (含 git) | 91,564 | 23.2m | 3,948 | S 级 | 151 | 0.16% | 100+ | 10-25 | v2.1.0 (10-25) | MIT 系 | Python/uvx 免容器 |
| idosal/git-mcp | 8,491 | 18.9m | 449 | A 级 | 84 | 0.99% | **0** | **05-08 停更 5 个月** | — | Apache-2.0 | ❌ |
| zereight/gitlab-mcp | 2,065 | 20.4m | 101 | B 级 | 10 | 0.48% | **100+** | 10-26（今天） | v2.3.11 (10-25) | MIT | ✅ |
| adhikasp/mcp-git-ingest | 314 | 22.3m | 14 | D 级 | 12 | 3.82% | 0 | **2025-01 停更** | — | MIT | — |
| cyanheads/git-mcp-server | 244 | 22.3m | 11 | C 级 | 18 | 7.38% | 0 | 09-26 | — | Apache-2.0 | ❌ |

### 2.2 逐项分析

**① github/github-mcp-server —— GitHub 场景明确首选**
- 官方出品，Go 编写，MIT。v2.0.3 于 2026-10-21 发布，30 天 40 commits，持续高质量维护
- **Docker 部署**：官方镜像 `ghcr.io/github/github-mcp-server`，一条 docker run 起 stdio，也支持 HTTP 远程模式；GitHub 还提供托管 remote server（`https://api.githubcopilot.com/mcp/`，OAuth 免管 token）
- **toolset 裁剪**：按 categories 启用（repos/issues/PR/actions/notifications 等），防止工具列表撑爆 context——这与你之前审计的"工具瘦身"原则一致
- issue 率 1.19% 健康偏上（体量大、用户多，正常）
- 注意：它是 **GitHub 平台 API 工具**，不做本地 `git add/commit/rebase` 这类操作

**② mcp-server-git（官方参考实现）—— 本地仓库操作**
- `modelcontextprotocol/servers` 的 `src/git` 子项目，Python，GitPython 封装
- 覆盖本地 git 全流程：status/log/show/diff/commit/branch 等
- **uvx mcp-server-git 一行启动**，无需 Docker——本地进程反而比容器更适合（要访问宿主机 git 仓库，容器还得挂载卷）
- 免维护成本：随官方 monorepo 发布（v2.1.0，10-25）

**③ idosal/git-mcp —— 注意：不是 git 操作工具，且已停更**
- 定位是"远程读取任意 GitHub 开源项目的文档/代码，防代码幻觉"（GitMCP.io），与你问的 git 操作 MCP 完全不同
- **2026-05-08 后 0 commits，停更 5 个月**——尽管 8.5K★ 也不建议作为基础设施依赖

**④ zereight/gitlab-mcp —— GitLab 自托管首选（如适用）**
- 277 个工具覆盖 projects/MR/issues/pipelines/wikis，MIT
- **维护强度全场第一**：30 天 100+ commits，今天还在 push，v2.3.11（10-25）
- 有 Dockerfile。你如果私有仓库在 GitLab，这是唯一认真维护的选择

**⑤ 淘汰项**
- adhikasp/mcp-git-ingest：2025-01 起停更 21 个月，淘汰
- cyanheads/git-mcp-server：功能最全（rebase/cherry-pick/worktree）但 issue 率 7.38% 最差、30 天 0 commit，观察即可。worktree 需求可先用 mcp-server-git + 手工 git

### 2.3 Git 推荐组合

```
GitHub 操作 → github-mcp-server（Docker / 托管 remote）
本地 git   → mcp-server-git（uvx，免容器）
GitLab     → zereight/gitlab-mcp（仅当有 GitLab）
```

---

## 三、搜索 MCP 多维对比

### 3.1 数据总表（2026-10-26 实测）

| 仓库 | ★ | 月龄 | 月均★ | 增速评级 | issues | issue/★ | 30d commits | 最近 push | License | Dockerfile/compose |
|---|---|---|---|---|---|---|---|---|---|---|
| firecrawl/firecrawl-mcp-server | 7,686 | 22.6m | 340 | S 级 | 191 | 2.49% | 100+ | 10-25 | MIT | ✅ / — |
| exa-labs/exa-mcp-server | 5,168 | 22.9m | 226 | S 级 | 20 | 0.39% | 5 | 10-19 | MIT | ✅ / — |
| tavily-ai/tavily-mcp | 2,460 | 20.9m | 118 | B 级 | 63 | 2.56% | 12 | 10-22 | MIT | ✅ / — |
| anysearch-ai/anysearch | 2,052 | **5.9m** | **349** | A 级（爆发） | 2 | 0.10% | **0** | **09-17 停更迹象** | Apache-2.0 | ❌ / ❌ |
| Aas-ee/open-webSearch | 1,874 | 16.2m | 116 | B 级 | 14 | 0.75% | 7 | 10-08 | Apache-2.0 | ✅ / ✅ |
| nickclyde/duckduckgo-mcp | 1,551 | 20.0m | 77 | C 级 | 8 | 0.52% | 0 | 09-04 | MIT | ✅ / — |
| **ihor-sokoliuk/mcp-searxng** | 1,329 | 22.1m | 60 | B 级 | **2** | **0.15%** | **52** | 10-25 | MIT | ✅ / **×3** |
| fastcrw/crw | 1,176 | **7.8m** | 151 | A 级 | 5 | 0.43% | 100+ | 10-25 | **AGPL-3.0** | ✅ / ×2 |
| langsearch-ai/langsearch | 83 | 22.7m | 3.7 | D 级 | 11 | 13.25% | 0 | 09-13 | — | — |

### 3.2 分层分析

**第一层：Docker 自托管搜索（正中你的需求）—— SearXNG + mcp-searxng**

这是唯一同时满足"搜索引擎可自托管 + MCP 层可容器化 + 用完即关"的方案：
- **架构**：`searxng`（搜索引擎本体，官方 Docker 镜像）+ `isokoliuk/mcp-searxng`（MCP 层，Docker Hub 官方镜像），两个容器，compose 文件仓库里现成 3 份
- **健康度全场最佳**：open issue 仅 2 个（issue/★ = 0.15%），30 天 52 commits，v2.8.1（10-25 刚发版）
- **经济性**：无 API key、无配额、无月费；聚合 Google/Bing/DDG/Brave 等 70+ 引擎，支持时间/区域/安全搜索过滤
- **运维**：`docker compose up -d` 开、`docker compose down` 关，数据不出本机
- **短板**：结果质量=元引擎聚合，无 AI 语义排序；中文结果取决于上游引擎配置（可配 Bing CN 等改善）

**第二层：托管 API 搜索（质量补充，非 Docker）**

| 方案 | 定位 | 免费额度 | 适合 |
|---|---|---|---|
| **Tavily** | agent 专用搜索+extract+crawl，LLM 优化摘要 | 1,000 credits/月 | 通用 agent 检索，接入最省事 |
| **Exa** | 神经语义搜索，"找相似"类查询最强 | 有免费层 | 英文语义发现、research 场景 |
| 现有 websearch_cn（智谱） | 中文引擎覆盖独有 | 现有套餐 | **保留**——上轮审计已确认中文价值不可替代 |

推荐策略：**SearXNG 打底（免费无限量）+ websearch_cn 保中文 + Tavily 做质量兜底**，三者覆盖面即完整。

**第三层：抓取增强层（搜索之后取全文）**
- **firecrawl-mcp-server**（7.7K★，100+ commits/30d）：search/scrape/crawl/map 一体，自托管需跑全栈容器组，成本高于 SearXNG 但功能独有
- **fastcrw/crw**（1.2K★，Rust，7.8 个月冲到 1,176★）：Firecrawl/Tavily 的轻量自托管替代，100+ commits/30d 极活跃，Dockerfile+compose 齐全。**注意 AGPL-3.0**（自用无碍，二开/集成需开源义务）

**淘汰/风险项**
- anysearch：5.9 个月冲 2,052★（增速 349/月全场第一）但 09-17 后 0 commit，无 Docker，需注册 key——爆发新项目，观望
- duckduckgo-mcp-server：9 月起停更，且 DDG 无自托管本体
- langsearch：83★ 太小众，issue 率 13.25% 最差
- open-webSearch：可作 SearXNG 之外的国内备选（多引擎免 key），但活跃度（7c/30d）不及 mcp-searxng（52c/30d）

---

## 四、落地建议（最小动作集）

1. **Git**：安装 `github-mcp-server`（Docker 方式，只开需要的 toolset）；本地 git 需求出现时再加 `uvx mcp-server-git`
2. **搜索自托管**：docker compose 起 `searxng` + `mcp-searxng`，MCP 配置指向 `http://localhost:8080`；不用时 down 掉，零残留
3. **搜索 API**：暂不加新 key——现有 websearch_cn 保留，若 SearXNG 质量不足再上 Tavily 免费层
4. **观察名单**：fastcrw/crw（抓取层若 firecrawl 太重）、zereight/gitlab-mcp（若迁 GitLab）

## 五、数据口径说明

- ★/issues/commits/release：GitHub API 2026-10-26 实测；`commits_30d=100` 表示达到 per_page 上限（即 ≥100）
- "月均★" = stars ÷ 仓库月龄（created 至今），非近 30 天增速（近期增速需 star 时间戳分页采样，本轮未采）
- issue/★ = open_issues ÷ stars，数值越低维护越健康；open_issues 含 PR（GitHub 口径）
- Dockerfile/compose 存在性：仓库根目录实测，非文档宣称
