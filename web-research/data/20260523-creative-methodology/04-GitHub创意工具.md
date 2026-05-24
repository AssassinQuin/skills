# GitHub 创意工具实现调研

---

## 1. creative-ideation（yogsoth-ai）— 最全面的AI创意引擎

**URL**: https://github.com/yogsoth-ai/creative-ideation
**规模**: 188个skill目录 / 287个文件 / 99个子Agent SOP

### 10个Campaign（按问题类型组织）
1. **结构拆解** — SCAMPER + TRIZ + SIT
2. **跨域发现** — 双联想网络 + 类比迁移
3. **假设摧毁** — 公理否定 + 逆向头脑风暴
4. **仿生学** — Design Spiral + BioTRIZ
5. **共情术** — Gordon四种类比（直接/个人/象征/幻想）
6. **形态探索** — Zwicky box + 交叉一致性分析
7. **侧向思维** — de Bono PO + 概念扇
8. **组合创意** — Fauconnier-Turner概念融合
9. **视角强制** — 六帽子 + 角色模拟
10. **系统枚举** — 基准扫描 + 失败分类学

### 核心创新
- **按问题类型组织**（非按方法名称）→ AI路由更自然
- **量化创意管理**: State Ledger（创意预算底限）+ HARD-GATE（硬门槛）+ 饱和度检测
- **"只发散不收敛"原则**: 创意引擎和验证引擎严格分离

### 设计哲学
"创造力是系统化的，不是随机的"

---

## 2. K-Dense-AI/claude-scientific-skills — Claude Code Skill范式

**URL**: https://github.com/K-Dense-AI/claude-scientific-skills
**格式**: 标准SKILL.md（与我们的skill格式一致）

### 5阶段工作流
1. 理解上下文（开放提问）
2. 发散探索（6种技巧：跨领域类比/假设反转/尺度变换/约束增删/学科融合/技术推测）
3. 连接发现（找模式和关联）
4. 批判评估（可行性+创新性平衡）
5. 综合下一步（具体行动路径）

### 自适应技巧（按状态路由）
- 卡壳时 → 随机输入/跨领域类比
- 太保守时 → 假设反转/约束删除
- 能量低时 → 快速原型/简化任务

### 方法论参考文档
SCAMPER（7维度+科学案例）/ Six Hats / 形态分析 / TRIZ（10原理+矛盾矩阵+理想最终结果） / 仿生学5步 / PO挑衅 / 随机输入 / 假设反转 / 未来倒推法

---

## 3. brainstormers（Azzedde）— Web应用

**URL**: https://github.com/Azzedde/brainstormers
**技术栈**: Next.js 15 + React 19 + TypeScript + OpenAI API

### 实现的6种方法
大思维导图 / 逆向头脑风暴 / 角色风暴(Role Storming) / SCAMPER / 六顶思考帽 / 5W1H星爆法(Starbursting)

### 工程特点
- 每个方法独立模块，Prompt模板集中管理
- Session历史追踪 + 流式响应
- 成本控制：每次会话约$0.01-0.02

---

## 4. AutoTRIZ — 学术论文

**URL**: https://arxiv.org/abs/2403.13002
**期刊**: Advanced Engineering Informatics（已发表）

### 核心创新
LLM自动化TRIZ推理：用户输入问题描述 → 系统自动执行TRIZ推理 → 生成结构化解决方案报告

### 可扩展性
作者明确指出可扩展到SCAMPER、Design Heuristics、Design-by-Analogy等方法

---

## 5. 与我们16工具的对比

### 我们的优势（其他项目未覆盖）
| 工具 | 类型 | 独特性 |
|------|------|--------|
| 多米诺因果链 | 叙事结构 | 专属小说因果链工具 |
| 虚假胜利 | 叙事结构 | 中点反转机制 |
| 延迟引爆 | 叙事结构 | 契诃夫之枪变体 |
| 代价守恒律 | 世界观张力 | 等价交换原则 |
| 潜台词冰山 | 对话深度 | 三层对话结构 |
| POV透镜过滤 | 视角叙事 | 多视角偏见融合 |

### 建议从GitHub项目借鉴
1. **Campaign路由架构**（creative-ideation）→ 按问题类型而非方法名组织
2. **饱和度检测**（creative-ideation）→ 量化头脑风暴底限
3. **自适应卡壳策略**（K-Dense）→ 三种状态应对方案
4. **SCAMPER领域适配**（K-Dense）→ 7维度+小说创作案例
5. **Gordon共情术**（creative-ideation Campaign 5）→ 角色动机深度工具
6. **仿生学5步法**（K-Dense）→ 异灵/世界观生物设计
