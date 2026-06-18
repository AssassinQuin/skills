# Skill 类型分类与 Reward 协议

论文 §3.1 假设 Domain-Skill Agent 能产出 binary reward。但实际 skill 类型多样，需要分类适配。

## 三种 skill 类型

| 类型 | 特征 | 典型例子 | Reward 协议 |
|------|------|---------|------------|
| **执行型 (Execution)** | 跑任务有可量化结果（pass/fail、文件生成、数值） | coder, programmer, tdd | Binary reward（论文原版） |
| **研究型 (Research)** | 输出是分析/评估/报告，无 binary 结果 | skill-search, web-research, code-review | Qualitative reward（A/B 对比 / 排序 / 命中 expected outcome） |
| **文档型 (Document)** | 无可执行任务，纯指导性 | coding-rules, citation-sourcing | Checkpoint review（人工评分 + 关键字段完整性） |

## 类型检测（Phase 1 Initialize 强制）

```
检测 skill 类型的 3 个信号：

1. SKILL.md frontmatter `allowed-tools` 是否含脚本执行工具（Bash/Edit/Write/MCP 执行类）？
   → Yes: 候选执行型
   → No: 候选研究型或文档型

2. references/ 是否含可执行 examples / test-prompts？
   → Yes + 有 binary 验证（pass/fail）: 执行型
   → Yes + 仅定性评估（好/差）: 研究型
   → No: 文档型

3. SKILL.md 主流程是否产生可量化副产物（文件、报告、评分）？
   → Yes: 研究型（产出报告但无 binary）
   → No: 文档型
```

## Reward 协议细节

### 执行型 — Binary Reward（论文原版）

```
Domain-Skill Agent 拿 candidate skill + T_train 任务
→ 真实执行
→ 产出轨迹 τ + binary reward y ∈ {0, 1}
  y = 1: 任务成功（生成的代码通过测试 / 文件正确生成）
  y = 0: 任务失败

对比：τ+ (y=1) vs τ- (y=0) → Contrast 信号 → Patch
```

### 研究型 — Qualitative Reward（v8.1 新增）

```
Evaluation-Trace Agent 拿 candidate skill + T_train 评估任务
→ 真实执行评估
→ 产出轨迹 τ + qualitative reward y ∈ {A, B, C, D, F} 或 ranking
  - A/B 对比：candidate vs BEFORE 在同一任务上的产出质量
  - 排序：candidate 在多个任务上的相对表现
  - 命中 expected：产出是否包含预期字段 / 是否走完整流程

对比：τ+ (高质量产出) vs τ- (低质量产出) → Contrast 信号 → Patch
```

**关键**：研究型 skill 的 reward 不能是 binary（"评估完成"vs"评估失败"无意义），必须是**产出质量的相对比较**。

### 文档型 — Checkpoint Review（v8.1 新增）

```
Domain-Skill Agent 无法跑（无可执行任务）
→ 降级为主 agent + 1 个 reviewer agent 的 checkpoint review
→ reviewer 拿 candidate skill + 1 个典型使用场景
→ 回答 5 个问题（每个 binary）：
  1. 场景触发是否命中？
  2. 主流程是否清晰可执行？
  3. 失败模式是否覆盖？
  4. 硬约束是否可独立验证？
  5. references 是否完整？
→ y = (5 个 yes 数) / 5

对比：高分管线 vs 低分管线 → Contrast → Patch
```

## 类型选择对 Algorithm 1 的影响

| Algorithm 1 步骤 | 执行型 | 研究型 | 文档型 |
|------------------|--------|--------|--------|
| Phase 2 Bootstrap | Domain-Skill Agent | Evaluation-Trace Agent | Reviewer Checkpoint |
| Phase 3 Refinement | 同上 + binary reward | 同上 + qualitative reward | 同上 + 5-question review |
| Phase 4 Validate | T_val 上 binary reward | T_val 上 ranking 对比 | T_val 上 5-question review |

**Phase 1-4 骨架不变**，只是 reward 函数和 agent 角色替换。

## 反例（v8.0 的 bug）

研究型 skill 在 v8.0 框架下被硬套执行型 Algorithm 1：
- 跳过 Domain-Skill Agent（因为没法 binary reward）
- 用"上一版评估的复盘"作为 failure signal（这不是论文要求的 (τ, y) 轨迹）
- 结果：进化过程形似神不至，T_train = T_val 过拟合到单一场景

**v8.1 修复**：Phase 1 检测 skill 类型 → 研究型自动切换到 Evaluation-Trace Agent + qualitative reward 协议。
