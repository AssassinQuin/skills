# SkillEvolver 论文规范（重构唯一依据）

**Source**: SkillEvolver: Skill Learning as a Meta-Skill, arXiv:2605.10500v1, 11 May 2026
**Authors**: Genrui Zhang, Erle Zhu, Jinfeng Zhou, Caiyan Jia, Hongning Wang
**本文档定位**: 所有 skill-evolver 重构动作的唯一权威规范。`origin-paper.md` 是早期摘要，**已过时**（错误描述 "Contrastive Update partial"、"完整改写不打补丁"），以本文档为准。

---

## 0. 核心修正（避免凭旧记忆重构）

| 旧记忆（错） | 论文原文（对） |
|---|---|
| SkillEvolver 是完整重写 | **line 11: "surgical patch rather than rebuilding from scratch"** |
| Contrastive Update 是 partial | 论文是**完整定义**：τ+ = Top(K), τ- = Bottom(K), Δ = Contrast(τ+, τ-) |
| Auditor 主要打 rubric 分 | 论文 Auditor 跑 **9 个机械检查**，返回 binary gate + violations 列表 |
| Domain-Skill Agent 是子 agent | 论文是**独立 CLI-agent session**（fresh context，看不到 evolver context） |
| 策略是固定 S1-S6 | 论文每轮**动态生成**，针对 v_r 弱点 |

---

## 1. §3.1 Meta-Skill 模式（双 Agent 架构）

### 1.1 角色定义

| 角色 | 是什么 | 在我们这里的对应 |
|---|---|---|
| **SkillEvolver Agent** | CLI-agent 加载 skill-evolver skill，编辑目标 skill | 主 agent（加载 skill-evolver SKILL.md） |
| **Domain-Skill Agent** | **独立的** CLI-agent，只拿到 candidate skill + 任务，真的去执行 | **当前缺失** —— 我们用 evolver-explorer "模拟执行"，是错的 |
| **Auditor** | 独立 CLI-agent session，clean context，跑 9 个机械检查 | 当前 evolver-auditor，但跑的是 rubric 打分 |

### 1.2 学习信号的来源（论文 §3.1 原文）

> "The learning signal is not the SkillEvolver Agent's reflection on its own execution trajectories, but what a **separate** CLI-agent (given only the candidate domain skill and the task) actually does when handed that skill."

**强制要求**：feedback 信号必须来自 Domain-Skill Agent 的**真实执行轨迹**，不能来自主 agent 的反思、不能来自子 agent 的模拟执行。

### 1.3 Candidate skill 的物理形态

论文 §3.2 原文：
> "each candidate is a domain skill — a **directory of prose and scripts** loadable by any CLI-agent"

**不是单文件**。多文件 skill（SKILL.md + references/ + scripts/）符合论文定义。

---

## 2. §3.2 Loop 总览

```
Input: task T = (T_train, T_val); R (iteration cap); K (explore width); V (validate trials)
Output: π(v*; T_val)

1. axes ← Parse(T_train)                          # §3.1 one-shot Understand
2. S_0 ← DiverseStrategies(axes, ∅, ∅)            # §3.2.1 r=0 bootstrap
3. τ_0 ← Explore(T_train, S_0, v=∅, K)            # §3.2.1 K parallel trials
4. Δ_0 ← Contrast(τ_0+, τ_0-)                     # §3.2.2
5. v_1 ← Patch(∅, Δ_0)                            # §3.2.2 first skill from scratch
6. for r = 1 to R:
7.    Install v_r as dependency in trial container     # KEY: deploy-grounded
8.    S_r ← DiverseStrategies(axes, v_r, traces_{<r})  # 针对 v_r 弱点
9.    τ_r ← Explore(T_train, S_r, v_r, K)
10.   Δ_r ← Contrast(τ_r+, τ_r-)
11.   ṽ_{r+1} ← Patch(v_r, Δ_r)                       # surgical patch
12.   (a_r, E_r) ← Audit(ṽ_{r+1}, T_train, {(τ_{r,i}, y_{r,i})})
       # a_r = binary gate; E_r = violations
13. v* ← argmax_{v ∈ {v_1,...,v_R}} score(v; T_train)  # Finalize
14. return Validate(v*, T_val, V)                      # held-out
```

### 2.1 关键设计抉择（论文 Algorithm 1 注释原文）

- **"strategy-diversified sampling on a deployed skill"** —— 每轮的策略都基于"已部署的 v_r"反馈，不是基于 axes 的静态展开
- **"v_r is installed as a real dependency in the trial container"** —— 不是把 SKILL.md 内容塞进 prompt，而是真的把 skill 装进 agent 能加载的目录
- **"the contrast at line 10 reflects where a fresh using-agent was actually helped or misled by the deployed skill"** —— contrast 信号来自**真实使用**，不是文本对比
- **"Line 11 applies a surgical patch rather than rebuilding from scratch"** —— r>0 时只打补丁，不重写
- **"Line 12 invokes the fresh-session auditor"** —— Auditor 是独立 session

### 2.2 r=0 vs r>0 的关键差异

| 阶段 | v_r 状态 | 策略目标 | Patch 形式 |
|---|---|---|---|
| **r=0** | 不存在（v=∅） | 覆盖决策轴（axes-only bootstrap） | **从无到有创建 v_1**（吸收 high-reward 轨迹里的可复用代码） |
| **r>0** | 上一轮的 v_r | 针对 v_r 观察到的弱点 | **patch v_r**，保留已工作的指导，只加缺失约束 |

---

## 3. §3.2.1 Strategy-Diversified Exploration（SDE）

### 3.1 策略生成方式（论文原文要点）

> "Before running K parallel rollouts at iteration r, the SkillEvolver Agent writes a strategy set S_r = {s_{r,i}}_{i=1}^K, where each s_{r,i} specifies a **distinct high-level solution plan**"

> "The strategies are **not sampled by raising model temperature**. Temperature changes local wording and tool-call details... Instead, the SkillEvolver Agent writes explicit strategy files before launch and checks that **no two strategies are identical on all major axes**."

**强制要求**：
- 每轮**新写** K 个策略文件（不是从 S1-S6 模板里选）
- 每个策略覆盖不同的**决策轴**（库选择、算法族、指令解读方式）
- 主 agent 必须做两个检查：
  1. **去重检查**：K 个策略在主要 axis 上不能完全相同
  2. **参数化检查**：每个训练常量标记为 `invariant` 或 `parametric`；每个 parametric axis 至少有一个策略在运行时推导该值（而不是拷贝训练值）

### 3.2 决策轴（axes）的来源

`axes ← Parse(T_train)` —— 论文 §3.1 称为 "one-shot Understand"。

axes 是任务的**高层决策维度**，例如：
- 库/工具选择（用 jq vs python）
- 算法族（贪心 vs DP vs 回溯）
- 指令解读（严格字面 vs 意图推断）

**不强制**论文未列举的轴。axes 由 SkillEvolver Agent 在 r=0 一次性 Parse 出来。

### 3.3 Trial 执行（Explore 函数）

```
(τ_{r,i}, y_{r,i}) = Trial(v_r, T_train, s_{r,i})    # i = 1,...,K
```

- 每个 trial spawn 一个**独立的 fresh Domain-Skill Agent**
- 给它：candidate skill v_r + T_train 任务 + 策略 s_{r,i}
- 它真的执行任务，产出**带标签的轨迹** (τ_{r,i}, y_{r,i})
- y_{r,i} 是 task reward（binary 或 scalar）

**关键**：trial 把 v_r 当 dependency 装载，不是塞进 prompt。Domain-Skill Agent 用 skill 的方式 = 真实用户用 skill 的方式。

---

## 4. §3.2.2 Contrastive Skill Update

### 4.1 τ+ / τ- 的定义（论文 Eq.2）

```
τ_r+ = Top({τ_{r,i}}, y_{r,i})      # 高奖励轨迹
τ_r- = Bottom({τ_{r,i}}, y_{r,i})   # 低奖励轨迹
```

- **binary-reward 任务**（如 SkillsBench）：passing trials vs failing trials
- **scalar-reward 任务**（如 KernelBench）：top-scoring vs bottom-scoring

### 4.2 Contrast 信号

论文称 contrast 是 **"verbal reinforcement"**（参考 Reflexion）—— 不是 DPO 那种 preference update，是**用语言描述**"τ+ 做了什么 τ- 没做"。

输出 Δ_r 是一组**候选 feature / constraint / code pattern**，每个都标注：
- 来源（哪个 τ+ 贡献的）
- 是否"likely known from pretraining alone"—— 是 → **不加入** Δ_r

**Main filter（论文原文）**：
> "The main filter is whether a candidate feature would likely be known from pretraining alone. If so, it is not added."

### 4.3 Patch 操作

```
ṽ_{r+1} = Patch(v_r, Δ_r)
```

- **r=0**：从 contrastive signal + 高奖励轨迹里的可复用代码 **创建 v_1**
- **r>0**：**patch v_r**，"preserving working guidance while adding only the missing constraint, code pattern, or tool exposed by the latest contrast"

Patch 是 **natural-language and code content 写入 skill artifact**，不动 model weights。

---

## 5. §3.2.3 Independent Audit and Finalization

### 5.1 Auditor 的输入（论文原文）

> "The Auditor receives only the candidate skill, the task instruction, the training data, and the labelled traces {(τ_{r,i}, y_{r,i})}, **not validation data or the SkillEvolver Agent's context**."

**白名单**：candidate skill + task + T_train + labelled traces
**黑名单**：T_val + SkillEvolver Agent 的 context（策略分析、gap 分析、进化方向等）

### 5.2 Auditor 检查的 4 个维度（论文原文）

> "it checks whether the candidate is:
> 1. **self-contained**
> 2. **grounded in observed traces**
> 3. **abstracted away from training-instance constants**
> 4. **structured so that a fresh Domain-Skill Agent can apply it without relying on the evolver's private reasoning**"

### 5.3 输出（论文 Eq.4）

```
(a_r, E_r) = Audit(ṽ_{r+1}, T_train, {(τ_{r,i}, y_{r,i})})
```

- **a_r**：binary gate（accept / reject）
- **E_r**：命名的 violations 列表

**不是 rubric 打分**。是 binary gate + 具体违规清单。

### 5.4 Auditor 的 9 个机械检查（Appendix A.2 Table 3）

论文把 9 个检查分两组：

⋆ 标记的是 critical check，任何命中都强制下一轮做 targeted patch。

**完整 Table 3（2026-06-18 已抽取自 arXiv HTML §A.2）**：

| # | Check | What it catches |
|---|---|---|
| 1 | **Framing⋆** | name/description 借用了训练实例的**业务名词**，而非抽象操作 |
| 2 | **Literals⋆** | 硬编码训练 filename / field name / entity string / 软限定数字（如 "typically << 2.5"） |
| 2b | Script bloat | 单脚本 >200 行（important）/ >400 行（critical）—— 几乎总是 bundled solution generator，不是 utility |
| 3 | Untraceable | 强制断言（"use X not Y" / "never" / "required"）无 trace 来源且非 pretraining 显然 |
| 4 | **Shape-bake⋆** | 脚本硬编码 column/sheet/key 而无 runtime probe（`df.columns` / `wb.sheetnames`）；单脚本里 ≥3 个 `if "keyword" in desc` 分支 = keyword-dispatch solution-generator |
| 5 | Coverage | 机械任务却 0 个 bundled scripts（high-pass 模式跳过） |
| 6 | **X-ref⋆** | skill 文件里任何 ≥4 字符的字面字符串匹配训练 filename/field/value |
| 7 | **Under-abstraction⋆** | 强制断言嵌入了 parametric-axis 常量（terminal-state code / threshold），但**没有**"运行时重新推导"指令或 invariance provenance |
| 8 | **Primary-action hoisting⋆** | skill 声明了 primary_script，但 SKILL.md 在 invocation block **之前**放了 constraints / background prose，导致 using-agent 先读 constraints 然后从不调用 script |
| 9 | **Silent-bypass⋆** | skill 声明了 primary_script，但 exploration traces 里**零次** Bash 调用它（且 majority-fail）—— 一个正确的 skill 被 quietly ignored |

**关键认知**：Check 7/8/9 是论文新引入的、**只能通过 deployed-skill trace 才能检测**的失败模式（Check 9 的 silent-bypass 必须有真实 Domain-Skill Agent 执行 trace 才能发现）。这论证了 §1.2 "必须有 Domain-Skill Agent 真实执行"不是可选项。

**编号注**：论文标题说 "nine checks"，实际 Table 3 有 10 行（Check 2 和 2b 分开）。重构时按 10 个 check 实现。

---

## 6. Appendix A.1 Pseudocode 完整版

见本文档 §2。Algorithm 1 是论文给的最高权威规范。

---

## 7. Appendix A.3 Contamination Controls

### 7.1 Layer 1: Train/Test Split

- 所有 evolve loop iterations 跑在 T_train（生成的变体，不同的 data / filenames / sub-domain）
- validation 跑在 T_val
- **如果 skill 编码了 training-specific 的 filename/value，silently fails validation**（文件不存在）
- **每次 exploration 前删除 curated training skill**，确保它不可达

### 7.2 Layer 2: Workspace Whitelist（PreToolUse Hook 强制）

> "A PreToolUse hook **denies every agent tool call outside a single per-run workspace prefix**. The validation task directory, curated validation skill, and test suites live outside and are unreachable. A denylist tripwire checked before the whitelist denies `..` traversal and any path resolving into the curated training-skill slot. Path resolution checks both the raw and symlink-resolved paths."

**强制要求**：用 PreToolUse hook 实现，不是 prompt 提醒。

---

## 8. Appendix A.4 参数配置（论文实验使用）

| 参数 | 论文 R=2 配置 | 论文 R=1 ablation | 我们当前 |
|---|---|---|---|
| K (explore trials) | 4 | 4 | 6-7 |
| Re-explore at r=1 | 4 | — | 6-7 |
| V (validate trials) | 5 | 5 | T_val（未量化） |
| R (iteration cap) | 2 | 1 | 3 |
| Dollar budget | $15 | $15 | 无 |
| Turn budget | 200 | 200 | 无 |
| Total trials | 13 (2K+V) | 9 (K+V) | — |

**建议**：保持 R=2（论文 R=1→R=2 贡献 2/3 gain，但 R≥3 论文没测）。K=4 或 K=6 都可。

---

## 9. 当前 skill-evolver 实现的差距矩阵（重构清单）

| 论文要求（spec） | 当前实现 | 差距类型 | 重构优先级 |
|---|---|---|---|
| Domain-Skill Agent 真实执行 | evolver-explorer 模拟执行 | **架构缺失** | P0 |
| 策略每轮动态生成针对 v_r 弱点 | 固定 S1-S6 矩阵 | **方法论错** | P0 |
| Contrast 自动提取 Δ_r patch | "展示排名让用户选" | **方法论错** | P0 |
| Patch surgical（r>0） | "完整改写" | **方法论错** | P0 |
| Auditor 9 个机械检查 + binary gate | evolver-auditor rubric 打分 | **方法论错** | P1 |
| Workspace PreToolUse hook 隔离 | prompt 提醒 | **强制缺失** | P1 |
| Training skill 删除 | 不删 | **强制缺失** | P2 |
| T_train 和 T_val 不同 data/filename | 同一 jsonl | **隔离弱** | P2 |
| v* ← argmax score(T_train) 自动选 | 用户选 | **自动化缺失** | P2 |
| axes ← Parse(T_train) one-shot | baseline gap 分析近似 | 部分对齐 | P3 |

---

## 10. 重构非目标（明确不抄的部分）

避免重构时膨胀：

1. **不抄 Harbor**：论文用 Harbor framework 跑 container 隔离的 trials。我们没 Harbor，用 Claude Code 子 agent + 工作目录隔离近似。
2. **不抄 dollar/turn budget**：论文有 $15 / 200 turns 硬预算。我们没有自动计费，用 R 上限 + Phase 确认点近似。
3. **不抄 SkillsBench / KernelBench benchmark**：论文实验在标准化 benchmark 上跑。我们优化的 skill 没有 ground truth。
4. **不抄 SkillCreator-SkillsBench baseline**：论文比较的对照组，我们不需要。
5. **不抄 GPT/Codex 跨模型实验**：论文 §5 limitations 说"cross-LLM parity is a design property rather than a benchmark-scale empirical finding"。我们单模型环境即可。

---

## 11. SkillOpt 概念的处置（必须删）

SkillOpt (arXiv:2605.23904) **不作为重构参考**。原因：

1. SkillOpt 论文 §Limitations 原文：**"most directly applicable when the target task has automatic verifiers... For open-ended domains where success is subjective, multi-dimensional, or costly to judge, the validation gate may require stronger human or model-based evaluation."** —— 我们优化的全是开放式 skill
2. SkillOpt 单文件优化（best_skill.md < 2000 tokens）—— 我们是多文件 skill
3. SkillOpt 需要自动评分器 —— 我们没有 ground truth

**从 skill-evolver 删除的 SkillOpt 概念**：
- 双轨编辑（bounded edit / full rewrite）→ SkillEvolver 一直是 surgical patch
- textual learning rate → SkillOpt 独有
- Slow Update / Patch Saturation → SkillOpt 的 epoch-wise meta update
- diff-budget-check 脚本
- evolver-explorer 输出"完整 SKILL.md" → 应输出 patch Δ_r
- SkillOpt-analysis.md 文件 → 删除或归档
- SkillOpt-2605.23904v2.pdf → 删除（避免误导后续阅读）

---

## 12. darwin-skill 的关系（暂不动，但记录定位）

darwin-skill (8 维 rubric + hill-climbing + 5 Phase) **与 SkillEvolver 是不同抽象层**：

- **darwin-skill = 评分器**（rubric + hill-climbing 选最优版本）
- **SkillEvolver = 进化框架**（SDE + Contrastive Patch + Auditor）

**长期定位**：darwin-skill 的 rubric 可以作为 SkillEvolver 在**没有 ground truth** 场景下的 reward 近似（y_{r,i} 的替代信号）。但这是后续工作，本次重构不处理。

---

## 13. 重构验证标准（如何判断重构成功）

重构后的 skill-evolver 必须能通过以下"论文一致性检查"：

1. ✅ 存在 Domain-Skill Agent 角色（不是 explorer 模拟）
2. ✅ 每轮策略是动态生成的（不是 S1-S6 固定矩阵）
3. ✅ Contrast 输出是 patch Δ_r（不是"让用户选最高分版本"）
4. ✅ r>0 时是 surgical patch（不是完整重写）
5. ✅ Auditor 跑 9 个机械检查返回 binary gate（不是 rubric 打分）
6. ✅ Workspace 隔离用 hook（不是 prompt 提醒）
7. ✅ 删除所有 SkillOpt 概念（双轨编辑、learning rate、slow update、patch saturation）
8. ✅ Algorithm 1 的 14 步在 SKILL.md 流程里都有对应

---

## 变更日志

- **2026-06-18 初版**：基于 arXiv:2605.10500v1 HTML 全文抽取。覆盖 origin-paper.md 的错误描述。
