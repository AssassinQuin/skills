---
phase: 5
name: phase-5-verification
description: Phase 5 验证 — 3 reviewer 并发模板（正确性 / S.U.P.E.R / 安全）+ fresh-context 对抗式审查。
source: "design.md §5.6 + §6.2"
status: skeleton
---

# Phase 5: 验证（🌟 3 reviewer 并发，Q2 已决策）

> **加载时机**：Phase 4 子 agent 输出 diff 后。

## 3 路并发 reviewer 分工

| reviewer | 职责 | 关注点 |
|---|---|---|
| **reviewer-正确性** | 验收 checklist 逐条核对 + edge case | 功能正确性 |
| **reviewer-S.U.P.E.R** | 新改动对架构健康的影响 + search_graph 回归 | 模块健康分衰减 |
| **reviewer-安全** | 私钥 / SQL 注入 / 权限绕过 / PII | OWASP top 10 |

**3 路并发 fresh-context 审查**（互不可见）。

## 并发模板

```yaml
spawn:
  - subagent_type: reviewer
    description: "正确性审查"
    prompt: "${REVIEWER_CORRECTNESS_PROMPT}"
  - subagent_type: reviewer
    description: "S.U.P.E.R 回归"
    prompt: "${REVIEWER_SUPER_PROMPT}"
  - subagent_type: reviewer
    description: "安全审查"
    prompt: "${REVIEWER_SECURITY_PROMPT}"
# orchestrator 等齐 → 合并报告
```

## fresh-context 关键

每个 reviewer 只看：
- diff（代码变更）
- 验收 checklist（Phase 0 输出）
- 该维度专属输入（如 S.U.P.E.R reviewer 看 Phase 1 热图）

**不看**：实现推理过程、其他 reviewer 的输出。

这是 Anthropic best practices 强烈推荐的"对抗式审查"模式。

## reviewer-正确性 prompt 模板

```
你是 fresh-context 正确性审查员。

输入:
- diff: {Phase 4 产出}
- 验收 checklist: {Phase 0 输出}

任务（不报告风格偏好）:
1. 每条验收 checklist 是否满足（✅/❌ + 证据）
2. diff 范围外的意外改动
3. 缺失的 edge case 测试（边界 / 并发 / 错误路径）

输出 schema: JSON
  {checklist: [{item, status, evidence}], unexpected_changes: [], missing_tests: []}
```

## reviewer-S.U.P.E.R prompt 模板

```
你是 fresh-context 架构健康审查员。

输入:
- diff
- Phase 1 S.U.P.E.R 热图
- search_graph 结果（影响节点）

任务:
1. 新改动让哪些模块从 🟢 → 🟡/🔴
2. 影响节点的测试覆盖情况（调 search_graph(neighbors_of=changed_nodes)）
3. 是否引入循环依赖（调 trace_path）

输出 schema: JSON
  {super_decay: [], missing_test_coverage: [], cycle_detected: bool}
```

## reviewer-安全 prompt 模板

```
你是 fresh-context 安全审查员（OWASP top 10 视角）。

输入:
- diff

任务（仅查安全）:
1. 私钥/密码/token 硬编码
2. SQL 注入 / 命令注入
3. 权限绕过 / 越权
4. PII 泄漏 / 不当日志
5. 不安全依赖

输出 schema: JSON
  {critical: [], high: [], medium: [], low: []}
```

## orchestrator 合并报告

```markdown
## Phase 5 审查报告

### 正确性
- 验收 checklist: {N}/{M} 满足
- 意外改动: {列表}
- 缺失测试: {列表}

### S.U.P.E.R
- 衰减: {模块从 X → Y}
- 测试覆盖缺口: {列表}
- 循环依赖: {是/否}

### 安全
- 🔴 严重: {列表}
- 🟡 高危: {列表}
- 🟢 中低: {列表}

### 决策
- 🔴 阻塞: {列表}（必须修）
- 🟡 建议: {列表}（可选）
- 🟢 通过: {列表}
```

## reviewer 工具扩展

- `mcp__codebase-memory-mcp__search_graph`（S.U.P.E.R reviewer 用）

## 降级（reviewer 并发失败）

- 1 个失败 → 其他保留 + ⚠️
- ≥50% 失败 → 重试 1 次
- 仍失败 → orchestrator 自审 + ⚠️ 标"审查深度降低"

## TODO（待 step 2 扩充）

- [ ] 3 个 reviewer 完整 prompt 模板
- [ ] 合并报告的 markdown 渲染器
- [ ] 各语言的安全 checklist（Go vs Python 差异）

## 引用

- design.md §5.6 + §6.2 + §6.3
- `phase-1-super-check.md`（S.U.P.E.R 基线）
- `codebase-memory-mcp.md`（触达点 5: search_graph 回归）
