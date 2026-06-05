# Sources Index & Degradation Log

## 降级日志

| 时间 | 能力 | 降级: 原工具 → 原因 → 降级到 → 结果 |
|------|------|--------------------------------------|
| 2026-05-31 | ctx_fetch_and_index | better-sqlite3 bindings missing → 20 URL全链失败 → 降级到直搜模式(webReader/WebFetch) → agent自行搜索提取 |
| 2026-05-31 | searxng_web_search | 3 query返回空结果 → 降级到 web_search_prime → 补充搜索成功 |

## URL 提取状态

### 主题 1: Claude Code Agent 能力边界
| URL | 状态 | 工具 | 主题 |
|-----|------|------|------|
| https://code.claude.com/docs/en/sub-agents | ✅ | webReader | Agent能力 |
| https://code.claude.com/docs/en/agent-sdk/subagents | ✅ | webReader | Agent能力 |
| https://code.claude.com/docs/en/agent-sdk/hooks | ✅ | webReader | Hooks |
| https://code.claude.com/docs/en/agent-sdk/overview | ✅ | webReader | Agent SDK |
| https://github.com/anthropics/claude-code/issues/32514 | ✅ | webReader | 子agent身份 |
| https://github.com/anthropics/claude-code/issues/31027 | ✅ | WebSearch | model参数缺失 |
| https://kotrotsos.medium.com/claude-code-internals-part-9-sub-agents-2c3da315b1c0 | ✅ | webReader | 逆向工程 |
| https://www.richsnapp.com/article/2025/10-05-context-management-with-subagents-in-claude-code | ✅ | webReader | 上下文管理 |

### 主题 2: Anthropic Agent SDK
| URL | 状态 | 工具 | 主题 |
|-----|------|------|------|
| https://www.anthropic.com/engineering/multi-agent-research-system | ✅ | web_url_read | 多agent研究 |
| https://www.augmentcode.com/guides/anthropic-agent-sdk-what-ships-vs-what-you-build | ✅ | webReader | SDK能力差距 |
| https://www.ksred.com/the-claude-agent-sdk-what-it-is-and-why-its-worth-understanding/ | ✅ | web_url_read | SDK实战 |

### 主题 3: 多Agent框架
| URL | 状态 | 工具 | 主题 |
|-----|------|------|------|
| https://www.augmentcode.com/tools/multi-agent-orchestration-platforms-build-vs-buy | ✅ | webReader | Build vs Buy |
| https://servicesground.com/blog/ai-orchestration-frameworks-comparison/ | ✅ | webReader | 框架对比 |
| https://aaronyuqi.medium.com/first-hand-comparison-of-langgraph-crewai-and-autogen-30026e60b563 | ✅ | webReader | 一手对比 |
| https://aimultiple.com/multi-agent-frameworks | ✅ | webReader | 基准测试 |

### 主题 4: 任务路由精度
| URL | 状态 | 工具 | 主题 |
|-----|------|------|------|
| https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents | ✅ | webReader | Context Engineering |
| https://arxiv.org/html/2602.03786v2 | ✅ | webReader | AOrchestra论文 |

### 主题 5: Claude Code 插件/MCP
| URL | 状态 | 工具 | 主题 |
|-----|------|------|------|
| https://www.zyte.com/blog/my-agentic-coding-setup-claude-code-multi-agent-orchestration-and-how-i-actually-work/ | ✅ | webReader | 多agent实战 |
| https://www.firecrawl.dev/blog/best-claude-code-plugins | ✅ | webReader | 插件列表 |
| https://alirezarezvani.medium.com/my-claude-code-multi-agent-orchestration-setup-4-instances-in-parallel-d91ff11ffe86 | ✅ | webReader | 4实例并行 |
| https://halallens.no/en/blog/agentic-coding-in-2026-the-complete-guide-to-plugins-multi-model-orchestration-and-ai-agent-teams | ✅ | webReader | 2026完整指南 |
