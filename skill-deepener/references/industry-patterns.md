# Industry Patterns（行业论文 + 轮子吸收清单）

调研来源（2026-06-18 [web-research/data/20260618-skill-depth-research/](../../web-research/data/20260618-skill-depth-research/)）的 12 个来源，每个含**可操作吸收内容**（不是简单引用，是垂直化到具体步骤）。

---

## 来源 1: andrej-karpathy-skills (177k stars)

**标杆意义**：单文件 80 行用 4 原则证明"深度不靠结构堆叠，靠专家语言精度"。

**4 原则专家语言**（深化 SKILL.md 时对照标杆）：

| 原则 | 专家语言 | 反例（流程化） |
|------|---------|--------------|
| Think Before Coding | "State your assumptions explicitly. If uncertain, ask." | "理解需求" |
| Simplicity First | "Would a senior engineer say this is overcomplicated? If yes, simplify." | "保持简洁" |
| Surgical Changes | "Every changed line should trace directly to the user's request." | "外科手术式修改" |
| Goal-Driven Execution | "Transform 'Fix the bug' → 'Write a test that reproduces it, then make it pass'." | "目标驱动" |

**应用到 skill-deepener P4**：每条新增内容必须用专家语言写（含具体场景 + 反问），不能写抽象指导。

---

## 来源 2: Codified Human Expertise (arXiv:2601.15153)

**5 步专家知识 codify 流程**（P3 内容采集的标准流程）：

```
Step 1: Elicititation（专家知识获取）
  - 观察 expert 真实执行（P2 Domain-Skill Agent 轨迹）
  - 提问"你为什么这样判断"
  - 录下 expert 的边角案例推理

Step 2: Structuring（结构化）
  - 把 expert 口头知识转为 do/don't 规则
  - 每条规则附 trigger 条件 + violation risk

Step 3: Validation（验证）
  - 用 held-out case 测规则是否可证伪
  - expert 复核规则是否符合真实判断

Step 4: Injection（注入 SKILL.md）
  - 规则按 Phase 段落映射插入（见 SKILL.md P4 映射表）
  - 加 Modeling 标注（"💡 专家视角"）

Step 5: Verification（验证生效）
  - P5 多专家评审（领域准确者验证术语）
  - 后续 skill 使用时观察规则是否被实际触发
```

**应用到 skill-deepener P3-P4**：把这 5 步作为标准 codify 协议。

---

## 来源 3: ECC `rules-distill` 6 verdicts（必读）

**P4 输出格式标准化**（每条新增内容必须有 verdict）：

| Verdict | 含义 | 应用场景 |
|---------|------|---------|
| **Append** | 加到现有段落 | 现有 Phase 段缺细节，加 expert 视角 |
| **Revise** | 修正现有内容 | 现有规则不准确或不充分 |
| **New Section** | 加新段落 | 现有 Phase 缺脚手架问题段 |
| **New File** | 创建新 reference | 现有 references 缺案例库 |
| **Already Covered** | 已覆盖（不动） | 避免重复 |
| **Too Specific** | 留 skill 内不提升 | 单一 case，不够普适 |

**3 层防抽象过滤**（必须满足才出 verdict）：
1. **可操作行为变化**（"do X" / "don't Y"，非"X 重要"）
2. **清晰违反风险**（忽略这条出什么问题，1 句话）
3. **可证伪**（held-out case 能验证）

**应用到 skill-deepener P4**：每条改动输出 verdict + 3 层过滤证据。

---

## 来源 4: ECC `skill-stocktake` 5 verdicts

**P1 输出 verdict**（不是 numeric score，是行动 verdict）：

| Verdict | 含义 | P1 评分条件 |
|---------|------|-----------|
| **Keep** | 不需深化 | 全 6 维度 ≥ 4 |
| **Improve** | 局部深化 | 1-2 维度 ≤ 3，其他 ≥ 4 |
| **Update** | 时效性更新 | Currency ≤ 3，其他 OK |
| **Retire** | 退役（不深化） | Uniqueness ≤ 2（被其他 skill 替代） |
| **Merge** | 合并到其他 skill | Scope fit ≤ 2（与另一 skill 重叠） |

**应用到 skill-deepener P1**：6 维度评分后输出 verdict，决定是否进 P2。

---

## 来源 5: Voyager (arXiv:2305.16291) — 可执行单元思想

**核心**：skill 不只是文本流程，是**可执行可复用可组合**的单元。

**应用到 skill-deepener**：
- references/ 下每个文件应能被**外部 skill 独立调用**
- 反例：references/cognitive-apprenticeship.md 只服务 skill-deepener 内部 → 不算可执行单元
- 正例：references/industry-patterns.md（本文件）可被 skill-evolver / skill-creator / 任何想做深度 skill 的调用

**自检**：每个 reference 问"外部 skill 能用吗？"，不能 → 重构或合并。

---

## 来源 6: Prompt Distillation (arXiv:2412.14964) — 决策规则过滤

**核心方法**：teacher LLM 提取规则 + contrastive loss 过滤冗余。

**应用到 skill-deepener P3**：

```
Step 3c: 决策规则 contrastive 过滤（v1.2 新增）

对 P3 采集的所有"专家规则"做 contrastive 过滤：

1. 用 opus 作为 teacher，对每条规则：
   - 在 held-out case A 上跑：有这条规则 → 答案 X
   - 在同一 case A 上跑：无这条规则 → 答案 Y

2. 判定：
   - X == Y → 规则冗余（不影响答案），删除
   - X != Y → 规则有价值，保留

3. 阈值：保留通过 contrastive 的 top 5-10 条规则（不超过 SKILL.md 行数预算）
```

**反例**：直接采纳所有 web-research 调研结果 → SKILL.md 膨胀。
**正例**：每条规则先 contrastive 过滤 → 留高价值。

---

## 来源 7: Han Lee 拆解 — description 是唯一营销渠道

**反常识**：Anthropic Skill 系统底层无 embedding/classifier/regex，纯靠 description 语义匹配。

**应用到 skill-deepener P1**：加 **Trigger Precision 第 6 维度**（v1.2 新增）：

| 评分 | 标准 | 反例 |
|------|------|------|
| 5/5 | description 含具体触发场景 + 显式 + 隐式 trigger + do/don't 边界 | "找 skill / skill 推荐 / how do I do X / wish I had help with X" |
| 3/5 | 显式 trigger 全，但缺隐式（能力缺口识别） | 只列"找 skill"，缺"how do I do X" |
| 1/5 | description 平庸，描述能力但不列触发场景 | "Skill 搜索与评估引擎"（无 trigger） |

**红线**：Trigger Precision ≤ 2 → 即使其他维度全 5，verdict 仍 Improve（因 description 决定 skill 能否被调用）。

---

## 来源 8: ACL WASP 2025 — 反直觉任务结构化

**反常识**：结构化输出（JSON schema / 三段式）在反直觉指令场景反而提升 LLM 遵守度。

**机制**：schema 强制模型停顿，降低"惯性滑入常识答案"。

**应用到 skill-deepener P4**：加 **"反直觉任务结构化原则"**：

```markdown
### 反直觉任务识别 + 结构化强制

反直觉任务特征（任一命中即强制结构化）：
- 金融合规 / 风控 / 支付 / 结算
- 安全审计 / 渗透测试 / 权限管理
- 法务 / 合同 / 隐私 / PII
- 跨系统数据迁移 / schema 变更
- 删除 / 销毁 / 不可逆操作

对反直觉任务的 skill，强制输出三段式：
1. **风险等级**：高/中/低 + 理由
2. **证据**：具体代码行 / 配置项 / 数据
3. **反证**：什么场景下这个判断会错

反例（自然语言，会失败）：
"这个改动看起来安全"

正例（结构化）：
"风险等级：高
证据：L42 直接修改 user.balance 字段，无事务包裹
反证：如果是初始化数据迁移且单线程，可降为中"
```

---

## 来源 9: Cognitive Apprenticeship — skill 类型 → CA 权重表

**完整权重映射**（v1.1 部分有，v1.2 完整化）：

| skill 类型 | Modeling | Coaching | Scaffolding | Fading | 典型 skill |
|-----------|----------|----------|-------------|--------|-----------|
| 执行型 | 40% | 30% | 20% | 10% | coder / programmer / tdd |
| 研究型 | 50% | 15% | 30% | 5% | skill-search / web-research / code-review |
| 文档型 | 60% | 10% | 30% | 0% | citation-sourcing / coding-rules |
| 元 skill | 35% | 25% | 25% | 15% | skill-evolver / skill-deepener / skill-creator |
| 创意型 | 45% | 20% | 25% | 10% | brainstorm / storytelling / huashu-nuwa |

**应用到 P3**：根据 target skill 类型查表，确定 CA 要素权重。

---

## 来源 10: Anthropic 反推法 — 失败 case 5 字段具体范例

**深化 P2 expert_reasoning_gaps 5 字段**：

```markdown
### 完整范例（5 字段全齐）

**Gap**: coder skill 在 Go 项目 nil map panic 修复中失败

trigger（触发场景）：
  "用户报告 Go 项目 panic: runtime error: invalid memory address
   or nil pointer dereference，并指了具体 stack trace 行"

failure（失败模式）：
  "Domain-Skill Agent 直接在 panic 行加 nil check：
   if x != nil { ... }
   未追根因到 init() 函数中 map 未初始化"

expert_action（专家正确做法）：
  "1. 用 panic stack trace 定位真实调用链
   2. 排查变量赋值时序（init / var / struct field）
   3. 找到 nil 的 root cause（如 map 字段未 make()）
   4. 修 root cause，不是症状
   5. 加 regression test 防回归"

missing_rule（SKILL.md 缺什么）：
  "coder/SKILL.md L150 'Bug 修复 → 语义定位 → 修复 → 回归测试'
   缺 'panic 类 bug 必须先追根因到 init/赋值时序，禁止症状式 nil check'"

evidence（可追溯）：
  "trajectory:L45-L62, 2026-06-18 T3 Domain-Skill Agent 跑 Go 项目修 panic"
```

---

## 来源 11: Reflexion — episodic memory buffer

**核心**：失败经验存入 episodic memory，下次类似场景自动召回。

**应用到 skill-deepener P6**：

```markdown
### Episodic Memory Buffer 设计

P6 持久化时，除 references/case-library.md 外，同步存 memory：

memory_store(
  content="{skill-name} 深化经验 #{N}: {trigger 简述} → {failure 简述} → {expert_action 简述}",
  metadata={
    "tags": "deepen-{skill-name}, episodic-memory, case-{N}",
    "type": "learning",
    "source_skill": "skill-deepener",
    "target_skill": "{skill-name}"
  }
)

下次类似场景：
  - target skill 启动时 memory_search(query="{similar trigger}")
  - 命中 → 加载历史 expert_action 提醒
```

---

## 来源 12: Agent-as-a-Judge — 每角色正反例对照

**深化 P5 3 角色**（每角色加正反例）：

### 方法论严谨者正反例

```markdown
# 正例（5 分）
方法论："panic 修复必须 reproduce → minimise → root cause → fix → regression"
反例：3 个真实 panic 修复案例 + 失败模式 + expert 视角
5 why 测试：问"为什么必须先 reproduce"答"避免修症状"，问"为什么修症状错"答"..."
→ 5/5

# 反例（3 分）
方法论："找到根因"
反例：无案例 + 无失败模式
5 why 测试：问"为什么必须找根因"答"因为是根因"（循环论证）
→ 3/5
```

### 案例真实者 / 领域准确者 同理（见 expert-role-audit.md v1.2 完整版）

---

## 自检：本文件是否符合 Voyager 可执行单元原则？

| 检查 | 通过 |
|------|------|
| 可被外部 skill 调用？ | ✓ skill-evolver / skill-creator / 任何想做深度 skill 的可引用 |
| 内容垂直可操作？ | ✓ 每个来源含具体步骤 / 阈值 / 反例 |
| 不重复其他 reference？ | ✓ cognitive-apprenticeship 讲方法本身，本文件讲来源 + 吸收度 |

---

## v1.2 改动落地清单

| 改动 | 来源 | SKILL.md 位置 |
|------|------|--------------|
| P1 加 Trigger Precision 第 6 维度 | Han Lee | P1 段 |
| P1 加 5 verdict 输出 | ECC skill-stocktake | P1 段 |
| P2 失败 case 5 字段完整范例 | Anthropic 反推法 | P2 段 |
| P3 加 5 步 codify 流程 | Codified Human Expertise | P3 段 |
| P3 加 contrastive 过滤 | Prompt Distillation | P3 段 |
| P3 skill 类型 → CA 权重完整表 | Cognitive Apprenticeship | P3 段 |
| P4 加 6 verdict 输出格式 | ECC rules-distill | P4 段 |
| P4 加反直觉任务结构化原则 | ACL WASP | P4 段 |
| P5 加每角色正反例 | Agent-as-a-Judge | expert-role-audit.md |
| P6 加 episodic memory buffer | Reflexion | P6 段 |
| 加 expert 语言标杆（4 原则） | karpathy-skills | industry-patterns.md（本文件） |
| 加可执行单元原则 | Voyager | industry-patterns.md（本文件） |
