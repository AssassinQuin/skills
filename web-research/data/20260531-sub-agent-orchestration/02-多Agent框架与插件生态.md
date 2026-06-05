# 主题2: 多Agent框架对比与Claude Code插件生态

> 调研日期: 2026-05-31 | 来源数: 11 | 交叉验证: ✅ 5源确认

## 核心发现

### 2.1 框架路由机制全景对比（2026基准）

**结论：LangGraph在复杂任务中96%错误恢复率为最高可靠性，但Claude Code场景下插件方案更实际。**

| 框架 | 路由方式 | 错误恢复 | 费用控制 | Claude Code兼容性 |
|------|---------|---------|---------|------------------|
| **LangGraph** | Conditional edges + Supervisor + Send API | 96% [✅ CodeBridge] | 可控（per-agent model） | 低（需独立部署） |
| **CrewAI** | Sequential/hierarchical/consensual | 中等 | ⚠️ 无硬退出→$7/run [✅ Augment] | 低（需独立部署） |
| **AutoGen** | 异步事件驱动 + Selector Group Chat | 中等 | 可控 | 低（需独立部署） |
| **Claude Agent SDK** | Loop + Hooks | 需自建 | 需自建 | ✅ 原生 |
| **Claude Code插件** | MCP + multi-model | 插件决定 | 插件决定 | ✅ 原生 |

**关键洞察**：对于books_creater项目（Claude Code内运行），独立部署LangGraph/CrewAI的ROI极低。应在Claude Code生态内解决路由问题。

### 2.2 Build vs Buy成本分析

| 方案 | 3年总成本 | 年均 | 适用场景 |
|------|----------|------|---------|
| 自建编排 | $752K-$1.386M | $250K-$462K | 需完全定制 |
| 购买平台 | $234K-$594K | $78K-$198K | 标准化 |
| 混合 | $399K-$864K | $133K-$288K | 部分定制 |

Gartner预测2027年底前超40% agentic AI项目将被取消——**建议先验证再投入**。

[✅ Augment Code, Paula Hingel 2026-05-04]

### 2.3 Claude Code插件生态（直接可用方案）

| 插件/方案 | Stars | 核心能力 | 多Agent路由 | 适用场景 |
|----------|-------|---------|-----------|---------|
| **Superpowers** | 42K | MCP管理+多模型路由 | ✅ 支持GPT-4/Gemini/Claude并行 | 需要多模型能力 |
| **Everything Claude Code** | 54.8K | 全能工具集 | ✅ 内置任务分解+subagent管理 | 一站式解决方案 |
| **Ayan Pahwa 4实例** | — | 4个独立Claude Code | ✅ 共享MCP协调 | 大规模并行研究 |
| **Firecrawl MCP** | — | 网页爬取+研究 | 部分支持 | web research场景 |

[来源: Firecrawl博客 + Medium文章 + Zyte实战]

### 2.4 编排框架 vs 编排平台 vs Agent SDK

| 类型 | 代表 | 核心差异 | 路由能力 |
|------|------|---------|---------|
| 编排框架（OSS） | LangGraph/CrewAI | 代码级控制，需自部署 | 完整路由DSL |
| 编排平台（SaaS） | LangGraph Cloud/CrewAI Enterprise | 托管，0运维 | 完整+监控 |
| Agent SDK | Claude Agent SDK | Agent构建工具包 | 原始循环，路由需自建 |
| CLI插件 | Superpowers/Everything | 增强CLI能力 | 依赖插件实现 |

**关键认知**：Claude Agent SDK不是编排平台——它提供Agent的构建块，路由逻辑必须自己写。

[✅ Augment Code + 腾讯云确认]

### 2.5 MCP/A2A开放治理状态

- **MCP**：2025-12捐赠给Linux Foundation，开放治理
- **A2A**：2025-06由Linux Foundation发布，开放治理
- 两者都在走向标准化，长期看好Claude Code生态的互操作性

[✅ Augment Code]

### 2.6 腾讯云8维度选型框架

| 维度 | Claude Agent SDK | LangGraph | CrewAI |
|------|-----------------|-----------|--------|
| 模型调用 | 仅Anthropic | 多供应商 | 多供应商 |
| Tool路由 | 需自建 | 图edges | Process模型 |
| 上下文管理 | 自动transcript | Checkpoint | 开箱即用 |
| 流程控制 | Hooks | DAG | Flow API |
| 容错回退 | 需自建 | 96%恢复 | 基础 |
| 可观测性 | Transcript | 完整监控 | 日志 |

建议：先POC → Adapter解耦 → ADR持续复审

[✅ 腾讯云 2026-05-16]

## 💡灵感

1. **Superpowers插件作为多模型路由器**：42K stars验证的方案，在Claude Code内直接路由到不同模型。可能是解决Agent工具model限制的最快路径——不需要等Anthropic修复，插件层面就实现了per-task model分配。
2. **Everything Claude Code的内置subagent管理**：54.8K stars，可能已经实现了我们在coding-rules R5.1中手动的model分层逻辑。值得实测。
3. **混合方案：Claude Code插件 + 自定义agents/文件**：用插件处理跨模型路由，用.claude/agents/定义带model锁定的专业subagent，两者组合可能覆盖90%的路由需求。

## ⚠️ 知识空白

- Superpowers插件具体路由实现机制（是否绕过Agent工具的schema限制？）
- Everything Claude Code的subagent管理能力边界
- AIMultiple 750次基准测试的完整数据（页面提取不完整）
- Ayan Pahwa 4实例方案的MCP共享冲突处理
