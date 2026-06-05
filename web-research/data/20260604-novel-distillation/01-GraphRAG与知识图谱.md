# 01-GraphRAG与小说知识图谱蒸馏

## 一、微软 GraphRAG Pipeline 全流程

微软 GraphRAG（GitHub 15.9K stars）源自 Microsoft Research 论文《A GraphRAG Approach to Query-Focused Summarization》(arXiv:2404.16130, 2024年)。Pipeline分两大阶段：

**索引阶段**：
1. 文本分块（默认600 tokens/chunk，300 overlap）
2. LLM 提取实体、关系、claims（每个chunk独立调用LLM）
3. Leiden 社区检测算法对实体图做层次化聚类
4. 对社区层次结构递归生成多粒度摘要（从叶子社区到根社区）
5. 向量嵌入写入向量存储
6. 输出格式为 Parquet 表

**查询阶段**：
1. 用户问题 → 在社区摘要上生成 partial response
2. Map-reduce 汇总所有 partial response 为最终回答
3. 支持全局查询（Global Search）和局部查询（Local Search）

**成本警告**：官方明确标注 "indexing can be an expensive operation"。全量索引百万字小说的token消耗可能达到数百万级别。社区fork `TheAiSingularity/graphrag-local-ollama` 提供本地模型替代方案。[来源: github.com/microsoft/graphrag, arxiv.org/abs/2404.16130]

## 二、中文网文 GraphRAG 实操案例

### 2.1 仙逆全本 GraphRAG 蒸馏

知乎博主 Mountain（ID: mountain-kylin）以耳根网文《仙逆》全本为输入：
- **使用模型**：DeepSeek deep-seek-chat（免费500万Token，128K上下文，max_tokens需设4096）
- **流程**：微软 GraphRAG 索引 → 实体/关系提取 → 导入 Neo4j 可视化
- **成果**：成功提取"王林""铁柱"等核心人物实体及关系，社区按特定事件聚类，地点实体可展开查看关联人物和文本单元
- **配套**：含完整 Cypher 代码，可复现
- [来源: zhihu.com/p/711511272]

### 2.2 凡人修仙传知识图谱

B站视频"AI开发者-就爱瞎鼓捣"展示 GraphRAG 对《凡人修仙传》生成的知识图谱可视化结果：
- **数据**：播放量19033、点赞457、收藏843
- **配套教程**："喂饭教程：GraphRAG+Neo4j打造基于知识图谱的本地知识库"也以凡人修仙传为例
- [来源: bilibili.com/video/BV1rr421T7jA/]

### 2.3 红楼梦 GraphRAG

知乎文章（716388476）和百度智能云文章（3373401）均以《红楼梦》为案例展示 GraphRAG 构建。[来源: zhihu.com/p/716388476, cloud.baidu.com/article/3373401] ✅ 双源确认

## 三、GraphRAG 对虚构文本的特殊挑战

微软 GraphRAG 官方 issue #1389 详细讨论了虚构文本适配问题：

| 挑战 | 具体表现 | 影响 |
|------|---------|------|
| 人物多别名 | 王林/铁柱/老怪/曾牛 | 同一实体被拆分为多个节点 |
| 虚构地名NER失败 | 修仙界的洞府/秘境名 | 关键地点实体遗漏 |
| 关系动态变化 | 敌人→盟友、师傅→对手 | 静态关系图无法表达 |
| 中文prompt不优化 | 默认prompt针对英文新闻 | 实体类型分类错误 |

**解决方案**：需按小说类型定制 entity-extraction prompt，定义类型专属实体类别（如修仙类：境界/法宝/功法/门派）和关系类型（师徒/道侣/宿敌/同门）。[来源: github.com/microsoft/graphrag/issues/1389]

## 四、Neo4j LLM Graph Builder 评估

### 4.1 功能全景

- **输入源**：本地文件(.docx/.pptx/.xls/.pdf/.jpeg/.png/.html/.txt/.md)、Web链接(YouTube字幕/Wikipedia/网页)、云存储(AWS S3/GCS)
- **LLM模型**：OpenAI GPT-3.5/4o、VertexAI Gemini、Anthropic、Bedrock、Ollama/Groq
- **Schema**：预定义/自定义/从已有数据库获取/自动推断
- **可视化**：词汇图、实体图、完整知识图谱三种模式
- **检索**：向量+全文混合搜索 → 2-hop实体关系扩展 → LLM生成回答

### 4.2 已知局限（Reddit r/Rag 社区反馈）

1. **孤岛节点**：提取后部分实体只与text chunks相连、不与其他实体相连
2. **LLM质量差异**：GPT-4o效果明显好于GPT-3.5
3. **中文准确率低**：中文实体提取准确率低于英文
4. **Schema适配差**：自动推断的schema偏向真实世界实体类型，对虚构世界观适配差
5. **2-hop限制**：对复杂小说关系链（修仙门派/师徒/宿敌链）可能不足，需3-5跳

[来源: neo4j.com/labs/genai-ecosystem/llm-graph-builder-features/, reddit.com/r/Rag/]

## 五、LazyGraphRAG：按需蒸馏策略

LazyGraphRAG 跳过索引时的社区摘要生成，改为查询时按需生成。优势：
- 索引阶段成本大幅降低（只需实体/关系提取，跳过最贵的社区摘要步骤）
- 对百万字连载小说，可以先建立实体图骨架
- 对感兴趣的部分"按需深入蒸馏"，渐进式构建知识图谱
- 与"渐进式蒸馏"理念天然契合

[来源: github.com/microsoft/graphrag 社区讨论]

## 六、Neo4j官方GraphRAG检索策略

Neo4j提供了官方Python包 `neo4j-graphrag`，检索流程：
1. 向量+全文混合搜索找到最相关chunks
2. 沿实体关系扩展2跳（2-hop traversal）
3. 将问题+向量结果+实体(名称+描述)+关系对+聊天历史送入LLM

**对小说场景的局限**：2-hop遍历可能不足以捕获复杂关系链（A认识B，B与C师徒关系，C与D宿敌...），需要3-5跳或路径查询。[来源: neo4j.com/labs/]

## 七、学术研究：从小说提取社会网络

- Diva-Portal论文《From literature to relationship network》(2024)：研究实体关系抽取模型能否创建可手动改进的综合社会模型
- PMC论文《Evaluating named entity recognition tools for extracting social networks from novels》(2021)：系统评估多种NER工具从小说中自动提取社会网络的效果
- GraphAware（Neo4j生态公司）2017年博客"Reverse engineering book stories with Neo4j and GraphAware NLP"：最早将Neo4j+小说结合的实践

[来源: diva-portal.org, pmc.ncbi.nlm.nih.gov/articles/PMC7924459/, graphaware.com]
