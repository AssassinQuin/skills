# 主题1: Claude Code Agent 工具能力边界与Model参数限制

> 调研日期: 2026-05-31 | 来源数: 10 | 交叉验证: ✅ 6源确认

## 核心发现

### 1.1 Model参数的三层差异（关键阻塞点）

**结论：Agent工具运行时调用的model参数被schema静默剥离，是当前最大的路由精度瓶颈。**

| 层级 | model支持 | 机制 | 状态 |
|------|----------|------|------|
| Agent SDK (`AgentDefinition.model`) | 完全支持 | Python SDK配置字段 | ✅ 正常 |
| 自定义subagent (`.claude/agents/` frontmatter) | 完全支持 | YAML frontmatter | ✅ 正常 |
| Agent工具运行时 (`Agent(..., model="haiku")`) | ❌ 被剥离 | JSON schema `additionalProperties:false` | 🔴 #31027 |

**具体证据**：
- GitHub Issue #31027（marcoabreu, 2026-03-05）：Agent工具的JSON schema不含model字段，传入会被静默丢弃 [✅ GitHub Issue确认]
- 内置subagent硬编码锁定：Explore和claude-code-guide锁定Haiku，statusline-setup锁定Sonnet [✅ Kotrotsos逆向工程+官方文档确认]
- 历史Bug #16115：Claude Code曾在subagent生成逻辑中硬编码"haiku"导致404错误 [✅ GitHub Issue确认]

**解决方案矩阵**：

| 方案 | 可行性 | 成本 | 时间 |
|------|--------|------|------|
| 等Anthropic修复#31027 | 被动等待 | 0 | 未知（Issue已关未实现） |
| 自定义subagent文件（`.claude/agents/`） | ✅ 可立即用 | 低 | 30min/个 |
| Hooks拦截（SubagentStart） | ⚠️ 只能监控不能修改 | 中 | 研发成本 |
| Agent SDK代替CLI Agent工具 | ✅ 完全控制 | 高（需迁移） | 数天 |
| 插件多模型路由（Superpowers） | ✅ 42K stars验证 | 低 | 1h配置 |

### 1.2 上下文隔离机制

**结论：subagent拥有完全独立的context window，父子间通过prompt字符串传递，无上下文共享。**

| 收到 | 不收到 |
|------|--------|
| 自己的system prompt + Agent工具prompt | 父会话对话历史 |
| 项目CLAUDE.md（通过settingSources） | 未列在skills中的内容 |
| 工具定义（继承或子集） | 父会话system prompt |

**特殊行为**：Explore和Plan subagent会跳过CLAUDE.md和git status，保持快速廉价。 [✅ Anthropic官方文档]

**transcript持久化**：subagent transcript独立于主对话持久化，主对话压缩不影响subagent。cleanupPeriodDays默认30天。 [✅ Anthropic官方文档]

### 1.3 工具控制与嵌套限制

- **工具白名单**：`tools`字段指定可用工具，`disallowedTools`移除特定工具
- **MCP工具**：`mcpServers`字段指定，支持引用已配置服务器或内联定义
- **嵌套禁止**：subagent不能生成自己的subagent（硬限制）
- **Plugin限制**：Plugin subagent不支持mcpServers和permissionMode（安全原因）

[✅ Anthropic官方文档 + ksred.com实战确认]

### 1.4 Hooks拦截全景

| Hook Event | 触发时机 | 可操作范围 |
|-----------|---------|-----------|
| SubagentStart | subagent初始化 | 追踪启动、记录元数据 |
| SubagentStop | subagent完成 | 聚合结果、清理资源 |
| PreToolUse | subagent内工具调用前 | 读取agent_id/agent_type |
| PostToolUse | 工具执行后 | 结果审计 |
| PostToolUseFailure | 工具执行失败 | 错误处理、降级 |

[✅ Agent SDK Hooks官方文档，Python+TypeScript双语言支持]

### 1.5 Agent SDK vs CLI Agent工具关键差异

| 特性 | Agent SDK | CLI Agent工具 |
|------|----------|-------------|
| model参数 | ✅ AgentDefinition.model | ❌ schema剥离 |
| 工具限制 | tools/disallowedTools | subagent_type锁定 |
| MCP服务器 | mcpServers字段 | 继承主会话 |
| 嵌套 | 需配置 | 硬禁止 |
| 持久化 | 手动 | 自动transcript |
| 自定义程度 | 完全 | 内置类型+自定义文件 |

## 💡灵感

1. **自定义subagent文件绕过model限制**：在`.claude/agents/`创建带model锁定frontmatter的定义文件，通过subagent_type参数调用。这比等#31027修复更实际，且立即可用。
2. **Hooks实现路由审计**：在SubagentStart中记录任务类型+分配的model，在SubagentStop中记录实际执行质量。积累数据后可分析路由准确率。

## ⚠️ 知识空白

- 自定义subagent的frontmatter model字段在运行时是否也被schema验证（需实测验证）
- SubagentStart hook能否修改subagent配置（文档只说触发未说可修改）
- Agent SDK嵌套深度是否有硬限制
