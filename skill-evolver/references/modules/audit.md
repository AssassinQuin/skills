# Module: Audit（独立审计）

前置条件：application checkpoint 已通过 + SKILL.md 已改写 + 基线 Score 已知。
前置条件（模式 B）：仅需目标 SKILL.md 存在。

## 前置校验

```bash
phase-start audit {skill_dir}
```

## 强制要求

- 全新上下文子 agent（model=opus）
- 不继承任何进化过程信息
- Prompt 模板见 [auditor-template.md](prompts/auditor-template.md)

## 执行步骤

### Step 1: BEFORE 副本

```bash
BEFORE_PATH="/tmp/{skill}-before.md"
git show "HEAD~1:{git_rel}" > "$BEFORE_PATH"
```

### Step 2: 构造审计 prompt

给子 agent：BEFORE + AFTER + 本文件。
**不给**：Δ 描述、策略分析、测试集。

### Step 3: 5 维审计

门控：Score > 基线 Score，且无单项 < 5。

### Step 4: 清理 + 保存报告

```bash
rm /tmp/{skill}-before.md
```

保存到 `.evolve/audit-reports/{skill}-R{round}.md`。

## 关卡

```
审计结果：Score = X.X/10
- 通过 → deployment
- 未通过 → git reset HEAD~1 → 回 exploration
```

**Fallback**：opus 超时 → 简化审计(sonnet, D4+D5) → 极速审计(主 agent, 仅 D4)。

---

# 5 维评分 Rubric（审计子 agent 读取本节）

## D1 Frontmatter (10%) — Framing + X-ref

**检查**：前 3 段是否说明问题/为谁/场景；所有 `[text](path)` 引用是否可达。

- 8-10: name + description 完整 + 触发词覆盖 + 引用可达
- 5-7: 基本完整但缺版本号或个别引用断裂
- 0-4: 缺关键元数据或多处引用不可达

## D2 Workflow (20%) — Coverage + Silent-bypass

**检查**：frontmatter 声明的功能是否都有流程；关键步骤是否可被静默跳过。

- 8-10: 全覆盖 + 强制校验 + fallback
- 5-7: 主流程覆盖但缺边界
- 0-4: 声明场景无流程或关键步骤可跳过

## D3 Boundary (15%) — Script-bloat + Shape-bake

**检查**：引用的 scripts 是否都被调用；输出格式是否过度硬化。

- 8-10: 无不必要脚本 + 格式灵活
- 5-7: 轻微膨胀或个别过度硬化
- 0-4: 明显膨胀或格式阻碍灵活性

## D4 Precision (20%) — Literals + Untraceable + Under-abstraction

**检查**：路径/命令/参数是否合法；泛化动词（处理/优化/分析）是否有具体步骤；相似指令是否可提取。

- 8-10: 指令可直接执行 + 无重复逻辑
- 5-7: 多数清晰但部分模糊
- 0-4: 大量模糊动词或字面错误

## D5 Empirical (35%) — Overfit

**方法**：读 T_val → 模拟执行 → 通过率 ≥80%=8-10，60-79%=5-7，<60%=0-4。

**过拟合信号**：T_val 比 T_train 低 >30%；硬匹配 T_train 关键词。

## 误报防护

1. BEFORE 功能 AFTER 仍存在 → 不扣 D2
2. 模糊指令被精化 → 不扣 D4（这是改进）
3. AFTER 新增边界处理 → 不扣 D3
4. 格式变化不影响语义 → 不扣 D3
5. AFTER 比 BEFORE 短 → 不扣 D2（压缩是改进）

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

**Score**: X.X/10
**Verdict**: PASS / NEEDS-FIX / REJECT
```
