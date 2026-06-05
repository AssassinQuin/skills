# Agent 3 — 主题: 子Agent任务路由精度 + 学术研究

调研时间：2026-05-31
模型：sonnet | 工具调用：23次 | 耗时：237s

## 搜索 Query

- "Anthropic effective context engineering sub-agent routing accuracy"
- "AOrchestra sub-agent creation orchestration arxiv"
- "AdaptOrch task-adaptive multi-agent orchestration LLM performance convergence"
- "critique routing LLM agent evaluate route arxiv"

## 搜索结果

- [Anthropic: Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — 上下文工程方法论
- [Anthropic: Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) — 5种Agent工作流模式
- [AOrchestra论文](https://arxiv.org/abs/2602.03786) — 4元组Phi=<I,C,T,M>动态子Agent创建
- [AdaptOrch论文](https://arxiv.org/abs/2602.16873) — Performance Convergence Scaling Law
- [Critique-and-Routing论文](https://arxiv.org/abs/2605.08686v1) — 有限期MDP批评-路由控制器
- [AgentOrchestra](https://openreview.net/forum?id=YcnKdeI9pp) — 层次化多Agent编排
- [LLM-AT (ACL 2025)](https://arxiv.org/abs/2502.04575) — 无训练LLM自动化测试

## 提取要点

### 1. Anthropic官方：Context Engineering 5种生产模式

| 模式 | 原理 | 适用场景 |
|------|------|---------|
| Compaction（压缩） | 摘要早期对话 | 中等复杂度任务 |
| Sub-agents（子代理） | 独立context window探索 | 深度探索型复杂任务 |
| Hybrid Retrieval（混合检索） | RAG+上下文 | 知识密集型任务 |
| Structured Context（结构化上下文） | 强制输出格式 | 需要精确输出的任务 |
| Context Window Management | 窗口管理策略 | 超长对话 |

关键概念：
- **Context Rot（上下文腐化）**：随对话轮次增加，LLM对早期信息注意力衰减。通过结构化笔记对抗。
- **Attention Budget**：模型对context中间位置注意力最低。子Agent模式间接规避此限制。

[来源: Anthropic工程博客, 2025]

### 2. AOrchestra: 4元组Phi=<Instruction, Context, Tools, Model>

**核心贡献**：框架无关的动态子Agent创建抽象。

| 维度 | 说明 | 示例 |
|------|------|------|
| Instruction | 任务指令 | "研究X框架的路由机制" |
| Context | 上下文 | 前序任务结果+领域知识 |
| Tools | 可用工具集 | WebSearch+Read+Grep |
| Model | 模型选择 | haiku(搜索)/sonnet(分析)/opus(决策) |

**Benchmark数据**：
- GAIA: 80% pass@1
- SWE-Bench: 82%
- Terminal-Bench: 52.86%
- 相对最强基线提升: 16.28%
- SFT数据提升编排质量: +11.51%

**模型分层经济**：Orchestrator用顶级模型（Claude Opus），子Agent用中低端（Haiku），10-50x成本差距使路由精度直接影响成本。

[来源: arXiv 2602.03786, 2025-02]

### 3. AdaptOrch: Performance Convergence Scaling Law

**核心公式**：Var_τ / Var_M >= Ω(1/ε²)

当目标精度ε→0时，编排拓扑优化价值超过模型选择优化价值。

**4种经典拓扑**：
| 拓扑 | 适用场景 | 特征 |
|------|---------|------|
| Parallel | 独立子任务 | 最快完成 |
| Sequential | 有依赖的任务链 | 严格顺序 |
| Hierarchical | 层次化分解 | 管理复杂度 |
| Hybrid | 混合依赖 | 灵活但复杂 |

**关键数据**：
- 拓扑路由器准确率: 81.2%
- SWE-Bench改进: 22.9%
- 路由开销: <50ms（远低于LLM推理2-15s/次）

💡启示：追求高精度时，优化编排拓扑比换更强模型更重要。

[来源: arXiv 2602.16873, 2025-02]

### 4. Critique-and-Router: 80.5%路由准确率

**核心机制**：Controller同时执行批评（评估路由正确性）和路由（选择子Agent）。
**建模**：有限期MDP，状态=任务描述+已完成步骤，动作=路由决策。
**训练**：GRPO + 拉格朗日松弛优化。
**结果**：路由准确率80.5%/82.3%，最强子Agent使用比例<25%。

**关键结论**：即使不用复杂RL训练，良好的路由prompt（含few-shot+结构化输出）也能达75%+准确率。

[来源: arXiv 2605.08686, 2025-05]

### 5. Anthropic Routing模式实践建议

- 路由分类器使用简单模型即可（路由决策不需要复杂推理）
- Evaluator-Optimizer循环可纠正路由错误（端到端精度 > 路由器精度）
- 不要过度复杂化："简单好提示90%准确率时，Agent系统只需处理剩余10%"
- 过度工程化的Agent系统可能引入更多compounding error

[来源: Anthropic "Building Effective Agents"]

### 6. 路由精度的经济影响

**非对称损失函数**：
- **上路由（under-routing）**：把简单任务分配给强模型 → 浪费金钱（10-50x成本差距）
- **下路由（over-routing）**：把复杂任务分配给弱模型 → 质量下降（不可恢复）

下路由的损失远大于上路由，因此路由器应该偏向保守（宁可多花钱也不可丢质量）。

[来源: AOrchestra + AdaptOrch综合分析]

## 💡灵感

- **AOrchestra的SFT发现**：编排质量可通过少量expert轨迹大幅提升（+11.51%）。对books_creater的启示：收集高质量写作编排轨迹可以训练路由器
- **AdaptOrch的Scaling Law**：追求高精度（小说写作质量）时，优化skill编排拓扑比升级模型更重要。与其换Claude Opus，不如优化skill间调用顺序
- **Critique-and-Router的few-shot方案**：不需要复杂训练，在路由prompt中加入few-shot示例就能达75%+准确率。可直接应用于Agent工具的prompt参数

## ⚠️ 知识空白

- AgentOrchestra的共享状态空间具体实现（OpenReview页面提取不完整）
- LLM-AT的无训练路由方案细节（ACL 2025论文全文未提取）
- AOrchestra的GitHub仓库（github.com/FoundationAgents/AOrchestra）具体代码结构
