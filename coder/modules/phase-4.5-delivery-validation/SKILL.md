---
phase: 4.5
name: phase-4.5-delivery-validation
description: Phase 4.5 子 agent delivery 校验协议。orchestrator 收集所有 subagent delivery → 跑 validate-delivery.py → 不合格返工。
source: ".deepen/20260625-execution-flow/design.md §3 Phase 4.5"
status: active
tokens_estimate: 1200
load_priority: on-demand
load_when: "Phase 4 完成后"
keywords: validate-delivery delivery-schema 7 rules drift adaptive-control rework
domain: coding
subdomain: phase
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  notes: "contract-based verification + drift detection"
---

# Phase 4.5: 子 agent 交付检查（v6.0 新增）

> **加载时机**：Phase 4 所有子 agent spawn 返回后，进 Phase 5 之前。
> **目的**：所有子 agent 必须按 `delivery-schema` 格式输出，否则返工。

## 核心流程

```
Phase 4 完成（所有子 agent 返回）
  ↓
orchestrator 收集每个子 agent 输出末尾的 delivery YAML 块
  ↓
对每个 delivery 跑：
  python3 .claude/scripts/validate-delivery.py <output.md> \
    --git-diff --allowed-deps <spec.allowed_deps>
  ↓
全部 PASS → Phase 5
任一 FAIL → 重新 spawn 该子 agent（带返工理由）
drift_score ≥ 0.4 → 回 Phase 3 重新分解（adaptive control）
```

## orchestrator 内联执行协议

### 1. 收集 delivery（无独立 subagent）

orchestrator 自己读每个子 agent 的返回值，提取末尾的 YAML 块：

```
对每个子 agent 输出：
  1. 用 regex 找最后一个 ```yaml ... ``` 块
  2. 验证块内含 'delivery:' 顶字段
  3. 把块写入 .claude/coder-state/specs-active/{spec_id}/delivery-{N}.yaml
```

### 2. 校验

**单个 delivery 校验命令**：
```bash
python3 .claude/scripts/validate-delivery.py \
  /tmp/agent-output-{N}.md \
  --git-diff \
  --allowed-deps "$(jq -r '.allowed_deps | join(",")' spec metadata)"
```

**批量校验脚本**（orchestrator 内联）：
```bash
ALL_PASS=true
for f in .claude/coder-state/specs-active/{spec_id}/delivery-*.yaml; do
  echo "=== validating $f ==="
  if ! python3 .claude/scripts/validate-delivery.py "$f" --git-diff; then
    ALL_PASS=false
    FAILED_DELIVERY="$f"
  fi
done

if $ALL_PASS; then
  bash .claude/scripts/coder-state.sh update-phase "Phase 4.5" completed
  # 进 Phase 5
else
  # 见下面"返工流程"
fi
```

### 3. 整合 diff

orchestrator 把所有 delivery 的 `files_changed` 聚合成完整 diff 清单，传给 Phase 5 reviewer：

```yaml
aggregated_diff:
  source: Phase 4 deliveries
  total_files_changed: 8
  total_lines_added: 234
  total_lines_removed: 56
  files:
    - path: src/auth/login.py
      risk_level: high
      changed_by: python-coder-project (task p4-impl-login)
    - path: tests/test_login.py
      risk_level: low
      changed_by: python-coder-project (task p4-impl-test)
  high_risk_files:
    - src/auth/login.py
  new_dependencies: []  # 必须为空（除非 spec 允许）
```

### 4. drift 监控

orchestrator 计算聚合 drift_score：

```python
# 取所有 delivery drift_score 的 max（不是 avg——一坏则坏）
max_drift = max(d.outputs.drift_score for d in deliveries)
sum_file_overrun = sum(d.outputs.drift_breakdown.file_overrun for d in deliveries)
sum_loc_overrun = sum(d.outputs.drift_breakdown.loc_overrun for d in deliveries)

if max_drift >= 0.4 or sum_file_overrun >= 3 or sum_loc_overrun >= 50:
    # 触发 adaptive control
    # 回 Phase 3 让 oracle 重新分解
```

## 返工流程

### 情况 1：单个 delivery 不合格（字段缺失 / verification 全 FAIL / focus_areas 空）

```
1. orchestrator 把 validate-delivery.py 的 violations 列表作为 prompt
2. 重新 spawn 同一个 {lang}-coder-project，prompt 含：
   "前次 delivery 不合格：
    - {violation 1}
    - {violation 2}
    请修复并重新返回 delivery。"
3. state.json tasks[].status = "rework"
4. 最多返工 2 次，第 3 次失败 → 标记 task failed，AskUserQuestion 用户决策
```

### 情况 2：drift_score ≥ 0.4（adaptive control 触发）

```
1. orchestrator 不返工子 agent
2. 把所有 deliveries + drift 信息回传给 oracle
3. oracle 重新分解任务（可能拆更细 / 改方案）
4. 用户重新确认 design
5. 重新走 Phase 4
```

### 情况 3：files_changed 与 git diff 不一致

```
1. 子 agent 声明改了 A.py 但 git diff 没有 → 子 agent 撒谎
2. 反过来：git diff 有 D.py 但 delivery 没声明 → 漏报
3. 直接 BLOCK + 返工（情况 1）
```

## 退出条件

Phase 4.5 → Phase 5：
- ✅ 所有 delivery 校验通过（rc=0）
- ✅ state.json `phases["Phase 4.5"] = completed`
- ✅ aggregated_diff 已生成（给 Phase 5 用）
- ✅ drift < 0.4（否则 adaptive control 已触发）

## 跳过场景

用户在 Phase 0 没选 Phase 4.5 → 跳过，直接 Phase 5。
但 Phase 5 的 reviewer 仍会做基础校验（只是不跑 validate-delivery.py）。

## Anti-pattern

### ❌ orchestrator 自己当 reviewer

Phase 4.5 是**校验**（delivery 格式 + 一致性），不是**审查**（逻辑正确性）。
审查在 Phase 5 reviewer，不能混。

### ❌ 跳过 Phase 4.5 "因为 delivery 看起来 OK"

`validate-delivery.py` 跑一次成本 < 5 秒，但能拦住：
- 子 agent 撒谎（files vs git diff 不一致）
- drift 累积（5 个子 agent 各 drift 0.3 → 整体 0.6 该回 Phase 3）
- verification 全 SKIP（agent 没跑测试就说完成）

### ❌ drift 触发但不回 Phase 3

drift ≥ 0.4 还硬走 Phase 5 → reviewer 发现一堆问题 → 返工更多。
**正确**：直接回 Phase 3 重新分解，符合 R10（长任务检查点）。

## 与 §11 Anti-pattern 的关系

- §11.5 "汇报时只写完成的" → Phase 4.5 强制 delivery 完整（包括 known_caveats）
- §11.6 "简单任务滑坡" → 即使单子 agent 也要走 Phase 4.5（除非用户跳过）
- §11.7 "Edit 前没排查同类模式" → delivery 的 files_changed 与 git diff 对比能发现"漏改"

## 引用

- 设计：[`.deepen/20260625-execution-flow/design.md`](../.deepen/20260625-execution-flow/design.md) §3 Phase 4.5
- delivery 格式：[`templates/delivery-schema.yaml`](../templates/delivery-schema.yaml)
- 校验脚本：[`scripts/validate-delivery.py`](../scripts/validate-delivery.py)
- 子 agent 协议：[`templates/agents/_delivery-template.md`](../templates/agents/_delivery-template.md)
- 上游：[`phase-4-execution-protocol.md`](phase-4-execution-protocol.md)
- 下游：[`phase-5-verification.md`](phase-5-verification.md)
