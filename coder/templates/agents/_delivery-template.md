---
name: _delivery-template
description: >
  内部模板：所有 spawn 的子 agent（lang-coder / reviewer / explorer / oracle）的最终输出
  必须以 delivery YAML 块结尾。Phase 4.5（validate-delivery.py）按此校验。
  本文件被引用到所有子 agent 的 system prompt（通过 spawn 时注入），不需要单独 spawn。
hidden: true
---

# Delivery 输出协议（子 agent 必读）

每个子 agent 完成任务后，最终输出**必须**以 YAML 块结尾，格式见 [`templates/delivery-schema.yaml`](../templates/delivery-schema.yaml)。

## 最小化模板（复制改）

\`\`\`yaml
delivery:
  agent: {agent_name}              # python-coder-project / project-reviewer / oracle
  task_id: {task_id}               # 从 spawn prompt 接收
  phase: {phase}                   # Phase 4 / Phase 5 / Phase 0.5
  model: {sonnet|opus|haiku}

  inputs_received:
    - spec.md
    - design.md (alt-{N})
    - test-plan.md
    - reuse-report.md

  outputs:
    files_changed:
      - path: src/example.py
        lines_added: 45
        lines_removed: 12
        new_methods: [method_a, method_b]
        modified_methods: [method_c]
        risk_level: medium         # low / medium / high / critical

    new_dependencies: []           # 空，除非 spec.allowed_deps 允许
    deleted_files: []

    drift_score: 0.1               # 0.0-1.0
    drift_breakdown:
      file_overrun: 0
      loc_overrun: 5
      unplanned_deps: 0
      super_decay: 0

  verification_self:
    lint: PASS                     # PASS / FAIL / SKIP
    type_check: PASS
    tests: "8/8 PASS"              # 或 "3/5 PASS (2 failed: ...)"
    build: PASS
    notes: ""

  known_caveats:
    - description: "rate limit TODO at line 45"
      severity: low
      location: "src/auth/login.py:45"

  handoff:
    to_reviewer:
      focus_areas:
        - "commit_user 的 transaction 安全性"
        - "并发场景下 race condition"
      skip_areas:
        - "logging 格式（简单 wrapper）"
      risk_notes: "整体 medium risk，主要 concern 是并发"

    to_orchestrator:
      next_actions:
        - "Phase 5 spawn reviewer"
      blockers: []
      suggested_followup:
        - "下一步可加 rate limit"
\`\`\`

## 校验规则（违反则返工）

| # | 规则 | 失败后果 |
|---|---|---|
| 1 | 必填字段齐全（agent / task_id / phase / inputs / outputs / verification / handoff） | BLOCK |
| 2 | files_changed 与实际 git diff 一致 | BLOCK |
| 3 | drift_score < 0.4 | BLOCK → 回 Phase 3 重新分解 |
| 4 | verification_self 至少 1 项 PASS | BLOCK |
| 5 | new_dependencies 为空 或 ⊆ spec.allowed_deps | BLOCK |
| 6 | known_caveats < 5 | WARN（建议拆任务） |
| 7 | handoff.to_reviewer.focus_areas ≥ 1 | BLOCK |

## 不同 agent 的差异

### 4 类 agent delivery 速查表

| 字段 | lang-coder-project (Phase 4) | reviewer (Phase 5) | explorer (Phase 0.5/1) | oracle (Phase 0.5/3) |
|---|---|---|---|---|
| **outputs.files_changed** | 详尽（每文件一行 + risk_level） | 通常空 | 通常空 | 通常空 |
| **outputs.new_dependencies** | 空（除非 spec 允许） | 空 | 空 | 空 |
| **outputs.drift_score** | 必填（0.0-1.0） | 0.0 | 0.0 | 0.0 |
| **outputs.design_alternatives** | ❌ | ❌ | ❌ | ✅（oracle 特有） |
| **outputs.findings** | ❌ | ✅（reviewer 特有：blockers/majors/minors/verdict） | ❌ | ❌ |
| **verification_self.lint** | MUST 真跑（PASS/FAIL） | SHOULD 跑一遍验证 | SKIP | SKIP |
| **verification_self.tests** | MUST 真跑（"8/8 PASS"） | SHOULD 跑一遍验证 | SKIP | SKIP |
| **known_caveats** | 高危代码必填 | 审查发现的边界 | 扫描盲点 | alternatives 的 cons |
| **handoff.to_reviewer.focus_areas** | MUST ≥1（除非复杂度极低） | ❌（reviewer 不需 reviewer） | ❌ | ❌ |
| **handoff.to_orchestrator.next_actions** | "Phase 5 spawn reviewer" | "verdict=PASS → Phase 6 / verdict=NEEDS_FIX → 返工" | "进 Phase 1 / 用户决策" | "用户选 alt 后 spawn lang-coder" |
| **handoff.to_orchestrator.blockers** | 漏掉的 spec 需求 | BLOCKER 列表 | 找不到关键文件 | 用户未决策 |

### lang-coder-project（Phase 4 执行者）
- files_changed 详尽（每个文件一行）
- risk_level 必填（low/medium/high/critical）
- verification_self 必须真跑（lint / type / tests 不能全 SKIP）
- drift_score 真实计算（不是 0.0）
- handoff.to_reviewer.focus_areas 至少 1 项（强制）

### reviewer（Phase 5 审查者）
- outputs.files_changed 通常空（reviewer 不改代码）
- outputs.findings 是核心字段（blockers/majors/minors/verdict）
- verification_self 反映 reviewer 跑的验证（应该真跑，不 SKIP）
- handoff.to_orchestrator.next_actions 含 "verdict=PASS/NEEDS_FIX"
- known_caveats 含审查发现的边界

### explorer（Phase 0.5/1 扫描）
- outputs.files_changed 通常空
- inputs_received 简化（只有 spec / 用户请求）
- verification_self 全 SKIP（explorer 不跑代码检查）
- handoff.to_orchestrator 含扫描结论（如"找到 N 个可复用模块"）

### oracle（Phase 0.5/3 设计）
- outputs.files_changed 通常空
- outputs.design_alternatives 是核心字段（每个 alt 含 id/description/pros/cons/effort/recommended）
- verification_self 全 SKIP（oracle 是分析者）
- handoff.to_orchestrator.blockers 通常含"需用户决策"

## Anti-pattern（避免）

- ❌ "我跑过了" 但 verification_self 全 SKIP → 返工
- ❌ files_changed 漏掉测试文件 → 校验失败
- ❌ drift_score 填 0.0 但实际超 5 文件 → 校验失败（与 git diff 对比）
- ❌ handoff.to_reviewer.focus_areas 为空 → 校验失败
