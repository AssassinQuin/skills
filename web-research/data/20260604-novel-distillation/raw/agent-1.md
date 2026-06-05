## Agent 1 — 主题: GraphRAG + 知识图谱 + 小说蒸馏工具

### 搜索 Query
- GraphRAG 小说 提取 实体 人物关系 知识图谱
- Neo4j LLM Graph Builder unstructured text entity extraction novel
- 仙逆 凡人修仙传 GraphRAG Neo4J 可视化
- 小说 知识提取 蒸馏 AI 工具 GitHub 实体关系抽取
- AI worldbuilding persistent memory knowledge base fiction
- Microsoft GraphRAG pipeline community summarization GitHub
- Novelcrafter Codex worldbuilding persistent memory AI fiction
- Neo4j LLM Graph Builder capabilities limitations
- novel story fiction knowledge extraction entity NLP GitHub
- GraphRAG arxiv community detection Leiden algorithm
- Jenova AI worldbuilding persistent memory knowledge base

### 降级日志
- [搜索] 降级: WebSearch → 权限被拒绝 → 降级到 web_search_prime
- [提取] 降级: mcp__searxng__web_url_read → 权限被拒绝 → 降级到 webReader

### 搜索结果
- [GraphRAG仙逆Neo4J可视化](https://zhuanlan.zhihu.com/p/711511272) — 博主 Mountain 以《仙逆》全本为输入，使用微软GraphRAG+DeepSeek提取实体/关系
- [凡人修仙传GraphRAG B站](https://www.bilibili.com/video/BV1rr421T7jA/) — 播放量19033，社区关注度高的实操教程
- [红楼梦GraphRAG](https://zhuanlan.zhihu.com/p/716388476) — 知乎+百度智能云双源确认
- [微软GraphRAG issue #1389](https://github.com/microsoft/graphrag/issues/1389) — 虚构文本prompt适配讨论
- [微软GraphRAG arXiv论文](https://arxiv.org/abs/2404.16130) — 2024年原始论文
- [GraphRAG本地Ollama方案](https://github.com/TheAiSingularity/graphrag-local-ollama) — 社区fork降低成本
- [Neo4j LLM Graph Builder](https://neo4j.com/labs/genai-ecosystem/llm-graph-builder-features/) — 官方功能全景
- [Neo4j GraphRAG Python包](https://neo4j.com/labs/genai-ecosystem/llm-graph-builder-features/) — 2-hop检索策略
- [Novelcrafter Codex](https://www.novelcrafter.com/features/codex) — 最成熟手动worldbuilding系统
- [Jenova AI](https://www.jenova.ai/en/resources/ai-with-persistent-memory) — 跨会话持久记忆
- [Dunia](https://dunia.gg/blog/best-ai-writing-tools) — 角色一致性持久记忆
- [Sudowrite Story Bible](https://sudowrite.com/blog/best-ai-writing-platforms-for-fiction-2026-ecosystem-integration/) — 消除连续性错误
- [EPOS-AI](https://epos-ai.ch/en/blog/writing-novel-with-ai-2026.html) — 12万词manuscript memory
- [Writer Memory Skill](https://mcpmarket.com/tools/skills/writer-memory) — Claude Code小说知识追踪skill
- [Giserlei123/StarrySky](https://github.com/Giserlei123/StarrySky) — 小说知识图谱demo
- [fighting41love/funNLP](https://github.com/fighting41love/funNLP) — 14亿实体中文知识图谱
- [GraphAware NLP](https://graphaware.com/blog/reverse-engineering-book-stories-nlp/) — 2017年Neo4j+小说实践
- [PMC小说社会网络评估](https://pmc.ncbi.nlm.nih.gov/articles/PMC7924459/) — NER工具评估论文
- [Reddit Neo4J批评](https://www.reddit.com/r/Rag/comments/1i1980p/neo4js_llm_graph_builder_seems_useless/) — 孤岛节点问题

### 核心要点

1. **仙逆 GraphRAG 实战** — 博主 Mountain 使用微软 GraphRAG + DeepSeek（免费500万Token, 128K上下文）处理《仙逆》全本，成功提取"王林""铁柱"等核心人物实体及关系。社区按特定事件聚类，地点实体可展开查看关联人物。[来源: zhihu.com/p/711511272]

2. **凡人修仙传 GraphRAG 社区关注度** — B站视频播放量19033、收藏843，说明GraphRAG在小说知识图谱领域有较高复现价值。[来源: bilibili.com/BV1rr421T7jA/]

3. **GraphRAG 对虚构文本的四大挑战** — (a) 同一人物多别名 (b) 虚构地名不在NER训练数据中 (c) 人物关系随章节动态变化 (d) 默认prompt未针对中文虚构文本优化。GitHub issue #1389 讨论定制prompt方案。[来源: github.com/microsoft/graphrag/issues/1389]

4. **微软 GraphRAG Pipeline 两阶段** — 索引阶段（实体/关系提取→Leiden社区检测→递归摘要→向量嵌入）+ 查询阶段（社区摘要map-reduce汇总）。源自 arXiv:2404.16130。[来源: arxiv.org/abs/2404.16130 + microsoft.github.io/graphrag/]

5. **GraphRAG 成本警告** — 百万字小说全量索引token消耗可达数百万级别。LazyGraphRAG跳过索引时社区摘要改为查询时按需生成，大幅降低成本。[来源: github.com/microsoft/graphrag]

6. **Neo4j 官方 GraphRAG 2-hop 策略** — 向量+全文混合搜索找chunks→沿实体关系扩展2跳→LLM生成回答。对复杂小说关系链可能不足（需3-5跳）。[来源: neo4j.com/labs/]

7. **Neo4j LLM Graph Builder 局限** — Reddit用户反馈：孤岛节点问题、中文实体提取准确率低于英文、图schema自动推断对虚构世界观适配差。[来源: reddit.com/r/Rag/]

8. **Novelcrafter Codex** ($4-$20/月) — 目前最成熟手动worldbuilding系统。每完成场景后AI自动推荐Codex更新。但本质是结构化笔记系统，非自动知识图谱提取。[来源: novelcrafter.com + Medium评测]

9. **Jenova AI 持久记忆** — "unlimited memory across sessions"，支持GPT-5.2、Claude Opus 4.5。自动记忆积累 vs Novelcrafter手动结构化。[来源: jenova.ai]

10. **AI写作工具三足鼎立** — Novelcrafter(Codex) / Sudowrite(Story Bible) / EPOS-AI(12万词manuscript memory)。均基于文档/对话持久化，无知识图谱导出能力。[来源: 各官方文档]

11. **Writer Memory Skill for Claude Code** — MCP Market上已有小说知识追踪skill，但无用户评价和GitHub仓库。[来源: mcpmarket.com/tools/skills/writer-memory]

### 💡灵感

1. **LazyGraphRAG按需生成策略** — 先建实体图，对感兴趣部分"按需深入蒸馏"，避免一次性全量索引的天文token成本。与"渐进式蒸馏"理念天然契合。

2. **Novelcrafter"场景后自动推荐Codex更新"可迁移** — 每处理完一个章节，自动检测实体状态变化（如"张三从筑基期突破到金丹期"），生成实体属性变更建议。

3. **Jenova对话即知识库 + GraphRAG结构化图谱互补** — 扁平对话记录作为原始数据源，GraphRAG定期从中蒸馏出结构化知识图谱。

4. **Prompt工程是小说蒸馏瓶颈** — 默认prompt针对新闻/维基百科式文本，对"渡劫期、法宝品阶"等垂直概念效果差。需为每个小说类型定制entity-extraction prompt。

5. **Neo4j 2-hop限制** — 小说复杂关系链可能需3-5跳或路径查询。

### 知识空白

1. 尚无端到端"小说→知识图谱"专用开源工具
2. 虚构文本实体抽取准确率缺乏基准测试
3. 动态实体状态追踪方案空白
4. 跨会话知识图谱增量更新机制未解决
5. AI worldbuilding工具与知识图谱的集成缺失
6. Writer Memory Skill实际效果未知
