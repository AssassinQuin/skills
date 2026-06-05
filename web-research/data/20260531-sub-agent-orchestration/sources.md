# 信息源列表

## 主题1: Claude Code Agent能力边界

| # | URL | 标题 | 可信度 | 提取状态 |
|---|-----|------|--------|---------|
| 1 | https://code.claude.com/docs/en/sub-agents | Claude Code Sub-agents官方文档 | 🟢 一手 | ✅ |
| 2 | https://code.claude.com/docs/en/agent-sdk/subagents | Agent SDK Subagents文档 | 🟢 一手 | ✅ |
| 3 | https://code.claude.com/docs/en/agent-sdk/hooks | Agent SDK Hooks文档 | 🟢 一手 | ✅ |
| 4 | https://github.com/anthropics/claude-code/issues/31027 | model参数缺失Issue | 🟢 一手 | ✅ |
| 5 | https://github.com/anthropics/claude-code/issues/32514 | 子agent身份隔离Issue | 🟢 一手 | ✅ |
| 6 | https://kotrotsos.medium.com/claude-code-internals-part-9-sub-agents-2c3da315b1c0 | Kotrotsos逆向工程 | 🟡 二手 | ✅ |
| 7 | https://www.richsnapp.com/article/2025/10-05-context-management-with-subagents-in-claude-code | Rich Snapp上下文管理 | 🟡 二手 | ✅ |
| 8 | https://www.anthropic.com/engineering/multi-agent-research-system | Anthropic多agent研究 | 🟢 一手 | ✅ |
| 9 | https://www.augmentcode.com/guides/anthropic-agent-sdk-what-ships-vs-what-you-build | Augment Code SDK分析 | 🟡 二手 | ✅ |
| 10 | https://www.ksred.com/the-claude-agent-sdk-what-it-is-and-why-its-worth-understanding/ | ksred SDK实战 | 🟡 二手 | ✅ |

## 主题2: 多Agent框架与插件生态

| # | URL | 标题 | 可信度 | 提取状态 |
|---|-----|------|--------|---------|
| 11 | https://www.augmentcode.com/tools/multi-agent-orchestration-platforms-build-vs-buy | 7 Multi-Agent Platforms | 🟡 二手 | ✅ |
| 12 | https://servicesground.com/blog/ai-orchestration-frameworks-comparison/ | AI Orchestration Frameworks | 🟡 二手 | ✅ |
| 13 | https://aaronyuqi.medium.com/first-hand-comparison-of-langgraph-crewai-and-autogen-30026e60b563 | Aaron Yu三框架一手对比 | 🟡 二手 | ✅ |
| 14 | https://aimultiple.com/multi-agent-frameworks | AIMultiple基准测试 | 🟡 二手 | ⚠️ 部分 |
| 15 | https://arxiv.org/html/2511.14136v1 | 企业Agent评估论文 | 🟢 一手 | ✅ |
| 16 | https://www.codebridge.tech/articles/choosing-a-multi-agent-framework-langgraph-crewai-microsoft-agent-framework-or-openai-agents-sdk | CodeBridge 2026指南 | 🟡 二手 | ✅ |
| 17 | https://cloud.tencent.com/developer/article/2669652 | 腾讯云编排框架选型 | 🟡 二手 | ✅ |
| 18 | https://www.firecrawl.dev/blog/best-claude-code-plugins | Firecrawl插件列表 | 🟡 二手 | ✅ |
| 19 | https://alirezarezvani.medium.com/my-claude-code-multi-agent-orchestration-setup-4-instances-in-parallel-d91ff11ffe86 | Ayan Pahwa 4实例并行 | 🟡 二手 | ✅ |
| 20 | https://www.zyte.com/blog/my-agentic-coding-setup-claude-code-multi-agent-orchestration-and-how-i-actually-work/ | Zyte多agent实战 | 🟡 二手 | ✅ |

## 主题3: 任务路由精度

| # | URL | 标题 | 可信度 | 提取状态 |
|---|-----|------|--------|---------|
| 21 | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents | Anthropic Context Engineering | 🟢 一手 | ✅ |
| 22 | https://www.anthropic.com/engineering/building-effective-agents | Anthropic Building Agents | 🟢 一手 | ✅ |
| 23 | https://arxiv.org/abs/2602.03786 | AOrchestra论文 | 🟢 一手 | ✅ |
| 24 | https://arxiv.org/abs/2602.16873 | AdaptOrch论文 | 🟢 一手 | ✅ |
| 25 | https://arxiv.org/abs/2605.08686v1 | Critique-and-Router论文 | 🟢 一手 | ✅ |
| 26 | https://openreview.net/forum?id=YcnKdeI9pp | AgentOrchestra论文 | 🟢 一手 | ⚠️ 部分 |

## 降级日志

| 时间 | 能力 | 降级: 原工具 → 原因 → 降级到 → 结果 |
|------|------|--------------------------------------|
| 2026-05-31 | ctx_fetch_and_index | better-sqlite3 bindings missing → 20 URL全链失败 → 降级到直搜模式(webReader/WebFetch) → agent自行搜索提取 |
| 2026-05-31 | searxng_web_search | 3 query返回空结果 → 降级到 web_search_prime → 补充搜索成功 |
