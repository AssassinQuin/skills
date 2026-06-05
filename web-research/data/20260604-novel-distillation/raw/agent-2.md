## Agent 2 — 主题: RAG 分块策略 + 超长上下文模型

### 搜索 Query
- RAG chunking strategy 分块 语义 结构
- 长文档 RAG 分块 检索 策略
- DOS RAG 斯坦福 长文档 基线
- MiA-RAG 全局大脑 全景 记忆
- 百万 token 上下文窗口 Gemini Claude 对比
- long context LLM infrastructure million token
- 1M token context window vs RAG benchmark
- RAG 2026 全景 演进 Agentic

### 降级日志
- [搜索] WebSearch 权限拒绝 x5 → 降级到 searxng_web_search
- [提取] searxng_web_url_read 权限拒绝 x2 → 降级到 webReader

### 搜索结果
- [DOS RAG arXiv](https://arxiv.org/html/2506.03989v2) — Stanford EMNLP 2025, 保持文档原始结构碾压复杂pipeline
- [MiA-RAG arXiv](https://arxiv.org/abs/2512.17220) — 中科院+腾讯微信AI, 分层心智景观摘要
- [Agentic RAG综述](https://arxiv.org/html/2501.09136v4) — 第四代RAG范式演进
- [1M vs RAG对比](https://www.mindstudio.ai/blog/1m-token-context-window-vs-rag-claude/) — MindStudio实测
- [AI上下文对比2026](https://www.digitalapplied.com/blog/ai-context-window-comparison-2026-1m-to-10m-tokens) — 5个模型1M+, 有效容量60-70%
- [长上下文基础设施](https://introl.com/blog/long-context-llm-infrastructure-million-token-windows-guide) — 生产级方案
- [MRCR v2基准](https://yage.ai/share/long-context-benchmark-en-20260315.html) — Claude Opus 4.6@1M=76%, GPT-5.4=36.6%, Gemini=16.4%
- [Gemini实测](https://cloud.tencent.com/developer/article/2673693) — 8万字以上Gemini几乎唯一选择
- [RAG全景2026](https://cloud.tencent.com.cn/developer/article/2654878) — 5代技术演进+落地选型
- [Weaviate分块](https://weaviate.io/blog/chunking-strategies-for-rag) — 5种分块策略详解

### 核心要点

1. **DOS RAG：保留原文结构碾压复杂pipeline** — Stanford EMNLP 2025(arXiv:2506.03989)。保持文档原始段落顺序的简单retrieve-then-read方法，在infinityBench上比ReadAgent、RAPTOR等复杂pipeline高2-8个点。小说蒸馏不应过度碎片化，按原始章节结构保留上下文比切成小块再重组效果更好。[来源: arxiv.org/html/2506.03989v2]

2. **MiA-RAG：三级心智景观摘要** — 中科院+腾讯微信AI(arXiv:2512.17220)。先建分层摘要（全局→局部→段落三级），形成"心智景观"，检索时同时检索原文和对应层级摘要。14B模型击败72B基线。映射到小说：全书摘要(世界观大纲)→卷摘要(大事件线)→章摘要(情节细节)。[来源: arxiv.org/abs/2512.17220]

3. **分块策略实证** — 语义分块比固定分块仅提升3-5%；分块大小影响远大于分块方法（512→1200 tokens比semantic vs fixed差异更大）；叙事文本宜用大块保留连贯性。小说建议：按章节分块+500-1000词重叠。[来源: Weaviate+多源benchmark]

4. **Agentic RAG：2026第四代范式** — arXiv:2501.09136综述。演进：Naive→Advanced→Modular→Agentic。引入自主agent具备规划、反思、工具使用能力。映射：编排"世界观提取agent""人物关系agent""情节分析agent"协同工作。[来源: arxiv.org/html/2501.09136v4]

5. **Lost in the Middle问题** — Stanford/UW 2023基础论文。LLM对长文本中间位置信息检索可靠性显著下降。百万字小说关键设定若出现在中段，RAG可能遗漏。MiA-RAG分层摘要+DOS RAG原始顺序保留可部分缓解。

6. **1M token ≠ 1M token可靠检索** — MRCR v2基准(yage.ai 2026.3)：Claude Opus 4.6@1M可靠率76%, GPT-5.4仅36.6%, Gemini 2.5 Pro仅16.4%。上下文窗口大小与实际可靠检索能力是两回事。[来源: yage.ai]

7. **Gemini 1M测试：RAG仍不可替代** — MindStudio实测：1M窗口适合"偶尔查一次大文档"，成本$0.15/1M tokens/call，延迟30s+。RAG在频繁查询场景下成本/延迟碾压纯长上下文。[来源: mindstudio.ai]

8. **混合架构成生产默认** — RAG检索相关段落(高效低成本)→长上下文模型做综合分析(利用推理能力)。比纯RAG(上下文太少)和纯长上下文(成本太高)都更好。[来源: MindStudio+TowardsAI+社区多方确认]

9. **2026 RAG技术全景** — 5代演进：Naive RAG→Advanced RAG→Modular RAG→Graph RAG→Agentic RAG。GraphRAG通过知识图谱增强全局理解能力，解决传统RAG"只能检索局部片段"的问题。斯坦福DOS-RAG重设基线：简单方法+原始结构保持=最优解。[来源: cloud.tencent.com.cn]

10. **上下文窗口实际对比** — 5个模型支持1M+(Gemini 2.5 Pro 2M, Claude Sonnet 4/Opus 4.6 1M, Qwen2.5-1M, Llama 4 Scout 10M)。有效容量仅为广告值的60-70%。处理1M token：Gemini 3.1 Pro $2.00, Claude Opus 4.6 $5.00(2.5倍溢价)。[来源: digitalapplied.com]

### 💡灵感

1. **DOS RAG + MiA-RAG互补** — 保留原始章节文本(DOS)+构建三级摘要支架(MiA的全局/卷/章)，检索时同时命中原文和摘要。

2. **LazyGraphRAG按需深入** — 先建实体图骨架，感兴趣部分按需深入蒸馏，避免全量索引成本。

3. **Grammar Builder + 角色化Agent = 最佳架构** — JSON schema约束确保一致性，角色化分工提升2-3倍。

4. **Claude Projects RAG 10倍扩展是最快验证路径** — 先上传测试内置RAG效果，验证后再投入GraphRAG全量蒸馏。

### 知识空白

1. 小说专用分块策略缺乏实验数据
2. 虚构文本实体抽取准确率无基准
3. 动态实体状态追踪方案空白
4. 百万字蒸馏token成本无公开估算
5. 小说蒸馏效果评估标准缺失
6. FTS5 vs 向量搜索对小说语义检索效果无对比数据
