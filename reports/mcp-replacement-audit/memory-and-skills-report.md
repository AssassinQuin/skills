# 跨 Agent 记忆 MCP 调研 + Skills 盘点

**日期**：2026-10-26
**配置变更**：codebase-memory ✅ 已恢复 / playwright ✅ 已卸载 / memory 保持禁用（等待升级替换）

---

## 一、跨 Agent 记忆 MCP 对比（GitHub 实测 2026-10-26）

| 项目 | ★ | 活跃度 | 架构 | 跨 agent 能力 |
|---|---|---|---|---|
| **mem0ai/mem0** | **67,816** | 活跃 | 记忆提取层：向量库 + LLM 提取/更新 | ⭐ **最强**：REST API + MCP 双接入，任意 agent 读写同一库 |
| topoteretes/cognee | 32,756 | 活跃 | ECL 管道：文档/代码 → 知识图谱 | 强（API/MCP），偏知识资产化 |
| getzep/graphiti | 32,222 | 活跃（今天） | **时序知识图谱**（bi-temporal） | 强；独有"事实随时间演化" |
| supermemoryai/supermemory | 31,399 | 活跃 | 托管为主，开源偏客户端 | 一般（绑定其云） |
| letta-ai/letta | 25,255 | 活跃 | agent 框架本体（MemGPT） | 不适用——是框架不是记忆层 |
| doobidoo/mcp-memory-service | 2,046 | 活跃 | 本地 SQLite-vec 纯 MCP | 弱（单机进程，无多 agent 并发设计）= 你刚禁用的这类 |
| mem0ai/openmemory | 99 | 停更（07-29） | 已并入 mem0 主仓 | 概念参考 |

### 推荐（按你的场景）

**首选：Mem0 自托管**
- 跨 agent 的标准答案：Codex / Claude Code / Cursor 全部通过同一个 MCP endpoint + REST API 读写同一记忆库
- Docker 部署：mem0 + Qdrant（向量库），Apache-2.0
- 语义去重/冲突解决/记忆更新管线内建——这正是单机 SQLite 方案（你刚禁的）缺的
- 注意：自报 benchmark（LoCoMo 92.5%）需并行试点验证，勿直接替换现有工作流

**场景备选：Graphiti（Zep 底座）**
- 如果记忆内容大量是"会过时的世界状态"（战争态势/金融数据/项目状态），bi-temporal 时序图谱比向量检索更准
- 32.2K★ 今天还在 push，Apache-2.0 可自托管

**落地顺序建议**：先 Mem0 Docker 试点 2 周 → 满意则删旧 memory server；对时序场景有强需求再加 Graphiti（两者可并存，不同 namespace）。

---

## 二、Skills 全量盘点

| 来源 | SKILL.md 数 | 说明 |
|---|---|---|
| ~/.agents/skills 顶层 | 24 | 小说系 19 + 工具系（deep-research/global-search/skill-stats 等） |
| cangjie-skill 嵌套 | **60** | naval 系（dist 3 份重复）+ novel-skeleton 13 + plot-thickens 等 |
| 插件 | 30 | superpowers 15 + context-mode 11 + openai 系（pdf/docs/ppt/sheets 等）8 + claude-hud 1 |
| **总计** | **~114 个文件** | 系统提示展示 ~200 条目（多路径重复注册） |

### 本次对话实际使用了哪些 skill？

**0 个被触发执行。**

- 所有工作由内置工具完成：exec(bash) / web_search_prime / websearch_cn / web_reader / playwright(演示) / gh CLI / python 脚本
- 唯二接触的 skill 文件：global-search、zhihu-search——仅作为调研对象读取内容（且因缺 API key 未启用）
- 结论：~114 个 skill 文件 + ~20K tokens 描述常驻，本会话贡献 **0 次执行**——清理的科学依据

### 清理路线（执行既有审计结论）

1. **删重复**：cangjie-skill 内 dist 3 份 naval 副本 → 保留 1 份（-16 文件）
2. **降维合并**：小说系 19 个 → 1 个路由 skill + 数据文件；naval 系 8 个 → 1 个
3. **插件取舍**：superpowers 15 个（若不用其 TDD/工作流则整包禁）；context-mode 11 个保留
4. **目标**：114 → ≤30，目录层 tokens 15-20K → ~5K
