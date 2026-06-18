# Module: Initialize（Phase 1）

对应论文 Algorithm 1 line 1：`axes ← Parse(T_train)` + 工作目录初始化。

## 目标

把目标 skill 的当前状态、训练任务、决策轴、Git 分支准备好。Phase 1 不产出 v_1（v_1 在 Phase 2 Bootstrap 创建）。

## 执行步骤

### Step 1: 确认范围 + 初始化工作目录

```bash
mkdir -p {skill_dir}/.evolve/{snapshots,strategies,traces,logs}
```

读取：
- 目标 skill 的 SKILL.md
- references/（如有）
- scripts/（如有）
- README.md（如有）

### Step 2: T_train / T_val 拆分（论文 Appendix A.3 Layer 1）

设计测试 prompt 集，**严格分离**：

```bash
cat > {skill_dir}/.evolve/test-prompts.json <<EOF
{
  "T_train": [
    {"id": "t1", "prompt": "...", "reward_type": "binary|scalar", "reward_def": "..."},
    {"id": "t2", ...}
  ],
  "T_val": [
    {"id": "v1", "prompt": "...", "reward_type": "...", "reward_def": "..."}
  ]
}
EOF
```

**论文要求（§A.3 Layer 1 原话）**：
> "A skill that encodes a training-specific filename or value silently fails validation – the file is not there."

**强制**：T_train 和 T_val 必须用**不同的 data / filename / sub-domain**。如果 T_train 用了 `foo.json`，T_val 不能再用 `foo.json`。

### Step 2b: Skill 类型检测（v8.1 新增，强制）

T_train / T_val 拆分后，立即检测 skill 类型，决定 Phase 2-4 的 reward 协议：

```
检测 3 个信号：
1. allowed-tools 含脚本执行工具？（Bash/Edit/Write/MCP 执行类）
2. references/ 含可执行 examples / test-prompts？
3. SKILL.md 主流程产生可量化副产物？

类型判定：
- 执行型：1=Yes + 2=Yes(binary) → Domain-Skill Agent + binary reward
- 研究型：3=Yes + 2=No(定性) → Evaluation-Trace Agent + qualitative reward
- 文档型：全 No → Reviewer Checkpoint + 5-question review
```

详见 [skill-taxonomy.md](skill-taxonomy.md)。

写入 evolution-log：
```json
{"phase":"initialize","skill_type":"execution|research|document","reward_protocol":"binary|qualitative|review"}
```

### Step 2c: T_train ≠ T_val 显式验证（v8.1 Gate 3）

研究型 skill 特别严（容易过拟合到单一评估对象）：

```
T_train / T_val 类型必须不同：
- 执行型：T_train 用 file_A，T_val 用 file_B（不同 filename）
- 研究型：T_train 用 [repo_1, repo_2, repo_3]，T_val 用 [repo_4, repo_5]（不同仓库 + 不同类型）
- 文档型：T_train 用 scenario_A，T_val 用 scenario_B（不同使用场景）
```

**Phase 1 拒绝 T_train = T_val**（同一任务 / 同一评估对象）。检测方式：
- T_train 和 T_val 的 `prompt` 字段不能完全相同
- T_train 和 T_val 的 `data` / `target` 字段不能完全相同
- 研究型 skill：T_train 和 T_val 的评估对象类型必须有交集外的差异

### Step 3: Parse(T_train) → axes（论文 §3.1 one-shot Understand）

读取 T_train，识别任务的**决策轴**（decision axes）。axes 是高层决策维度，例如：

| 轴类型 | 例子 |
|--------|------|
| 库/工具选择 | jq vs python；grep vs ripgrep |
| 算法族 | 贪心 vs DP vs 回溯；同步 vs 异步 |
| 指令解读 | 严格字面 vs 意图推断 |
| 输出形态 | markdown 表格 vs JSON vs 自由文本 |
| 错误处理 | fail-fast vs best-effort |

```bash
cat > {skill_dir}/.evolve/axes.json <<EOF
{
  "axes": [
    {"name": "library_choice", "options": ["jq", "python"], "type": "parametric"},
    {"name": "instruction_interpretation", "options": ["literal", "intent"], "type": "parametric"},
    ...
  ],
  "training_constants": [
    {"name": "input_filename", "value": "foo.json", "type": "parametric"},
    ...
  ]
}
EOF
```

**Parametric vs Invariant 标记**（论文 §3.2.1 原话）：
> "A second check marks each concrete training constant as either invariant or parametric; for every parametric axis, at least one strategy must derive the value at runtime rather than copy the training value."

- `parametric`：训练里出现的具体值（如 filename），抽象 skill 时不能硬编码
- `invariant`：与训练无关的固定值（如 yaml 格式名）

### Step 4: 基线评分（可选，论文无要求但便于对比）

用当前 SKILL.md 跑一次 self-audit（D1-D5 旧 rubric 已删，改用 paper-spec.md §13 的"论文一致性自检"清单）。

### Step 5: Git 分支 + BEFORE 快照

```bash
git checkout -b evolve/{skill-name}/$(date +%Y%m%d)
cp -r {skill_dir}/SKILL.md {skill_dir}/.evolve/snapshots/{skill-name}-BEFORE.md
# 多文件 skill 时，整个目录快照
```

### Step 6: Checkpoint（CP-01）

**展示给用户**：
- T_train / T_val 拆分（特别是两者的 filename / data 差异）
- 识别到的 axes + parametric constants
- BEFORE 快照路径
- 本轮局限（必须声明，禁止写"无"）：例如"只测了 3 个 T_train prompt，覆盖度可能不足"

**确认后才能进入 Phase 2**。

## 失败模式诊断

如果 Phase 1 卡住，对照 [failure-modes.md](../failure-modes.md) 的 FM1-FM7。

| 症状 | 可能 FM | 缓解 |
|------|--------|------|
| 拆不出 axes | FM6 触发模糊 | 让用户提供 2-3 个典型使用场景 |
| T_train / T_val 太相似 | （新）过拟合风险 | 强制要求不同 filename |
| Parametric constants 太多 | FM3 输出膨胀 | skill 设计需抽象化 |

## 输出

完成后，`.evolve/` 下应包含：
- `axes.json` — 决策轴
- `test-prompts.json` — T_train / T_val 拆分
- `snapshots/{skill}-BEFORE.md` — BEFORE 副本
- `evolution-log.jsonl` — 第一行：`{"phase":"initialize","ts":"...","axes_count":N,"t_train_count":N,"t_val_count":N}`
