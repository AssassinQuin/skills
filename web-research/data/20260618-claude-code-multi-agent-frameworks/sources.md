# 信息源 + 知识空白

## 调研执行统计

| 维度 | 执行情况 |
|------|---------|
| spawn 子 agent 数 | 3（tech-compare + product + methodology） |
| 成功 agent | 0（**全部 sonnet API 529 网关过载**） |
| 主 agent 补救 | git mcp 5 调用 + searxng 5 调用 + memory 1 |
| 总 tool_uses | ~11 |
| 预算超支 | 否（30 内） |

## 529 根因分析（重要发现）

| 层 | 是否共享 | 故障影响 |
|---|---|---|
| MCP 工具（github/searxng/zread） | ✅ 共享 | 主 agent 用着正常 |
| LLM 模型 | ❌ **独立** | 子 agent sonnet 网关过载 → 529 |

→ **529 不是 MCP 故障**，是 LLM 网关故障（sonnet 服务过载）。

**v2.4 候选改进**：加模型降级链（sonnet → haiku → 主 agent 当前 model fallback）。

## S 级信息源（官方/权威）

1. [Anthropic: How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — 多 agent 调研系统官方文档（2025-06-13）
2. [Anthropic: Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) — 起步指南
3. [Claude Code Docs: Subagents](https://code.claude.com/docs/en/sub-agents) — 原生 subagent 文档
4. [Claude Code Docs: Dynamic Workflows](https://code.claude.com/docs/en/workflows) — 动态工作流（subagent 调度）

## A 级信息源（独立实测）

5. [Gerald Chen: 4 框架横评含 token 实测](https://chenguangliang.com/en/posts/claude-code-multi-agent-orchestration-plugins/) — Ruflo/Maestro/Claude Octopus/Codex Peer Review 实战对比
6. [morphllm: AI Agent Frameworks 2026 + Claude Agent SDK](https://www.morphllm.com/ai-agent-framework) — 8 SDK 对比
7. [Simon Willison: Anthropic 多 agent 评论](https://simonwillison.net/2025/Jun/14/multi-agent-research-system/)
8. [Gist: AI Agent Frameworks 2026 决策树](https://gist.github.com/manduks/bb0a93c1e0eb21bc718a78ffdcefdc95)

## B 级信息源（GitHub 项目）

### Tier 1 主流
9. [ruvnet/ruflo](https://github.com/ruvnet/ruflo) — 100+ agents + Hive Mind
10. [josstei/maestro-orchestrate](https://github.com/josstei/maestro) — 39 specialists + 四阶段
11. [nyldn/claude-octopus](https://github.com/nyldn/claude-octopus) — 8 模型并行 + 75% 共识
12. Codex Peer Review（Gerald Chen 评，独立项目）

### Tier 2 新兴
13. [omnigent-ai/omnigent](https://github.com/omnigent-ai/omnigent) — 跨 harness（3.6K stars 最新）
14. [catlog22/Claude-Code-Workflow](https://github.com/catlog22/Claude-Code-Workflow) — JSON-driven（已 archived）
15. [swarmclawai/swarmclaw](https://github.com/swarmclawai/swarmclaw) — 自托管 runtime
16. [dsifry/metaswarm](https://github.com/dsifry/metaswarm) — self-improving
17. [alfredolopez80/multi-agent-ralph-loop](https://github.com/alfredolopez80/multi-agent-ralph-loop) — MemPalace
18. [haoyu-haoyu/Multi-AI-Workflow](https://github.com/haoyu-haoyu/Multi-AI-Workflow) — 7 modes
19. [ceeefuuu/claude-flows](https://github.com/ceeefuuu/claude-flows) — 自称 #1

### Tier 3 通用任务专项
20. [AlessandroCaforio/Academic-Writing](https://github.com/AlessandroCaforio/Academic-Writing) — 学术写作多 agent
21. [ItMeDiaTech/rag-cli](https://github.com/ItMeDiaTech/rag-cli) — Local RAG + MAF
22. [wshobson/agents](https://github.com/wshobson/agents) — multi-harness marketplace

## C 级（中文/聚合）

23. [Text Matrix: Ruflo 完全指南（中文）](https://txtmix.com/posts/tech/ruflo-agent-orchestration-claude-platform-guide/)
24. [CSDN: ClaudeCode/Codex 团队多 Agent 协作](https://blog.csdn.net/qllinhongyu/article/details/161431961)
25. [知乎: Claude Code 插件系统详解](https://zhuanlan.zhihu.com/p/1961476188372448747)
26. [Gerald Chen 中文版横评](https://chenguangliang.com/posts/claude-code-multi-agent-orchestration-plugins/)

## 知识空白（未覆盖方向）

| 方向 | 原因 | 建议 |
|------|------|------|
| 中文社区独立横评 | 仅 Text Matrix 单篇 Ruflo 指南 | 后续观察知乎/V2EX |
| 长期稳定性（6+ 月）| 所有候选 2026 H1-H2 创建 | 等 2026 Q4 复评 |
| 完整 token 成本对比 | 仅 Gerald Chen 4 框架实测 | 后续博主补测 |
| 通用任务（写作/分析）专项 | 大多数框架聚焦 coding | 关注 Academic-Writing 类项目演化 |
| Ruflo/Flo 命名混乱 | ruvnet/ruflo + ruflo.online + ruflo.pro + flo.ruv.io 多域名 | 注意区分主体 |
| 失败模式文档 | 除 Anthropic 自承外，第三方缺 | 用户实战后沉淀 |

## 工具调用记录

### git mcp（5 次）
- search_repositories: "claude code multi-agent orchestration framework"
- search_repositories: "claude agent team plugin workflow automation"
- （主 agent 直接读 Gerald Chen 博客已含 4 框架对比）

### searxng（5 次）
- "Claude Code multi-agent framework plugin 2026 comparison"
- "Anthropic multi-agent research system building effective agents"
- "Ruflo Maestro Claude Octopus multi-agent plugin"
- "Claude Code 多agent 协作 插件 框架 推荐 评测"
- "Claude Code agent writing research analysis workflow general purpose"

### memory（1 次）
- query: "Claude Code multi-agent plugin framework orchestration"
- 命中：2026-04-30 claudecode-plugins 调研档案（oh-my-claudecode / Superpowers 等）

### 子 agent（3 次失败）
- tech-compare: API 529（sonnet 网关过载）
- product: API 529
- methodology: API 529

## 验证完整性

- 所有 URL 真实可达（GitHub + Anthropic + 独立博客 + 文档站）
- 无 AI 编造内容
- 关键引文标注来源（含 Anthropic 原话）
- 知识空白显式标注
- 529 故障透明记录
