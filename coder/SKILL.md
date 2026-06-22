---
name: coder
description: >
  多语言编码元 skill（router + 7 Phase 流水线 + parallel subagents + 5 MCP 集成）。


  显式 trigger：写代码、实现、重构、修复、修改、coder、编码、开发、debug、新增、
  审计代码、review diff、add feature、implement、build、fix。
  隐式 trigger："修这个 bug" / "加个 X 功能" / "重构这块" / "这块代码不对" /
  "为什么 X 报错" / "改下 X"。

  不触发：纯问答、解释、分析、调研（用 web-research / researcher）、人物思维（用 huashu-nuwa）。

  架构（v5.0）：本 skill 是 router，按 7 Phase 流水线编排 + parallel subagents；
  语言知识在 memory MCP（不在 references）。
metadata:
  version: "5.0"
  skill_type: execution
  agent_compatible: true
  previous_version: "3.2"
  design_doc: ".deepen/20260622-v5.0/design.md"
---

# Coder v5.0 — Router + Parallel Subagents

> v3.2 → v5.0 推倒重做。完整设计见 [`design.md`](.deepen/20260622-v5.0/design.md)。
> v3.2 备份在 [`snapshots/SKILL-v3.2.md.bak`](snapshots/SKILL-v3.2.md.bak)。

**核心形态**：SKILL.md 是路由表（本文件），细节全在 `references/`（progressive disclosure）。
语言约束 / 踩坑 / 经验**不在文件**，全在 memory MCP（详见 §5）。

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

## 2. 7 Phase 路由表（核心）

| Phase | 名字 | 执行者 | 输入 | 输出 | 下一 Phase |
|---|---|---|---|---|---|
| 0 | 需求捕获 | orchestrator（内联）| 用户请求 | 意图 + 验收 checklist | 1 |
| 1 | 元数据 + 架构 | 🌟 **3 路并发**: explorer(haiku) + get_architecture(orch) + researcher(sonnet, 触发式) | 意图 | metadata + S.U.P.E.R 热图 | 2 |
| 2 | 语言路由 | orchestrator（内联）| metadata | spawn `{lang}-coder` | 3 或 4 |
| 3 | 设计方案 | 🌟 **N oracle 并发**（2-4，按复杂度，仅复杂任务）| metadata + 热图 | 2-4 方案 + 推荐 | 4 |
| 4 | 执行 | `{lang}-coder`（sonnet，可多语言并发）| 方案 + memory 注入 | diff + drift 遥测 | 5 |
| 5 | 验证 | 🌟 **3 reviewer 并发**: 正确性 / S.U.P.E.R / 安全 | diff + checklist | 审查报告 | 6 |
| 6 | 持久化 | orchestrator（内联）| 全部产出 | memory + MASTER.md + 索引 | — |

**Phase 详执行协议**：见 [`references/phase-{N}-*.md`](references/)。

**简单任务跳过 Phase 3**：改动 <3 文件 / 无 public API 变更 / 无跨模块影响 / 无新依赖。

---

## 3. 语言路由（Phase 2 细则）

| 信号 | 路由 |
|---|---|
| 目标文件 `.go` 或项目含 `go.mod` | → [`agents/go-coder.md`](agents/go-coder.md) |
| 目标文件 `.py` 或项目含 `pyproject.toml`/`setup.py`/`requirements.txt` | → [`agents/python-coder.md`](agents/python-coder.md) |
| `.ts`/`.tsx`/`.js` | 暂无 agent，回退通用 + 提示扩展 |
| `.rs` | 暂无 agent，回退通用 + 提示扩展 |
| 三层未匹配 | 退出 |

**spawn `{lang}-coder` 前**：orchestrator 必调 `memory_search(tags=["coding-{lang}-*"])`
注入语言上下文。若返回空 → 触发 seed 流程（§5 + [`references/memory-tier-strategy.md`](references/memory-tier-strategy.md)）。

---

## 4. 硬约束（12 条摘要）

| # | 约束 | 出处 |
|---|---|---|
| 1 | 意图不清必问（Phase 0） | R1 + R4 |
| 2 | 子 agent 必须显式指定 model（R5.1） | R5.1 |
| 3 | token 预算硬性（主上下文 ≤30k + ctx_index 长文件） | R6 |
| 4 | 暴露冲突不折中（R7） | R7 |
| 5 | 先读再写（R8） | R8 |
| 6 | 测试验证意图（R9） | R9 |
| 7 | 长任务检查点（R10） | R10 |
| 8 | 惯例优先于新颖（R11） | R11 |
| 9 | 失败显性化（R12） | R12 |
| 10 | 外科手术式修改（R3） | R3 |
| 11 | 简洁优先（R2） | R2 |
| 12 | 编码前先思考（R1） | R1 |

**完整版**（含检查命令 + 例子）：[`references/hard-constraints.md`](references/hard-constraints.md)。

---

## 5. 语言知识在 memory MCP（v5.0 核心决策）

**不存 references 文件**。语言约束 / 踩坑 / 经验全部在 memory MCP。

| tag | tier | 用途 |
|---|---|---|
| `coding-{lang}-convention` / `-trap` / `-tooling` / `-verification` | 共享级 | 跨项目通用知识 |
| `coding-{lang}-gotcha` | 项目级 | 项目专属坑（子 agent 可写）|
| `coding-super-decay` | 共享级 | S.U.P.E.R 衰减记录 |
| `coding-audit-finding` | 项目级 | reviewer 发现（子 agent 可写）|
| `coding-user-pref` | 全局级 | 用户偏好 |

**写入权限**：子 agent 只能写项目级；共享/全局级必须 orchestrator + 🔒 用户确认。
**首次使用 memory 为空**：orchestrator 检测 → AskUserQuestion（是 / 这次否 / 永不问）→
用户选"是"才跑 `scripts/seed-memory.py`。详见 [`memory-tier-strategy.md`](references/memory-tier-strategy.md)。

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

## 硬约束执行检查（§4 的 12 条）
- [✓/✗] 1-12

## drift_score（若触发 adaptive control）
- {file_overrun}/{loc_overrun}/{unplanned_deps}/{super_decay} → drift = {0.X}
- 决策: 继续 / warning / 重新分解 / 回 Phase 0

## 文件列表 + 验证结果
- path/to/file: {改动} | lint: PASS | type: PASS | test: {M}P/{K}F
```

---

## 7. references 索引（progressive disclosure）

| 文件 | 何时加载 |
|---|---|
| [`phase-0-intent-capture.md`](references/phase-0-intent-capture.md) | Phase 0 触发 AskUserQuestion |
| [`phase-1-metadata-scan.md`](references/phase-1-metadata-scan.md) | Phase 1 开始 |
| [`phase-1-super-check.md`](references/phase-1-super-check.md) | Phase 1 S.U.P.E.R 评分 |
| [`phase-3-design-options.md`](references/phase-3-design-options.md) | Phase 3 复杂任务 |
| [`phase-4-execution-protocol.md`](references/phase-4-execution-protocol.md) | Phase 4 spawn 子 agent |
| [`phase-5-verification.md`](references/phase-5-verification.md) | Phase 5 spawn reviewer |
| [`phase-6-persistence.md`](references/phase-6-persistence.md) | Phase 6 持久化 |
| [`codebase-memory-mcp.md`](references/codebase-memory-mcp.md) | 任 Phase 调 codebase-memory-mcp |
| [`context-mode-integration.md`](references/context-mode-integration.md) | 子 agent 读大文件 / 批量命令 |
| [`memory-tier-strategy.md`](references/memory-tier-strategy.md) | Phase 6 写 memory |
| [`github-integration.md`](references/github-integration.md) | 任务涉及 issue/PR/上游 |
| [`context7-integration.md`](references/context7-integration.md) | 子 agent 写库代码 |
| [`adaptive-control.md`](references/adaptive-control.md) | Phase 4 drift ≥ 0.2 |
| [`hard-constraints.md`](references/hard-constraints.md) | **永远加载**（orchestrator + 所有子 agent） |

---

## 8. 降级策略（失败显性化，符合硬约束 #9）

| 场景 | 降级 | 标注 |
|---|---|---|
| memory MCP 不可用 | 子 agent 裸跑（不回退 legacy）| ⚠️ 无语言经验注入 |
| codebase-memory-mcp 不可用 | grep/glob/Read | ⚠️ 影响分析可能不全 |
| context-mode 不可用 | Read（可能爆 context）| ⚠️ token 成本增加 |
| oracle 并发失败 ≥50% | 串行 1 oracle | ⚠️ 方案多样性降低 |
| reviewer 并发失败 | orchestrator 自审 | ⚠️ 审查深度降低 |
| drift ≥ 0.4 | spawn oracle 重新分解 | 🔒 用户确认新计划 |

**绝不静默降级**（R12）。

---

## 9. 新语言扩展协议

新增语言（TypeScript / Rust / Java）按此协议：

1. 在 `agents/` 新建 `{lang}-coder.md`（参考 `go-coder.md`）
2. 在 `references/legacy/` 提供 4 个种子文件（`{lang}-conventions/traps/tooling/verification.md`）
3. 跑 `scripts/seed-memory.py --lang={lang}` seed 到 memory MCP
4. 在本文件 §3 语言路由表加对应行

缺任一步骤 → 该语言不可用，§3 路由退出"未匹配"。

---

## 10. 相关文件

- 编码子 agent：[`agents/go-coder.md`](agents/go-coder.md) / [`agents/python-coder.md`](agents/python-coder.md)
- 全局子 agent（被本 skill 复用）：`agents/explorer.md` / `agents/oracle.md` / `agents/reviewer.md` / `agents/researcher.md`
- 14 个 references：见 §7
- v3.2 语言 references（待 seed）：`references/legacy/`
- 完整设计文档：[`.deepen/20260622-v5.0/design.md`](.deepen/20260622-v5.0/design.md)（716 行）
- v3.2 SKILL.md 备份：[`snapshots/SKILL-v3.2.md.bak`](snapshots/SKILL-v3.2.md.bak)
