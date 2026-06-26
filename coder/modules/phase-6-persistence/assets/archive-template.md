# Archive: {{SPEC_ID}}

**Slug**: {{SPEC_SLUG}}
**Started**: {{STARTED_AT}}
**Archived**: {{ARCHIVED_AT}}
**Final phase**: {{FINAL_PHASE}}
**Outcome**: {{OUTCOME}}（delivered / partial / abandoned）

---

## 0. Handoff 视角（v6.3，给"未来翻档的人"）

> 这个 spec 是什么？为什么这么做？下次类似任务能学到什么？

### One-Sentence Summary
{{ONE_SENTENCE_SUMMARY}}

例：实现 login 功能，复用 LoginService，新增并发安全 test，无新依赖。

### Key Decisions（最重要的 3 个）
{{KEY_DECISIONS}}
1. {{DECISION_1}}（理由：{{REASON_1}}）
2. {{DECISION_2}}
3. {{DECISION_3}}

### Surprises（没想到的事）
{{SURPRISES}}
- 例："原以为 authlib 是最佳选择，grilling 后发现项目内 LoginService 已够用"

### Lessons Learned（沉淀到 memory MCP 的）
{{LESSONS_LEARNED}}
- coding-{lang}-trap: {新坑 1}
- coding-{lang}-reuse-decision: {复用决策}
- coder-execution-drift: {如适用}

---

## 1. Phase 历史

| Phase | Status | Started | Completed | 签字 |
|---|---|---|---|---|
{{PHASE_HISTORY}}

### Skipped Phases
{{SKIPPED_PHASES_LIST}}（理由已记录在 spec.md / state.json）

---

## 2. Tasks 完成情况

| Task ID | Subagent | Status | Deliverable |
|---|---|---|---|
{{TASKS_TABLE}}

### Tasks 统计
- Total: {{TASKS_TOTAL}}
- Completed: {{TASKS_COMPLETED}}
- Failed: {{TASKS_FAILED}}
- Pending（未做）: {{TASKS_PENDING}}

---

## 3. 交付物清单（最终）

| 类型 | 路径 | 状态 |
|---|---|---|
{{FINAL_DELIVERABLES}}

### 代码改动统计
- Files changed: {{FILES_CHANGED}}
- Lines added: {{LINES_ADDED}}
- Lines removed: {{LINES_REMOVED}}
- New tests: {{NEW_TESTS}}
- Test pass rate: {{TEST_PASS_RATE}}

---

## 4. Memory MCP 写入清单

| Tag | Tier | 内容摘要 |
|---|---|---|
{{MEMORY_WRITES}}

---

## 5. Post-mortem（v6.3 新增）

### What went well
{{WHAT_WENT_WELL}}

### What went wrong
{{WHAT_WENT_WRONG}}

### What to do differently next time
{{NEXT_TIME_DIFFERENTLY}}

### Drift 分析（如有）
{{DRIFT_ANALYSIS}}
- max_drift: {{MAX_DRIFT}}
- 触发 adaptive control: {{ADAPTIVE_TRIGGERED}}（是/否）
- root cause: {{DRIFT_ROOT_CAUSE}}

---

## 6. 后续 spec 候选

> 本次未做但 handoff.suggested_followup 提到的，留给下个 spec。

{{FOLLOWUP_CANDIDATES}}

---

## 7. Artifact Hashes（下一棒可校验）

- spec.md: `{{SPEC_HASH}}`
- design.md: `{{DESIGN_HASH}}`
- test-plan.md: `{{TEST_PLAN_HASH}}`
- delivery-checklist.md: `{{DELIVERY_HASH}}`
- review-report.md: `{{REVIEW_HASH}}`
- code diff: `{{DIFF_HASH}}`

---

## 引用

- 来源：mattpocock `handoff` skill（[skills/handoff/SKILL.md](../../handoff/SKILL.md)）
- 上游：[`templates/delivery-checklist.md.template`](delivery-checklist.md.template)（Phase 6 输出）
- 生成：[`scripts/coder-state.py`](../scripts/coder-state.py) `archive` 命令
