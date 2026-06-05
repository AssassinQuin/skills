# 独立审计指南 — 5 维评分制

Phase 4 审计时读取本文件。

---

## 审计执行要求

**必须用全新上下文子 agent（model=opus）**。只给子 agent：
- 原始 SKILL.md
- 补丁后的 SKILL.md
- 本文件

**不给**：Phase 1-3 的分析结果、进化过程记录、信号数据、测试 prompt。

---

## 5 维评分（唯一评分标准）

每个维度 0-10 分，加权平均得总分。每个维度对应 2-3 个检查项。

### D1 Frontmatter (10%) — Framing + X-ref

**检查项**：
- 读 SKILL.md 前 3 段：是否清楚说明解决什么问题、为谁、什么场景用
- 收集所有 `[text](path)` 引用：文件是否存在？路径正确？

**评分**：
- 8-10: name + description 完整 + 触发词覆盖 + 所有引用可达
- 5-7: 基本完整但缺版本号或个别引用断裂
- 0-4: 缺关键元数据或多处引用不可达

### D2 Workflow (20%) — Coverage + Silent-bypass

**检查项**：
- 对比 frontmatter description 声明的功能：每个功能是否有对应流程
- 模拟执行每个步骤：是否有步骤可在不报错的情况下被跳过

**评分**：
- 8-10: 全场景覆盖 + 关键步骤有强制校验 + 有 fallback
- 5-7: 主流程覆盖但缺部分边界或 fallback
- 0-4: 声明场景无流程或关键步骤可被静默跳过

### D3 Boundary (15%) — Script-bloat + Shape-bake

**检查项**：
- 列出所有引用的 scripts/ 文件：每个是否被实际调用？
- 检查输出格式要求：是否在不需要固定格式的地方硬编码了格式？

**评分**：
- 8-10: 无不必要脚本 + 格式灵活适应场景
- 5-7: 轻微膨胀或个别过度硬化
- 0-4: 明显膨胀或格式阻碍灵活性

### D4 Precision (20%) — Literals + Untraceable + Under-abstraction

**检查项**：
- 提取所有文件路径、命令、URL、参数名：路径存在？命令合法？
- 搜索泛化动词（处理、优化、分析、生成、检查、调整、确保）：是否有具体步骤？
- 寻找相同或非常相似的步骤/指令出现 2+ 次：是否可提取？

**评分**：
- 8-10: 所有指令可直接执行 + 无重复逻辑
- 5-7: 多数清晰但部分模糊或有轻微重复
- 0-4: 大量模糊动词或字面错误

### D5 Empirical (35%) — Overfit (T_val held-out 验证)

**检查方法**：
1. 读取 test-prompts.json 中的 **T_val** 数组
2. 对每个 T_val prompt 模拟执行改写后的 skill
3. T_val 通过率 ≥80% → 8-10；60-79% → 5-7；<60% → 0-4

**过拟合信号**：
- T_val 通过率显著低于 T_train（差距 >30%）
- 补丁中出现对 T_train prompt 关键词的硬匹配
- 无 T_val 时至少 1 个自创新 prompt 表现出改善

---

## 误报防护规则

以下变化 **不应** 扣分：
1. BEFORE 中存在的功能，AFTER 中仍存在 → 不扣 D2 Coverage 分
2. BEFORE 中的模糊指令被 AFTER 精化 → 不扣 D4 Untraceable 分（这是改进）
3. AFTER 新增了 BEFORE 没有的边界处理 → 不扣 D3 Script-bloat 分（这是增强）
4. 格式变化不影响功能语义 → 不扣 D3 Shape-bake 分
5. AFTER 比 BEFORE 短 → 不扣 D2 Coverage 分（压缩是改进）

---

## 审计报告格式

```markdown
## Audit Report: {skill-name} R{round}

| 维度 | Score | Evidence |
|------|-------|----------|
| D1 Frontmatter (10%) | X | ... |
| D2 Workflow (20%) | X | ... |
| D3 Boundary (15%) | X | ... |
| D4 Precision (20%) | X | ... |
| D5 Empirical (35%) | X | ... |

**Score**: X.X/10 (加权平均)
**Verdict**: PASS (>基线且无<5) / NEEDS-FIX / REJECT
```

保存到 `.evolve/audit-reports/{skill}-R{round}.md`
