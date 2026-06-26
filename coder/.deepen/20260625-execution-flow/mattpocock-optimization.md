# mattpocock skills 反哺优化方案

**日期**：2026-06-25
**来源**：mattpocock/skills 11 个 skills 调研
**目的**：把 mattpocock 的方法论融入 coder v6.x，强化 + 重构现有流程

---

## 0. mattpocock 核心方法论提炼

| Skill | 核心方法论 | 一句话 |
|---|---|---|
| **tdd** | vertical tracer bullet + red-green-refactor | "Never write all tests first"——test1→impl1→test2→impl2 |
| **diagnose** | 6 Phase 诊断循环 + falsifiable hypotheses | 先建 feedback loop，再 3-5 个可证伪假设 |
| **handoff** | compact 对话给其他 agent | "下次会话用来做什么？" |
| **to-prd** | PRD 模板 + deep module 识别 | 简单接口封装大量功能 + 很少变 |
| **to-issues** | tracer-bullet vertical slices | thin slice 贯穿所有层（schema/API/UI/tests），不是 horizontal |
| **grill-with-docs** | grilling loop + inline 文档更新 | 决策结晶时立即更新 CONTEXT.md / 写 ADR |
| **improve-codebase-architecture** | deepening opportunities | shallow → deep module（testability + AI-navigability） |
| **prototype** | throwaway 验证设计 | "throwaway code that answers a question" |
| **triage** | state machine driven | 状态转换触发不同 role |

---

## 1. 9 个优化方向（按优先级）

### 优化 1：tdd → test-strategist 强化（**vertical tracer bullet**）⭐⭐⭐

**当前**：test-strategist 输出 test-plan.md 列"测什么"。

**问题**：plan 容易变成 horizontal slicing（先写所有 test，再写所有 impl）—— mattpocock 明确说这是反模式："Tests written in bulk test imagined behavior, not actual behavior"。

**升级**：
- test-plan.md 加 **vertical slice 规划**：每个 `test→impl` 是独立 cycle
- 明确反 horizontal（"DO NOT write all tests first, then all implementation"）
- 加 **"Never refactor while RED"** 约束（先到 GREEN 再重构）
- 4 步 workflow：Planning → Tracer Bullet → Incremental Loop → Refactor

### 优化 2：to-issues → Phase 4 task 分解强化（**tracer-bullet vertical slices**）⭐⭐⭐

**当前**：Phase 4 按文件分组 spawn（horizontal）。

**问题**：按文件分组 = "改 schema 的所有文件一起，改 API 的所有文件一起"——典型 horizontal。每个 task 不能独立 demo。

**升级**：
- 改为 **vertical slice 分组**：每个 task 贯穿 schema/API/logic/tests
- 加 **HITL vs AFK 标注**（哪些 task 需要人决策）
- "Prefer AFK over HITL"
- 每个 slice 独立 demoable / verifiable

### 优化 3：to-prd → Phase 0 spec.md 强化（**deep module**）⭐⭐⭐

**当前**：spec.md 是需求 + 验收 + Phase 选择。

**问题**：缺 module 设计视角。to-prd 强调"找 deep module 机会"——简单接口封装大量功能。

**升级**：
- 加 **module sketch** 段（"要建/改哪些 module？哪些是 deep module 机会？"）
- 用户确认 module 划分
- PRD 模板字段：Problem / Solution / User Stories / Implementation Decisions / Testing Decisions / Out of Scope

### 优化 4：diagnose → 新增 Phase 0.6 bug 诊断子流程（仅 bug 类任务）⭐⭐

**当前**：bug 修复走通用 Phase 0-7，没有专门的诊断循环。

**升级**：bug 类任务（用户说"修这个 bug" / "为什么 X 报错"）触发 Phase 0.6：
- 6 步：Build feedback loop → Reproduce（最小化）→ Hypothesise（3-5 ranked falsifiable）→ Instrument → Fix + regression → Cleanup + post-mortem
- 关键约束：**单假设会锚定**——必须 3-5 个 ranked
- 每个假设必须可证伪："If X then Y"

### 优化 5：grill-with-docs → Phase 3 oracle 强化（**pressure test + inline docs**）⭐⭐

**当前**：oracle 输出 design.md + test-plan，结束。

**问题**：oracle 没有"对自己方案做压力测试"的环节。

**升级**：
- oracle 在 design 后加 **grilling loop**（自我压力测试）：
  - Challenge against glossary（用 CONTEXT.md 词汇）
  - Sharpen fuzzy language
  - Discuss concrete scenarios
  - Cross-reference with code
- **inline 文档更新**：决策结晶时立即更新 CONTEXT.md / 写 ADR
- "Offer ADRs sparingly"（仅"未来 explorer 会需要"的原因）

### 优化 6：improve-codebase-architecture → Phase 1 强化（**deepening opportunities**）⭐

**当前**：Phase 1 explorer 只扫描技术栈 + 同类查找。

**升级**：
- 加 **deepening opportunities** 维度（找 shallow → deep module 机会）
- 输出 candidates report
- 用户在 Phase 3 选 design 时同时看 deepening 机会

### 优化 7：prototype → 新增 Phase 2.5（**throwaway 验证**，仅复杂/不确定任务）⭐⭐

**当前**：复杂任务 Phase 3 design → Phase 4 直接执行。

**问题**：复杂设计没验证就开干，可能整个返工。

**升级**：复杂度极高 / 设计不确定时，加 **Phase 2.5 prototype**：
- throwaway code 验证 design 的关键假设
- 6 rules：throwaway marked / one command / no persistence / skip polish / surface state / delete or absorb
- "A prototype is throwaway code that answers a question"

### 优化 8：handoff → Phase 6/7 强化（**cross-session handoff**）⭐

**当前**：delivery-checklist 是给用户看的。

**升级**：加 **handoff 视角**（"如果换一个 agent 接手，需要什么？"）：
- handoff 文档结构：current state / next actions / known unknowns / context hashes
- archive.md 模板借鉴 handoff

### 优化 9：triage → Phase -1 强化（**state machine driven**）⭐

**当前**：Phase -1 只是检测 current.json + AskUserQuestion 续跑。

**升级**：
- **state machine driven**：spec 状态转换（new → triaging → designing → implementing → reviewing → delivered → archived）
- 不同状态触发不同 role / hook
- Needs-info template（用户回应前 spec 暂停）

---

## 2. 实现优先级（v6.2 路线图）

| 优化 | 优先级 | 实现复杂度 | v6.2 包含 |
|---|---|---|---|
| 优化 1（tdd → test-strategist） | 高 | 低（改 test-plan 模板） | ✅ |
| 优化 2（to-issues → Phase 4） | 高 | 中（改 task 分解逻辑） | ✅ |
| 优化 3（to-prd → Phase 0） | 高 | 低（改 spec 模板） | ✅ |
| 优化 5（grill-with-docs → oracle） | 中 | 中（oracle 加 grilling 段） | ✅ |
| 优化 4（diagnose → Phase 0.6） | 中 | 高（新 Phase） | ⏳ v6.3 |
| 优化 7（prototype → Phase 2.5） | 中 | 中（新 Phase） | ⏳ v6.3 |
| 优化 8（handoff → Phase 6/7） | 低 | 低（改 archive 模板） | ⏳ v6.3 |
| 优化 9（triage → Phase -1） | 低 | 高（状态机重构） | ⏳ v6.4 |
| 优化 6（deepening → Phase 1） | 低 | 中（加扫描维度） | ⏳ v6.4 |

---

## 3. v6.2 实现（优化 1/2/3/5）

### v6.2-1：test-strategist 升级（vertical tracer bullet）

修改 [`agents/test-strategist.md`](../../agents/test-strategist.md) + [`templates/test-plan.md.template`](../../templates/test-plan.md.template)：

- 加 **vertical slice 规划**段
- 加 **anti-horizontal-slicing** 警告
- 加 **"Never refactor while RED"** 约束
- 4 步 workflow（Planning / Tracer Bullet / Incremental Loop / Refactor）

### v6.2-2：Phase 4 task 分解升级（tracer-bullet vertical slices）

修改 [`references/phase-4-execution-protocol.md`](../../references/phase-4-execution-protocol.md)：

- 改 task 分解逻辑：**按 vertical slice**（贯穿 schema/API/logic/tests），不按文件
- 加 HITL / AFK 标注字段（delivery-schema 的 `outputs.slice_type`）
- "Prefer AFK over HITL" 决策树

### v6.2-3：spec.md 升级（deep module sketch）

修改 [`templates/spec.md.template`](../../templates/spec.md.template) + [`references/phase-0-intent-capture.md`](../../references/phase-0-intent-capture.md)：

- 加 **module sketch** 段（要建/改哪些 module？deep module 机会？）
- 加 **User Stories** 段（to-prd 模板）
- 加 **Out of Scope** 已有，强化

### v6.2-4：oracle 加 grilling loop

修改 [`agents/oracle.md`](../../agents/oracle.md)：

- 加 **grilling loop** 段（design 后自我压力测试）
- 4 步：Challenge glossary / Sharpen language / Concrete scenarios / Cross-reference code
- **inline 文档更新**：决策结晶时更新 CONTEXT.md / 写 ADR（sparing）

---

## 4. 关键反例对照（mattpocock 反模式 vs coder 当前）

| mattpocock 反模式 | coder 当前风险 | v6.2 修复 |
|---|---|---|
| Horizontal slicing（先写所有 test） | test-plan 列 test 列表 → 容易 horizontal | v6.2-1 强制 vertical |
| Single-hypothesis anchoring | bug 修复"我觉得是 X" → 锚定 | v6.3 加 Phase 0.6 |
| "Tests written in bulk test imagined behavior" | test-plan 脱离实际 | v6.2-1 vertical cycle |
| Shallow module 没识别 | Phase 1 只扫描技术栈 | v6.4 加 deepening |
| Plan 没压力测试就开干 | oracle 出 design 直接 Phase 4 | v6.2-4 grilling loop |
| Throwaway 留在 repo | 实验 code 没归档 | v6.3 Phase 2.5 |
| 状态机不显式 | spec 状态隐含在 Phase | v6.4 triage 化 |

---

## 5. 总结

mattpocock 的方法论**强化 coder 的 4 个核心维度**：

1. **测试维度**（tdd）：vertical tracer bullet 反 horizontal
2. **任务分解维度**（to-issues）：vertical slice 反按文件
3. **需求维度**（to-prd）：deep module 识别
4. **决策维度**（grill-with-docs）：grilling loop + inline docs

v6.2 实现 4 个高优先级优化，v6.3 加 bug 诊断 + prototype，v6.4 状态机化。
