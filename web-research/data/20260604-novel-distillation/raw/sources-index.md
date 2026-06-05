# 降级日志

| 时间 | 能力 | 原工具 | 原因 | 降级到 | 结果 |
|------|------|--------|------|--------|------|
| 2026-06-04 | 搜索 | WebSearch | 权限拒绝 x5 | searxng_web_search | ✅ 成功 |
| 2026-06-04 | 提取 | searxng_web_url_read | 权限拒绝 x2 | webReader | ✅ 成功 |
| 2026-06-04 | 提取 | ctx_fetch_and_index | 知乎403、towardsai未知错误 | 跳过 | ⚠️ 4个URL提取失败 |
| 2026-06-04 | 搜索 | github search_code | 权限拒绝 | 无可用降级 | ⚠️ GitHub代码搜索缺失 |

# 提取状态表

| URL | 状态 | 工具 | 主题 |
|-----|------|------|------|
| https://www.53ai.com/news/knowledgegraph/2024071791063.html | ✅ 成功 | ctx_fetch_and_index | 知识图谱+小说 |
| https://cloud.tencent.com/developer/article/2439637 | ✅ 成功 | ctx_fetch_and_index | GraphRAG |
| https://neo4j.com/blog/developer/unstructured-text-to-knowledge-graph/ | ✅ 成功 | ctx_fetch_and_index | Neo4J |
| https://cloud.tencent.com/developer/article/2649876 | ✅ 成功 | ctx_fetch_and_index | MiA-RAG |
| https://cloud.tencent.com/developer/article/2536970 | ✅ 成功 | ctx_fetch_and_index | DOS-RAG |
| https://weaviate.io/blog/chunking-strategies-for-rag | ✅ 成功 | ctx_fetch_and_index | RAG分块 |
| https://www.mindstudio.ai/blog/1m-token-context-window-vs-rag-claude/ | ✅ 成功 | ctx_fetch_and_index | 长上下文vs RAG |
| https://www.digitalapplied.com/blog/ai-context-window-comparison-2026-1m-to-10m-tokens | ✅ 成功 | ctx_fetch_and_index | 上下文窗口对比 |
| https://introl.com/blog/long-context-llm-infrastructure-million-token-windows-guide | ✅ 成功 | ctx_fetch_and_index | 长上下文基础设施 |
| https://www.siliconslopes.com/c/ai-posts/code-level-rag-using-claude-code-with-a-custom-knowledge-base | ✅ 成功(仅标题) | ctx_fetch_and_index | Claude Code RAG |
| https://www.jenova.ai/en/resources/best-ai-for-worldbuilding | ✅ 成功 | ctx_fetch_and_index | AI世界观构建 |
| https://leonfurze.com/2023/11/29/science-fiction-worldbuilding-with-generative-ai/ | ✅ 成功 | ctx_fetch_and_index | AI科幻世界观 |
| https://www.nature.com/articles/s41698-025-01103-4 | ✅ 成功 | ctx_fetch_and_index | 医疗信息提取 |
| https://blog.csdn.net/Kenji_Shinji/article/details/159789725 | ✅ 成功 | ctx_fetch_and_index | 大模型信息抽取 |
| https://cloud.tencent.com/developer/article/2673693 | ✅ 成功 | ctx_fetch_and_index | Gemini实测 |
| https://cloud.tencent.com.cn/developer/article/2654878 | ✅ 成功 | ctx_fetch_and_index | RAG全景2026 |
| https://zhuanlan.zhihu.com/p/1995220964301107288 | ❌ 403 | ctx_fetch_and_index | GraphRAG凡人修仙传 |
| https://pub.towardsai.net/graphrag-explained-* | ❌ 未知错误 | ctx_fetch_and_index | GraphRAG+Neo4J |
| https://pub.towardsai.net/building-a-private-* | ❌ 未知错误 | ctx_fetch_and_index | MCP知识库 |
| https://pub.towardsai.net/ai-and-llm-for-document-* | ❌ 未知错误 | ctx_fetch_and_index | LLM文档提取 |

# Agent 降级补充搜索

| Agent | 补充搜索 | 工具 | 结果 |
|-------|---------|------|------|
| Agent 1 | 微软GraphRAG pipeline | web_search_prime | ✅ |
| Agent 1 | Novelcrafter Codex | web_search_prime | ✅ |
| Agent 1 | Neo4J Graph Builder局限 | web_search_prime | ✅ |
| Agent 1 | GitHub小说知识提取 | web_search_prime | ✅ |
| Agent 1 | GraphRAG arxiv | web_search_prime | ✅ |
| Agent 1 | Jenova AI | web_search_prime | ✅ |
| Agent 2 | DOS RAG arxiv | webReader | ✅ |
| Agent 2 | MiA-RAG arxiv | webReader | ✅ |
| Agent 2 | Agentic RAG综述 | webReader | ✅ |
| Agent 2 | MRCR v2基准 | webReader | ✅ |
