# 信息源列表

## 核心来源（多源确认 ✅）

| # | 来源 | URL | 可信度 |
|---|------|-----|--------|
| 1 | 微软 GraphRAG 论文 (arXiv:2404.16130) | https://arxiv.org/abs/2404.16130 | 一手学术论文 |
| 2 | 微软 GraphRAG GitHub (15.9K stars) | https://github.com/microsoft/graphrag | 一手官方仓库 |
| 3 | DOS RAG (Stanford EMNLP 2025) | https://arxiv.org/html/2506.03989v2 | 一手顶会论文 |
| 4 | MiA-RAG (中科院+腾讯) | https://arxiv.org/abs/2512.17220 | 一手论文 |
| 5 | Agentic RAG 综述 | https://arxiv.org/html/2501.09136v4 | 一手综述论文 |
| 6 | Nature LLM-AIx 医疗流水线 | https://www.nature.com/articles/s41698-025-01103-4 | Nature顶刊 |
| 7 | 角色化LLM法律文档抽取 | https://arxiv.org/html/2604.01529v1 | arXiv论文 |
| 8 | Neo4j LLM Graph Builder | https://neo4j.com/labs/genai-ecosystem/llm-graph-builder-features/ | 官方文档 |
| 9 | Claude Projects RAG官方文档 | https://support.claude.com/en/articles/11473015 | 官方文档 |
| 10 | 仙逆GraphRAG实操 | https://zhuanlan.zhihu.com/p/711511272 | 一手实操教程 |
| 11 | 凡人修仙传GraphRAG (B站) | https://www.bilibili.com/video/BV1rr421T7jA/ | 视频教程 |
| 12 | MRCR v2长上下文基准 | https://yage.ai/share/long-context-benchmark-en-20260315.html | 一手benchmark |
| 13 | 1M token vs RAG (MindStudio) | https://www.mindstudio.ai/blog/1m-token-context-window-vs-rag-claude/ | 一手实测 |
| 14 | AI上下文窗口对比2026 | https://www.digitalapplied.com/blog/ai-context-window-comparison-2026-1m-to-10m-tokens | 一手数据 |
| 15 | RAG全景2026 | https://cloud.tencent.com.cn/developer/article/2654878 | 二手综合分析 |

## 辅助来源（单源 ⚠️）

| # | 来源 | URL | 类型 |
|---|------|-----|------|
| 16 | MCP私有知识库实践 | https://pub.towardsai.net/building-a-private-knowledge-base-with-mcp-* | 实践文章 |
| 17 | Neo4j转知识图谱博客 | https://neo4j.com/blog/developer/unstructured-text-to-knowledge-graph/ | 官方博客 |
| 18 | GraphRAG仙逆Neo4J可视化 | https://www.53ai.com/news/knowledgegraph/2024071791063.html | 教程 |
| 19 | GraphRAG知识图谱检索增强 | https://cloud.tencent.com/developer/article/2439637 | 技术文章 |
| 20 | Weaviate分块策略 | https://weaviate.io/blog/chunking-strategies-for-rag | 技术博客 |
| 21 | 长上下文基础设施指南 | https://introl.com/blog/long-context-llm-infrastructure-* | 技术博客 |
| 22 | Jenova AI worldbuilding | https://www.jenova.ai/en/resources/best-ai-for-worldbuilding | 官方资源 |
| 23 | AI科幻世界观构建 | https://leonfurze.com/2023/11/29/science-fiction-worldbuilding-with-generative-ai/ | 博客 |
| 24 | 大模型生成式信息抽取综述 | https://blog.csdn.net/Kenji_Shinji/article/details/159789725 | 技术文章 |
| 25 | Gemini万字长文实测 | https://cloud.tencent.com/developer/article/2673693 | 实测文章 |
| 26 | GraphRAG issue #1389 | https://github.com/microsoft/graphrag/issues/1389 | GitHub issue |
| 27 | GraphRAG本地Ollama | https://github.com/TheAiSingularity/graphrag-local-ollama | 社区fork |
| 28 | Novelcrafter Codex | https://www.novelcrafter.com/features/codex | 官方文档 |
| 29 | Redwood Neo4J批评 | https://www.reddit.com/r/Rag/comments/1i1980p/ | 社区反馈 |
| 30 | Writer Memory Skill | https://mcpmarket.com/tools/skills/writer-memory | MCP Market |
| 31 | PMC小说社会网络评估 | https://pmc.ncbi.nlm.nih.gov/articles/PMC7924459/ | 学术论文 |
| 32 | GraphAware NLP博客 | https://graphaware.com/blog/reverse-engineering-book-stories-nlp/ | 企业博客 |

## 提取失败

| URL | 原因 | 主题 |
|-----|------|------|
| https://zhuanlan.zhihu.com/p/1995220964301107288 | 知乎403 | GraphRAG凡人修仙传 |
| https://pub.towardsai.net/graphrag-explained-* | 未知错误 | GraphRAG+Neo4J |
| https://pub.towardsai.net/building-a-private-* | 未知错误 | MCP知识库 |
| https://pub.towardsai.net/ai-and-llm-for-document-* | 未知错误 | LLM文档提取 |

## ⚠️ 知识空白

1. 小说专用分块策略缺乏实验数据（所有benchmark基于新闻/维基）
2. 虚构文本实体抽取准确率无基准（precision/recall/F1）
3. 动态实体状态追踪方案空白
4. 百万字蒸馏token成本无公开估算
5. 小说蒸馏效果评估标准缺失
6. FTS5 vs 向量搜索对小说语义检索效果无对比数据
7. 用户novel-db MCP架构细节未知（自建工具）
