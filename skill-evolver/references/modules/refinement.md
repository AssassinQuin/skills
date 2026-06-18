# Module: Refinement Loop（Phase 3，r=1..R）

对应论文 Algorithm 1 line 6-12。每轮把 v_r 进化到 v_{r+1}，由 Auditor 9-check 守门。

```
for r = 1 to R:                                      # line 6
  Install v_r as dependency in trial workspace        # line 7
  S_r ← DiverseStrategies(axes, v_r, traces_{<r})    # line 8
  τ_r ← Explore(T_train, S_r, v_r, K)                # line 9
  Δ_r ← Contrast(τ_r+, τ_r-)                         # line 10
  ṽ_{r+1} ← Patch(v_r, Δ_r)                          # line 11：surgical patch
  (a_r, E_r) ← Audit(ṽ_{r+1}, T_train, traces)       # line 12
```

## 与 Bootstrap 的关键差异

| 维度 | Bootstrap (r=0) | Refinement (r>0) |
|------|----------------|------------------|
| Trial 行为 | 裸 agent + 策略 | **Domain-Skill Agent 用 v_r 解题** |
| 策略目标 | 覆盖 axes | **针对 v_r 弱点** |
| Patch 形式 | 从无到有创建 | **surgical patch（不重写）** |
| Audit | 无 | **每轮 9-check + binary gate** |

## 执行步骤（每轮 r = 1..R）

### Step 1: Install v_r as dependency（论文 line 7）

把当前 v_r 装到 Domain-Skill Agent 能加载的位置。

```bash
# 确保 v_r 已写入 {skill_dir}/SKILL.md
# 多文件 skill 时，确保整个目录是 v_r 状态
ls {skill_dir}/SKILL.md
```

**论文 line 7 注释原话**：
> "v_r is installed as a real dependency in the trial container, so the contrast at line 10 reflects where a fresh using-agent was actually helped or misled by the deployed skill."

**强制**：Domain-Skill Agent 必须真的 load v_r，不是把 SKILL.md 内容塞进 prompt。在我们的实现里：Domain-Skill Agent 子 agent prompt 只传路径，由它自己 Read 加载。

### Step 2: S_r ← DiverseStrategies(axes, v_r, traces_{<r})（论文 line 8）

主 agent 写新的 K 个策略，**针对 v_r 在历史 trial 中暴露的弱点**。

读取：
```bash
# 历史轨迹
jq -s '.' {skill_dir}/.evolve/traces.jsonl | head -100
# 上一轮 v_r
cat {skill_dir}/SKILL.md
```

识别 v_r 的弱点：
- 哪些 trial fail 了？为什么？
- 哪些策略导致 silent-bypass？
- 哪些指令被 Domain-Skill Agent 误读？
- primary_script 是否被实际调用？

针对弱点写 K 个策略：
```bash
mkdir -p {skill_dir}/.evolve/strategies/r{r}
# 每个 s_r_{i}.md 描述：针对哪个弱点 + 用什么高层方案修补 + 在 v_r 基础上怎么验证修补有效
```

**仍然执行两个检查**（与 Bootstrap Step 1 相同）：
1. 去重：K 个策略在主要 axis 上不能完全相同
2. 参数化：每个 parametric axis 至少有一个策略要求运行时推导

记录到 strategies.jsonl。

### Step 3: τ_r ← Explore(T_train, S_r, v_r, K)（论文 line 9）

为 K 个策略**并行** spawn K 个 Domain-Skill Agent。这次 prompt **包含 candidate skill 路径**：

```
Agent(
  description="trial-r{r}-s{i}",
  subagent_type="domain-skill-agent",
  model="sonnet",
  prompt="""
[CANDIDATE SKILL]
{skill_dir}/SKILL.md  ← 加载这个 skill 真实用它解题

[T_TRAIN TASK]
{t_train_prompt}

[STRATEGY s_r_{i}]
{策略内容，针对 v_r 弱点}

[REWARD DEFINITION]
{reward_type + reward_def}
"""
)
```

**Workspace 隔离强制**：prompt 只包含上述四项。**禁止传**：
- evolution-log.jsonl
- traces.jsonl（其他 trial）
- strategies.jsonl
- SkillEvolver Agent 的策略分析 / gap 推理 / 痛点描述

每个 Domain-Skill Agent 返回 (τ, y, silent_bypass_flag, primary_script_called_flag)。

### Step 4: Δ_r ← Contrast(τ_r+, τ_r-)（论文 line 10）

主 agent 选 τ+ 和 τ-，做 verbal contrast（与 Bootstrap Step 3 相同）。

**额外关注**：
- 如果有任何 trial 标记 `silent_bypass=true` 或 `primary_script_called=false` → 这些信号会喂给 Auditor Check 8/9
- 如果全部 τ+ 都 fail → 不要强行做 contrast，直接进入 Fallback

### Step 5: ṽ_{r+1} ← Patch(v_r, Δ_r) — surgical patch（论文 line 11）

**关键约束**（论文原话）：
> "Line 11 applies a surgical patch rather than rebuilding from scratch"

> "At r>0, it patches v_r rather than rewriting it, preserving working guidance while adding only the missing constraint, code pattern, or tool exposed by the latest contrast"

**操作**：
1. 在 v_r 基础上**只改动** Δ_r 触及的部分
2. 不动其他已工作内容
3. 用 Edit 而非 Write（精确小改）
4. 改动有明确动机（每个改动对应 Δ_r 一个 candidate feature）

```bash
# 主 agent 用 Edit 工具按 Δ_r 做定点修改
# 不要重写整个 SKILL.md
```

产出 ṽ_{r+1}（带 tilde，表示待审计版本）。

### Step 6: (a_r, E_r) ← Audit(ṽ_{r+1}, T_train, traces)（论文 line 12）

读取 [audit.md](audit.md) 执行 Auditor 9-check（v8.1 含 Check 10 硬约束自验证）。

**v8.1 Gate 2 强制**：每个 ṽ_{r+1} patch 完成后**立即** spawn Auditor，**不允许批量延迟到最后一轮**。违反则整个 round 无效。

```
patch ṽ_{r+1}
  ↓ 立即（同 tool_calls 块或下一个 tool_call）
spawn evolver-auditor (opus, fresh context)
  ↓
accept → 进入 Step 7 accept 分支
reject → 用 E_r 做 targeted patch（同 r 重试）
```

返回：
- `a_r`：binary gate（accept / reject）
- `E_r`：violations 列表（含 v8.1 Check 10 violations 如有）

### Step 6b: Token 预算检查（v8.1 Gate 4）

每轮 r 结束前检查 token 消耗：

```
主上下文累计 tokens ≤ 50k？
子 agent 独立 context 每个 ≤ 30k？
  ↓ 任一超出
立即停止当前 r，展示当前 v_r 状态
写入 evolution-log：{"phase":"refinement","r":r,"stop_reason":"token_budget_exceeded","main_tokens":X,"agent_tokens":[...]}
```

长文档（>300 行 / >2000 字）必须 `ctx_index` + `ctx_search`，不全文进上下文。

### Step 7: 根据 audit 结果分支

```
if a_r == accept:
    v_{r+1} = ṽ_{r+1}    # tilde 去掉，正式版本
    保存 snapshots/{skill}-v{r+1}.md
    if r < R:
        r += 1, 回到 Step 1
    else:
        进入 Phase 4 Finalize
else:  # reject
    用 E_r 做 targeted patch（同 r 重试，r 不变）
    - 最多重试 2 次
    - 第 3 次 reject → 终止 + 写 failure report
    - **v8.1 强化**：reject 时主 agent 不允许跨 r 带病前进（v8.0 曾允许早轮跳过 audit，导致后期才发现过累积违规）
```

### Step 8: Checkpoint（每轮结束）

**展示给用户**：
- v_r 在历史 trial 中的弱点分析
- S_r 策略集
- K 个 trial 的 (τ, y) 摘要 + silent_bypass / primary_script_called 统计
- τ+ / τ- 选择 + Δ_r
- surgical patch diff（v_r → ṽ_{r+1}）
- Audit 9-check 结果 + violations
- 决定：accept v_{r+1} / targeted patch retry / 终止
- 本轮局限：必须声明

## Fallback

| 情况 | 处理 |
|------|------|
| Audit reject ≥ 3 次 | 终止 + 写 failure report（包含所有 E_r 历史） |
| K 个 trial 全 fail | 同 Bootstrap Fallback |
| Domain-Skill Agent 全部 silent-bypass | 说明 v_r 严重不通——回 Bootstrap 重设计 v_1 |
| 修补引入新 violation（regression） | 回滚到上一版本，记录到 traces.jsonl 失败经验 |

## 输出

每轮 r 完成后：
- `strategies/r{r}/s_r_{i}.md` × K
- `traces.jsonl` 增 K 条 r 记录
- `evolution-log.jsonl` 增 `{"phase":"refinement","round":r,"v_before":"v_r","v_after":"v_{r+1}","delta_count":N,"audit":"accept|reject","violations":[...]}`
- `snapshots/{skill}-v{r+1}.md`
