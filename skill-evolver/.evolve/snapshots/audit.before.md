# Module: Audit（论文 §3.2.3 + Appendix A.2）

对应论文 Algorithm 1 line 12：`(a_r, E_r) ← Audit(ṽ_{r+1}, T_train, traces)`。

**已彻底重写**：删除 v7 的 D1-D5 rubric 5 维评分。改为论文 Appendix A.2 Table 3 的 9 个机械检查（实际 10 行，含 2b）+ binary gate。

## 强制要求（论文 §3.2.3）

- **独立 fresh context 子 agent**（model=opus）
- Auditor 收到的输入**严格白名单**：

| ✅ 允许 | ❌ 禁止 |
|--------|--------|
| candidate skill (ṽ_{r+1}) 路径 | T_val 测试 prompts |
| task instruction | SkillEvolver Agent 的策略分析 |
| T_train 训练数据 | SkillEvolver Agent 的 gap 推理 |
| labelled traces {(τ_{r,i}, y_{r,i})} | evolution-log 历史 |
| 9 个 check 的 rubric（本文件） | traces 里**其他轮次**的轨迹（只给本轮） |

调用方式：

```
Agent(
  description="audit-r{r}",
  subagent_type="evolver-auditor",
  model="opus",
  prompt="""
[CANDIDATE SKILL ṽ_{r+1}]
{skill_dir}/SKILL.md

[T_TRAIN TASK]
{t_train 任务描述，本轮 K 个 trial 用过的}

[LABELLED TRACES]
{本轮 K 个 (τ, y) 摘要，含 silent_bypass / primary_script_called 标记}

[RUBRIC]
{本文件 §1 的 9 个 check + binary gate 契约}
"""
)
```

## 1. 9 个机械检查（论文 Appendix A.2 Table 3）

⋆ = critical check，任何命中 → **强制 reject** + 下一轮 targeted patch。

### Checks 1-6：标准 content-level 泄露

| # | Check | 触发条件 | 严重度 |
|---|------|---------|-------|
| 1 | **Framing⋆** | name / description 借用了训练实例的**业务名词**（如具体公司名 / 项目名 / 用户名），而非抽象操作 | critical |
| 2 | **Literals⋆** | 硬编码训练 filename / field name / entity string / 软限定数字（如 "typically << 2.5"、"about 100"） | critical |
| 2b | Script bloat | 单脚本 >200 行（important）/ >400 行（critical）—— 几乎总是 bundled solution generator，不是 focused utility | important / critical |
| 3 | Untraceable | 强制断言（"use X not Y" / "never" / "required"）无 trace 来源且非 pretraining 显然 | standard |
| 4 | **Shape-bake⋆** | 脚本硬编码 column / sheet / key 而无 runtime probe（`df.columns` / `wb.sheetnames`）；单脚本 ≥3 个 `if "keyword" in desc` 分支 = keyword-dispatch solution-generator | critical |
| 5 | Coverage | 机械任务却 0 个 bundled scripts（high-pass 模式跳过） | standard |
| 6 | **X-ref⋆** | skill 文件里任何 ≥4 字符的字面字符串匹配训练 filename / field / value | critical |

### Checks 7-9：论文新引入的 deployed-skill 失败模式

| # | Check | 触发条件 | 严重度 |
|---|------|---------|-------|
| 7 | **Under-abstraction⋆** | 强制断言嵌入了 parametric-axis 常量（terminal-state code / threshold / magic number），但**没有**"运行时重新推导"指令或 invariance provenance | critical |
| 8 | **Primary-action hoisting⋆** | skill 声明了 primary_script，但 SKILL.md 在 invocation block **之前**放了 constraints / background prose，导致 using-agent 先读 constraints 然后从不调用 script | critical |
| 9 | **Silent-bypass⋆** | skill 声明了 primary_script，但 exploration traces 里**零次** Bash 调用它（且 majority-fail）—— 一个正确的 skill 被 quietly ignored | critical |

**Check 7/8/9 关键性**（论文原话）：
> "Checks 7–9 are observable only because our pipeline refines against traces of the candidate skill as a live dependency, not against the authoring agent's reflection on its own work."

Check 9 必须从 traces 拿证据，不能从 skill 文本判断。

## 2. 输出契约（必须严格遵守）

Auditor 返回单个 markdown 块：

```markdown
## Audit Report: {skill-name} R{round}

### 9-check 结果

| # | Check | Hit? | Evidence |
|---|-------|------|----------|
| 1 | Framing | NO | — |
| 2 | Literals | YES | line 42: "input.json" hardcoded |
| 2b | Script bloat | NO | largest script: 87 lines |
| 3 | Untraceable | NO | — |
| 4 | Shape-bake | YES | scripts/parse.py:12 indexes column by hardcoded "name" |
| 5 | Coverage | N/A | non-mechanical task |
| 6 | X-ref | YES | "acmecorp" matches training filename |
| 7 | Under-abstraction | NO | — |
| 8 | Primary-action hoisting | NO | — |
| 9 | Silent-bypass | NO | primary_script called 3/4 trials |

### Violations (E_r)
1. [critical] Check 2: hardcoded "input.json" in line 42 — should be runtime-derived
2. [critical] Check 4: scripts/parse.py uses df["name"] without runtime probe
3. [critical] Check 6: "acmecorp" leaked from training data

### Binary Gate (a_r)
REJECT  # 3 critical violations

### Targeted Patch Suggestions
- Replace "input.json" with `{user_provided_path}` and add runtime check
- Replace df["name"] with `df.columns.intersection(["name", "Name", "NAME"])[0]`
- Remove "acmecorp" reference, generalize to "vendor name"
```

若无法满足，最后一行必须是 `[FAIL] {原因}`。

## 3. 主 agent 后处理（Audit 返回后）

### Step 1: Contamination 检查

主 agent 检查 Audit 报告是否泄露训练信号（论文 §A.3 Layer 2 强化）：

| 泄露信号 | 处理 |
|----------|------|
| 报告引用"策略 s_{r,i}" | 标 `[CONTAMINATION WARNING]`，重新调用 Auditor |
| 报告引用 pain-points 内容 | 同上 |
| 报告引用 evolution-log 历史 | 同上 |
| 报告引用 T_train 之外的 prompt | 同上 |

### Step 2: 根据 binary gate 分支

```
if a_r == accept (无 critical violation):
    v_{r+1} = ṽ_{r+1}
    进入下一轮或 Phase 4
elif a_r == reject:
    用 E_r 的 Targeted Patch Suggestions 做 surgical patch
    重试同 r（最多 2 次）
    第 3 次 reject → 终止 + 写 failure report
```

### Step 3: 保存审计报告

```bash
mkdir -p {skill_dir}/.evolve/audit
cat > {skill_dir}/.evolve/audit/r{r}.md <<EOF
{Auditor 完整报告}
EOF
```

记录到 evolution-log.jsonl：
```json
{"phase":"audit","round":r,"gate":"accept|reject","critical_count":N,"standard_count":N,"violations_summary":[...]}
```

### Step 4: 失败经验记录（reject 时必须）

```bash
# 论文要求：violations 必须用于下一轮 targeted patch
# 不再使用 rejected-edit-record 脚本（已删），直接 jq 写 traces.jsonl
cat >> {skill_dir}/.evolve/traces.jsonl <<EOF
{"type":"audit_reject","round":r,"violations":[...],"ts":"..."}
EOF
```

## 4. Fallback

| 情况 | 处理 |
|------|------|
| opus Auditor 超时 | 降级 sonnet 跑 Checks 1-6（content-level），跳过 7-9（需要 trace 证据） |
| sonnet 也超时 | 极速审计：主 agent 自己跑 Checks 2/6（grep 字面字符串匹配） |
| 全部降级失败 | 标 `audit=UNVERIFIED`，强制人工确认才接受 v_{r+1} |

### Step 5: Checkpoint（CP-AUDIT）

展示给用户：a_r (accept/reject)、violations E_r、targeted patch suggestions。决定：
- accept → 进入下一轮或 Phase 4
- reject → 用 E_r 做 targeted patch，同 r 重试

**检查点意义**：audit 是 paper-spec §3.2.3 强制的 binary gate。在这里拦截成本最低。

## 5. 论文一致性自检

| 论文要求 | 本模块实现 | 状态 |
|---------|----------|------|
| binary gate（不是 rubric 打分） | `a_r ∈ {accept, reject}` | ✅ |
| 返回 violations 列表 | E_r | ✅ |
| 9 个机械检查（Table 3） | §1 完整 10 行（含 2b） | ✅ |
| Workspace 白名单 | §强制要求 + Contamination 检查 | ✅ |
| Fresh-session | `Agent()` 子 agent fresh context | ✅ |
| Reject 强制下一轮 targeted patch | §3 Step 2 分支 | ✅ |
