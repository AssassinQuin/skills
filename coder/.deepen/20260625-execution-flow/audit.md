# v6.0 Audit 报告：4 问深挖

**日期**：2026-06-25
**问题来源**：用户对 v6.0 的 4 个 audit 追问
**目的**：找出当前 v6.0 仍存在的盲区，规划 v6.1

---

## 问题 1：哪些流程约束可以放在 hook 中，让流程更稳定准确？

### 当前 v6.0 已 hook 强制（9 个）

| Hook | 强制什么 |
|---|---|
| `edit-guard.sh` | Edit 前必须有 grep（硬约束 #13）+ 不超 §2.2 直编限制 |
| `phase-guard.sh` | Phase 4 之外不允许 Edit + spawn 痕迹记录 |
| `spec-guard.sh` | 无 spec 不允许代码 Edit |
| `signature-guard.sh` | Phase 0/3/5/6 完成前必须签字 |
| `task-progress-guard.sh` | spawn 前必须登记 task + 完成后自动 update |
| `git-guard.sh` | 拦危险 git 命令 |
| `session-resume.sh` | 断点续跑检测 |
| `session-load.sh` | 项目元信息注入 |
| `spawn-trace.sh` | spawn + grep 痕迹记录 |

### 仍靠自觉、应该升级为 hook 的（v6.1 候选）

| # | 当前约束 | 当前位置 | 升级方案 | 优先级 |
|---|---|---|---|---|
| **A1** | Phase 0 spec.md 必填字段齐全 | reference 文字描述 | **`spec-completeness-guard.sh`** PreToolUse Edit/Write 时检查 spec.md 是否含 11 个必填字段。缺字段 → block | 高 |
| **A2** | Phase 3 design.md 必须有 alternatives + test-plan | reference 文字 | **`design-completeness-guard.sh`** orchestrator update-phase "Phase 3" completed 时检查 design.md + test-plan.md 字段 | 高 |
| **A3** | Phase 4 spawn 子 agent 必须传 model | R5.1 + agent frontmatter | **`model-binding-guard.sh`** PreToolUse Agent 检查 `tool_input.model` 字段；空 → block | 高 |
| **A4** | Phase 4.5 校验后必须 update phase | orchestrator 自觉 | **`phase-completion-guard.sh`** PostToolUse Bash 检测 `validate-delivery.py` 调用，rc=0 后自动提示 orchestrator 跑 `coder-state.sh update-phase` | 中 |
| **A5** | Phase 5 reviewer 必须 ≥1 spawn | reference 文字 | **`reviewer-spawn-guard.sh`** update-phase "Phase 5" completed 前检查 spawn-trace 含至少 1 个 reviewer subagent | 高 |
| **A6** | Phase 6 delivery-checklist 用户签字 | signature-guard 已覆盖 | ✅ 已强制（不需新增） |
| **A7** | 子 agent delivery 必须有 focus_areas | validate-delivery.py 已覆盖 | ✅ 已强制（不需新增） |
| **A8** | drift ≥ 0.4 触发 adaptive control | orchestrator 自觉 | **`drift-guard.sh`** validate-delivery.py 后自动检查 max drift，超阈值 → block + 提示回 Phase 3 | 高 |
| **A9** | MCP 必须触发（"我熟悉"不是理由） | reference 文字 | **`mcp-trigger-guard.sh`** PreToolUse Edit 前检查本次会话是否有 `codebase-memory-mcp` 或 `memory_search` 调用；多文件改动但无 MCP → warn | 中 |
| **A10** | 子 agent 不允许直接 commit/push | 隐含 | **`subagent-git-block.sh`** 子 agent（Agent tool 返回值里）出现 `git commit/push` → block | 中 |
| **A11** | new_dependencies ⊆ spec.allowed_deps | validate-delivery.py 已覆盖 | ✅ 已强制 | 
| **A12** | orchestrator 不允许直接跑测试（必须 spawn test-runner） | reference 文字 | **`test-runner-guard.sh`** Phase 5 PreToolUse Bash 拦截 `pytest/go test/npm test` → 提示 spawn test-runner | 中 |

### 推荐立即实现（v6.1）

**A1 / A3 / A5 / A8** —— 这 4 个是高风险盲区：
- A1：spec 不全就开干 = 用户主导失效
- A3：spawn 子 agent 不传 model = 违反 R5.1
- A5：Phase 5 没 reviewer = §11.3 反例复现
- A8：drift 不触发 adaptive = 上线炸

---

## 问题 2：哪些子 agent 职能没分离，不单一？

### 4 个全局 agent 职责审计

| Agent | 当前职责 | 是否单一？ | 问题 |
|---|---|---|---|
| `explorer` (haiku) | 项目扫描 + 同类查找 + 技术栈识别 | ✅ 单一 | 无 |
| `researcher` (sonnet) | 网络搜索 + 文档提取 + 多源综合 + **外部库评估** | ⚠️ **不单一** | "外部库评估"是战略任务，应该是 oracle 的事 |
| `oracle` (opus) | 任务拆解 + 架构评审 + 方案选型 + 风险分析 + **复用决策** + **test-plan 生成** | ⚠️ **不单一** | test-plan 生成应该是独立的 test-strategist（sonnet） |
| `reviewer` (sonnet) | correctness + style + security + maintainability + docs | ⚠️ **不单一** | 一个 reviewer 评 5 维度太重，应该拆 |

### 拆分建议（v6.1）

#### 拆分 1：oracle → oracle + test-strategist

| Agent | model | 职责 |
|---|---|---|
| `oracle` | opus | 战略 alternatives + 复用决策（聚焦"做什么"） |
| **`test-strategist`** (新) | sonnet | test-plan 生成（聚焦"怎么证明做对了"） |

**理由**：test-plan 是独立的工程领域（高危代码识别 + property test 设计 + 性能基准），不需要 opus 战略推理，但需要专门的测试知识。

#### 拆分 2：reviewer → correctness-reviewer / project-reviewer / security-reviewer

| Agent | model | 职责 |
|---|---|---|
| **`correctness-reviewer`** | sonnet | 逻辑 + 边界 + 并发 + 错误处理 |
| **`project-reviewer`** | sonnet | 项目 codestyle + 模块边界 + 硬约束 |
| **`security-reviewer`** | sonnet | 注入 / PII / 鉴权 / OWASP |

**理由**：v6.0 SKILL.md §2 路由表已经写了"3 reviewer 并发"但**实际还是同一个 reviewer 跑 3 维度**。真正拆开后，每个 reviewer focus 单一维度，深度更高。

#### 拆分 3：researcher 剥离"外部库评估"

| Agent | 保留 | 剥离 |
|---|---|---|
| `researcher` | 网络搜索 + 文档提取 + 多源综合 | ~~外部库评估~~（归 oracle） |

**理由**：评估"是否引入某库"是战略决策（涉及长期维护 / 集成成本），属于 oracle。researcher 只负责"列出候选 + 客观数据"。

#### 拆分 4：lang-coder-project → 不拆，但限制文件数

lang-coder-project 已单一（按语言执行）。但当前"按文件分组 spawn"可能导致 1 个 agent 改 5 文件 → 上下文污染。

**调整**：每个 lang-coder-project 上限改 3 文件。超过 → orchestrator 拆更多组。

### 拆分后的 subagent 全景（v6.1）

```
explorer (haiku)              — 扫描
researcher (sonnet)           — 搜索
oracle (opus)                 — 战略
test-strategist (sonnet) 新   — 测试策略
correctness-reviewer (sonnet) 新 — 正确性审查
project-reviewer (sonnet)     — 项目规范审查
security-reviewer (sonnet) 新 — 安全审查
{lang}-coder-project (sonnet) — 执行
test-runner (script/haiku)    — 跑测试
```

9 个 subagent，每个职责单一。

---

## 问题 3：哪些流程中内容可以使用 MCP 保存？

### 当前 v6.0 流程产出分布

| Phase | 产出 | 当前存储 | 应该存储 | 理由 |
|---|---|---|---|---|
| Phase 0 | spec.md | 文件 | ✅ 文件（保留） | 用户可读 + git trackable |
| Phase 0.5 | reuse-report.md | 文件 | ✅ 文件 + **memory MCP** | 文件保留完整，**决策**写 memory（避免下次重复评估） |
| Phase 1 | metadata + 热图 | 临时 | **memory MCP**（项目级 tag） | 跨 session 复用，下次 Phase 1 不重扫 |
| Phase 3 | design.md + test-plan.md | 文件 | ✅ 文件 + **memory MCP** | design 决策写 memory（避免下次同类任务重复设计） |
| Phase 4 | diff + delivery YAML | 文件 + git | ✅ 文件（保留） | git 是源 |
| Phase 4.5 | 校验报告 | 临时 | ❌ 不存（瞬间信息） | 校验是过程不是产出 |
| Phase 5 | review-report.md + test-result.md | 文件 | ✅ 文件 + **memory MCP** | findings 中"必修项"写 memory（避免下次同类错误） |
| Phase 6 | delivery-checklist.md | 文件 | ✅ 文件 + **memory MCP** | known_caveats + 项目决策写 memory |
| Phase 7 | archive.md | 文件 | ✅ 文件（保留） | 归档总结 |

### 应该写 memory MCP 但当前没写的（v6.1 候选）

| # | 产出 | 应写 tag | tier | 当前 | 升级 |
|---|---|---|---|---|---|
| **B1** | Phase 0.5 复用决策 | `coding-{lang}-reuse-decision` | 共享级 | ❌ 未写 | **复用模式**应跨项目复用（"FastAPI + Typer 的最佳实践"） |
| **B2** | Phase 1 metadata | `coding-{lang}-project-meta` | 项目级 | ❌ 未写 | 下次进项目不重扫 |
| **B3** | Phase 3 design 选择的 alternative | `coding-{lang}-design-choice` | 项目级 | ❌ 未写 | 避免下次同类任务重复设计 |
| **B4** | Phase 5 reviewer 发现的 BLOCKER | `coding-{lang}-trap` | 共享级 | 部分写（手写到 gotcha） | **自动化**：reviewer delivery 含 blocker → 自动写 memory |
| **B5** | Phase 6 用户接受的 known_caveats | `coding-{lang}-gotcha` | 项目级 | ❌ 未写 | 已知问题持久化 |
| **B6** | drift 触发 adaptive control 的案例 | `coder-execution-drift` | 共享级 | ❌ 未写 | 沉淀"什么任务容易 drift"，下次预防 |
| **B7** | 高危代码模式（test-plan 识别的） | `coding-{lang}-high-risk-pattern` | 共享级 | ❌ 未写 | 跨项目复用（"金融精度常见于 X 场景"） |

### 推荐立即实现（v6.1）

**B1 / B4 / B6** —— 这 3 个最有价值：
- B1：复用决策跨项目共享，避免每个项目重新评估"用 authlib 还是 fastapi-login"
- B4：reviewer 发现的 BLOCKER 自动写 memory，下次同类错误避免
- B6：drift 案例沉淀，"什么任务容易 drift"是元知识

### 实现方式

不需要新 hook，在现有流程里加：

**B1（Phase 0.5 复用决策）**：oracle delivery 含 `decision_summary` 字段 → orchestrator 自动 `memory_store(tags=["shared", "coding-{lang}-reuse-decision", ...])`

**B4（Phase 5 reviewer blocker）**：reviewer delivery 含 `findings.blockers` → orchestrator 对每个 blocker `memory_store(tags=["shared", "coding-{lang}-trap", "bug"])`

**B6（drift 案例）**：drift ≥ 0.4 触发 adaptive 时，orchestrator `memory_store(tags=["shared", "coder-execution-drift"])` 记录任务特征 + drift 原因

---

## 问题 4：哪些流程会被跳过，没有 task 记录最终？

### Phase 跳过审计

| Phase | 跳过方式 | 跳过后是否记录？ | 风险 |
|---|---|---|---|
| Phase -1 | 用户设 CODER_RESUME_MODE=off | ⚠️ 不记录（hook 静默放行） | 用户忘记有未完成 spec |
| **Phase 0** | 用户说"直接改就行，别问" | ❌ 不记录 | spec 缺失，后续无 trace |
| Phase 0.5 | 用户在 Phase 0 选跳 | ✅ skipped_phases 记录 | OK |
| Phase 1 | "我熟悉" | ❌ **静默跳过** | §11.1 反例复现 |
| Phase 2 | 单语言项目 | ✅ 自动跳 + 记录 | OK |
| **Phase 3** | 用户在 Phase 0 选跳 | ✅ 记录 | OK |
| **Phase 4** | orchestrator 直编（§2.2） | ⚠️ 只在汇报时标注 | 静默滑坡（§11.6） |
| Phase 4.5 | 用户在 Phase 0 选跳 | ✅ 记录 | OK |
| **Phase 5** | reviewer 全失败 → 自审降级 | ⚠️ ⚠️ 标注但无替代记录 | 自审产出不进 state.json |
| Phase 6 | 持久化简化（只写部分 memory） | ❌ 静默简化 | memory 不完整 |
| Phase 7 | 用户在 Phase 0 选跳 | ✅ 记录 | OK |

### 高风险盲区（v6.1 必修）

| # | 风险 | 当前 | 升级方案 |
|---|---|---|---|
| **C1** | Phase 0 跳过 | spec-guard 只 warn | **block 模式**（CODER_SPEC_GUARD=block 默认）+ 用户必须显式 `--allow-no-spec` 才跳 |
| **C2** | Phase 1 "我熟悉"跳过 | 无检测 | **`mcp-trigger-guard.sh`** PreToolUse Edit 多文件时，检查本 session 是否调过 `get_architecture`；没调 → block |
| **C3** | Phase 4 orchestrator 直编滑坡 | edit-guard 部分覆盖 | **强化**：连续第 3 次 Edit 无 spawn → block（不 warn） |
| **C4** | Phase 5 自审降级 | 只标注 ⚠️ | **强制**：自审产出也必须写 `review-report.md`（标"self-review"）+ 进 state.json |
| **C5** | Phase 6 持久化简化 | 无检测 | **`persistence-guard.sh`** archive 前检查 delivery-checklist.md + memory 写入条数；不达标 → block |
| **C6** | Phase -1 跳过（用户设 off） | 不记录 | **session-resume.sh** 即使 off 也写一行 trace：`user_set_off_mode` 到 spawn-trace.jsonl |

### 跳过记录的"最终"要求

**所有跳过必须留 3 类痕迹**：

1. **state.json `skipped_phases`**：显式记录
2. **state.json `phases[X].skip_reason`**：用户为什么跳（不是"agent 觉得简单"）
3. **archive.md 总结**：归档时列出所有跳过 + 影响

### 当前 v6.0 实现 vs 目标

| 维度 | v6.0 现状 | v6.1 目标 |
|---|---|---|
| Phase 0 跳过 | warn 模式，用户可忽略 | block 默认，显式 `--allow-no-spec` 才跳 |
| Phase 1 跳过 | 无检测 | mcp-trigger-guard 强制 |
| Phase 4 直编 | edit-guard warn | 连续第 3 次 → block |
| Phase 5 自审 | 标注 ⚠️ | 自审产出也写文件 + 进 state |
| Phase 6 简化 | 无检测 | persistence-guard 强制 |
| 跳过痕迹 | 部分记录 | 3 类痕迹强制（state / reason / archive） |

---

## v6.1 实现优先级

### P0（必做，高风险盲区）

1. **A3 model-binding-guard**：spawn 子 agent 必须传 model（R5.1 强制）
2. **A5 reviewer-spawn-guard**：Phase 5 ≥1 reviewer
3. **A8 drift-guard**：drift ≥ 0.4 触发 adaptive
4. **C1 Phase 0 block 模式**：spec-guard 默认 block
5. **C2 mcp-trigger-guard**：拦"我熟悉"跳 Phase 1
6. **C3 强化 edit-guard**：连续第 3 次 Edit 无 spawn → block

### P1（应做，子 agent 拆分）

7. **拆分 reviewer**：correctness / project / security（已有 project-reviewer，新增 2 个）
8. **新增 test-strategist**：从 oracle 剥离 test-plan 生成
9. **B4 reviewer blocker 自动写 memory**：findings.blockers → memory_store

### P2（可做，沉淀优化）

10. **B1 复用决策写 memory**：跨项目共享
11. **B6 drift 案例写 memory**：元知识沉淀
12. **拆分 researcher**：剥离"外部库评估"给 oracle
13. **C5 persistence-guard**：archive 前检查产出完整

---

## 总结

| 问题 | 答案摘要 |
|---|---|
| Q1 hook 强制 | v6.0 已强制 9 个，v6.1 加 6 个（A1/A3/A5/A8 + C2/C3） |
| Q2 agent 单一 | oracle 拆 test-strategist / reviewer 拆 3 / researcher 剥评估 |
| Q3 MCP 保存 | v6.1 加 3 个自动写（B1 复用 / B4 blocker / B6 drift） |
| Q4 跳过记录 | v6.0 部分覆盖，v6.1 强化 5 处（C1-C5） |

整体方向：**hook 强制 + agent 拆分 + memory 自动沉淀 + 跳过痕迹强制**。
