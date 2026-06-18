# Skill 深度调研：让 skill 从"流程合规"到"专业深度"

**日期**: 2026-06-18
**触发**: 用户反思 skill-evolver 产出流程化但缺专业深度，对比 harness/huashu-nuwa/darwin-skill
**方法**: web-research（论文 agent + 方法论灵感 agent + 开源 skill 主 agent 补）
**预算**: 30 tool calls 实际 ~25（开源 agent 因 API 529 中断，主 agent 补）

---

## 一、核心结论（先看这里）

**用户的痛点不是新问题，学术界和工业界已有成熟解法**。三个关键洞察：

1. **Skill 深度 ≠ 流程优化**。skill-evolver (SkillEvolver 论文) 是 robustness 优化器，深度问题要靠**专家知识 codify + 反推失败模式**。
2. **Anthropic 官方反 monolithic**：build micro-skills that chain + always hand-edit。当前 34 个 skill + 全自动 evolver 是错的方向。
3. **ECC `rules-distill` + `skill-stocktake` 已实现我们想要的功能**，且 stars 217k。可直接借鉴架构。

**最小可行方案**（建议路径）：
- 短期：借鉴 ECC `rules-distill` 升级 skill-evolver v8.2，加"专家知识 codify"维度
- 中期：新建 `skill-deepener`（基于 Anthropic evaluation-first 反推法）
- 长期：拆 monolithic skill 成 micro-skill 链（按 Anthropic 最佳实践）

---

## 二、论文发现（7 篇，按可借鉴度排序）

### 1. ⭐⭐⭐ Codified Human Expertise（arXiv:2601.15153）

**最贴痛点**。把领域专家知识显式 codify 进 LLM agent，减少 expert bottleneck。

- **核心方法**：从专家知识到 prompt/skill 的结构化迁移流程
- **解决什么**：直击"流程合规但缺专业深度" — 不是写流程，是 codify 真实专家判断
- **借鉴点**：skill-evolver 加"专家知识 codify 通道"，从真实项目踩坑 → references/

### 2. ⭐⭐⭐ Agent-as-a-Judge（arXiv:2508.02994）

- **核心方法**：agent 在评估中扮演 domain expert / critic / defender 多角色
- **解决什么**：9-check Auditor 全是反过拟合，没"专业度"评估
- **借鉴点**：升级 auditor 为多专家角色评审（方法论严谨性 / 案例真实性 / 领域准确性 三角色）

### 3. ⭐⭐⭐ Agent Skills 综述（arXiv:2602.12430）

- **核心方法**：7 个开放挑战 + skill 获取方法分类法
- **解决什么**：提供"专业 skill 应具备哪些维度"的地图
- **借鉴点**：taxonomy 可作为 auditor 第 11-check（内容深度）的评分维度

### 4. ⭐⭐ Voyager（arXiv:2305.16291, NeurIPS 2023）

- **核心方法**：三组件（自动课程 + 可执行代码 skill library + 迭代 prompt）
- **借鉴点**：skill 不只是文本流程，是可执行可复用单元

### 5. ⭐⭐ Reflexion（arXiv:2303.11366）

- **核心方法**：语言反馈存入 episodic memory，不更新权重
- **借鉴点**：skill-evolver 已有 FM1-FM7 雏形，可升级为 references/ 失败案例库

### 6. ⭐ SAGE（arXiv:2512.17102）

- **核心方法**：RL 从 skill library 选 skill 自我改进
- **借鉴点**：与 SkillEvolver 互补，但偏运行时调度非内容深化

### 7. ⭐ SkillsBench（arXiv:2602.12670）

- **核心方法**：Harbor 框架跨任务 skill 增效基准
- **借鉴点**：held-out validate 应覆盖多任务而非单 prompt

---

## 三、开源 Skill 发现（4 个高价值）

### 1. ⭐⭐⭐ andrej-karpathy-skills（177k stars）

**单 CLAUDE.md 80 行，极致 micro-skill**。无目录结构、无 references、无 Phase 流程。

4 条核心原则：
- Think Before Coding（暴露假设，不静默选）
- Simplicity First（"Would a senior engineer say overcomplicated?"）
- Surgical Changes（"Every changed line should trace to user request"）
- Goal-Driven Execution（Define success criteria, loop until verified）

**借鉴点**：**深度不靠结构堆叠，靠专家语言精度**。每条原则都是专家"出声思考"，不是流程模板。

### 2. ⭐⭐⭐⭐⭐ affaan-m/ECC（217k stars）

**198 个 micro-skill 目录**。每 skill 聚焦单一垂直领域：
- healthcare-phi-compliance / hipaa-compliance
- quarkus-tdd / django-security / defi-amm-security
- skill-stocktake / rules-distill / prompt-optimizer

**金矿**：内部有 `rules-distill` + `skill-stocktake` 直接实现我们想要的功能。

### 3. ⭐⭐⭐⭐⭐ ECC `rules-distill`（必读）

**直接对应我们的痛点**。三阶段：

```
Phase 1: Inventory（脚本收集所有 skills + rules）
Phase 2: Cross-read + Match + Verdict（LLM 跨读 → 抽取 cross-cutting principles → 6 verdicts）
Phase 3: User Review（never auto-modify rules）
```

**6 种 verdict**：
- Append / Revise / New Section / New File / Already Covered / Too Specific

**3 层防抽象过滤**（关键）：
1. **2+ skills 证据**（单一 skill 内的 principle 留 skill 内）
2. **可操作行为变化**（"do X" / "don't do Y"，非"X is important"）
3. **清晰违反风险**（忽略这条会出什么问题，1 句话）

**核心设计原则**：
- **What, not How**：principles 进 rules，代码示例留 skill
- **Link back**：rule 含 `See skill: [name]` 反向引用
- **Deterministic collection, LLM judgment**：脚本保证穷尽，LLM 保证理解

**借鉴点**：升级 skill-evolver v8.2 加"principles 提取"维度。当前 axes 来自单 skill 复盘，缺 cross-skill 共性提取。

### 4. ⭐⭐⭐⭐ ECC `skill-stocktake`

**Skill 库审计**。两种模式：
- Quick Scan（仅改动 skill，5-10 分钟）
- Full Stocktake（全库，20-30 分钟）

**4 维 holistic 判断**（**不是 numeric rubric**）：
- Actionability（能否立即行动）
- Scope fit（name/trigger/content 对齐）
- Uniqueness（vs MEMORY.md / CLAUDE.md / 其他 skill）
- Currency（技术参考是否过期）

**5 种 verdict**：Keep / Improve / Update / Retire / Merge into [X]

**借鉴点**：darwin-skill 的 8 维 rubric + ECC 的 holistic 判断，可合成新版 auditor。

---

## 四、方法论（3 个）

### 方法 1: ⭐⭐⭐ Cognitive Apprenticeship 提示词嵌入

来源：Collins/Brown/Newman 1989 → Koblic 2024

**四要素写进 prompt**：
- **Modeling**（专家出声思考 — 为什么这样判断）
- **Coaching**（练习时反馈）
- **Scaffolding**（搭脚手架）
- **Fading**（逐步撤支撑）

**应用**：SKILL.md 分两段 — (a) "专家心智模型"段（隐性判断标准）；(b) "脚手架问题"段（执行前反问用户 1-2 个澄清题）。

**反例**：当前 SKILL.md 全是 Phase 流程，无"专家出声思考"段。

### 方法 2: ⭐⭐ Prompt Distillation（arXiv:2412.14964）

**用 teacher LLM 提取决策规则 + contrastive loss 过滤冗余**。

**应用**：skill-evolver 加"规则蒸馏"步骤 — references/ 全文喂 opus，输出"决策规则集"，held-out 题做 contrastive 过滤（保留能改答案的规则）。

**解决**：SKILL.md 膨胀（多个 >1000 行）。

### 方法 3: ⭐⭐⭐ Anthropic 反推法（evaluation-first）

来源：https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills

**"Start with evaluation"** — 先收集 agent 失败的真实任务，从失败模式反推该注入什么专家知识。

**应用**：skill-evolver 加"反推通道" — Domain-Skill Agent 跑一批真实任务 → 记录失败 case → evolver 从失败 case 萃取缺什么专家规则 → 定向补 references/。

**比当前"通用 evolve"高效得多**。

---

## 五、💡 灵感（3 个）

### 灵感 1: ⭐⭐⭐ Skill 路由没有算法，纯靠 description 语义匹配

来源：Han Lee 拆解 https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/

**反常识**：Anthropic Skill 系统底层**没有 embedding、没有 classifier、没有 regex**。skill 选择完全在 Claude forward pass 里，靠 description 文本与用户 query 的语义匹配。

**含义**：**description 字段是唯一营销渠道**。SKILL.md 写得再有深度但 description 平庸就永远不被调用。

**启示**：skill-evolver 评分应给 description 字段单独权重（≥30%）。深度 9 分 + description 5 分 = 实际效果 0 分。

### 灵感 2: ⭐⭐ 结构化 prompt 在反直觉指令上更强

来源：ACL WASP 2025

**反常识**：结构化输出（JSON schema）在反直觉指令场景反而显著提升 LLM 遵守度。

**机制**：schema 强制模型停下来处理约束，降低"惯性滑入常识答案"。

**启示**：对反直觉任务（金融合规、风控、安全审计），强制 skill 输出结构化字段（如"风险等级 / 证据 / 反证"三段式）。fin-code-review 这类 skill 可验证。

### 灵感 3: ⭐⭐⭐ Anthropic 官方反 monolithic

来源：r/ClaudeAI 讨论 + https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

**反工程直觉**：Anthropic 明确建议 **build small focused micro-skills that chain together, instead of one giant monolithic skill** + **Always hand-edit the model output**。

**张力**：与当前 34 个 monolithic skill + 全自动 evolver 的现状冲突。

**启示**：skill-evolver 评分应惩罚过长 SKILL.md（>500 行扣分）。完全自动化 evolver 有上限，最优是 evolver 起草 + 人工 review。

---

## 六、关键张力（必须用户决策）

| 路线 | 特征 | 适合 |
|------|------|------|
| **A. Micro-skill 拆分** | 单 skill <300 行，组合使用 | 跟随 Anthropic 官方，长期可维护 |
| **B. 保持 monolithic + 强化深度** | 单 skill 500+ 行，靠 description + 反推通道 | 短期改动小，长期违背官方 |

**禁止混合**（按用户 coding-rules R7）。建议在 skill-evolver 下次迭代前明确选 A 或 B。

---

## 七、给 skill-evolver v8.2 的具体改进（可操作）

### 优先级 P0（必修）

1. **加 Check 11: 内容深度**
   - references 是否含真实案例（不是空泛描述）
   - 是否有可操作判断标准（"do X" / "don't Y"，非"X 重要"）
   - 是否有具体方法论（不是抽象指导）

2. **加 Check 12: description 单独权重**
   - description 是否含具体触发场景
   - description 是否有"do/don't"边界
   - 单独评分（≥30% 权重）

3. **加"专家知识 codify"通道**（借鉴 Codified Human Expertise）
   - Domain-Skill Agent 不只测流程，记录"专家会怎么判断"
   - 失败 case 萃取为 references/ 失败案例库

### 优先级 P1（应修）

4. **加 cross-skill principles 提取**（借鉴 ECC rules-distill）
   - 3 层过滤（2+ skills evidence / actionable / violation risk）
   - 输出 rules/ 而非只动 SKILL.md

5. **Auditor 升级为多专家角色**（借鉴 Agent-as-a-Judge）
   - 方法论严谨性角色
   - 案例真实性角色
   - 领域准确性角色

6. **加"反推通道"**（借鉴 Anthropic evaluation-first）
   - Phase 0 收集失败 case
   - Phase 1 axes 从失败 case 反推（非用户痛点）

### 优先级 P2（优化）

7. **加 SKILL.md 行数惩罚**
   - >500 行扣分
   - >1000 行强制拆分建议

8. **加"hand-edit 强制"**
   - evolver 输出后必须人工 review
   - 完全自动 commit 标注 `⚠️ UNVERIFIED-HUMAN`

---

## 八、新建 `skill-deepener` skill 建议

填补 skill-evolver 的盲区。专门做"内容深化"：

```
输入: 已有 skill（结构合规但内容空）
过程:
  Phase 1: 识别内容缺口（用 ECC skill-stocktake 4 维度）
  Phase 2: 调研补内容（web-research + huashu-nuwa 蒸馏 + memory 历史经验）
  Phase 3: Cognitive Apprenticeship 重写（专家出声思考段 + 脚手架问题段）
  Phase 4: Anthropic 反推验证（Domain-Skill Agent 跑真实任务 → 失败 case 反推）
输出: 内容深化的 skill（结构归 skill-evolver，不动）
```

与 skill-evolver 互补：
- `skill-deepener` = 内容深化（专业度）
- `skill-evolver` = 结构合规（鲁棒性）

---

## 九、知识空白（搜索 0 结果或失败）

- ❌ 开源 skill agent 因 API 529 中断，仅完成部分（主 agent 用 github 搜索补 4 个高 stars 候选）
- ❌ `knowledge distillation into prompt` query 因 529 未完成（Distilling Step-by-Step / PaD 可能相关）
- ❌ SearXNG 对学术 query 失效（返回 arxiv 首页），降级 WebSearch + github search

---

## 十、信息源列表

### 论文
1. [Voyager (arXiv:2305.16291)](https://arxiv.org/abs/2305.16291)
2. [SAGE (arXiv:2512.17102)](https://arxiv.org/abs/2512.17102)
3. [Agent Skills 综述 (arXiv:2602.12430)](https://arxiv.org/html/2602.12430v4)
4. [Codified Human Expertise (arXiv:2601.15153)](https://arxiv.org/html/2601.15153v1)
5. [Reflexion (arXiv:2303.11366)](https://arxiv.org/abs/2303.11366)
6. [Agent-as-a-Judge (arXiv:2508.02994)](https://arxiv.org/html/2508.02994v1)
7. [SkillsBench (arXiv:2602.12670)](https://arxiv.org/html/2602.12670v1)
8. [Prompt Distillation (arXiv:2412.14964)](https://arxiv.org/html/2412.14964v1)
9. [ACL WASP 2025 - Counterintuitive Instructions](https://aclanthology.org/2025.wasp-main.13.pdf)

### 开源 Skill
10. [andrej-karpathy-skills (177k stars)](https://github.com/multica-ai/andrej-karpathy-skills)
11. [affaan-m/ECC (217k stars, 198 skills)](https://github.com/affaan-m/ECC)
12. [ECC rules-distill](https://github.com/affaan-m/ECC/blob/master/skills/rules-distill/SKILL.md)
13. [ECC skill-stocktake](https://github.com/affaan-m/ECC/blob/master/skills/skill-stocktake/SKILL.md)

### 方法论/博客
14. [Anthropic Equipping Agents](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
15. [Anthropic Skill Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
16. [Han Lee - Skill First Principles Deep Dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
17. [Cognitive Apprenticeship in AI Prompt](https://edtechbooks.org/promptbook/from-model-to-mentor)
18. [Cognitive Apprenticeship Original (Collins/Brown/Holum)](https://www.aft.org/ae/winter1991/collins_brown_holum)
19. [r/ClaudeAI Anthropic 32-page skill guide discussion](https://www.reddit.com/r/ClaudeAI/comments/1r3hr40/)
