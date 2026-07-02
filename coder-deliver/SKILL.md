---
phase: 4.5
name: coder-deliver
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
version: "1.1"
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

---

## 强化：pytest 真跑了校验（v7.3 · dim8 补强）

> 来源：2026-07-02 session S1 子 agent 报 `pytest: PASS` 但实际因 hook 阻塞 + fixture loop scope 问题未跑通；validate-delivery.py 信任自报导致 orchestrator 推进基于错误假设。

### 新增 mandatory delivery 字段

所有 spawn 子 agent 必须在 delivery 末尾输出：

```yaml
verification:
  lint: PASS|FAIL
  type_check: PASS|FAIL
  tests:
    ran: bool                    # 是否真的跑了 pytest（不是自报 PASS）
    passed: int                  # 真实通过数（从 pytest 输出解析）
    failed: int                  # 真实失败数
    output_snippet: str          # 最后 20 行 pytest 输出（含 ===== N passed in X.XXs ===== 行）
    skipped_reason: str | null   # 若 ran=false 必填："hook blocked" / "DB unavailable" / "fixture broken"
```

### validate-delivery.py 强校验规则（v7.3 升级）

```python
# 旧版（v1.x）：只校验 lint/type_check/tests 字段存在
# 新版（v7.3）：tests 必须是 dict 且 ran=true 才算合格

def validate_tests_field(delivery: dict) -> list[str]:
    issues = []
    tests = delivery.get("verification", {}).get("tests")

    # 场景 1：tests 是 string（旧格式 "PASS" / "N passed"）
    if isinstance(tests, str):
        issues.append("tests 字段必须是 dict（v7.3 升级），含 ran/passed/failed/output_snippet")
        return issues

    # 场景 2：tests.ran = false
    if not tests.get("ran"):
        reason = tests.get("skipped_reason")
        if not reason:
            issues.append("tests.ran=false 但 skipped_reason 为空（必须说明为什么没跑）")
        else:
            # ran=false 的 slice 不许进 Phase 5，必须返工
            issues.append(f"tests 未真跑（{reason}），delivery=incomplete，必须返工或显式标 skip_phase5=true")

    # 场景 3：ran=true 但 output_snippet 空
    if tests.get("ran") and not tests.get("output_snippet", "").strip():
        issues.append("tests.ran=true 但 output_snippet 空（必须附 pytest 最后 20 行含统计行）")

    # 场景 4：ran=true 但 failed > 0
    if tests.get("ran") and tests.get("failed", 0) > 0:
        issues.append(f"tests 有 {tests['failed']} 个失败，delivery=incomplete")

    # 场景 5：passed + failed 不一致
    if tests.get("ran"):
        total = tests.get("passed", 0) + tests.get("failed", 0)
        snippet = tests.get("output_snippet", "")
        # 解析 snippet 里的 "N passed, M failed"
        import re
        m = re.search(r"(\d+) passed(?:.*?(\d+) failed)?", snippet)
        if m:
            snippet_passed = int(m.group(1))
            snippet_failed = int(m.group(2) or 0)
            if snippet_passed != tests.get("passed") or snippet_failed != tests.get("failed"):
                issues.append(f"tests 数字与 snippet 不一致（claimed={tests.get('passed')}/{tests.get('failed')} vs snippet={snippet_passed}/{snippet_failed}）")

    return issues
```

### orchestrator 决策表

| delivery.tests 状态 | 进 Phase 5？ | 处理 |
|---|---|---|
| `ran=true, failed=0, output_snippet 非空` | ✅ 是 | 正常推进 |
| `ran=true, failed>0` | ❌ 否 | 返工：子 agent 必须先修失败用例 |
| `ran=false, skipped_reason="hook blocked"` | ❌ 否 | orchestrator STOP + 跑 TG-1 hook self-test + 修 hook + 让子 agent 重 spawn |
| `ran=false, skipped_reason="DB unavailable"` | ⚠️ 视情况 | 若 spec 验收标准要 DB → 返工；否则 orchestrator 显式标 `delivery=db_optional` 推进 |
| `ran=false, skipped_reason="fixture broken"` | ❌ 否 | 触发 TG-6（pytest-asyncio 陷阱）流程；返工或降级到 inline cleanup |
| `tests` 字段是旧 string 格式 | ❌ 否 | 返工：要求子 agent 重新输出 v7.3 格式 |

### 子 agent prompt 模板（orchestrator spawn 时附在末尾）

```
**DELIVERY REQUIREMENT (v7.3 strict)**：

你必须在 delivery 末尾输出完整 verification 字段：

verification:
  lint: PASS|FAIL
  type_check: PASS|FAIL
  tests:
    ran: <true 如果真跑了 pytest；false 如果没跑>
    passed: <从 pytest 输出解析的真实通过数>
    failed: <从 pytest 输出解析的真实失败数>
    output_snippet: |
      <贴最后 20 行 pytest 输出，必须含 "===== N passed in X.XXs =====" 行>
    skipped_reason: <null 若 ran=true；否则必填，说明为什么没真跑>

⚠️ 禁止：
- 自报 "pytest: PASS" 但实际因 hook 阻塞 / fixture 失败 / 网络 跳过
- output_snippet 为空（ran=true 时必填）
- skipped_reason 为空（ran=false 时必填）

任一字段缺失或不一致 → delivery=incomplete → 返工。
```

### 与 TG-1 联动

若 orchestrator 在 Phase -1 没跑 TG-1 hook self-test，子 agent 报 `tests.ran=false, skipped_reason="hook blocked"` 时，orchestrator 必须：
1. STOP 所有后续 slice spawn
2. 跑 `bash -n .claude/hooks/*.sh` 自检
3. 发现 hook 损坏 → 提示用户授权修复（参考 TG-1 协议）
4. 修好后重 spawn 失败的 slice
