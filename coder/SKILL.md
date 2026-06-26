---
name: coder
description: >
  多语言编码元 skill（router + 13 Phase 流水线 + 22 modular skills + parallel subagents + 9 MCP 集成 + 14 hook 强制 + state 持久化 + token 经济 progressive disclosure）。


  显式 trigger：写代码、实现、重构、修复、修改、coder、编码、开发、debug、新增、
  审计代码、review diff、add feature、implement、build、fix。
  隐式 trigger："修这个 bug" / "加个 X 功能" / "重构这块" / "这块代码不对" /
  "为什么 X 报错" / "改下 X"。

  不触发：纯问答、解释、分析、调研（用 web-research / researcher）、人物思维（用 huashu-nuwa）。

  架构（v7.2）：本 skill 是 router，按 13 Phase 流水线编排 + parallel subagents；
  14 个 Phase / 协议核心抽为 first-class skill（coder-{spec,reuse,debug,metadata,prototype,design,execute,deliver,verify,persist,archive,constraints,antipatterns,adaptive}/，见 skills-lock.json）；
  8 个 module 保留在 modules/（v6-execution-protocol 瘦身版 + 5 MCP 集成 + project-init + test-strategy）；
  语言知识在 memory MCP；协议靠 14 个 hook 强制。
metadata:
  version: "7.2"
  skill_type: execution
  agent_compatible: true
  previous_version: "7.1"
  modular: true
  modules_count: 22
  design_doc: ".deepen/20260625-execution-flow/design.md"
  modularization_doc: ".deepen/20260625-execution-flow/v7.0-skill-modularization.md"
---

# Coder v7.2 — 14 first-class skill + skills-lock + 强制协议

> v5.0 → v6.0：7 Phase → 11 Phase + state 持久化 + delivery schema + 用户主导签字 + 9 hook 强制。
> v6.0 → v6.1：14 hook 强制（+5）+ reviewer 拆 3 + test-strategist + memory 自动沉淀。
> v6.1 → v6.2：mattpocock 反哺（tdd vertical cycle + to-issues slice + to-prd deep module + grill-with-docs）。
> v6.2 → v6.3：bug 诊断 + prototype + handoff + token 经济（from Anthropic Cybersec Skills）。
> v6.3 → v7.0：22 个 references → 22 个 modular skills（每个独立目录 + scripts + assets）。
> v7.0 → v7.1：单条消息并发子 agent 硬性 [3,5]（§4 #14）+ spawn 时必显式 model（不可全部继承主 agent）。
> v7.1 → **v7.2**：14 个核心 module 拆为顶层 first-class skill（books_creater 模式）+ skills-lock.json 锁 hash。
> 完整设计：[`design.md`](.deepen/20260625-execution-flow/design.md) + [`v7.0-skill-modularization.md`](.deepen/20260625-execution-flow/v7.0-skill-modularization.md)。
> v5.0 SKILL 备份：[`snapshots/`](snapshots/)。

**核心形态（v7.2）**：SKILL.md 是 router（本文件，目标 ≤400 行）。
14 个 first-class skill 在顶层 `skills/coder-{name}/`（每个独立 SKILL.md + README + scripts + assets），由 [`skills-lock.json`](skills-lock.json) 锁定。
8 个 Tier 2 module 在 `coder/modules/{name}/`（v6-execution-protocol 瘦身 + 5 MCP 集成 + project-init + test-strategy）。
语言约束 / 踩坑 / 经验**不在文件**，全在 memory MCP。

---

## 1. 何时触发 / 何时不触发

**触发**：见 frontmatter `description`。

**退出条件**：

| 条件 | 行为 |
|---|---|
| 无匹配语言且目标文件无法确定 | 退出，使用通用编码 |
| 纯文档任务 | 退出，使用文档 skill |
| 非 coding 任务 | 退出，使用通用能力 |

---

## 2. 13 Phase 路由表（v6.3 核心）

| Phase | 名字 | 执行者 | 输入 | 输出 | 下一 Phase | **前置 gate**（MUST） |
|---|---|---|---|---|---|---|
| **-1** | 断点检测 | SessionStart hook | current.json | 续跑/重开决策 | 0 或 续 | state.json 存在 → AskUserQuestion |
| **0** | 需求确认 | orchestrator + AskUserQuestion 多轮 | 用户请求 | **spec.md** + 验收 + Phase 选择 + 用户签字 | 0.5 / 0.6 / 1 | spec.md 已生成 + signature-guard 签字 |
| **0.5** | 复用 + 替代分析 | 🌟 **3 路并发**: explorer(haiku) + researcher(sonnet) + oracle(opus) | spec.md | **reuse-report.md** | 1 | 用户已选 reuse decision |
| **0.6** | bug 诊断（v6.3 新）| orchestrator + 6 步 diagnose 循环 | bug 类任务 | **bug-report.md** + minimal repro + hypotheses | 1 | loop 已建 + 3-5 ranked hypotheses |
| **1** | 元数据 + 架构 | 🌟 **3 路并发**: explorer(haiku) + get_architecture(orchestrator 内联) + researcher(sonnet) | spec + reuse | metadata + S.U.P.E.R 热图 | 2 | **get_architecture MUST 触发** |
| **2** | 语言路由 | orchestrator（内联）| metadata | spawn `{lang}-coder-project` × 3-5（sonnet） | 3 或 4 | Phase 1 已记录 |
| **2.5** | throwaway prototype（v6.3 新）| prototype-coder (sonnet) | design.md | prototype 验证报告 | 3 或 4 | 6 rules 强制 + 用户决策 |
| **3** | 设计方案 + test-plan | 🌟 **2-4 oracle(opus) + 1 test-strategist(sonnet) 并发**（仅复杂任务，硬上限 5）| metadata + 热图 + reuse | **design.md** + **test-plan.md**（vertical cycle） | 4 | 用户选 design + signature-guard 签字 |
| **4** | 执行（vertical slice 并发）| `{lang}-coder-project` × 3-5（sonnet，按 vertical slice 分组，硬上限 5）| 方案 + memory 注入 | **diff + delivery-schema per agent**（含 slice 元数据） | 4.5 | **MUST spawn**（§2.2）+ task-progress-guard 登记 |
| **4.5** | 子 agent 交付检查 | orchestrator + `validate-delivery.py` | delivery × N | 校验报告 | 5 | 所有 delivery 合格 + drift < 0.4 |
| **5** | 验证 | 🌟 **3 reviewer 并发**: correctness(sonnet) + project(sonnet) + security(sonnet) + test-runner | diff + checklist + test-plan | **review-report.md** + **test-result.md** | 6 | ≥1 reviewer + signature-guard 签字 |
| **6** | 持久化 + 交付清单 + handoff | orchestrator + AskUserQuestion 验收 | 全部产出 | memory + **delivery-checklist.md**（含 handoff 段） | 7 | 用户在 checklist 签字 |
| **7** | 归档（含 post-mortem）| orchestrator | 全部产出 | **archive.md**（含 handoff + post-mortem）+ state 清除 | — | persistence-guard 检查 + `coder-state.sh archive` |

**Phase 详执行**：14 个 first-class skill（v7.2 拆分），见 [`skills-lock.json`](skills-lock.json) 和 `/Users/ganjie/skills/coder-{name}/`：
- Phase 0 → `coder-spec` / Phase 0.5 → `coder-reuse` / Phase 0.6 → `coder-debug`
- Phase 1 → `coder-metadata`（含合并的 S.U.P.E.R check） / Phase 2.5 → `coder-prototype`
- Phase 3 → `coder-design` / Phase 4 → `coder-execute` / Phase 4.5 → `coder-deliver`
- Phase 5 → `coder-verify` / Phase 6 → `coder-persist` / Phase 7 → `coder-archive`
- 协议核心（always loaded）：`coder-constraints` / `coder-antipatterns` / `coder-adaptive`（drift 触发）

**简单任务跳过**：Phase 0.5 / 3 / 4.5 / 7 用户在 Phase 0 选。Phase 1/4/5 不可跳。

### 2.1 复杂度评估（决定是否跳过 Phase 3）

任一命中 → 走 Phase 3：改动 ≥3 文件 / public API 变更 / 跨模块 / 新依赖 / 含"重构""统一" / 涉及高危代码。

### 2.2 Phase 4 唯一允许 orchestrator 直接编码

仅当**全部**满足：1 文件 + <20 行 + 不涉及第三方库语法 + 无 API 变更 + 无高危代码。
否则 MUST spawn。直编时 MUST 即时标注 `⚠️ orchestrator_direct_coding`（不能事后补）。

### 2.3 Phase 4 并发策略

按 vertical slice 分组 → 每组 spawn 一个 `{lang}-coder-project`，**一条消息里并发**。**硬性 3-5 个**（见 §4 #14）：低于 3 个说明 slice 切得太粗（应再拆），超过 5 个说明切得太细（应合并相邻 slice）。每个 spawn 必须显式 `model: sonnet`，返回 delivery-schema。

---

## 3. 语言路由（Phase 2 细则）

| 信号 | 路由 |
|---|---|
| `.go` 或项目含 `go.mod` | → `agents/go-coder.md` 或项目 `.claude/agents/go-coder-project.md`（优先） |
| `.py` 或项目含 `pyproject.toml`/`setup.py`/`requirements.txt` | → `agents/python-coder.md` 或项目 `python-coder-project.md` |
| `.ts`/`.tsx`/`.js` | 暂无 agent，回退通用 |
| `.rs` | 暂无 agent，回退通用 |
| 三层未匹配 | 退出 |

**spawn 前**：orchestrator 必调 `memory_search(tags=["coding-{lang}-*"])` 注入语言上下文。

### 3.1 MCP 触发条件表（MUST / SHOULD / OPTIONAL）

| MCP | 何时 MUST | 何时 SHOULD | 何时 OPTIONAL |
|---|---|---|---|
| **codebase-memory-mcp** | 多文件改动前；service/store 方法可能复用 | 改 1 文件但牵涉调用方 | 单文件 <20 行 |
| **context7** | 第三方库 API 不确定；新库集成 | 用了库但常用部分 | 纯 stdlib |
| **context-mode** | 命令输出 >20 行；读 >1 个大文件；批量 grep | 单文件 Read | 短输出观察 |
| **github MCP** | 任务涉及 PR/issue/上游 | 查 CI 状态 | 纯本地 |
| **memory MCP** | spawn 子 agent 前；Phase 6 写决策 | 涉及历史决策 | — |

**Anti-pattern**："我熟悉"**不构成**跳过 MCP 的理由。

---

## 4. 硬约束（14 条摘要）

| # | 约束 | 强制方式 |
|---|---|---|
| 1 | 意图不清必问（Phase 0） | spec-guard hook |
| 2 | 子 agent 显式指定 model（R5.1，**不可全部继承主 agent**） | agent frontmatter + spawn 时不可省 |
| 3 | token 预算硬性（主上下文 ≤30k） | context-mode 强制 |
| 4 | 暴露冲突不折中（R7） | orchestrator 内联 |
| 5 | 先读再写（R8） | hard-constraints.md |
| 6 | 测试验证意图（R9） | test-strategy.md |
| 7 | 长任务检查点（R10） | state.json + signature-guard |
| 8 | 惯例优先于新颖（R11） | project-reviewer |
| 9 | 失败显性化（R12） | 所有 hook 输出 |
| 10 | 外科手术式修改（R3） | edit-guard hook |
| 11 | 简洁优先（R2） | reviewer |
| 12 | 编码前先思考（R1） | Phase 0 强制 |
| 13 | **Edit 前 grep 同类模式** | edit-guard hook + hard-constraints.md |
| 14 | **单条消息并发子 agent ∈ [3, 5]**（v7.1 新） | spawn-count-guard hook + orchestrator 自检 |

**完整版**：[`modules/hard-constraints/SKILL.md`](modules/hard-constraints/SKILL.md)。

---

## 5. 语言知识在 memory MCP

**不存 references 文件**。语言约束 / 踩坑 / 经验全部在 memory MCP。

| tag | tier | 用途 |
|---|---|---|
| `coding-{lang}-convention` / `-trap` / `-tooling` / `-verification` | 共享级 | 跨项目通用 |
| `coding-{lang}-gotcha` | 项目级 | 项目专属坑 |
| `coding-super-decay` | 共享级 | S.U.P.E.R 衰减 |
| `coding-audit-finding` | 项目级 | reviewer 发现 |
| `coding-user-pref` | 全局级 | 用户偏好 |

详见 [`modules/memory-tier-strategy/SKILL.md`](modules/memory-tier-strategy/SKILL.md)。

---

## 6. 汇报（强制字段）

```markdown
## 改动摘要
- 语言: {lang} | 文件数: {N} | 类型: {类型} | 风险: {等级}

## 并发产出
- Phase 1: explorer + get_architecture + researcher → {N}/3 成功
- Phase 3: {N} oracle 并发 → 选定方案 {X}
- Phase 5: 3 reviewer 并发 → 🔴{N}/🟡{N}/🟢{N}

## MCP 调用
- codebase-memory-mcp / context-mode / memory / github / context7: {触发列表}

## 硬约束执行检查（§4 的 13 条）
- [✓/✗] 1-13

## drift_score（若触发 adaptive control）
- {file_overrun}/{loc_overrun}/{unplanned_deps}/{super_decay} → drift = {0.X}

## 文件列表 + 验证结果
- path/to/file: {改动} | lint: PASS | type: PASS | test: {M}P/{K}F
```

---

## 7. Skills 索引（v7.2：14 first-class + 8 内部 module）

> v7.2：原 22 个 module 拆为 **14 first-class skill**（顶层 `coder-{name}/`，独立 SKILL.md + README + scripts + assets）+ **8 个内部 module**（`coder/modules/{name}/`，按需加载）。
> 模式参照 books_creater：`skills-lock.json` 锁定 14 个 first-class skill 的 sha256 hash（防本地漂移）。

### 7.1 Token 预算总览

| Priority | Tokens | 包含 |
|---|---|---|
| **always**（每次加载） | ~3500 | coder-constraints + coder-antipatterns |
| **high**（v6 协议核心） | ~2800 | v6-execution-protocol（v7.2 瘦身版） |
| **on-demand**（按 Phase） | ~800-2200 each | 对应 coder-{phase} skill |

**总预算承诺**：always (~3500) + high (~2800) + 当前 Phase (~1500) ≤ **8000 tokens**

### 7.2 Tier 1 — 14 个 first-class skill（v7.2 新）

| Phase | Skill | Tokens | 备注 |
|---|---|---|---|
| 0 | [`coder-spec`](../coder-spec/) | ~1800 | assets/spec-template |
| 0.5 | [`coder-reuse`](../coder-reuse/) | ~1500 | assets/reuse-report-template |
| 0.6 | [`coder-debug`](../coder-debug/) | ~1600 | 6 步 diagnose |
| 1 | [`coder-metadata`](../coder-metadata/) | ~2200 | **含合并的 S.U.P.E.R check** |
| 2.5 | [`coder-prototype`](../coder-prototype/) | ~1700 | 6 rules 强制 |
| 3 | [`coder-design`](../coder-design/) | ~1900 | 2-4 oracle + test-strategist |
| 4 | [`coder-execute`](../coder-execute/) | ~1800 | vertical slice |
| 4.5 | [`coder-deliver`](../coder-deliver/) | ~1600 | validate-delivery.py |
| 5 | [`coder-verify`](../coder-verify/) | ~2100 | 3 reviewer 并发 |
| 6 | [`coder-persist`](../coder-persist/) | ~1500 | delivery-checklist |
| 7 | [`coder-archive`](../coder-archive/) | ~800 | post-mortem + handoff |
| always | [`coder-constraints`](../coder-constraints/) | ~2200 | 14 条硬约束 |
| always | [`coder-antipatterns`](../coder-antipatterns/) | ~1400 | AP-1 to AP-10 |
| drift 触发 | [`coder-adaptive`](../coder-adaptive/) | ~1300 | drift ≥ 0.4 重分解 |

完整 lock（含 sha256 hash）：[`skills-lock.json`](skills-lock.json)

### 7.3 Tier 2 — 8 个内部 module（保留 `modules/`）

| Module | Tokens | 用途 |
|---|---|---|
| [`modules/v6-execution-protocol/`](modules/v6-execution-protocol/) | ~2800 | v7.2 瘦身版（仅 state / delivery / 断点续跑） |
| [`modules/codebase-memory-mcp/`](modules/codebase-memory-mcp/) | ~800 | codebase-memory-mcp 集成 |
| [`modules/context-mode-integration/`](modules/context-mode-integration/) | ~800 | 子 agent 读大文件 |
| [`modules/context7-integration/`](modules/context7-integration/) | ~600 | 写库代码 |
| [`modules/github-integration/`](modules/github-integration/) | ~600 | 涉及 issue/PR |
| [`modules/memory-tier-strategy/`](modules/memory-tier-strategy/) | ~1000 | Phase 6 写 memory |
| [`modules/project-init-protocol/`](modules/project-init-protocol/) | ~2500 | 新项目 init（5 模板） |
| [`modules/test-strategy/`](modules/test-strategy/) | ~1200 | 测试规范（Phase 3/5 共用） |

### 7.4 Tier 2 清单（8 个）

```
coder/modules/
├── v6-execution-protocol/         # high（v7.2 瘦身版）
├── codebase-memory-mcp/           # MCP 集成
├── context-mode-integration/      # MCP 集成
├── context7-integration/          # MCP 集成
├── github-integration/            # MCP 集成
├── memory-tier-strategy/          # memory tier 规范
├── project-init-protocol/         # + assets (5 项目模板)
└── test-strategy/                 # 测试规范
```

---

## 8. 降级策略（失败显性化）

| 场景 | 降级 | 标注 |
|---|---|---|
| memory MCP 不可用 | 子 agent 裸跑 | ⚠️ 无语言经验注入 |
| codebase-memory-mcp 不可用 | grep/glob/Read | ⚠️ 影响分析可能不全 |
| context-mode 不可用 | Read（可能爆 context） | ⚠️ token 成本增加 |
| oracle 并发失败 ≥50% | 串行 1 oracle | ⚠️ 方案多样性降低 |
| reviewer 全失败 | orchestrator 自审 | ⚠️ 审查深度降低 |
| drift ≥ 0.4 | spawn oracle 重新分解 | 🔒 用户确认新计划 |
| **借"熟悉项目"跳 Phase 1** | **不允许降级** | 🔒 严禁静默跳过 |
| **借"任务简单"直接编码（§2.2）** | **不允许降级** | 🔒 严禁静默跳过 |
| **简化 Phase 5 reviewer** | reviewer 全失败时降级 | ⚠️ 显式标注 |

**绝不静默降级**（R12）。

---

## 9. 新语言扩展协议

新增语言按此协议：
1. `agents/{lang}-coder.md` 通用版
2. `templates/agents/{lang}-coder.template.md` 项目版模板
3. `snapshots/references-legacy-v3.2/` 4 个种子（conventions/traps/tooling/verification）
4. `scripts/seed-memory.py --lang={lang}` seed 到 memory MCP
5. 本文件 §3 路由表加对应行

---

## 10. 相关文件

- 编码子 agent：[`agents/go-coder.md`](agents/go-coder.md) / [`agents/python-coder.md`](agents/python-coder.md)
- 项目 agent 模板：[`templates/agents/`](templates/agents/)
- 全局子 agent：`agents/explorer.md`(haiku) / `oracle.md`(opus) / `researcher.md`(sonnet) / `correctness-reviewer.md`(sonnet) / `project-reviewer.md`(sonnet) / `security-reviewer.md`(sonnet) / `test-strategist.md`(sonnet)（每个含 v6.0 delivery + MCP 说明 + model 硬约束）
- v6.0 state：[`scripts/coder-state.{sh,py}`](scripts/)
- delivery 校验：[`scripts/validate-delivery.py`](scripts/validate-delivery.py)
- 9 个 hook：[`templates/hooks/scripts/`](templates/hooks/scripts/)
- 项目 init：[`scripts/init-project.{sh,py}`](scripts/)
- 完整设计：[`.deepen/`](.deepen/)（项目 init + v6.0 执行流程）

---

## 11. v5.0 → v7.2 关键变化（速查）

| 维度 | v5.0 | v6.0 | v6.1 | v6.2 | v6.3 | v7.0 | v7.1 | **v7.2** |
|---|---|---|---|---|---|---|---|---|
| Phase 数 | 7 | 11 | 11 | 11 | 13 | 13 | 13 | **13** |
| state.json | 无 | 持久化 | 同 | 同 | 同 | 同 | 同 | 同 |
| delivery-schema | 无 | 子 agent 必须 | 同 | + slice | 同 | 同 | 同 | 同 |
| 子 agent 并发 | Phase 1/3/5 | + Phase 4 | 同 | + vertical slice | 同 | 同 | 同 | 同 |
| 协议执行 | 靠自觉 | 9 hook | 14 hook | 同 | 同 | 同 | 同 | 同 |
| 子 agent 数 | 4 | 4 | 6 | 7 | 8 | 8 | 8 | **8** |
| **单条消息并发上限** | 无 | 无 | 无 | 无 | 无 | 无 | **[3,5]** | **[3,5]** |
| **子 agent model 显式** | 隐式 | 同 | 同 | 同 | 同 | 同 | **强制** | **强制** |
| **first-class skill 数** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **14**（拆分） |
| **skills-lock** | 无 | 无 | 无 | 无 | 无 | 无 | 无 | **sha256 锁 14 skill** |
| **内部 module 数** | — | — | — | — | — | 22 | 22 | **8**（瘦身） |
| bug 诊断 | 无 | 无 | 无 | 无 | Phase 0.6 | 同 | 同 | 同 |
| prototype | 无 | 无 | 无 | 无 | Phase 2.5 | 同 | 同 | 同 |
| SKILL.md 行数 | 318 | 717 | 同 | 274 | ≤400 | ≤400 | ≤400 | **≤400** |

**向后兼容**：未跑 v6.3 init 的项目按 v5.0/v6.0 跑。state.json 字段是 "Phase 0" 字符串，与 module 路径解耦，v7.2 拆分完全兼容老 state。

详细差异：[`modules/v6-execution-protocol/SKILL.md`](modules/v6-execution-protocol/SKILL.md)。

### v7.2 核心新增（from books_creater pattern）

| 新增 | 来源 |
|---|---|
| **14 module 拆 first-class skill** | books_creater `skills-lock.json` 模式 |
| **skills-lock.json**（sha256 + sourceType: local） | books_creater 同款 hash 算法 |
| **coder-metadata 合并 phase-1-super-check** | 减少跨 module 引用 |
| **coder-archive 从 v6-execution-protocol §11 抽出** | Phase 7 独立可调用 |
| **v6-execution-protocol 瘦身 442 → ~280** | 协议核心抽走，仅留 state/delivery |

---

## 12. Skills-lock（v7.2 新）

14 个 first-class skill 由 [`skills-lock.json`](skills-lock.json) 锁定：

- **sourceType**: `local`（与 books_creater 的 `github` 模式对应）
- **source**: `./skills/coder-{name}`
- **skillPath**: `SKILL.md`
- **computedHash**: sha256 of SKILL.md content

**校验命令**（read-only，检测 hash 漂移）：

```bash
cd /Users/ganjie/skills
python3 -c "
import json, hashlib, pathlib
lock = json.load(open('coder/skills-lock.json'))
for name, e in lock['skills'].items():
    actual = hashlib.sha256(pathlib.Path(name, 'SKILL.md').read_bytes()).hexdigest()
    status = '✓' if actual == e['computedHash'] else '✗ DRIFT'
    print(f'{status} {name}')
"
```

**hash 漂移处置**：`coder-{name}/SKILL.md` 改动后 MUST 跑 hash 重算脚本：

```bash
python3 -c "
import json, hashlib, pathlib
lock = json.load(open('coder/skills-lock.json'))
for name, e in lock['skills'].items():
    e['computedHash'] = hashlib.sha256(pathlib.Path(name, 'SKILL.md').read_bytes()).hexdigest()
json.dump(lock, open('coder/skills-lock.json','w'), indent=2, ensure_ascii=False)
print(f'{len(lock[\"skills\"])} hashes updated')
"
```

**主 coder 进 lock？不进**（books_creater 模式：主 router 由 git 直接管）。
