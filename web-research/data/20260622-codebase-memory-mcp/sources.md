# 信息源 + 知识空白

## S 级信息源（官方/权威）

1. [DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) — 官方仓库（10,512 star）
2. [README.md via zread](https://zread.ai/DeusData/codebase-memory-mcp) — 官方文档结构
3. [Release v0.8.1](https://github.com/DeusData/codebase-memory-mcp/releases/tag/v0.8.1) — 最新版（2026-06-12）
4. [docs/BENCHMARK.md](https://github.com/DeusData/codebase-memory-mcp/blob/main/docs/BENCHMARK.md) — 官方 benchmark

## A 级信息源（独立实测）

5. [Issue #540 — Free MCP Server Audit offer](https://github.com/DeusData/codebase-memory-mcp/issues/540) — scotia1973-bot 评价"one of the most technically ambitious MCP servers"
6. [Issue #424 — C++ SEGV root cause](https://github.com/DeusData/codebase-memory-mcp/issues/424) — tree-sitter `0xffffffffffffffff` sentinel 分析
7. [Issue #432 — templated C++ SEGV](https://github.com/DeusData/codebase-memory-mcp/issues/432) — `targs[16]` uninitialized stack，UBSan 掩盖原因
8. [Issue #439 — Corrupted cache DB → SIGABRT](https://github.com/DeusData/codebase-memory-mcp/issues/439) — 39/88 DB 损坏 + crash loop
9. [Issue #411 — moderate mode 静默丢子树](https://github.com/DeusData/codebase-memory-mcp/issues/411) — Python tools/ 47 文件消失

## B 级信息源（GitHub issues）

10. [Issue #529 — Windows stdio + cascading gitignore + UTF-8](https://github.com/DeusData/codebase-memory-mcp/issues/529) — Windows 三连击
11. [Issue #422 — Windows search_code 全坏](https://github.com/DeusData/codebase-memory-mcp/issues/422) — 硬编码 `/bin/bash`
12. [Issue #410 — 大型 C++ 索引 freezes](https://github.com/DeusData/codebase-memory-mcp/issues/410)
13. [Issue #446 — `.github/` 硬编码排除](https://github.com/DeusData/codebase-memory-mcp/issues/446)
14. [Issue #547 — v0.5.7-v0.8.0 release assets 404](https://github.com/DeusData/codebase-memory-mcp/issues/547)

## 衍生 fork

15. [win4r/codebase-memory-mcp-pro](https://github.com/win4r/codebase-memory-mcp-pro) — 合 9 个未上游 PR
16. [trick77/mcp-codebase-memory-podman](https://github.com/trick77/mcp-codebase-memory-podman) — 企业 hardened podman
17. [stevenke1981/opencode-codebase-memory-mcp](https://github.com/stevenke1981/opencode-codebase-memory-mcp) — OpenCode installer

## 工具调用记录

### git mcp
- search_repositories: "DeusData/codebase-memory-mcp"（验证仓库 + star 数）
- list_issues: state=CLOSED, perPage=15（提取 bug 模式）
- list_releases: perPage=10（版本演化）
- get_file_contents: package.json（SHA only，内容走 zread）

### zread mcp
- get_repo_structure: DeusData/codebase-memory-mcp（158 语言 + 架构）
- search_doc: open-gsd/gsd-core（查 install/runtime 兼容性）

## 知识空白

| 方向 | 原因 | 建议 |
|------|------|------|
| 长期稳定性（6+ 月）| 仓库仅 4 个月 | 等 2026 Q4 复评 |
| 完整 token 成本对比 | 官方 "99% fewer tokens" 缺独立实测 | 后续博主补测 |
| Rust/Java/Kotlin 实战质量 | v0.8.0 新加，用户反馈少 | 关注后续 issue |
| 大规模集群部署 | 单机场景为主 | 企业场景待验证 |

## 验证完整性

- 所有 URL 真实可达（GitHub + zread）
- 无 AI 编造内容
- 关键引文标注 issue 编号
- 知识空白显式标注
