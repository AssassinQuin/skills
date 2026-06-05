## Agent 3 — 主题: Claude Code/MCP实现路径 + 跨领域灵感

### 搜索 Query
- novel analysis fiction knowledge graph LLM stars:>10
- novel analysis NLP fiction structured extraction knowledge
- novel distillation LLM knowledge extraction MCP server
- Claude Code MCP knowledge base RAG architecture
- LLM medical legal document extraction structured output
- CREFT character relation extraction novel
- memory: novel-db MCP distillation_evolve
- memory: worldbuilding world-lore knowledge graph
- memory: novel distillation skill architecture

### 降级日志
- [提取] 降级: searxng_web_url_read → 权限拒绝 → webReader (成功 4/4)
- [搜索] 降级: github search_code → 权限拒绝 → 无可用降级
- [搜索] 降级: WebSearch → 权限拒绝 → 依赖已有 searxng 结果

### 搜索结果
- [MCP私有知识库实践](https://pub.towardsai.net/building-a-private-knowledge-base-with-mcp-how-i-made-claude-search-my-own-articles-06c591bb300a) — Suman Saha 2026年2月, FastMCP+ChromaDB
- [Claude Projects RAG官方文档](https://support.claude.com/en/articles/11473015-retrieval-augmented-generation-rag-for-projects) — 内置RAG自动10倍上下文扩展
- [hyunjae-labs/lore](https://github.com/hyunjae-labs/lore) — Claude Code对话历史语义搜索MCP
- [Lookio RAG MCP](https://mcpmarket.com/) — RAG知识库管理工具
- [Nature LLM-AIx医疗流水线](https://www.nature.com/articles/s41698-025-01103-4) — TU Dresden/Heidelberg 2025, 四阶段流水线
- [角色化LLM政策文档抽取](https://arxiv.org/html/2604.01529v1) — Zhang/Bao/Li, UW/GIT, 3角色分工
- [CREFT角色关系抽取](https://arxiv.org/) — 顺序多agent架构
- [对话式多维关系抽取](https://arxiv.org/abs/2507.04852) — 基于对话的角色关系抽取

### 核心要点

1. **MCP + RAG 架构：FastMCP + ChromaDB + nomic-embed-text** — Suman Saha 2026年方案。分块500词/50词重叠，相关性阈值10%。Claude自动通过project knowledge search tool检索。[来源: towardsai.net]

2. **Claude Projects 内置 RAG 10倍上下文扩展** — 官方文档：project knowledge超出窗口时RAG自动激活。百万字小说上传为project knowledge后Claude可自动检索相关段落。但无法精细控制分块策略和结构化抽取。[来源: support.claude.com]

3. **hyunjae-labs/lore: 对话语义搜索MCP** — 嵌入模型索引过往对话，通过MCP工具查询。与context-mode的FTS5方案互为替代。[来源: github.com/hyunjae-labs/lore]

4. **LLM-AIx 四阶段医疗流水线 (Nature npj Precision Oncology)** — (1) Define定义抽取schema (2) Preprocess分块 (3) Extract用Grammar Builder约束JSON+4-bit量化Llama 3.1 70B (4) Evaluate金标准对比。TCGA病理报告87%准确率。[来源: nature.com + github.com/KatherLab/LLMAIx]

5. **Grammar Builder 是关键创新** — JSON schema约束LLM输出格式，确保结构化一致性。VRAM从139GB降至43GB（4-bit量化），单卡A100/H100可运行。[来源: nature.com]

6. **角色化LLM框架效果提升2-3倍** — 3个专业化角色分别抽取不同维度，Llama-3.3-70B在608份健康食品政策上精确匹配率44.16%（基线19-27%）。[来源: arxiv.org/html/2604.01529v1]

7. **CREFT: 顺序多agent角色关系抽取** — 每个agent负责一个维度（关系类型、强度、时间演化）。与角色化框架思路交叉验证。[来源: arxiv.org]

8. **对话式多维关系抽取** — 从角色对话中提取情感、权力、亲疏等维度。传统纯叙述文本抽取会遗漏大量信息。[来源: arxiv.org/abs/2507.04852]

9. **用户novel-db MCP已有distillation_evolve工具** — 结合Grammar Builder+角色化架构可增强：(a) 添加JSON schema约束 (b) 角色化prompt模板 (c) 结构化存储。[来源: memory搜索]

### 💡灵感

1. **Grammar Builder模式可移植** — 定义WorldSetting schema（continent, powerSystem, culturalNorms, historicalEvents），让LLM按schema填充，保证输出一致性。

2. **"角色化agent分工"是核心架构决策** — "世界观架构师"（设定/体系）+"人物传记作者"（角色/关系）+"叙事分析师"（情节/主题），比通用prompt效果提升2-3倍。

3. **4-bit量化使本地70B模型可行** — Llama 3.1 70B量化后43GB VRAM，A100单卡可运行。小说蒸馏不必实时响应，本地大模型完全可行。

4. **Claude Projects RAG是最简方案但有天花板** — 适合"查原文"，蒸馏适合"建知识库"，两者互补。

5. **novel-db MCP + Grammar Builder + 角色化是最佳组合** — 已有基础设施 + 论文验证的方法论。

### 知识空白

1. GitHub上无公开"novel distillation"高星项目
2. novel-db MCP架构细节未知（用户自建）
3. 百万字级分块策略缺乏实验数据
4. 小说蒸馏效果评估标准缺失
5. FTS5 vs 向量搜索对小说语义检索效果对比无数据
