# Module: Baseline（基线评估 + 差距理解 + 轨迹收集）

前置条件：无。预估 token：~14K。

## 执行步骤

### Step 1: 确认进化范围 + 脚本初始化

```bash
source scripts/evolve.sh
phase-start baseline {skill_dir}
```

- 用户指定 → 直接使用
- 用户未指定 → 扫描所有 skill 的 5 维评分，展示 TOP-10 低分列表

### Step 2: Trace Collection（实证信号）

搜索 `~/.claude/projects/` 会话文件，提取目标 skill 的使用记录。保存到 `.evolve/traces.jsonl`。

trace_source 判定：≥3 条→`empirical`，1-2 条→`sparse`，0 条→`none`。

### Step 3: 读取历史指标 + 痛点收集

读取 `.evolve/metrics.json`，按 [constants.md](../constants.md) 中的效率告警阈值检查。

**痛点写入（Mode G 时）**：用户提供痛点 → `pp-create` 写入 `.evolve/pain-points.jsonl`，source="user-stated"。

### Step 4: 创建 git 分支

```bash
git-setup {skill_name}
```

### Step 5: 基线评估

按 5 维 Rubric 评分。评分权重和锚点见 [constants.md](../constants.md)。

**每个维度 0-10 分**。总分由 `score` 命令计算：
```bash
score D1 D2 D3 D4 D5
```

### Step 6: 设计测试集（T_train / T_val 拆分）

设计 5-8 个测试 prompt，保存到 `.evolve/test-prompts.json`。
- T_train(60%)：exploration 评分用
- T_val(40%)：held-out，仅 deployment 可见

### Step 7: 初始化 .evolve 目录

```bash
mkdir -p {skill}/.evolve/audit-reports
```

### Step 8: 差距分析

**痛点推断写入**：
- traces 中同一失败点 >= 3 次 → `pp-create`，source="trace-inferred"
- 连续 2 轮某维度 <= 4 → `pp-create`，source="audit-found"

### Step 9: Quick Fix 判定

```bash
quick-fix-check {skill_dir}
```

- `QUICK_FIX_OK` → 跳过 exploration，直接 application
- `FULL_EVOLUTION` → 进入 exploration 模块

### Step 10: Checkpoint（CP-01）

```bash
git-checkpoint "evolve {skill}: baseline+gap-r{r}"
```

## 关卡：用户确认

展示：trace_source + 基线评分 + 差距报告 + Quick Fix 判定结果。
