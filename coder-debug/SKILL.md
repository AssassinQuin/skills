---
phase: 0.6
name: coder-debug
description: Phase 0.6 bug 诊断子流程（v6.3 新增，from mattpocock diagnose）。bug 类任务触发，跳过 Phase 0.5。6 步：Build feedback loop / Reproduce 最小化 / Hypothesise 3-5 ranked falsifiable / Instrument / Fix+regression / Cleanup+post-mortem。
source: ".deepen/20260625-execution-flow/mattpocock-optimization.md 优化 4 + mattpocock diagnose skill"
status: active
tokens_estimate: 2000
load_priority: on-demand
load_when: "bug 类任务（"修 bug"/"为什么 X 报错"）"
keywords: bug diagnosis 6-phase feedback-loop reproduce minimal hypothesise falsifiable instrument post-mortem
domain: coding
subdomain: phase
parent_skill: coder
version: "1.1"
license: Apache-2.0
frameworks:
  notes: "scientific method（hypothesis-test-falsify）+ root-cause-analysis"
---

# Phase 0.6: Bug 诊断子流程（v6.3 新增）

> **加载时机**：bug 类任务（用户说"修这个 bug" / "为什么 X 报错" / "X 坏了" / "X 性能回退"）。
> **跳过 Phase 0.5**（复用分析对 bug 无意义），直接走本流程。
> **来源**：mattpocock `diagnose` skill 的 6 Phase 诊断循环。

## 触发判定

| 用户原话 | 触发 Phase 0.6？ |
|---|---|
| "修这个 bug" / "X 报错" / "X 坏了" | ✅ |
| "为什么 X 不工作" | ✅ |
| "X 性能回退了" | ✅ |
| "X 偶发失败" | ✅ |
| "加个 X 功能" | ❌ → 走 Phase 0.5 |
| "重构 X" | ❌ → 走 Phase 0.5 |

## 6 步诊断循环

### 步骤 1: Build a feedback loop（**必先有 loop**）

**MUST**：在 hypothesise 前先有可重复的复现路径。

loop 构造方式（按优先级）：
1. **单元测试复现**：写一个 failing test
2. **脚本复现**：python/bash 脚本调相关代码
3. **curl / HTTP 请求**：API bug
4. **手动步骤**：UI bug，记下精确步骤
5. **生产日志查询**：定期查询触发条件

**Iterate on the loop itself**：如果第一次没复现，先优化 loop（不是直接 hypothesise）。

**Non-deterministic bugs**（偶发）：
- 跑 N 次直到出现（N ≥ 100）
- 或加临时 instrumentation 强制触发

**When you genuinely cannot build a loop**：
- 显式声明 "无法构建 loop"
- 列出已尝试的方法
- AskUserQuestion 问用户：(a) 环境访问 (b) 捕获的 artifact（HAR / log dump / core dump） (c) 加临时生产 instrumentation 权限
- **不进步骤 2 直到有可信 loop**

### 步骤 2: Reproduce（最小化）

把 loop 缩到最小：
- 删无关代码
- 删无关配置
- 删无关数据
- 直到再删一步就不能复现

**目的**：最小复现 = 最快验证 + 最容易 hypothesise。

### 步骤 3: Hypothesise（**反单假设锚定**）

**MUST**：生成 **3-5 个 ranked hypotheses**，不是只生成一个。

**为什么**：单假设会锚定（"我觉得是 X"），后续验证会找证据支持 X 而忽略反证。

每个 hypothesis **必须可证伪**：

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

不可证伪的 hypothesis（"可能是缓存问题"）→ discard 或 sharpen。

**Show ranked list to user**（在测试前）：
- 用户常有 domain knowledge 立即重排（"我们刚部署了 #3 的变更"）
- 或知道哪些已排除
- 不阻塞（用户 AFK 就按你的 ranking 走）

### 步骤 4: Instrument（验证假设）

按 ranking 测试每个 hypothesis：
- 加日志 / 断点 / print
- 改 Y 看 bug 是否消失
- 改 Z 看 bug 是否变严重

**找不到证据 = 假设错了**，回步骤 3 重排。

### 步骤 5: Fix + regression test

确认 root cause 后：
1. **fix**（最小修改，R3 外科手术式）
2. **regression test**：把步骤 1 的复现 loop 转成永久 test
3. 跑 test 验证 fix

### 步骤 6: Cleanup + post-mortem

- 删临时 instrumentation
- 写 post-mortem 到 `.claude/coder-state/specs-active/{id}/post-mortem.md`：
  - Root cause
  - Why it took N cycles to find
  - What to do differently next time
  - 是否需要类似检查的其他地方（grep 同类）

**自动写 memory**（v6.1 协议）：
```
memory_store(
  content=f"bug: {root_cause}. Fix: {fix}. Post-mortem: {lesson}",
  metadata={tags: f"shared,coding-{lang}-trap,bug"}
)
```

## 输出契约

返回 markdown 块，结构必须为：

```markdown
## Bug 诊断报告

### Loop
- 复现方式: {test / script / curl / manual / log query}
- 复现率: {100% / 偶发 1/100 / ...}

### Minimal Reproduction
- 步骤数: {N}
- 涉及代码: {file:line}

### Hypotheses（3-5 ranked）
1. [H1] {assumption} → Prediction: {if X then Y}
2. [H2] ...
3. [H3] ...

### Validation Result
- H1: {verified / falsified / unclear}
- H2: ...
- 选定 root cause: {H?}

### Fix
- 改动: {file:line}
- regression test: {test name}

### Post-mortem
- Root cause: ...
- Lesson: ...
- 同类检查: {grep 结果}
```

## Anti-pattern（避免）

### ❌ "我觉得是 X"（单假设）
**正确**：3-5 个 ranked hypothesis。

### ❌ "试一下看看"（无 hypothesis）
**正确**：每个改动对应一个 hypothesis 的 prediction。

### ❌ 直接 fix（无 loop）
**正确**：先有可重复复现，再 hypothesise。

### ❌ 跳过 minimal reproduction
**正确**：缩到最小，更容易定位。

### ❌ 不写 regression test
**正确**：步骤 1 的 loop 必须转成永久 test。

### ❌ 不写 post-mortem
**正确**：每个 bug 都有 lesson，下次避免。

## 与其他 Phase 的关系

| Phase | 关系 |
|---|---|
| Phase 0（需求确认） | bug 类任务简化 Phase 0（不问 priority/budget，直接进 0.6） |
| Phase 0.5（复用分析） | **跳过**（bug 修复不需复用分析） |
| Phase 1（元数据扫描） | 仍走（看 bug 涉及的代码依赖） |
| Phase 3（设计方案） | 简化（fix 已在步骤 5 定） |
| Phase 4（执行） | 走（spawn lang-coder-project 写 fix + regression test） |
| Phase 5（验证） | 走（reviewer + test-runner） |

## 何时降级到通用 Phase 0.5

- 用户说"修复 + 加新功能"（bug + feature）→ feature 部分走 Phase 0.5，bug 部分走 Phase 0.6
- bug 是性能问题且需要重构 → 走 Phase 0.5（不是诊断）

## 引用

- 来源：mattpocock `diagnose` skill（[skills/diagnose/SKILL.md](../../diagnose/SKILL.md)）
- 设计：[`.deepen/20260625-execution-flow/mattpocock-optimization.md`](../.deepen/20260625-execution-flow/mattpocock-optimization.md) 优化 4
- 上游：[`phase-0-intent-capture.md`](phase-0-intent-capture.md)
- 下游：[`phase-1-metadata-scan.md`](phase-1-metadata-scan.md)
