# Agent 2 — 主题: 多Agent框架对比 + Claude Code插件生态

调研时间：2026-05-31
模型：sonnet | 工具调用：14次 | 耗时：197s

## 搜索 Query

- "multi-agent orchestration platforms build vs buy 2026"
- "LangGraph vs CrewAI vs AutoGen benchmark 2025"
- "Claude Code plugin multi-agent orchestration"

## 搜索结果

- [Augment Code: 7 Multi-Agent Platforms](https://www.augmentcode.com/tools/multi-agent-orchestration-platforms-build-vs-buy) — Build vs Buy成本对比
- [Services Ground: AI Orchestration Frameworks](https://servicesground.com/blog/ai-orchestration-frameworks-comparison/) — 四框架对比指南
- [Aaron Yu: LangGraph/CrewAI/AutoGen一手对比](https://aaronyuqi.medium.com/first-hand-comparison-of-langgraph-crewai-and-autogen-30026e60b563) — 航空案例实测
- [AIMultiple: Multi-Agent Benchmarks](https://aimultiple.com/multi-agent-frameworks) — 750次运行基准测试
- [arXiv: Enterprise Agentic AI评估](https://arxiv.org/html/2511.14136v1) — 300企业任务评估
- [CodeBridge: 2026框架指南](https://www.codebridge.tech/articles/choosing-a-multi-agent-framework-langgraph-crewai-microsoft-agent-framework-or-openai-agents-sdk) — 生产就绪度数据
- [腾讯云: Agent编排框架选型](https://cloud.tencent.com/developer/article/2669652) — 8维度选型分析
- [Zyte: 多agent实战](https://www.zyte.com/blog/my-agentic-coding-setup-claude-code-multi-agent-orchestration-and-how-i-actually-work/) — Claude Code多agent实战
- [Firecrawl: Claude Code插件](https://www.firecrawl.dev/blog/best-claude-code-plugins) — 插件列表
- [Ayan Pahwa: 4实例并行](https://alirezarezvani.medium.com/my-claude-code-multi-agent-orchestration-setup-4-instances-in-parallel-d91ff11ffe86) — 4agent并行设置
- [2026完整指南](https://halallens.no/en/blog/agentic-coding-in-2026-the-complete-guide-to-plugins-multi-model-orchestration-and-ai-agent-teams) — 插件+多模型编排

## 提取要点

### 1. 框架路由机制对比

| 框架 | 路由方式 | 精度特征 |
|------|---------|---------|
| **LangGraph** | Conditional graph edges + Supervisor/subagent + Send API | 96%错误恢复率（CodeBridge 2026） |
| **CrewAI** | Sequential/hierarchical/consensual + Flow API | 角色直观，但无硬退出→费用失控（$7/run） |
| **AutoGen** | 异步事件驱动 + Selector Group Chat + Magentic-One | 过程式控制力最强，可读性随复杂度下降 |
| **Claude Agent SDK** | Loop with tool dispatch + Hooks | 原始执行循环，非编排平台 |
| **MS Agent Framework** | Conversation + graph + Selector Group Chat | v0.2→v0.4迁移需大量改动 |

[来源: Augment Code + Aaron Yu + CodeBridge]

### 2. Build vs Buy成本数据

| 方案 | 3年总成本 | 适用场景 |
|------|----------|---------|
| Build（自建） | $752K-$1.386M | 需要完全定制控制 |
| Buy（购买平台） | $234K-$594K | 标准化需求 |
| Hybrid（混合） | $399K-$864K | 部分定制+部分标准化 |

Gartner预测2027年底前超40% agentic AI项目将被取消。

[来源: Augment Code, Paula Hingel 2026-05-04]

### 3. Model分层能力

| 框架 | Per-Agent模型分配 | 多模型支持 |
|------|-------------------|-----------|
| LangGraph | 每个节点/Agent独立模型 | OpenAI/Anthropic/本地 |
| CrewAI | 每Agent独立模型 | OpenAI/Anthropic/本地 |
| Claude Agent SDK | 仅Anthropic模型 | 单一供应商 |
| AutoGen | 每Agent独立模型 | OpenAI/Anthropic/本地 |

[来源: CodeBridge + Augment Code]

### 4. Claude Code插件生态

| 插件 | Stars | 用途 | 多Agent能力 |
|------|-------|------|------------|
| **Superpowers** | 42K | MCP服务器管理+多模型路由 | 支持多模型并行调用 |
| **Everything Claude Code** | 54.8K | 全能工具集 | 内置任务分解和subagent管理 |
| **Ayan Pahwa方案** | — | 4实例并行Claude Code | 4个独立Claude Code实例+共享MCP |
| **Zyte方案** | — | Firecrawl+Claude Code | 多agent爬取+研究 |

[来源: Firecrawl + Medium + Zyte]

### 5. 关键发现：编排平台 ≠ 编排框架

- **编排平台**（LangGraph Cloud/CrewAI Enterprise）：托管编排，0运维，但vendor lock-in
- **编排框架**（LangGraph OSS/CrewAI OSS）：代码级控制，需自行部署运维
- **Claude Agent SDK**：不是编排平台也不是框架——是Agent构建SDK，路由逻辑需自行实现
- MCP已于2025-12捐赠给Linux Foundation，A2A于2025-06发布，均开放治理

### 6. 腾讯云8维度选型建议

选型维度：模型调用/Tool路由/上下文管理/流程控制/容错回退/HITL/流式/可观测性
建议：先POC验证 → 引入Adapter层解耦 → 用ADR持续复审选型

[来源: 腾讯云 2026-05-16]

## 💡灵感

- **Superpowers插件的multi-model routing**：42K stars，支持在Claude Code中直接路由到不同模型（GPT-4/Gemini/Claude），可以绕过Agent工具的model限制
- **Ayan Pahwa的4实例并行方案**：开4个独立Claude Code实例通过共享MCP协调，本质上是最原始但也最灵活的多agent编排
- **LangGraph的96%错误恢复**：如果任务精度是首要目标，LangGraph的checkpoint+重试机制是最成熟的方案

## ⚠️ 知识空白

- AIMultiple的750次基准测试具体数据（页面提取不完整）
- Superpowers插件的具体路由实现（是否真的解决了model参数限制？）
- Everything Claude Code的subagent管理能力细节
