# Coder v6.0 执行流程设计

**日期**：2026-06-25
**作者**：Quin
**前置**：v5.0（router + parallel subagents）+ v5.0+（项目初始化系统）
**状态**：设计完成，待实现

---

## 0. 用户痛点（v5.0+ 暴露的问题）

| 痛点 | 案例 | v6.0 解决方案 |
|---|---|---|
| **没有 task 全流程追踪** | Phase 4 spawn 子 agent 后，主 agent 不知道子 agent 进度 | state.json + TaskCreate 全程同步 |
| **跨 session 续跑难** | 长任务 /compact 后丢上下文，重头来 | `.claude/coder-state/` 持久化 + SessionStart 检测 |
| **需求模糊就开干** | 用户说"加个登录"，agent 默认理解可能错 | Phase 0 多轮 AskUserQuestion + spec.md 签字 |
| **Phase 全跑浪费时间** | 1 行 typo 修也走 7 Phase | Phase 0 用户选哪些 Phase 跑 |
| **不知道有没有现成的** | 重复造轮子 | Phase 0.5 explorer + oracle 评估替代方案 |
| **测试策略缺失** | 改了核心代码没测，上线炸 | Phase 3 输出 test-plan.md（高危代码 + 测试范围） |
| **子 agent 产出格式乱** | reviewer 拿到的 diff 描述不一致 | delivery-schema 强制格式 |
| **没有交付清单** | "做完了"但用户不知道验收什么 | Phase 6 delivery-checklist.md |
| **静默跳过协议** | §11.6 滑坡 | phase-guard hook 拦截 |
| **并发没真正用起来** | 多文件改动还是串行 | Phase 4 多 lang-coder 并发 spawn |

---

## 1. v6.0 核心理念

**3 个根本转变**：

### 转变 1：从"靠自觉"到"靠强制"

| v5.0+ | v6.0 |
|---|---|
| 13 硬约束写文档，靠 orchestrator 读 | phase-guard hook 在 PreToolUse 拦截违反 |
| Phase 跳过是"事后反思" | task 跟踪强制：跳过必须显式 declare + 用户确认 |
| 子 agent 返回啥都行 | delivery-schema 校验，不合格 phase 4.5 拦截 |

### 转变 2：从"一次性"到"跨 session"

```
.claude/coder-state/
├── current.json              # 当前活跃 spec（如有）
├── archive/
│   ├── 20260625-1320-add-login/
│   │   ├── spec.md
│   │   ├── reuse-report.md
│   │   ├── design.md
│   │   ├── test-plan.md
│   │   ├── tasks.json
│   │   ├── delivery-checklist.md
│   │   └── archive.md
│   └── ...
└── specs-active/              # 未完成的 spec
    └── 20260625-1500-refactor-db/
        ├── spec.md
        └── partial-state.json
```

SessionStart hook 检测 `current.json` 存在 → AskUserQuestion：续跑 / 重新开始 / 查看进度。

### 转变 3：从"agent 主导"到"用户主导"

每个 Phase 开始前 AskUserQuestion 确认（除非用户在 Phase 0 选了"全自动"）：
- Phase 0 完成 → 用户确认 spec
- Phase 3 完成 → 用户选 design
- Phase 5 完成 → 用户确认通过
- Phase 6 完成 → 用户验收 delivery

---

## 2. v6.0 完整 Phase 流水线（9 个 Phase）

```
SessionStart
  ↓
Phase -1: 断点检测
  ↓ 无未完成 / 用户选重新开始
Phase 0: 需求确认（强化版，多轮 AskUserQuestion）
  → spec.md + 验收 checklist + Phase 选择 + 用户签字
  ↓
Phase 0.5: 复用 + 替代分析（explorer + oracle 并发）
  → reuse-report.md
  ↓ 用户确认复用策略
Phase 1: 元数据 + 架构（explorer + get_architecture + researcher 并发）
  → metadata + S.U.P.E.R 热图
  ↓
Phase 2: 语言路由
  → 决定 spawn 哪些 {lang}-coder-project
  ↓
Phase 3: 设计方案（N oracle 并发，仅复杂任务）
  → design.md + test-plan.md（高危代码 + 测试范围）
  ↓ 用户选 design
Phase 4: 执行（多 {lang}-coder-project 并发）
  → 每个 agent 返回 delivery-schema
  ↓
Phase 4.5: 子 agent 交付检查
  → 校验 delivery-schema + 整合 diff
  ↓ 不合格 → 返工（回 Phase 4）
Phase 5: 验证（3 reviewer 并发 + test-runner）
  → review-report.md + test-result.md
  ↓ 用户确认通过
Phase 6: 持久化
  → delivery-checklist.md + memory 写入
  ↓ 用户验收
Phase 7: 归档
  → 移动到 archive/ + 更新 MEMORY
```

---

## 3. 各 Phase 详细设计

### Phase -1: 断点检测（SessionStart 触发）

```
检测 .claude/coder-state/current.json
  ↓ 存在
AskUserQuestion:
  - 续跑（从 current_phase）
  - 查看进度（show state）
  - 重新开始（archive 当前 + 走 Phase 0）
  - 永不问（写到 memory MCP coder-user-pref）
  ↓ 不存在
跳到 Phase 0
```

**state.json schema**：

```json
{
  "spec_id": "20260625-1320-add-login",
  "spec_slug": "add-login",
  "started_at": "2026-06-25T13:20:00Z",
  "last_active": "2026-06-25T14:45:00Z",
  "current_phase": "Phase 4",
  "phases": {
    "Phase 0": {"status": "completed", "ts": "...", "user_signed_hash": "abc123"},
    "Phase 0.5": {"status": "completed", "ts": "...", "reuse_decisions": [...]},
    "Phase 1": {"status": "completed", "ts": "...", "metadata": {...}},
    "Phase 3": {"status": "completed", "ts": "...", "chosen_design": "alt-2"},
    "Phase 4": {"status": "in_progress", "started_ts": "...", "spawned_agents": [...]}
  },
  "skipped_phases": ["Phase 2"],  // 单语言项目跳过
  "tasks": [
    {"id": "p4-impl-login-handler", "phase": "Phase 4", "status": "completed",
     "subagent": "python-coder-project", "deliverable": "delivery-1.yaml"},
    {"id": "p4-impl-login-test", "phase": "Phase 4", "status": "in_progress",
     "subagent": "python-coder-project"}
  ],
  "deliverables_paths": {
    "spec": "specs-active/20260625-1320-add-login/spec.md",
    "reuse_report": ".../reuse-report.md",
    "design": ".../design.md",
    "test_plan": ".../test-plan.md"
  },
  "user_preferences": {
    "auto_confirm_phases": ["Phase 1", "Phase 2"],  // 这些 Phase 不问
    "timeout_budget_minutes": 60
  }
}
```

### Phase 0: 需求确认（强化版）

**子步骤**：

```
0.1 意图捕获
    orchestrator 复述用户需求（一句话 + 关键词）
    AskUserQuestion: "我理解对了吗？"（确认 / 修改 / 重新描述）

0.2 多轮追问（AskUserQuestion 多个并行问题）
    Q1: 这个需求是？
      - must（阻塞业务）
      - nice-to-have（优化体验）
      - experiment（验证想法）
    Q2: 验收 checklist（用户列，agent 提示模板）
      - [ ] 功能 X 能跑
      - [ ] 测试覆盖 Y
      - [ ] 文档更新 Z
    Q3: 时间预算
      - 30 分钟（小修）
      - 2 小时（中等）
      - 半天+（大改）
    Q4: 哪些 Phase 必跑？（multiSelect）
      - [x] Phase 0.5 复用分析（推荐）
      - [x] Phase 3 设计方案（推荐，复杂任务必跑）
      - [ ] Phase 4.5 子 agent 交付检查（简单任务可跳）
      - [x] Phase 5 reviewer（必跑）
      - [ ] Phase 7 归档（保留在 specs/）

0.3 生成 spec.md
    .claude/coder-state/specs-active/{ts}-{slug}/spec.md
    内容：
      - 用户原话
      - agent 复述（已确认）
      - 验收 checklist
      - Phase 选择
      - 时间预算
      - 用户签字 hash（commit hash + timestamp）

0.4 写 state.json
    phases["Phase 0"] = completed
    user_signed_hash = sha256(user.id + ts + spec_content)
```

**spec.md 模板**：
```markdown
# Spec: {slug}

**Created**: {ts}
**Phase 0 confirmed**: ✅ (hash: {hash})

## 用户原话
> {用户原始输入}

## Agent 复述（已确认）
{agent 一句话总结}

## 验收 Checklist
- [ ] {用户列的验收点 1}
- [ ] {用户列的验收点 2}

## Phase 选择
- ✅ Phase 0.5: 复用 + 替代分析
- ✅ Phase 3: 设计方案
- ⏭ Phase 4.5: 跳过（用户选）
- ✅ Phase 5: 验证

## 时间预算
{budget}

## 用户偏好
- 自动确认 Phase: [Phase 1, Phase 2]
- 完成 Phase 3 / 5 / 6 时需用户签字
```

### Phase 0.5: 复用 + 替代分析

**3 个 subagent 并发**：

| Subagent | 任务 | 输出 |
|---|---|---|
| `explorer` (haiku) | 在本 codebase 找同类实现 | reuse-internal.md |
| `researcher` (sonnet) | 在 GitHub / PyPI / pkg.go.dev 找现成方案 | reuse-external.md |
| `oracle` (opus) | 评估"复用 vs 自造 vs 替代" | reuse-decision.md |

**reuse-report.md 输出**：
```markdown
# Reuse Analysis: {slug}

## 1. 项目内可复用（explorer）
| 现有代码 | 复用方式 | 改动量 |
|---|---|---|
| `auth/login.py:42 LoginService` | 直接用 | 0 |
| `utils/validator.py:email` | 扩展 | +5 行 |

## 2. 外部现成方案（researcher）
| 库 / 项目 | 优势 | 劣势 | 集成成本 |
|---|---|---|---|
| `fastapi-login` | 开箱即用 | 灵活性差 | 1h |
| `authlib` | 标准协议 | 学习曲线 | 3h |

## 3. 决策（oracle）
**推荐**：复用 `LoginService` + 扩展 validator（不引入新依赖）

**理由**：
- 项目内 LoginService 已存在，0 集成成本
- 外部库灵活性差，不匹配本项目 N 个定制需求
- 扩展 validator 比 import authlib 轻

**反例（用户应避免）**：
- ❌ 重新写一个 LoginService（重复造轮子）
- ❌ 引入 fastapi-login（违反"无新依赖"约束）

## 4. 用户确认
[ ] 同意推荐方案
[ ] 改用：____
```

### Phase 1: 元数据 + 架构（v5.0 沿用 + 注入复用）

不变，但 explorer/researcher 拿到的 reuse-report.md 作为输入。

### Phase 2: 语言路由

不变。单语言项目自动跳过。

### Phase 3: 设计方案 + Test Plan

**N oracle 并发**输出 design.md + test-plan.md。

**test-plan.md**：
```markdown
# Test Plan: {slug}

## 1. 高危代码识别
| 改动位置 | 高危类型 | 原因 |
|---|---|---|
| `auth/login.py:commit_user` | 并发 + IO | DB 写 + 可能 race condition |
| `payment/refund.py` | 金融精度 | 涉及金额计算 |
| `external/github_api.py` | 外部 API | rate limit / timeout |

## 2. 测试范围
### Unit
- [ ] `LoginService.commit_user` 并发场景（pytest + pytest-asyncio）
- [ ] `RefundService.calculate` 精度边界（hypothesis property test）

### Integration
- [ ] 登录流程 end-to-end（真实 DB，不 mock）
- [ ] GitHub OAuth callback（mock server）

### Property（如有金融代码）
- [ ] refund 金额 = 原金额 - 手续费（任意输入都成立）

## 3. 性能基准（如有性能敏感改动）
- 登录响应 < 200ms (p99)
- DB query < 50ms (p99)

## 4. 不需要测试的（声明）
- `utils/logger.py` 简单 wrapper，仅依赖 stdlib
- 理由：低风险 + 现有测试覆盖
```

### Phase 4: 执行（多子 agent 并发）

**并发策略**：
```
按文件分组 → 每组 spawn 一个 {lang}-coder-project
  ↓
所有 spawn 在一条消息里（Claude Code 自动并发）
  ↓
每个子 agent 返回 delivery-schema（YAML）
```

**delivery-schema（强制格式）**：
```yaml
delivery:
  agent: python-coder-project
  task_id: p4-impl-login-handler
  phase: Phase 4
  
  inputs_received:
    - spec.md
    - design.md (alt-2)
    - test-plan.md
    - reuse-report.md (复用 LoginService)
  
  outputs:
    files_changed:
      - path: src/auth/login.py
        lines_added: 45
        lines_removed: 12
        new_methods: [commit_user]
      - path: tests/test_login.py
        lines_added: 78
        new_tests: [test_commit_user_concurrent, test_commit_user_db_error]
    
    new_dependencies: []  # 必须为空除非 spec 明确允许
    
    drift_score: 0.1
    drift_breakdown:
      file_overrun: 0  # 计划 2 文件，实际 2
      loc_overrun: 5   # 计划 40 行，实际 45
      unplanned_deps: 0
      super_decay: 0
  
  verification_self:
    - "lint: PASS (ruff check)"
    - "type: PASS (pyright)"
    - "tests: 8/8 PASS (只跑新测试)"
    - "reuse: ✅ 复用 LoginService，未造轮子"
  
  known_caveats:
    - "edge case: 用户被 ban 后 5 分钟内仍能登录（按 spec 不处理）"
    - "TODO line 45: 待加 rate limit"
  
  handoff_to_reviewer:
    focus_areas:
      - "commit_user 的 transaction 安全性"
      - "并发场景下 race condition"
    skip_areas:
      - "logging 格式（简单 wrapper）"
  
  handoff_to_orchestrator:
    next_actions:
      - "Phase 5: spawn reviewer"
      - "如 reviewer 通过 → Phase 6"
```

### Phase 4.5: 子 agent 交付检查

`scripts/validate-delivery.py`：
```python
# 校验规则
1. delivery-schema 字段齐全（agent / task_id / inputs / outputs / verification）
2. files_changed 与实际 git diff 一致
3. drift_score < 0.4（否则触发 adaptive control）
4. verification_self 至少 1 项 PASS
5. new_dependencies 为空 或 在 spec.allowed_deps 里
6. known_caveats 数量 < 5（否则提示拆任务）

# 不合格 → block + 返工理由
```

### Phase 5: 验证（3 reviewer + test-runner 并发）

| Reviewer | 维度 |
|---|---|
| `project-reviewer` | 项目 codestyle + 硬约束 |
| `correctness-reviewer` | 逻辑正确性 + 边界 + 并发 |
| `security-reviewer` | 安全（输入校验 / SQL / PII / 鉴权） |
| `test-runner` (script) | 按 test-plan.md 跑测试 |

输出：`review-report.md` + `test-result.md`。

### Phase 6: 持久化 + 交付清单

**delivery-checklist.md**：
```markdown
# Delivery Checklist: {slug}

## 验收 Checklist（从 spec.md 复制）
- [x] ✅ 功能 X 能跑（已演示）
- [x] ✅ 测试覆盖 Y（23/23 PASS）
- [ ] ⚠️ 文档更新 Z（未完成，原因：...）

## 交付物
| 类型 | 路径 | 状态 |
|---|---|---|
| Code | src/auth/login.py | ✅ |
| Tests | tests/test_login.py | ✅ 8 new tests |
| Docs | docs/auth.md | ⚠️ updated but needs review |
| Migration | migrations/001_add_banned_at.py | ✅ |

## Memory 写入
- coding-python-gotcha: "commit_user 并发场景必须用 SELECT FOR UPDATE"
- coding-python-convention: "LoginService 必须通过 container 注入，禁止直接 import"

## 已知问题（known caveats）
1. rate limit TODO at login.py:45
2. banned user 5 分钟窗口（按 spec 不处理）

## 用户验收
[ ] 同意交付
[ ] 需要返工：____
```

### Phase 7: 归档

```
mv .claude/coder-state/specs-active/{ts}-{slug}/ \
   .claude/coder-state/archive/

# 生成 archive.md 总结
# 更新 state.json: 标记 spec 完成
# 移除 current.json（如有）
```

---

## 4. 子 agent 体系（v6.0 全景）

```
orchestrator（主 agent）
  ↓ spawn
按 Phase 分工：

Phase 0.5:
  explorer (haiku)        — 项目内复用扫描
  researcher (sonnet)     — 外部方案调研
  oracle (opus)           — 复用决策

Phase 1:
  explorer (haiku)        — 元数据扫描
  get_architecture (orch) — MCP 直接调
  researcher (sonnet)     — 触发式（用第三方库时）

Phase 3:
  oracle × N (opus)       — 方案设计（2-4 并发）

Phase 4:
  {lang}-coder-project × N (sonnet) — 按文件分组并发

Phase 5:
  project-reviewer (sonnet)        — 项目硬约束
  correctness-reviewer (sonnet)    — 正确性
  security-reviewer (sonnet)       — 安全
  test-runner (script)             — 跑测试
```

**模型分配**（按 R5.1 硬约束）：
- 不需推理：haiku（explorer 扫描）
- 推理非战略：sonnet（lang-coder / reviewer / researcher）
- 战略推理：opus（oracle 设计方案）

---

## 5. Hook 强制清单（v6.0 新增）

| Hook | 时机 | 作用 |
|---|---|---|
| `phase-guard.sh` | PreToolUse Edit/Write | 检查 current_phase 是否允许 Edit（Phase 4 之外 warn） |
| `phase-guard.sh` | PreToolUse Agent | spawn 前更新 state.json tasks |
| `phase-guard.sh` | PostToolUse Agent | spawn 完成后更新 task status |
| `spec-guard.sh` | PreToolUse Edit/Write | 检查 spec.md 是否存在（不存在 → block，要求先 Phase 0） |
| `delivery-validator.sh` | PostToolUse Agent（lang-coder） | 校验返回的 delivery-schema（不合格 → 提示返工） |
| `task-trace.sh` | 所有 PreToolUse | 记录到 state.json activity log |
| `session-resume.sh` | SessionStart | 检测 current.json，AskUserQuestion 续跑 |
| edit-guard / git-guard / spawn-trace / session-load（v5.0+ 沿用） | — | 不变 |

---

## 6. 与 v5.0+ 的兼容性

- v5.0 的 7 Phase 路由表 → v6.0 扩展到 9 Phase（-1 / 0 / 0.5 / 1 / 2 / 3 / 4 / 4.5 / 5 / 6 / 7）
- v5.0 的 references/ 14 个文件**保留**
- v5.0+ 的项目 init 系统**完全兼容**（hook 在 init 时一起生成）
- v5.0 的 13 硬约束**保留**（在 phase-guard 里强制）

**向后兼容**：未跑 init 的项目继续按 v5.0 跑（无 state.json，无 phase-guard）。

---

## 7. 实现里程碑

| M | 内容 | 文件 |
|---|---|---|
| M1 | 设计文档（本文） | `.deepen/20260625-execution-flow/design.md` |
| M2 | state 管理脚本 | `scripts/coder-state.{sh,py}` |
| M3 | delivery-schema 模板 + 校验 | `templates/delivery-schema.yaml` + `scripts/validate-delivery.py` |
| M4 | phase-guard hook | `templates/hooks/scripts/phase-guard.sh` |
| M5 | Phase 0 spec.md 模板 + 引用 | `references/phase-0-intent-capture.md` + `templates/spec.md.template` |
| M6 | Phase 0.5 复用分析引用 | `references/phase-0.5-reuse-analysis.md` |
| M7 | 测试策略引用 + test-plan 模板 | `references/test-strategy.md` + `templates/test-plan.md.template` |
| M8 | SKILL.md v6.0 路由表 | `SKILL.md` §2 + §13 + §14 + §15 |
| M9（可选） | init 集成 phase-guard | `init-project.py` |
| M10（可选） | session-resume hook | `templates/hooks/scripts/session-resume.sh` |

---

## 8. Tradeoffs

### 8.1 强制 Phase 选择 vs 默认全跑

**用户选**（v6.0 推荐）→ 灵活，但用户负担重
**默认全跑**（v5.0）→ 一致，但简单任务浪费时间

**当前选择**：Phase 0 必问（multiSelect），简单任务用户可勾掉 Phase 0.5/4.5/7。复杂任务默认全选。

### 8.2 每 Phase 用户签字 vs 自动通过

**每 Phase 签字**（v6.0 严格）→ 安全，但慢
**自动通过 + 完成时签字**（v6.0 灵活）→ 快，但可能积累错误

**当前选择**：Phase 0/3/5/6 必签字，1/2/4/4.5 自动（除非用户在 spec 里改）。

### 8.3 state.json 持久化粒度

**每工具调用都更新**（细）→ 续跑精确，但 IO 频繁
**每 Phase 结束更新**（粗）→ 快，但 Phase 中断时丢进度

**当前选择**：粗粒度 + PreToolUse Agent 时更新 task 状态（细粒度）。

### 8.4 子 agent 数量上限

**无限制**→ 充分并发，但 token 成本高
**≤3**（v5.0）→ 安全，但大任务慢

**当前选择**：Phase 4 按文件分组，每组一个 lang-coder-project，上限 5 个并发（防 token 爆炸）。

---

## 9. 风险

| 风险 | 缓解 |
|---|---|
| phase-guard 误判卡住正常工作 | `CODER_PHASE_GUARD=warn` 降级 |
| spec.md 生成太慢，简单任务也走 Phase 0 | 用户在隐式触发时可选"跳过 Phase 0"（写 memory） |
| state.json 写失败 | 所有写操作有 backup + rollback |
| 子 agent delivery 格式不一致 | delivery-validator 在 Phase 4.5 拦截，不合格返工 |
| 并发子 agent 上下文污染 | 每个子 agent fresh context，无 conversation 历史 |
| 用户嫌多 AskUserQuestion | Phase 0 一次性多选，不在中间反复问 |

---

## 10. 与 Auto Mode 的关系

Claude Code auto mode（"bias toward working without stopping"）在 v6.0 下：
- **Phase 0 不降级**：必须用户确认 spec（这是用户主导的核心）
- **Phase 0.5/4.5 可降级**：用户在 Phase 0 选了跳过则跳
- **Phase 4 并发不降级**：多文件必并发
- **Phase 5 reviewer 不降级**：至少 1 个 reviewer

auto mode 只影响"问 vs 不问"，不影响"协议执行"。
