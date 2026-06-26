---
name: v6-execution-protocol
description: v6.0 执行流程完整协议（SKILL.md §13-15 详细版）。state / delivery / 断点续跑 / Phase 协议。
source: ".deepen/20260625-execution-flow/design.md"
status: active
tokens_estimate: 3500
load_priority: high
load_when: "第一次进 v6 Phase / 协议不清时"
keywords: 11 phase pipeline state.json delivery-schema signature adaptive-control memory auto-store
domain: coding
subdomain: protocol
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  twelve_factor:
    - IV
    - IX. Disposability - 快启动 + 优雅退出
    - XI. Logs - 当作事件流
  notes: "state 持久化 + 断点续跑 = disposability + logs"
---

# Coder v6.0 执行流程协议（详细版）

> SKILL.md §13-15 的完整版。SKILL.md 只留路由表，详细协议在本文。

## 1. 11 Phase 流水线总览

```
Phase -1: 断点检测（SessionStart hook 自动）
Phase 0:  需求确认（多轮 AskUserQuestion + spec.md + 用户签字）
Phase 0.5: 复用 + 替代分析（explorer + researcher + oracle 并发）
Phase 1:  元数据 + 架构（explorer + get_architecture + researcher 并发）
Phase 2:  语言路由
Phase 3:  设计方案 + test-plan（N oracle 并发，复杂任务）
Phase 4:  执行（多 {lang}-coder-project 并发，按文件分组）
Phase 4.5: 子 agent 交付检查（validate-delivery.py）
Phase 5:  验证（3 reviewer 并发 + test-runner）
Phase 6:  持久化 + delivery-checklist（用户验收）
Phase 7:  归档
```

## 2. 3 个根本转变（v5.0+ → v6.0）

| 维度 | v5.0+ | v6.0 |
|---|---|---|
| 协议执行 | 靠 orchestrator 自觉 | phase-guard / spec-guard / signature-guard hook 强制 |
| 跨 session | /compact 丢上下文 | state.json 持久化 + session-resume hook |
| 主导权 | agent 主导 | 用户主导（Phase 0/3/5/6 必签字） |

## 3. state 持久化结构

```
.claude/coder-state/
├── current.json              # 当前活跃 spec
├── spawn-trace.jsonl         # 所有 spawn 痕迹
├── specs-active/{ts}-{slug}/ # 未完成 spec
│   ├── spec.md               # Phase 0 输出
│   ├── reuse-report.md       # Phase 0.5 输出
│   ├── design.md             # Phase 3 输出
│   ├── test-plan.md          # Phase 3 输出
│   ├── delivery-*.yaml       # Phase 4 子 agent 交付
│   ├── review-report.md      # Phase 5 输出
│   ├── test-result.md        # Phase 5 输出
│   └── delivery-checklist.md # Phase 6 输出
└── archive/                  # 已完成
    └── {ts}-{slug}/
        └── archive.md        # Phase 7 总结
```

state.json schema：
```json
{
  "spec_id": "20260625-1320-add-login",
  "spec_slug": "add-login",
  "started_at": "...",
  "last_active": "...",
  "current_phase": "Phase 4",
  "phases": {
    "Phase 0": {"status": "completed", "ts": "...", "user_signed_hash": "abc123"},
    "Phase 4": {"status": "in_progress", "started_ts": "..."}
  },
  "skipped_phases": ["Phase 2"],
  "tasks": [
    {"id": "p4-impl-login", "phase": "Phase 4", "status": "completed",
     "subagent": "python-coder-project", "deliverable": "delivery-1.yaml"}
  ],
  "checkpoints": [...],
  "user_preferences": {...}
}
```

## 4. Phase 跳过 vs 必跑

| Phase | 默认 | 用户可跳 | 理由 |
|---|---|---|---|
| -1 / 0 / 1 / 2 / 4 / 5 / 6 | 必跑 | ❌ | 核心协议 |
| 0.5（复用分析） | 推荐跑 | ✅ | 简单任务可跳 |
| 3（设计方案） | 推荐跑 | ✅ | 按 §2.1 复杂度评估 |
| 4.5（交付检查） | 推荐跑 | ✅ | 单 agent 简单任务可跳 |
| 7（归档） | 推荐跑 | ✅ | 保留 specs-active 也行 |

跳过必须在 Phase 0 spec.md 显式列出，state.json `skipped_phases` 记录。

## 5. 用户签字协议

### 5.1 必签 Phase（4 个）

| Phase | 签什么 | 用什么命令 |
|---|---|---|
| Phase 0 | spec.md（需求 + 验收 + Phase 选择） | `signature-guard.sh sign "Phase 0"` |
| Phase 3 | design.md（设计方案） | `signature-guard.sh sign "Phase 3"` |
| Phase 5 | review-report.md（审查通过） | `signature-guard.sh sign "Phase 5"` |
| Phase 6 | delivery-checklist.md（交付验收） | `signature-guard.sh sign "Phase 6"` |

### 5.2 签字流程

```
orchestrator 完成 Phase X 输出
  ↓
提示用户："Phase X 完成，请审阅 [文件路径]"
  ↓
用户读 + AskUserQuestion："同意 / 修改 / 返工"
  ↓ 同意
orchestrator 跑：bash signature-guard.sh sign "Phase X"
  ↓ 写入 state.json phases[X].user_signed_hash
orchestrator 跑：bash coder-state.sh update-phase "Phase X" completed
```

未签字不允许 completed。signature-guard verify 在 archive 前检查所有必签。

### 5.3 自动通过 Phase（不需签字）

默认 `["Phase 1", "Phase 2"]` 自动跑（用户在 Phase 0 可改）。

## 6. 子 agent delivery 协议

### 6.1 delivery-schema 7 字段

见 [`templates/delivery-schema.yaml`](../templates/delivery-schema.yaml) + [`templates/agents/_delivery-template.md`](../templates/agents/_delivery-template.md)。

### 6.2 校验规则（validate-delivery.py，7 条）

| # | 规则 | 失败 |
|---|---|---|
| 1 | 必填字段齐全 | BLOCK |
| 2 | files_changed 与 git diff 一致 | BLOCK |
| 3 | drift_score < 0.4 | BLOCK → 回 Phase 3 |
| 4 | verification_self ≥ 1 PASS | BLOCK |
| 5 | new_dependencies ⊆ spec.allowed_deps | BLOCK |
| 6 | known_caveats < 5 | WARN |
| 7 | handoff.to_reviewer.focus_areas ≥ 1 | BLOCK |

### 6.3 4 类 agent 差异

见 [`templates/agents/_delivery-template.md`](../templates/agents/_delivery-template.md) §4 类 agent delivery 速查表。

## 7. 断点续跑协议

### 7.1 SessionStart 检测

session-resume.sh 检测 current.json：
- 存在 → AskUserQuestion："续跑 / 查看进度 / 重新开始 / 永不问"
- 不存在 → 正常 Phase 0

### 7.2 续跑流程

```
读 current.json
  → 读 spec.md / design.md / test-plan.md / 已完成 delivery
  → 恢复上下文
  → 从 current_phase 继续
  → 跳过已 completed 的 Phase
```

### 7.3 重新开始

```
bash coder-state.sh abandon --reason "重新开始"
# 当前 spec 归档到 archive/，标记 abandoned
# 走 Phase 0 重新生成 spec
```

### 7.4 永不问

```
memory_store(
  content="用户偏好：不主动提示续跑，需要时手动 bash coder-state.sh resume",
  metadata={tags: "global,preference,coder-user-pref"}
)
```

## 8. Hook 强制清单（v6.0）

| Hook | 时机 | 作用 | 强制度 |
|---|---|---|---|
| `edit-guard.sh` | PreToolUse Edit/Write | 拦违反 §2.2 / 硬约束 #13 | block（可降级 warn） |
| `phase-guard.sh` | PreToolUse Edit/Agent + PostToolUse Agent | Phase 状态守卫 + spawn trace | warn（可升级 block） |
| `spec-guard.sh` | PreToolUse Edit/Write | 无 spec 拦代码改动 | warn（可升级 block） |
| `signature-guard.sh` | orchestrator 内联（非 hook） | Phase 完成前检查签字 | 强制（必签 Phase） |
| `task-progress-guard.sh` | PreToolUse/PostToolUse Agent | spawn 前 task 登记 + 完成后更新 | warn（可升级 block） |
| `git-guard.sh` | PreToolUse Bash | 拦危险 git 命令 | block（critical）/ warn |
| `session-resume.sh` | SessionStart | 检测 current.json 续跑 | hint |
| `session-load.sh` | SessionStart | v5.0+ 项目元信息 | hint |
| `spawn-trace.sh` | PostToolUse Agent/Bash | 记录 spawn + grep 痕迹 | hint |

降级：`CODER_*_GUARD=warn/off`（各 hook 独立）。

## 9. Phase 4 并发策略

```
按文件分组 → 每组 spawn 一个 {lang}-coder-project
所有 spawn 在一条消息里（Claude Code 自动并发）
上限 5 个并发（防 token 爆炸）
每个子 agent fresh context（无 conversation 历史）
每个子 agent 必须返回 delivery-schema
```

## 10. adaptive control（drift 触发）

> v7.2：完整内容抽到独立 first-class skill [`coder-adaptive`](../../../coder-adaptive/SKILL.md)。
> 本节仅留触发条件速查；公式 + 实施细节见 coder-adaptive/SKILL.md。

```
触发条件（任一）：
  - max_drift >= 0.4
  - sum_file_overrun >= 3
  - sum_loc_overrun >= 50

触发后：spawn oracle 重新分解 + 🔒 用户确认新计划（详见 coder-adaptive）
```

## 11. Phase 7 归档流程

> v7.2：完整内容抽到独立 first-class skill [`coder-archive`](../../../coder-archive/SKILL.md)。
> 本节仅留 6 步速查；archive.md 模板 + handoff 段 + post-mortem 段见 coder-archive/SKILL.md。

```
1. signature-guard.sh verify（必签 Phase 0/3/5/6）
2. 生成 archive.md（含 handoff + post-mortem）
3. mv specs-active/{ts}-{slug}/ archive/
4. 清除 current.json
5. 更新 MASTER.md 索引
6. memory MCP 沉淀（详见 coder-archive + coder-persist）
```

## 12. 与 v5.0+ 的兼容性

- v5.0+ 项目 init 系统完全兼容
- 未跑 v6.0 init 的项目按 v5.0 跑（无 state.json，无新 hook）
- v6.0 init 在 v5.0+ init 基础上加：state 系统 + phase-guard + spec-guard + delivery 校验
- 跑 `bash init-project.sh` 自动启用 v6.0

## 13. tradeoffs

### 13.1 强制 Phase 选择 vs 默认全跑

**v6.0**：Phase 0 用户选 → 灵活
**v5.0**：默认全跑 → 一致但浪费

### 13.2 每 Phase 用户签字 vs 自动通过

**v6.0**：Phase 0/3/5/6 必签，1/2/4/4.5 自动（除非用户改）
**严格**：每 Phase 签 → 安全但慢

### 13.3 state.json 持久化粒度

**v6.0**：粗粒度（Phase 结束）+ 细粒度（task 完成时）混合
**全细**：每工具调用写 → IO 频繁

### 13.4 子 agent 数量上限

**v6.0**：上限 5 个（Phase 4 并发）
**无限制**：充分并发但 token 爆炸

## 14. 风险

| 风险 | 缓解 |
|---|---|
| hook 误判卡住正常工作 | `CODER_*_GUARD=warn` 降级 |
| spec.md 生成太慢 | 简单任务用户在 Phase 0 选 "skip spec" |
| state.json 写失败 | 所有写操作 backup + rollback |
| 子 agent delivery 格式不一致 | validate-delivery.py 拦截 |
| 并发子 agent 上下文污染 | 每个 fresh context |
| 用户嫌多 AskUserQuestion | Phase 0 一次问全 |

---

## 15. Memory MCP 自动沉淀协议（v6.1）

orchestrator 在 3 个关键点**自动**写 memory MCP（不需用户操作）。

### 15.1 Phase 0.5 → `coding-{lang}-reuse-decision`（shared）

**触发**：Phase 0.5 oracle delivery 的 `outputs.decision_summary` 字段非空。

**写什么**：oracle 的复用决策（"用 X 不用 Y 的理由"）。

```python
# orchestrator 内联
decision = oracle_delivery.outputs.decision_summary
memory_store(
  content=f"{spec_slug}: {decision}",
  metadata={
    "tags": f"shared,coding-{lang}-reuse-decision,pattern",
    "type": "pattern",
    "lifecycle": "refined"
  }
)
```

**目的**：跨项目复用"X 库 vs Y 库"决策。下次同类项目直接搜到。

### 15.2 Phase 5 → `coding-{lang}-trap`（shared）

**触发**：Phase 5 reviewer delivery 的 `outputs.findings.blockers` 列表非空。

**写什么**：每个 BLOCKER 自动写一条 memory（避免下次同类错误）。

```python
# orchestrator 内联
for reviewer_delivery in [correctness, project, security]:
    for blocker in reviewer_delivery.outputs.findings.blockers:
        memory_store(
          content=f"{blocker.category}: {blocker.description} at {blocker.location}. Fix: {blocker.suggestion}",
          metadata={
            "tags": f"shared,coding-{lang}-trap,bug",
            "type": "bug",
            "lifecycle": "raw"
          }
        )
```

**目的**：reviewer 发现的 BLOCKER 自动沉淀，下次同类错误避免。

### 15.3 drift ≥ 0.4 → `coder-execution-drift`（shared）

**触发**：drift-guard hook 检测到 drift ≥ 0.4，回 Phase 3 时。

**写什么**：drift 案例特征 + 原因（"什么任务容易 drift"）。

```python
# orchestrator 内联（drift-guard 触发后）
memory_store(
  content=f"""
drift case: {spec_slug}
phase: Phase 4 → Phase 3 (adaptive control triggered)
max_drift: {max_drift}
breakdown: {drift_breakdown}
task characteristics: {task_features}
root cause analysis: {why_drift_happened}
lesson: {what_to_do_differently}
""",
  metadata={
    "tags": "shared,coder-execution-drift,learning",
    "type": "learning",
    "lifecycle": "raw"
  }
)
```

**目的**：沉淀元知识"什么任务容易 drift"，下次预防。

### 15.4 写 memory 的 best practice

- **必精炼**：去掉对话残留，一句话能说清不用两句
- **必给上下文**：脱离原 spec 也能理解
- **必带 tag**：scope + type + 自定义（如 `coding-go-trap`）
- **MAY 加 lifecycle**：raw → refined → canonical

详见 [memory skill Cross-Skill API](../../memory/SKILL.md)。

### 15.5 何时**不**写 memory

| 场景 | 不写 |
|---|---|
| spec 内容（已在文件） | ❌ |
| diff（已在 git） | ❌ |
| Phase 4.5 校验报告（过程信息） | ❌ |
| 临时 caveats（如"测试偶发失败"） | ⚠️ 看 severity，low 不写 |

---

## 16. v6.1 新增 hook 清单

v6.0 9 个 hook + v6.1 新增 7 个 = **16 个 hook 强制协议**。

### v6.1 新增

| Hook | 时机 | 作用 | 强制度 |
|---|---|---|---|
| `model-binding-guard.sh` | PreToolUse Agent | spawn 必须显式 model（R5.1） | warn / block |
| `reviewer-spawn-guard.sh` | PreToolUse Bash（update-phase Phase 5） | Phase 5 ≥1 reviewer | block |
| `drift-guard.sh` | PostToolUse Bash（validate-delivery.py） | drift ≥ 0.4 强制 adaptive | block |
| `mcp-trigger-guard.sh` | PreToolUse Edit/Write | 多文件改动前必触发 MCP | warn / block |
| `persistence-guard.sh` | PreToolUse Bash（archive） | 归档前检查产出完整 | block |

### v6.0 + v6.1 完整 hook 清单

| # | Hook | 强制度 |
|---|---|---|
| 1 | edit-guard.sh | block（第 3 次） |
| 2 | git-guard.sh | block（critical） |
| 3 | phase-guard.sh | warn |
| 4 | spec-guard.sh | **block**（v6.1 升级） |
| 5 | signature-guard.sh | 强制（必签 Phase） |
| 6 | task-progress-guard.sh | warn |
| 7 | spawn-trace.sh | hint |
| 8 | session-resume.sh | hint |
| 9 | session-load.sh | hint |
| 10 | **model-binding-guard.sh** | warn（v6.1） |
| 11 | **reviewer-spawn-guard.sh** | block（v6.1） |
| 12 | **drift-guard.sh** | block（v6.1） |
| 13 | **mcp-trigger-guard.sh** | warn（v6.1） |
| 14 | **persistence-guard.sh** | block（v6.1，待实现） |

---

## 17. v6.1 子 agent 全景

v6.0 4 个 + v6.1 新增 2 + 拆分 2 = **8 个 subagent**，每个职责单一。

| Agent | model | 职责 | Phase |
|---|---|---|---|
| `explorer` | haiku | 扫描（项目结构 / 同类查找） | 0.5, 1 |
| `researcher` | sonnet | 搜索（不含库评估，归 oracle） | 0.5 |
| `oracle` | opus | 战略 alternatives + 复用决策 | 0.5, 3 |
| **`test-strategist`** (v6.1 新) | sonnet | test-plan 生成 | 3 |
| `{lang}-coder-project` | sonnet | 执行（写代码） | 4 |
| **`correctness-reviewer`** (v6.1 拆) | sonnet | 正确性 + 并发 + 错误处理 | 5 |
| `project-reviewer` | sonnet | 项目 codestyle + 模块边界 | 5 |
| **`security-reviewer`** (v6.1 拆) | sonnet | OWASP + PII + 鉴权 | 5 |

每个 agent：
- ✅ Model 硬约束（R5.1 显式锁定）
- ✅ MCP 使用说明（每个 MCP 触发条件 + 调用 + 降级）
- ✅ v6.0 delivery 协议（标准 YAML 输出）
- ✅ 单一职责（不混维度）
