# Spec: {{SPEC_SLUG}}

**Created**: {{DATE}}
**Spec ID**: {{SPEC_ID}}
**Phase 0 confirmed**: ⏳ 待用户签字
**User signature hash**: {{USER_HASH}}

---

## 用户原话

> {{USER_RAW_INPUT}}

## Agent 复述（已用户确认）

{{AGENT_RESTATED}}

## User Stories（v6.2，from to-prd）

> 用 user 视角描述"能做什么"。每个 story = 一个 vertical slice 的 user behavior。

{{USER_STORIES}}

例：
- As a user, I can log in with correct credentials, so that I access my account
- As a user, I see a clear error when my password is wrong, so that I know to retry

## 验收 Checklist

{{ACCEPTANCE_CHECKLIST}}

> Phase 6 交付时，每项必须勾选 ✅ 或显式标注 ⚠️（未完成 + 原因）。

## Module Sketch（v6.2，from to-prd deep module）

> 要建/改哪些 module？哪些是 deep module 机会？

{{MODULE_SKETCH}}

### Deep Module 候选

| Module | 接口复杂度 | 封装功能 | 测试隔离性 | 是 deep module？ |
|---|---|---|---|---|
| LoginService | 低（2 个 method） | 高（auth + session + audit） | ✅ 可 mock | ✅ deep |
| LoginValidator | 中 | 低 | ⚠️ 浅 | ❌ shallow，考虑合并 |

**Deep module 定义**（mattpocock）：简单接口 + 封装大量功能 + 很少变 + 可测试隔离。

用户确认 module 划分：[ ] 同意 / [ ] 修改：____

## Phase 选择（用户决定）

| Phase | 是否跑 | 理由 |
|---|---|---|
| Phase -1: 断点检测 | 自动 | — |
| Phase 0: 需求确认 | ✅ 必跑 | 本文件 |
| Phase 0.5: 复用 + 替代分析 | {{PHASE_0_5}} | {{PHASE_0_5_REASON}} |
| Phase 1: 元数据 + 架构 | ✅ 必跑 | — |
| Phase 2: 语言路由 | 自动 | — |
| Phase 3: 设计方案 + test-plan | {{PHASE_3}} | {{PHASE_3_REASON}} |
| Phase 4: 执行（多子 agent 并发） | ✅ 必跑 | — |
| Phase 4.5: 子 agent 交付检查 | {{PHASE_4_5}} | {{PHASE_4_5_REASON}} |
| Phase 5: 验证（3 reviewer + test） | ✅ 必跑 | — |
| Phase 6: 持久化 + delivery checklist | ✅ 必跑 | — |
| Phase 7: 归档 | {{PHASE_7}} | {{PHASE_7_REASON}} |

## 时间预算

- 预算：{{BUDGET_MINUTES}} 分钟
- 自动确认 Phase：{{AUTO_PHASES}}（不需用户签字）
- 必须 Phase 签字：Phase 3 / Phase 5 / Phase 6

## 用户偏好（本次执行）

{{USER_PREFERENCES}}

## 允许的新依赖

{{ALLOWED_DEPS}}
> 默认为空。子 agent delivery 不允许引入此列表外的依赖。

## 已知约束 / 不做范围

{{OUT_OF_SCOPE}}

---

## 用户签字

```
签字 hash: {{USER_HASH}}
签字时间: {{SIGN_TS}}
用户: {{USER_ID}}
```

> 用户确认本 spec 后，phase 0 标记 completed，进入 Phase 0.5 / 1。
> 任何变更必须更新本文件 + 重新签字。
