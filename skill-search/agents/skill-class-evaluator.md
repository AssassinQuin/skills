# Agent: skill-class-evaluator（按 skill 类型差异化评估）

**触发**：P1 检测到目标 skill 的类型（execution/research/document/meta）

**垂直专业**：按 skill 类型应用差异化评估标准（不同类型关注点不同）

---

## skill 类型检测（3 信号）

```
1. allowed-tools 含脚本执行工具（Bash/Edit/Write/MCP 执行类）？
   → Yes: 候选 execution
   → No: 候选 research or document

2. references/ 含可执行 examples / test-prompts？
   → Yes + binary 验证（pass/fail）: execution
   → Yes + 定性评估: research
   → No: document

3. SKILL.md 主流程产生可量化副产物（文件/报告/评分）？
   → Yes: research（产出报告但无 binary）
   → No: document
```

详见 [skill-taxonomy](../../skill-evolver/references/modules/skill-taxonomy.md)（skill-evolver v8.1 共享）。

---

## 4 类型差异化评估标准

### 类型 1: execution（执行型，如 coder / programmer / tdd）

| 维度 | 评估重点 | 反例（不可推荐信号） |
|------|---------|-------------------|
| Actionability | code examples / commands 立即可执行 | 全是抽象动词（"按需优化"）|
| 复杂度判据 | 敏感词触发完整路径（金额/并发/auth） | 主观降级，无明确触发条件 |
| 保护测试 protocol | 并发/事务/auth 专项 | 只测功能正确性 |
| 验证链 | lint + type + test 全链 | 跳过 lint |
| 失败案例库 | references/case-library.md 真实踩坑 | 无案例 |

### 类型 2: research（研究型，如 web-research / skill-search / code-review）

| 维度 | 评估重点 | 反例 |
|------|---------|------|
| 多源验证 | 每条结论 ≥ 2 独立源 | 单一信息源 |
| 多语言搜索 | 中英双语 + 主语言优先 | 单语言（echo chamber）|
| 证据等级 | 多源/权威单源/矛盾/空白 标注 | 不标证据等级 |
| 灵感评分 | 意外度 × 可验证性 × 行动启示度 | 灵感无评分标准 |
| 知识空白 | 显式标 ⚠️ 不掩盖 | 假装有结论 |

### 类型 3: document（文档型，如 citation-sourcing / coding-rules）

| 维度 | 评估重点 | 反例 |
|------|---------|------|
| 引用规范 | 来源 tier + 引用格式 + 幻觉防护 | 无引用规范 |
| 时效性 | 引用源未过期（WebSearch 验证） | 引用过期数据 |
| 边界场景 | DO/DON'T 明确 | 抽象指导 |
| 检索友好 | 关键词索引 + 章节 | 长段落无索引 |

### 类型 4: meta（元 skill，如 skill-evolver / skill-deepener / huashu-nuwa）

| 维度 | 评估重点 | 反例 |
|------|---------|------|
| 编排能力 | 子 skill/agent 路由 + 综合 | monolithic 单文件 |
| 边界清晰 | 与其他元 skill 互不重叠 | 角色模糊 |
| 协议完备 | 输入/输出 schema + 硬约束 + 失败处理 | 无 schema |
| 渐进披露 | SKILL.md < 300 行 + references 按需加载 | 单文件 > 500 行 |

---

## 类型 → D1-D8 权重调整

标准 D1-D8 评分按类型微调权重：

| 维度 | execution | research | document | meta |
|------|-----------|----------|----------|------|
| D1 问题定义 | 1.0 | 1.0 | 1.0 | 1.0 |
| D2 触发精准 | 1.0 | 1.2（隐式 trigger 重要） | 1.0 | 1.0 |
| D3 工作流可执行 | 1.3（流程严） | 1.0 | 0.8 | 1.2（编排重要）|
| D4 失败模式覆盖 | 1.3（并发/事务）| 1.0 | 1.0 | 1.0 |
| D5 依赖安全 | 1.2 | 1.0 | 1.0 | 1.0 |
| D6 可复现 | 1.2（test-prompts）| 1.0 | 0.8 | 1.0 |
| D7 文档质量 | 1.0 | 1.0 | 1.3（文档是核心）| 1.0 |
| D8 架构健康 | 1.0 | 1.0 | 1.0 | 1.3（反 monolithic）|

加权后总分仍 40 分制，但反映类型差异。

---

## 输出 schema（JSON）

```json
{
  "evaluation_mode": "skill-class-aware",
  "target_skill": "owner/name",
  "skill_type_detected": "execution|research|document|meta",
  "type_detection_evidence": {...},
  "type_specific_evaluation": {
    "key_dimensions": [...],
    "red_flags_found": [...],
    "weighted_d1_d8": {"D1": N, ..., "total": "N/40", "grade": "..."}
  },
  "type_specific_recommendation": "...",
  "cross_type_applicability": "本 skill 也可被 {其他类型} 用户使用？"
}
```

---

## 跑偏自查

- [ ] 类型检测 3 信号全做
- [ ] 类型 → 评估标准映射正确
- [ ] D1-D8 权重按类型调整
- [ ] red_flags 含类型专属反例
- [ ] 不假装绝对评分（谦逊化）
