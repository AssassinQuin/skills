---
name: coder
description: >
  多语言编码元 skill（router + 13 Phase 流水线 + 22 modular skills + parallel subagents + 9 MCP 集成 + 14 hook 强制 + state 持久化 + token 经济 progressive disclosure）。


  显式 trigger：写代码、实现、重构、修复、修改、coder、编码、开发、debug、新增、
  审计代码、review diff、add feature、implement、build、fix。
  隐式 trigger："修这个 bug" / "加个 X 功能" / "重构这块" / "这块代码不对" /
  "为什么 X 报错" / "改下 X"。

  不触发：纯问答、解释、分析、调研（用 web-research / researcher）、人物思维（用 huashu-nuwa）。

  架构（v7.1）：本 skill 是 router，按 13 Phase 流水线编排 + parallel subagents；
  22 个 module（modules/{name}/SKILL.md + scripts/ + assets/）符合 Anthropic Cybersec skill anatomy；
  语言知识在 memory MCP；协议靠 14 个 hook 强制；references/ 已删除（v7.0 直接迁移到 modules/）。
metadata:
  version: "7.1"
  skill_type: execution
  agent_compatible: true
  previous_version: "7.0"
  modular: true
  modules_count: 22
  design_doc: ".deepen/20260625-execution-flow/design.md"
  modularization_doc: ".deepen/20260625-execution-flow/v7.0-skill-modularization.md"
---

# Coder v7.1 — Modular Skills + 强制协议 + Token 经济

> v5.0 → v6.0：7 Phase → 11 Phase + state 持久化 + delivery schema + 用户主导签字 + 9 hook 强制。
> v6.0 → v6.1：14 hook 强制（+5）+ reviewer 拆 3 + test-strategist + memory 自动沉淀。
> v6.1 → v6.2：mattpocock 反哺（tdd vertical cycle + to-issues slice + to-prd deep module + grill-with-docs）。
> v6.2 → v6.3：bug 诊断 + prototype + handoff + token 经济（from Anthropic Cybersec Skills）。
> v6.3 → v7.0：22 个 references → 22 个 modular skills（每个独立目录 + scripts + assets）。
> v7.0 → **v7.1**：单条消息并发子 agent 硬性 [3,5]（§4 #14）+ spawn 时必显式 model（不可全部继承主 agent）。
> 完整设计：[`design.md`](.deepen/20260625-execution-flow/design.md) + [`v7.0-skill-modularization.md`](.deepen/20260625-execution-flow/v7.0-skill-modularization.md)。
> v5.0 SKILL 备份：[`snapshots/`](snapshots/)。

**核心形态（v7.1）**：SKILL.md 是 router（本文件，目标 ≤400 行），22 个 module 在 `modules/{name}/`（每个含 SKILL.md + scripts/ + assets）。
语言约束 / 踩坑 / 经验**不在文件**，全在 memory MCP。
`references/` 已删除（v7.0 完全迁移到 `modules/`）。

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

**Phase 详执行**：见 [`modules/phase-{N}-*/SKILL.md`](modules/)。

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

## 7. Modules 索引（v7.0 模块化 + Token 经济 progressive disclosure）

> v7.0：22 个 references → 22 个 modular skills（每个 `modules/{name}/SKILL.md` + scripts + assets）。
> 每个 module 符合 Anthropic Cybersec skill anatomy（独立目录 + frontmatter + keyword-rich）。
> `references/` 已删除（v7.0），所有内容在 `modules/{name}/SKILL.md`。

### 7.1 Token 预算总览

| Priority | Tokens | 包含 |
|---|---|---|
| **always**（每次加载） | ~3500 | hard-constraints + anti-patterns |
| **high**（v6 协议核心） | ~3500 | v6-execution-protocol |
| **on-demand**（按 Phase） | ~1000-2500 each | 对应 Phase module |

**总预算承诺**：always (~3500) + high (~3500) + 当前 Phase (~1500) ≤ **10000 tokens**

### 7.2 always（每次必加载）

| Module | Tokens | 用途 |
|---|---|---|
| [`modules/hard-constraints/`](modules/hard-constraints/) | ~1500 | 13 硬约束（R1-R12） |
| [`modules/anti-patterns/`](modules/anti-patterns/) | ~2000 | AP-1 to AP-10 案例库 |

### 7.3 high（v6 协议核心）

| Module | Tokens | 用途 |
|---|---|---|
| [`modules/v6-execution-protocol/`](modules/v6-execution-protocol/) | ~3500 | 13 Phase 完整协议 / state / delivery / 断点续跑 / adaptive / memory 自动沉淀 |

### 7.4 Phase 协议 module（on-demand）

| Phase | Module | Tokens | 配套 |
|---|---|---|---|
| Phase 0 | [`modules/phase-0-intent-capture/`](modules/phase-0-intent-capture/) | ~1800 | assets/spec-template.md |
| Phase 0.5 | [`modules/phase-0.5-reuse-analysis/`](modules/phase-0.5-reuse-analysis/) | ~1200 | assets/reuse-report-template.md |
| Phase 0.6 | [`modules/phase-0.6-bug-diagnosis/`](modules/phase-0.6-bug-diagnosis/) | ~2000 | — |
| Phase 1 | [`modules/phase-1-metadata-scan/`](modules/phase-1-metadata-scan/) + [`phase-1-super-check/`](modules/phase-1-super-check/) | ~1800 | — |
| Phase 2.5 | [`modules/phase-2.5-prototype/`](modules/phase-2.5-prototype/) | ~1500 | — |
| Phase 3 | [`modules/phase-3-design-options/`](modules/phase-3-design-options/) + [`test-strategy/`](modules/test-strategy/) | ~2700 | test-strategy/assets/test-plan-template.md |
| Phase 4 | [`modules/phase-4-execution-protocol/`](modules/phase-4-execution-protocol/) | ~1800 | assets/ |
| Phase 4.5 | [`modules/phase-4.5-delivery-validation/`](modules/phase-4.5-delivery-validation/) | ~1200 | **scripts/validate-delivery.py** + assets/delivery-schema.yaml |
| Phase 5 | [`modules/phase-5-verification/`](modules/phase-5-verification/) | ~1200 | — |
| Phase 6 | [`modules/phase-6-persistence/`](modules/phase-6-persistence/) | ~1000 | assets/delivery-checklist + archive-template |
| adaptive（drift ≥ 0.4） | [`modules/adaptive-control/`](modules/adaptive-control/) | ~1000 | — |

### 7.5 MCP 集成 module（on-demand）

| Module | Tokens | 何时 |
|---|---|---|
| [`modules/codebase-memory-mcp/`](modules/codebase-memory-mcp/) | ~800 | 调 codebase-memory-mcp |
| [`modules/context-mode-integration/`](modules/context-mode-integration/) | ~800 | 子 agent 读大文件 |
| [`modules/memory-tier-strategy/`](modules/memory-tier-strategy/) | ~1000 | Phase 6 写 memory |
| [`modules/github-integration/`](modules/github-integration/) | ~600 | 涉及 issue/PR |
| [`modules/context7-integration/`](modules/context7-integration/) | ~600 | 写库代码 |

### 7.6 项目 init module（on-demand）

| Module | Tokens | 配套 |
|---|---|---|
| [`modules/project-init-protocol/`](modules/project-init-protocol/) | ~2500 | assets/ 含 5 个项目模板（CLAUDE.md + 4 个 agent template） |

### 7.7 v7.0 module 全清单（22 个）

```
modules/
├── phase-0-intent-capture/        # + scripts + assets
├── phase-0.5-reuse-analysis/      # + assets
├── phase-0.6-bug-diagnosis/
├── phase-1-metadata-scan/
├── phase-1-super-check/
├── phase-2.5-prototype/
├── phase-3-design-options/
├── phase-4-execution-protocol/    # + assets
├── phase-4.5-delivery-validation/ # + scripts + assets
├── phase-5-verification/
├── phase-6-persistence/           # + assets
├── hard-constraints/              # always
├── anti-patterns/                 # always
├── v6-execution-protocol/         # high
├── test-strategy/                 # + assets
├── adaptive-control/
├── codebase-memory-mcp/
├── context-mode-integration/
├── context7-integration/
├── github-integration/
├── memory-tier-strategy/
└── project-init-protocol/         # + assets (5 项目模板)
```

22 个 module，2 个含 scripts，7 个含 assets。

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

## 11. v5.0 → v6.3 关键变化（速查）

| 维度 | v5.0 | v6.0 | v6.1 | v6.2 | v6.3 |
|---|---|---|---|---|---|
| Phase 数 | 7 | 11 | 11 | 11 | **13**（+0.6 bug / +2.5 prototype） |
| state.json | 无 | 持久化 | 同 | 同 | 同 |
| delivery-schema | 无 | 子 agent 必须 | 同 | + slice 字段 | 同 |
| Phase 选择 | 全跑 | 用户选 | 同 | 同 | 同 |
| 用户签字 | 无 | Phase 0/3/5/6 必签 | 同 | 同 | 同 |
| test-plan | 无 | Phase 3 输出 | 同 | + vertical cycle | 同 |
| 复用分析 | 隐含 Phase 1 | 独立 Phase 0.5 | 同 | 同 | 同 |
| 归档 | 无 | Phase 7 | 同 | 同 | + handoff + post-mortem |
| 子 agent 并发 | Phase 1/3/5 | 同 + Phase 4 文件并发 | 同 | **+ Phase 4 vertical slice** | 同 |
| 协议执行 | 靠自觉 | 9 hook | **14 hook** | 同 | 同 |
| 子 agent 数 | 4 | 4 | 6 | 7 | **8**（+test-strategist / +2 reviewer） |
| **单条消息并发上限** | 无 | 无 | 无 | 无 | **3-5**（v7.1 §4 #14 硬约束） |
| **子 agent model 显式** | 隐式 | 同 | 同 | 同 | **强制 frontmatter + spawn 时双校验** |
| references | 隐式 progressive | 同 | 同 | 同 | **显式 token 估算 + load_priority** |
| bug 诊断 | 无 | 无 | 无 | 无 | **Phase 0.6（from diagnose）** |
| prototype | 无 | 无 | 无 | 无 | **Phase 2.5（from prototype）** |
| grilling loop | 无 | 无 | 无 | **oracle 自我压力测试** | 同 |
| SKILL.md 行数 | 318 | 717 | 同 | 274 | ≤400（progressive） |

**向后兼容**：未跑 v6.3 init 的项目按 v5.0/v6.0 跑。跑 init 自动启用最新。

详细差异：[`modules/v6-execution-protocol/SKILL.md`](modules/v6-execution-protocol/SKILL.md)。

### v6.3 核心新增（来自 Anthropic Cybersecurity Skills + mattpocock）

| 新增 | 来源 |
|---|---|
| **Phase 0.6 bug 诊断**（6 步 + falsifiable hypotheses） | mattpocock `diagnose` |
| **Phase 2.5 throwaway prototype**（6 rules） | mattpocock `prototype` |
| **delivery-checklist + archive 加 handoff 段** | mattpocock `handoff` |
| **references 显式 tokens_estimate + load_priority** | Anthropic Cybersec Skills |
| **SKILL.md §7 Token 预算表**（≤10000 tokens 承诺） | Anthropic Cybersec Skills |
| **每个 reference 加 keywords 字段**（可发现性） | Anthropic Cybersec Skills |
