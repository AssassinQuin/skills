# Delivery Checklist: {{SPEC_SLUG}}

**Generated**: {{DATE}}
**Phase**: 6
**Spec ID**: {{SPEC_ID}}
**User signature**: ⏳ 待用户验收

---

## 0. Handoff 视角（v6.3，from mattpocock handoff）

> 如果换一个 agent 接手这个 spec，他需要什么？这一段不是给用户的，是给"下一棒"的。

### Current State（当前在哪）
- spec_id: {{SPEC_ID}}
- current_phase: Phase 6（delivery-checklist 生成）
- 已完成 Phase: {{COMPLETED_PHASES}}
- 跳过 Phase: {{SKIPPED_PHASES}}（理由已记录）

### Next Actions（下一棒该做什么）
{{NEXT_ACTIONS}}
- [ ] 用户在 §8 签字
- [ ] 签字后：`bash coder-state.sh update-phase "Phase 6" completed`
- [ ] 进 Phase 7：`bash coder-state.sh archive`
- [ ] （如有）后续 spec 候选：{{FOLLOWUP_SPECS}}

### Known Unknowns（已知不确定项，留给下一棒判断）
{{KNOWN_UNKNOWNS}}
- 例："rate limit 实现用了 token bucket，但在 1000 QPS 下未测"
- 例："外部 API X 的 rate limit 是 100/min（未验证，假设的）"

### Context Hashes（关键 artifact 的 hash，下一棒可校验）
- spec.md: `{{SPEC_HASH}}`
- design.md: `{{DESIGN_HASH}}`
- test-plan.md: `{{TEST_PLAN_HASH}}`
- review-report.md: `{{REVIEW_HASH}}`

---

## 1. 验收 Checklist（从 spec.md 回填）

> Phase 0 用户列的每条验收点，逐项打勾。

{{ACCEPTANCE_CHECKLIST_FILLED}}

### 验收统计

- ✅ 通过: {{ACCEPTANCE_PASS}} / {{ACCEPTANCE_TOTAL}}
- ⚠️ 未完成（含原因）: {{ACCEPTANCE_INCOMPLETE}}
- ❌ 失败: {{ACCEPTANCE_FAIL}}

**整体**：{{OVERALL_STATUS}}（🟢 可交付 / 🟡 部分交付 / 🔴 不可交付）

---

## 2. 交付物清单

| 类型 | 路径 | 状态 | 备注 |
|---|---|---|---|
{{DELIVERABLES_TABLE}}

### 子 agent delivery（Phase 4 产出）

{{SUBAGENT_DELIVERIES}}

每个 delivery 已通过 [`validate-delivery.py`](../scripts/validate-delivery.py) 校验（7 条规则）。

---

## 3. Memory 写入（Phase 6 持久化）

> reviewer 发现的新坑 / 项目决策 / 经验，写到 memory MCP。

### 项目级（project tag）

{{MEMORY_PROJECT_WRITES}}

### 共享级（shared tag，需 🔒 用户确认）

{{MEMORY_SHARED_WRITES}}

### 全局级（global tag，需 🔒 用户确认）

{{MEMORY_GLOBAL_WRITES}}

---

## 4. 测试结果（Phase 5 test-runner 输出）

| 类别 | 命令 | 结果 |
|---|---|---|
{{TEST_RESULTS_TABLE}}

### 覆盖率

- 高危代码: {{COVERAGE_HIGH_RISK}}%（目标 100%）
- 总体: {{COVERAGE_TOTAL}}%（目标 ≥ {{COVERAGE_TARGET}}%）

详见 `.claude/coder-state/specs-active/{{SPEC_ID}}/test-result.md`。

---

## 5. Reviewer 报告摘要（Phase 5）

{{REVIEW_SUMMARY}}

### 必修项（已修复）

{{REVIEW_MUST_FIX_RESOLVED}}

### 建议项（可后续）

{{REVIEW_SUGGESTIONS}}

---

## 6. 已知问题（known caveats）

> 来自子 agent delivery 的 known_caveats + reviewer 未覆盖项。

{{KNOWN_CAVEATS}}

---

## 7. 后续建议（handoff.suggested_followup）

> 子 agent 建议的后续任务（不强求本次做）。

{{SUGGESTED_FOLLOWUP}}

---

## 8. 用户验收签字

```
签字 hash: {{USER_VERIFY_HASH}}
签字时间: {{VERIFY_TS}}
用户: {{USER_ID}}

[ ] 同意交付（→ Phase 7 归档）
[ ] 需要返工：{{REWORK_REASON}}
[ ] 部分交付（同意 {{ACCEPTANCE_PASS}}/{{ACCEPTANCE_TOTAL}}，剩余移到下个 spec）
```

**用户决策**：{{USER_DECISION}}
**决策时间**：{{DECISION_TS}}

---

## 9. 归档信息（Phase 7，自动填充）

- 归档时间：{{ARCHIVE_TS}}
- 归档路径：`.claude/coder-state/archive/{{SPEC_ID}}/`
- state.json：current 清除，spec 标记 completed
- MASTER.md 索引：已更新
