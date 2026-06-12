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
- Prompt 模板见 [templates.md](prompts/templates.md#Auditor)

## Contamination Controls（论文 Layer 1 + Layer 2）

**Layer 1: T_train/T_val 拆分**（已有）
- 审计只用 T_val，不用 T_train

**Layer 2: Workspace 白名单**（新增）
构造 auditor prompt 时，主 agent 只传递以下文件路径：
- BEFORE 副本
- AFTER 副本（改写后 SKILL.md）
- test-prompts.json（仅 T_val 部分）
- audit.md rubric

**禁止传递**：evolution-log.jsonl、traces.jsonl、metrics.json、pain-points.jsonl。
主 agent 在调用 auditor 子 agent 前，必须执行 `silent-bypass-check {skill_dir}` 验证无绕过信号。

## 信息泄露检测（论文 Contamination Check）

审计报告返回后，主 agent 检查报告中是否包含：
1. 对"策略 S{k}"或"Δ"的引用 → 泄露训练信号
2. 对 pain-points 内容的引用 → 泄露修复意图
3. 对 evolution-log 历史记录的引用 → 泄露进化方向
4. 对 T_train 测试 prompt 的直接引用 → 泄露训练集

发现任何一项 → 在报告中标记 `[CONTAMINATION WARNING]`，该维度扣 2 分。

## 执行步骤

### Step 1: BEFORE 副本

从 `.evolve/snapshots/` 读取（由 baseline 阶段 `snapshot-save` 创建）：

```bash
BEFORE_PATH="{skill_dir}/.evolve/snapshots/{skill-name}-latest.md"
ls "$BEFORE_PATH" || { echo "ERROR: BEFORE snapshot not found. Was snapshot-save run in baseline?" >&2; exit 1; }
```

如果 snapshot 不存在（异常情况），从 git 获取并报警告。

### Step 2: 构造审计 prompt

给子 agent：BEFORE + AFTER + 本文件。
**不给**：Δ 描述、策略分析、测试集。

### Step 3: 5 维审计

门控：Score > 基线 Score，且无单项 < 5。

### Step 4: 进化效果对比（主 agent 生成，非审计子 agent）

审计子 agent 返回评分后，**主 agent** 基于已知信息生成效果对比：

```
## 进化效果对比
### 问题解决
| 痛点 | 进化前 | 进化后 | 改善 |
|------|--------|--------|------|
| PP-xxx | {痛点描述} | {如何解决} | {量化效果} |

### 量化对比
| 指标 | Before | After | Δ |
|------|--------|-------|---|
| Score | X.X | Y.Y | +Z.Z |
| 约束数 | N | M | -K |
| 行数 | L1 | L2 | ±L |
| 痛点 open | O1 | O2 | -P |
```

此对比与审计报告一起展示给用户确认。

### Step 5: 保存审计报告（必须执行）

```bash
source evolve.sh && audit-save {skill_dir} {round}
```

主 agent 将审计子 agent 的完整报告写入 `audit-save` 输出的路径。不删除 snapshots。

## 关卡

```
审计结果：Score = X.X/10
- 通过 → 展示进化效果对比 + 诚实边界 → 用户确认 → deployment
- 未通过 → git reset HEAD~1 → 回 exploration
```

**检查点意义**：audit 是最终质量门。通过后直接进入部署，问题不在此拦截就会带到生产。

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

**Silent-bypass 检测（必查）**：
1. SKILL.md 中标记为"必须"或"硬约束"的步骤，是否有执行层保障（脚本/确认机制），还是仅靠文字声明？
2. 历史进化轮次中，是否有 phase 被跳过的记录？（对比 `.evolve/*.marker` 时间戳）
3. 关键约束（如"用户确认"、"路径锚定"）是否可被 agent 忽略而不触发任何错误？

- 8-10: 全覆盖 + 强制校验 + fallback + silent-bypass 无死角
- 5-7: 主流程覆盖但缺边界，或 silent-bypass 存在理论可能但未被利用
- 0-4: 声明场景无流程或关键步骤可被静默跳过（silent-bypass 已实际发生）

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
