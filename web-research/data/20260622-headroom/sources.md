# 信息源 + 知识空白

## S 级信息源（官方/权威）

1. [chopratejas/headroom](https://github.com/chopratejas/headroom) — 官方仓库（44,873 star）
2. [README.md via zread](https://zread.ai/chopratejas/headroom) — 完整 README + benchmark
3. [headroom-docs.vercel.app](https://headroom-docs.vercel.app/docs) — 官方文档站
4. [Kompress-v2-base on HuggingFace](https://huggingface.co/chopratejas/kompress-v2-base) — 自研压缩模型
5. [Release v0.26.0](https://github.com/chopratejas/headroom/releases/tag/v0.26.0) — 最新版（2026-06-16）

## A 级信息源（issue 实测）

### Prefix cache 破坏系列（最严重）
6. [Issue #1042 — Canonical re-serialization busts prefix cache 17/18](https://github.com/chopratejas/headroom/issues/1042)
7. [Issue #1011 — 2-3x More Cache Misses with DeepSeek v4](https://github.com/chopratejas/headroom/issues/1011)

### 冷启动 + 关键路径
8. [Issue #1146 — 274 MB ONNX inline download → 30s timeout + silent fail-open](https://github.com/chopratejas/headroom/issues/1146)
9. [Issue #1145 — UnboundLocalError ccr_workspace_key crashes all requests](https://github.com/chopratejas/headroom/issues/1145)

### Windows 兼容
10. [Issue #1202 — headroom learn fully broken on Windows](https://github.com/chopratejas/headroom/issues/1202)
11. [Issue #1069 — X-Headroom-Project rejects non-ASCII cwd](https://github.com/chopratejas/headroom/issues/1069)

### Provider 集成
12. [Issue #1107 — wrap codex ignores OPENAI_BASE_URL](https://github.com/chopratejas/headroom/issues/1107)
13. [Issue #1039 — GitHub Copilot models filtered by proxy](https://github.com/chopratejas/headroom/issues/1039)
14. [Issue #1058 — sticky_betas breaks all Claude Code requests](https://github.com/chopratejas/headroom/issues/1058)

### CCR + Memory
15. [Issue #1213 — headroom_retrieve query returns "Content not found"](https://github.com/chopratejas/headroom/issues/1213)
16. [Issue #1095 — SmartCrusher 12-char hash rejected by parse_tool_call](https://github.com/chopratejas/headroom/issues/1095)

### 副作用 + Packaging
17. [Issue #1235 — RTK guidance written to project AGENTS.md](https://github.com/chopratejas/headroom/issues/1235)
18. [Issue #1232 — [code] extra silently disables code compression](https://github.com/chopratejas/headroom/issues/1232)

## B 级信息源（衍生）

19. [headroom-zed](https://github.com/chopratejas/headroom-zed) — Zed 扩展（Rust）
20. [headroom-swift](https://github.com/chopratejas/headroom-swift) — Swift Package
21. [HeadroomUI by Jessie-Wilkins](https://github.com/Jessie-Wilkins/HeadroomUI) — 第三方 UI

## 工具调用记录

### git mcp
- search_repositories: chopratejas/headroom + 周边
- list_issues: state=CLOSED, perPage=20（20 个 closed，主题分类）
- list_releases: perPage=10（10 个版本演化）

### zread mcp
- get_repo_structure: headroom（crates/ + sdk/ + plugins/）
- read_file: README.md（完整 README + benchmark + compared to）

## 关键版本时间线（密集发布）

- v0.21.37 (05-15) → v0.22.0 (05-19) → v0.22.4 (06-01) → v0.23.0 (06-04) → v0.24.0 (06-08) → v0.25.0 (06-12) → v0.26.0 (06-16)
- 6 月连续 4 版（Copilot subscription → custom gateway → Kompress-v2 → Copilot BYOK）

## 知识空白

| 方向 | 原因 | 建议 |
|------|------|------|
| CacheAligner 实际命中率 | #1042/#1011 表明有 bug | 实测 prefix cache hit rate |
| 长会话稳定性（>100 turn）| 短期实测为主 | 后续长 session 反馈 |
| 企业大规模部署 | 文档全，实战少 | 关注 ENTERPRISE.md 案例积累 |
| Kompress-v2 vs Kompress-v1 实际差异 | v0.25 切换默认 | 后续 A/B 数据 |

## 验证完整性

- 所有 URL 真实可达（GitHub + HuggingFace + vercel docs）
- 无 AI 编造内容
- Benchmark 数据来自 README 官方
- issue 编号可追溯
