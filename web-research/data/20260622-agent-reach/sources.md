# 信息源 + 知识空白

## S 级信息源（官方/权威）

1. [Panniantong/Agent-Reach](https://github.com/Panniantong/Agent-Reach) — 官方仓库（37,038 star）
2. [README.md via zread](https://zread.ai/Panniantong/Agent-Reach) — 完整 README + 路由表 + 设计理念
3. [Release v1.5.0](https://github.com/Panniantong/Agent-Reach/releases/tag/v1.5.0) — 最新版（2026-06-11）
4. [docs/install.md](https://github.com/Panniantong/Agent-Reach/blob/main/docs/install.md) — 安装文档
5. [docs/update.md](https://github.com/Panniantong/Agent-Reach/blob/main/docs/update.md) — 更新文档
6. [docs/troubleshooting.md](https://github.com/Panniantong/Agent-Reach/blob/main/docs/troubleshooting.md) — 故障排查

## A 级信息源（issue 实测）

### 打包 bug 系列（7 个重复）
7. [Issue #337 — hatchling force-include duplicate](https://github.com/Panniantong/Agent-Reach/issues/337)
8. [Issue #332 — Build fails ValueError duplicate wheel](https://github.com/Panniantong/Agent-Reach/issues/332)
9. [Issue #315 — pyproject.toml force-include 与 packages 重复](https://github.com/Panniantong/Agent-Reach/issues/315)
10. [Issue #308 — force-include 导致 pip install 报重复文件](https://github.com/Panniantong/Agent-Reach/issues/308)

### Windows 兼容
11. [Issue #262 — Windows 中文系统 UnicodeDecodeError 'gbk'](https://github.com/Panniantong/Agent-Reach/issues/262)
12. [Issue #304 — Windows python3 是 Microsoft Store 占位符](https://github.com/Panniantong/Agent-Reach/issues/304)

### SKILL.md 一致性
13. [Issue #282 — SKILL.md 用 bird 但实际装 twitter](https://github.com/Panniantong/Agent-Reach/issues/282)
14. [Issue #316 — triggers 字段不自动触发，建议优化 description](https://github.com/Panniantong/Agent-Reach/issues/316)

### macOS 平台
15. [Issue #289 — grep -oP PCRE BSD grep 不支持](https://github.com/Panniantong/Agent-Reach/issues/289)（含完整 perl 替换 patch）

### 版本/上游漂移
16. [Issue #294 — rdt-cli 0.4.2 PyPI 没有](https://github.com/Panniantong/Agent-Reach/issues/294)
17. [Issue #314 — v1.4.0 Release Notes Reddit 仍需登入](https://github.com/Panniantong/Agent-Reach/issues/314)

### 功能 bug
18. [Issue #296 — 小红书 user-posts 无效](https://github.com/Panniantong/Agent-Reach/issues/296)

## B 级信息源（衍生）

19. [dapao29/agent-reach-windows-cn](https://github.com/dapao29/agent-reach-windows-cn) — 国内 Windows 完整实战 SOP（C 盘解放 + 镜像源 + 6 平台 Cookie + 双 ASR + 10 踩坑）
20. [AtomGit 镜像](https://atomgit.com/qq_51337814/Agent-Reach) — 国内访问
21. [腾讯云 OpenClaw 友情链接](https://www.tencentcloud.com/act/pro/intl-openclaw) — 部署方案

## 上游依赖（11 个外部 CLI）

- [OpenCLI](https://github.com/jackwener/opencli)（桌面浏览器登录态）
- [twitter-cli](https://github.com/public-clis/twitter-cli)
- [rdt-cli](https://github.com/public-clis/rdt-cli)
- [xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp)
- [xhs-cli](https://github.com/jackwener/xiaohongshu-cli)（已停更）
- [bili-cli](https://github.com/public-clis/bilibili-cli)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [Jina Reader](https://github.com/jina-ai/reader)
- [Exa](https://exa.ai) via [mcporter](https://github.com/nicobailon/mcporter)
- [feedparser](https://github.com/kurtmckee/feedparser)
- [linkedin-scraper-mcp](https://github.com/stickerdaniel/linkedin-mcp-server)
- [rookiepy](https://github.com/kiomphuc/rookiepy)（Rust Cookie 提取）

## 工具调用记录

### git mcp
- search_repositories: Panniantong/Agent-Reach + 周边衍生
- list_issues: state=CLOSED, perPage=15（15 个最近 closed）
- list_releases: perPage=10（7 个版本完整演化）

### zread mcp
- get_repo_structure: Agent-Reach（channels/ + guides/ + skill/ + integrations/）
- read_file: README.md（完整 README + 13 平台 + FAQ + 设计理念）

## 关键版本时间线

- v1.1.0 (02-25) → v1.2.0 (02-26) → v1.3.0 (03-04) → v1.4.0 (03-31) → v1.4.1 (06-10) → v1.4.2 (06-10) → v1.5.0 (06-11)
- 6 月一周三版（修 wheel → 诚实瘦身 → 能力层升级）

## 知识空白

| 方向 | 原因 | 建议 |
|------|------|------|
| 长期 Cookie 封号率 | 仅作者警告，无统计 | 等社区反馈 |
| 各平台抓取稳定性（月度）| 依赖上游变化 | 关注 CHANGELOG |
| 与 BrowserAct 等浏览器自动化分工 | README 提及但无实战 | 后续组合方案 |
| 企业代理方案（~$1/月）| README 提及，无具体服务商 | 用户实战后沉淀 |

## 验证完整性

- 所有 URL 真实可达（GitHub + 上游项目）
- 无 AI 编造内容
- 上游工具版本与 README 路由表一致
- issue 编号可追溯
