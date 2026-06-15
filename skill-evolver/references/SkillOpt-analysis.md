# SkillOpt vs skill-evolver 同异分析

**SkillOpt**: Microsoft Research, arXiv:2605.23904 (2026-05)
**skill-evolver**: 本仓库实现，基于 SkillEvolver 论文 arXiv:2605.10500

## 核心同异速查

| 维度 | SkillOpt (MSR) | skill-evolver (ours) |
|------|----------------|---------------------|
| **优化目标** | 单一 `best_skill.md` 文件 | `SKILL.md` + `references/` + `scripts/` |
| **目标模型** | GPT-5.x 系列 (7个), Claude Code | 任意 LLM（通过 agent 框架） |
| **执行环境** | direct chat / Codex / Claude Code | Claude Code CLI（子 agent 框架） |
| **优化模型** | 独立 frontier model (GPT-5.5) | `evolver-explorer`(sonnet) + `evolver-auditor`(opus) |
| **反馈信号** | 自动评分器（benchmark ground truth） | 5 维 rubric 评分 + 痛点 + T_train/T_val |
| **编辑粒度** | add/delete/replace 行级操作 | 整文档完整重写（不打补丁） |
| **学习率控制** | textual learning rate budget (lr=4 默认) | 无显式学习率；用"完整改写" + 审计门控 |
| **验证机制** | held-out selection gate（严格提升才接受） | audit(opus) + deployment(T_val) + 痛点回归 |
| **迭代轮次** | 多 epoch，通常 3-4 轮接受 edit | ≤3 轮 (R ≤ 3) |
| **记忆机制** | rejected-edit buffer + slow update + meta skill | pain-points.jsonl + metrics.json + deployment-traces.jsonl |
| **污染防护** | train/val split（数据层面） | Layer 1(T_train/T_val) + Layer 2(文件白名单) + 泄露自检 |
| **可复现性** | 52/52 cells 全胜，有消融实验数据 | 无量化基准测试；依赖用户确认 |
| **传输性** | 跨模型 +15.2, 跨框架 +31.8 | 未设计传输验证 |

## 相同点（共同理念）

1. **Skill 作为外部状态**：两者都将 skill 文档视为可训练状态，不修改模型权重
2. **独立优化器**：分离执行模型和优化模型，避免自评偏差
3. **Held-out 验证门控**：都有训练集/验证集拆分，防止过拟合
4. **迭代优化**：都是多轮 rollout → 反思 → 编辑 → 验证 的循环
5. **紧凑输出**：都追求最小化 skill 文档体积（SkillOpt <2000 tokens，我们追求精简）
6. **对比学习**：SkillOpt 对比成功/失败 minibatch；我们 τ+/τ- Contrastive Update 几乎相同
7. **失败记忆**：SkillOpt 的 rejected-edit buffer ≈ 我们的 pain-points.jsonl

## 关键差异

### 1. 编辑策略：行级 patch vs 完整重写

**SkillOpt** 的核心创新是 **bounded edits**（add/delete/replace），类似 git diff 的行级操作，受 textual learning rate 约束。这直接对应深度学习的梯度下降——每步只改一点点。

**skill-evolver** 采用"完整改写，不打补丁"。每个策略探索子 agent 输出完整 SKILL.md，主 agent 选择最优版本。这更像进化算法（种群→选择→变异）而非梯度下降。

**SkillOpt 优势**：编辑粒度可控，不会意外删除已有好规则；rejected-edit buffer 有明确的负反馈信号。
**我们优势**：完整重写可发现结构性改进（重组章节、重构流程），行级编辑做不到。

### 2. 学习率控制

**SkillOpt** 有显式的 textual learning rate (lr=1/4/8/16)，控制每轮最大编辑行数。消融实验显示 lr=4 最优，无 lr 时性能下降明显。

**skill-evolver** 没有学习率概念。用"完整重写 + 审计门控 + R ratchet（只保留改进版本）"间接控制。这更粗粒度。

### 3. 评分信号

**SkillOpt** 依赖自动评分器（ground truth），每个 benchmark 都有确定性评分。这使得优化循环可以完全自动化。

**skill-evolver** 的评分来自子 agent 的 5 维 rubric（D1-D5），是主观评估。T_train/T_val 由子 agent "模拟执行"，不是真实执行。这是一个根本性的弱信号问题。

### 4. 工程复杂度

**SkillOpt** 是一个 Python 训练脚本，自动化程度高。给定 benchmark + 评分器，可以无人值守运行。

**skill-evolver** 是一个 Claude Code skill，重度依赖人机协作（每个 Phase 都有 AskUserQuestion 确认点）。更复杂但更灵活——可以处理没有自动评分器的 skill。

### 5. 适用范围

**SkillOpt** 针对有自动评分器的 benchmark（SearchQA、SpreadsheetBench、ALFWorld 等）。论文 Limitation 明确指出：需要 scored trajectories + held-out split，对开放式任务不适用。

**skill-evolver** 面向任意 SKILL.md 的优化，不依赖外部评分器。但代价是评分信号弱，进化效果难以量化验证。

## SkillOpt 可借鉴的改进点

### 高优先级

1. **Textual Learning Rate**：在 application 阶段引入编辑预算。当前"完整改写"无约束，可能导致好规则被意外删除。可以实现为：对比 BEFORE/AFTER diff，限制删除行数 ≤ N。

2. **Rejected-Edit Buffer**：当前审计失败的改写直接回滚，失败经验丢失。应记录失败改写的关键差异到 `.evolve/rejected-edits.jsonl`，在后续 exploration 中作为负面样本。

3. **Slow/Meta Update**：SkillOpt 每 3 个 epoch 做一次 longitudinal comparison（跨轮次比较），允许更宽泛的更新。我们可以借鉴：连续 2 轮同维度低分时，触发 meta 策略（跨维度结构重写）。

### 中优先级

4. **量化基准测试**：SkillOpt 有 6 个 benchmark 的量化结果。skill-evolver 应设计标准测试集（如 5 个不同类型的 SKILL.md），跑自动进化后对比前后评分，建立可信的改进证据。

5. **编辑粒度混合**：不必全盘完整重写。Quick Fix 场景适合行级编辑；范式转换场景适合完整重写。根据改动范围自动选择编辑策略。

### 低优先级

6. **跨 Skill 传输验证**：SkillOpt 证明了 skill 可跨模型/框架传输。我们可以增加传输测试：进化后的 skill 在不同 LLM 上测试泛化能力。

## 各自优缺点总结

### SkillOpt 优势
- 52/52 全胜的量化结果，有消融实验支撑
- textual learning rate 提供精确的编辑控制
- rejected-edit buffer 提供系统化负反馈
- 完全自动化，不依赖人工确认
- 传输性验证（跨模型 +31.8 跨框架）
- 学术严谨性高（可复现、有消融、有成本分析）

### SkillOpt 局限
- 依赖自动评分器，对开放式 skill 不适用
- 仅优化单一文件，不支持多文件 skill（如 SKILL.md + references/ + scripts/）
- 目标模型限于 GPT 系列和 Claude Code
- 行级编辑无法做结构性重组
- 无用户意图通道（不处理"痛点"等主观反馈）

### skill-evolver 优势
- 渐进披露架构（SKILL.md + references/modules/），支持复杂 skill
- 多文件编辑（SKILL.md + references/ + scripts/ + agents/）
- 脚本强制执行（phase-check/phase-start），防止流程被跳过
- 5 种模式（A-E）适应不同场景
- 人类-in-the-loop 质量门控
- 痛点驱动进化，可直接响应用户反馈
- 支持 Quick Fix 快速路径
- 自我进化能力（模式 D）

### skill-evolver 局限
- 无量化基准测试，改进效果不可度量
- 评分信号弱（子 agent 模拟执行 ≠ 真实执行）
- 无 textual learning rate，编辑粒度不可控
- 重度依赖人工确认，自动化程度低
- 无 rejected-edit 积累，失败经验浪费
- 无传输性验证
- 6-7 个并行子 agent 的 MCP 中转路径有信息损失风险
