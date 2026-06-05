# Agent 1 — 主题: Claude Code Agent 工具能力边界 + Anthropic Agent SDK

调研时间：2026-05-31
模型：sonnet | 工具调用：18次 | 耗时：174s

## 搜索 Query

- "Claude Code Agent tool model parameter sub-agent"
- "Anthropic Agent SDK subagents model configuration"
- "Claude Code hooks subagent interception"

## 搜索结果

- [Claude Code Sub-agents 官方文档](https://code.claude.com/docs/en/sub-agents) — 自定义subagent frontmatter完整配置
- [Agent SDK Subagents 文档](https://code.claude.com/docs/en/agent-sdk/subagents) — AgentDefinition.model字段详解
- [Agent SDK Hooks 文档](https://code.claude.com/docs/en/agent-sdk/hooks) — SubagentStart/SubagentStop钩子
- [GitHub Issue #31027](https://github.com/anthropics/claude-code/issues/31027) — Agent工具model参数被schema剥离
- [GitHub Issue #32514](https://github.com/anthropics/claude-code/issues/32514) — 子agent身份隔离
- [Kotrotsos 逆向工程分析](https://kotrotsos.medium.com/claude-code-internals-part-9-sub-agents-2c3da315b1c0) — 内置subagent模型锁定
- [Rich Snapp 上下文管理](https://www.richsnapp.com/article/2025/10-05-context-management-with-subagents-in-claude-code) — subagent独立上下文窗口
- [Anthropic 多agent研究](https://www.anthropic.com/engineering/multi-agent-research-system) — Anthropic官方多agent系统
- [Augment Code SDK分析](https://www.augmentcode.com/guides/anthropic-agent-sdk-what-ships-vs-what-you-build) — SDK能力vs自建差距
- [ksred.com SDK实战](https://www.ksred.com/the-claude-agent-sdk-what-it-is-and-why-its-worth-understanding/) — Agent SDK实战指南

## 提取要点

### 1. model 参数支持的三层差异

| 层级 | model支持 | 状态 |
|------|----------|------|
| Agent SDK (AgentDefinition.model) | 完全支持：sonnet/opus/haiku/inherit/完整ID | ✅ 正常工作 |
| 自定义 subagent (frontmatter) | 完全支持：sonnet/opus/haiku/完整ID/inherit | ✅ 正常工作 |
| Agent 工具运行时调用 | ❌ schema设置additionalProperties:false，model字段被静默剥离 | 🔴 Issue #31027 |

[来源: Anthropic官方文档 + GitHub #31027]

### 2. 内置subagent模型锁定

| 内置Subagent | 默认模型 | 可否覆盖 |
|-------------|---------|---------|
| Explore | Haiku（锁定） | 不可改 |
| Plan | 继承主会话 | 不可改 |
| General-purpose | 继承主会话 | — |
| statusline-setup | Sonnet（锁定） | 不可改 |
| claude-code-guide | Haiku（锁定） | 不可改 |

[来源: Kotrotsos逆向工程 + 官方文档]

### 3. 上下文隔离机制

subagent拥有完全独立的上下文窗口：
- 收到：自己的system prompt + Agent工具传入的prompt + 项目CLAUDE.md + 工具定义
- 不收到：父会话对话历史、父会话system prompt、未列在skills中的预加载内容
- Explore/Plan会跳过CLAUDE.md和git status以保持快速廉价
- transcript独立持久化，主对话压缩不影响subagent transcript
- cleanupPeriodDays默认30天自动清理

[来源: Rich Snapp分析 + 官方文档]

### 4. Hooks拦截能力

| Hook Event | 可拦截subagent | 说明 |
|-----------|--------------|------|
| SubagentStart | ✅ | subagent初始化时触发 |
| SubagentStop | ✅ | subagent完成时触发 |
| PreToolUse | ✅ | 可读取agent_id和agent_type |
| PostToolUse | ✅ | subagent内工具执行后 |
| PostToolUseFailure | ✅ | 工具执行失败时 |

[来源: Agent SDK Hooks官方文档]

### 5. 工具与嵌套限制

- subagent不能生成自己的subagent（禁止嵌套）
- Task工具必须在主会话allowedTools中才能自动批准subagent调用
- MCP工具通过mcpServers字段指定，支持引用已配置服务器或内联定义
- Plugin subagent不支持mcpServers和permissionMode（安全原因）

### 6. Agent SDK vs CLI Agent工具的关键差异

| 特性 | Agent SDK | CLI Agent工具 |
|------|----------|-------------|
| model参数 | ✅ AgentDefinition.model | ❌ schema剥离 |
| 工具限制 | tools/disallowedTools | subagent_type锁定 |
| MCP服务器 | mcpServers字段 | 继承主会话配置 |
| 嵌套 | 子Agent可调Agent工具（需配置） | 禁止嵌套 |
| 持久化 | 手动管理 | 自动持久化transcript |

[来源: Augment Code分析 + 官方文档]

## 💡灵感

- **Hooks实现路由精度控制**：可以在SubagentStart hook中插入路由逻辑，根据任务特征动态覆盖subagent的model选择。这比等待Anthropic修复Issue #31027更实际
- **自定义subagent绕过model限制**：通过`.claude/agents/`创建自定义subagent定义文件，在frontmatter中锁定model，避免运行时被schema剥离

## ⚠️ 知识空白

- Agent SDK的subagent嵌套深度限制（文档说"不能"，但实际代码是否有硬限制？）
- custom subagent的model字段在运行时是否也会被schema验证剥离（frontmatter ≠ 运行时参数）
- SubagentStart hook能否修改subagent的model配置（文档只说"触发"，没说"可修改"）
