---
name: adaptive-control
description: Adaptive Control — drift_score 公式 + 决策表 + oracle 重新分解触发条件。
source: "design.md §10"
status: skeleton
---

# Adaptive Control（drift_score 反馈环）

> **加载时机**：Phase 4 子 agent 返回 drift 遥测后；drift ≥ 0.2 时主加载。

## drift_score 公式

每个 Phase 4 subtask 完成后，子 agent 返回遥测 JSON：

```json
{
  "estimated_files": 3, "actual_files": 7,
  "estimated_loc": 150, "actual_loc": 420,
  "unplanned_dependencies": ["github.com/new/lib"],
  "super_violations": [{"module": "internal/auth", "principle": "S", "before": "🟢", "after": "🟡"}],
  "test_failures_unexpected": 2
}
```

orchestrator 计算：

```
drift_score = 0.4 × file_overrun + 0.3 × loc_overrun + 0.2 × unplanned_deps + 0.1 × super_decay

file_overrun = max(0, actual_files - estimated_files) / max(estimated_files, 1)
loc_overrun  = max(0, actual_loc - estimated_loc) / max(estimated_loc, 1)
unplanned_deps = min(1.0, len(unplanned_dependencies) / 5)
super_decay = count(🟢→🟡/🔴) / total_principles_checked
```

drift_score ∈ [0, 1]。

## 决策表（Q1 配套：spawn oracle）

| drift_score | 动作 | 用户交互 |
|---|---|---|
| `< 0.2` | 继续 | 无 |
| `0.2 - 0.4` | 下个 subtask 加 warning annotation | 无 |
| `0.4 - 0.6` | 🌟 **spawn oracle 重新分解**（opus fresh context）| 🔒 展示新计划 + 确认 |
| `> 0.6` | 🌟 **spawn oracle 回 Phase 0 重新对齐意图** | 🔒 强制澄清 |

## oracle 重新分解 prompt（drift 0.4-0.6）

```
你是战略分析师。任务跑偏了，需要重新分解。

输入:
- 原计划: {Phase 3 输出}
- 实际进度: {已完成的 subtask + drift JSON}
- drift_score: {0.X}（超阈）

任务:
1. 分析跑偏原因（高估 / 新依赖 / 架构问题）
2. 给出剩余 subtask 的新分解
3. 评估是否需要回 Phase 0 重新对齐

约束:
- 不重写已完成的部分
- 新分解要可执行（明确文件 / LOC / 步骤）

输出 schema: JSON
  {root_cause, new_plan: [{subtask, files, loc, rationale}], need_phase_0: bool}
```

## oracle 回 Phase 0 prompt（drift > 0.6）

```
你是战略分析师。任务严重跑偏，需要回 Phase 0。

输入:
- 原 Phase 0 意图: {...}
- 实际进度: {...}
- drift_score: {0.X}

任务:
1. 判断意图是否理解错了（vs 执行错了）
2. 若意图错了 → 给出新意图候选
3. 若执行错了 → spawn oracle 重新分解（不是 Phase 0）

输出 schema: JSON
  {intent_misunderstood: bool, new_intent_candidates: [], recommendation: ""}
```

## 约束

- drift_score 计算需要子 agent 配合（必须返回遥测 JSON）
- 子 agent 不返回 → drift_score=0（乐观）+ 标 "⚠️ 无遥测"
- 用户可在汇报后 override drift 决策

## 反例（避免）

- ❌ drift ≥ 0.4 时继续死执行（小问题滚成大返工）
- ❌ drift 计算时忽略 S.U.P.E.R 衰减（架构债）
- ❌ spawn oracle 后无条件接受其新计划（🔒 必须用户确认）

## TODO（待 step 2 扩充）

- [ ] drift_score 各阈值的真实 case
- [ ] oracle 重新分解的 markdown 报告模板
- [ ] drift 历史（同任务跨 subtask 的 drift 趋势）

## 引用

- design.md §10
- `phase-3-design-options.md`（oracle 模板）
- `phase-4-execution-protocol.md`（遥测 schema）
