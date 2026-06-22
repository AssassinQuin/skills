# Coder Skill v5.0 重设计方案

**日期**：2026-06-22
**作者**：Quin + Claude
**版本**：v3.2 → v5.0（推倒重做）
**状态**：design pending review
**前作**：`../20260622-v4.0/design.md`（已废弃，作为 v5.0 的起点对照）

---

## TL;DR

v5.0 按 Anthropic 官方 skill 规范推倒重做，核心理念三层叠加：

1. **Progressive disclosure** — SKILL.md = 路由表（≤200 行），细节全进 `references/`
2. **Parallel subagents** — Phase 1/3/5 默认并发（parallel exploration，Anthropic best practices 经典模式）
3. **Orchestrator-as-router** — 主 agent 只做 4 件事：路由 / spawn / 合并 / 用户交互

v4.0 失败诊断（详见 §1）：在 v3.2 流水线上不断叠 phase + MCP，SKILL.md 会爆到 800+ 行，orchestrator 做 S.U.P.E.R / drift_score / 方案综合等所有重活，违反自己引用的 "subagent 做研究保持主 context 干净" 原则。

v5.0 推倒重做，代价是 4-6 周工作量，收益是 SKILL.md 可维护、context 干净、并发提速、5 个 MCP 全覆盖。

---

## 一、为什么推倒 v4.0

### 1.1 v4.0 的三个根本问题

| # | 问题 | 证据 | 后果 |
|---|---|---|---|
| **A** | **SKILL.md 会爆** | Phase 0-6 + 元数据 + MCP + S.U.P.E.R + Adaptive 全塞主文件 | 落地后 800+ 行，违反 Anthropic ≤500 行硬规范 |
| **B** | **零并发** | §4.1 流水线全串行；Phase 3 "2-3 方案"是 parallel exploration 经典场景却没用 | 慢且贵，浪费 Anthropic 官方强推能力 |
| **C** | **元 skill 不够"元"** | orchestrator 做 S.U.P.E.R 评分 / drift_score 决策 / 方案综合 | 违反 §2.2 自己引用的 "subagent 做研究保持主 context 干净" |

### 1.2 修不动 vs 重做

v4.0 design 已嵌入"orchestrator 做重活"的假设（Phase 1 S.U.P.E.R / Phase 3 方案 / Phase 5 验证都内联）。要改这条假设，需要重写 design 的 50%+ 章节，等同于推倒。所以 v5.0。

### 1.3 v5.0 保留的 v4.0 资产

- 7 Phase 流水线骨架（Phase 0/1/3 新增有价值）
- codebase-memory-mcp 5 触达点设计
- S.U.P.E.R 5 维评分规则
- Adaptive Control drift_score 公式
- 7 维元数据策略
- MASTER.md 跨 session 设计

这些进 `references/`，不丢。

---

## 二、v5.0 设计原则（7 条）

1. **官方规范优先** — SKILL.md ≤200 行（理想 ≤150），frontmatter 只放 `name` + `description` + `metadata.version`（`allowed-tools` v2 规范已废弃，工具声明进 `agents/*.md`）
2. **Progressive disclosure** — SKILL.md 是路由表，深度知识按需加载（§9 加载规则）
3. **Parallel by default** — 无依赖任务必须并发（R5.1 model 分层 + Agent 工具单条消息多 spawn）
4. **Orchestrator-as-router** — 主 agent 只做 4 件事：路由 / spawn / 合并 / 用户交互
5. **复用不新建**（coding-rules R8）— `agents/` 已有的 `explorer` / `oracle` / `reviewer` / `researcher` 全复用，按需扩工具
6. **失败显性化**（coding-rules R12）— MCP 降级 / 并发失败 / drift 超阈 必须标注
7. **12 硬约束继承** — v3.2 的 12 条硬约束全保留，搬到 `references/hard-constraints.md`

---

## 三、目标文件结构

```
coder/
├── SKILL.md                              # ≤200 行, 路由表 (见 §4)
├── README.md                             # 用户文档 (触发词 + 快速上手)
├── agents/                               # 编码子 agent (垂直)
│   ├── go-coder.md                       # (v3.2 保留 + 扩工具, §8.1)
│   └── python-coder.md                   # (v3.2 保留 + 扩工具, §8.1)
└── references/                           # 按需加载 (progressive disclosure)
    ├── phase-0-intent-capture.md         # AskUserQuestion 模板 + 跳过条件
    ├── phase-1-metadata-scan.md          # 7 维扫描命令 + explorer schema
    ├── phase-1-super-check.md            # S.U.P.E.R 5 维评分规则
    ├── phase-3-design-options.md         # oracle 3 路并发 prompt 模板
    ├── phase-4-execution-protocol.md     # 子 agent 调用约定 + drift 遥测 schema
    ├── phase-5-verification.md           # reviewer 3 路并发 prompt 模板
    ├── phase-6-persistence.md            # MASTER.md 格式 + memory 写入规则
    ├── codebase-memory-mcp.md            # 5 触达点 + 降级链
    ├── context-mode-integration.md       # ctx_execute_file / batch / search 场景
    ├── memory-tier-strategy.md           # 项目/共享/全局三层 + tag 规范 + seed 策略
    ├── github-integration.md             # issues/PR/code search 触发条件
    ├── context7-integration.md           # 库文档查询触发条件
    ├── adaptive-control.md               # drift_score 公式 + 决策表
    └── hard-constraints.md               # 12 条硬约束完整版
```

**14 个 references** vs v3.2 的 11 个：新增 3 个 phase-*.md（把原 code-audit-protocol / core-protocols 拆开）+ 4 个 MCP integration 文档。

**🚫 语言知识不进 references（v5.0 核心决策）**：

v3.2 在 references/ 里有 8 个语言专属文件（go-conventions / go-editing-traps / go-gopls-strategy / go-verification-loop / python-conventions / python-editing-rules / python-tooling / python-verification-loop），共约 13K。**v5.0 全部迁到 memory MCP**，理由：

1. **可持续累积**：每次 coder 跑完发现的新坑可增量写入 memory；references 是静态文件，改它需要 git commit
2. **跨项目复用**：Go 的"error 必须显式返回"在所有 Go 项目都适用，共享级 memory 自动生效
3. **references 更稳定**：只放流程性知识（phase 流程 / MCP 集成），不放经验性知识
4. **检索更精准**：memory MCP 支持 semantic + tag + tier 三维检索，比 grep references 更准
5. **符合 Anthropic 规范**：references 是"如何执行流程"，memory 是"执行时知道什么"

详见 §7.3 memory tier tag 规范 + §7.3.1 seed 策略。

---

## 四、SKILL.md 形态（router 模板，≤200 行）

```markdown
---
name: coder
description: 编码执行引擎。7 Phase 流水线 + parallel subagents + 5 MCP 集成。
  触发：开发/实现/修复/refactor/feature/fix/需求/帮我做/add feature/implement/build。
  不触发：纯问答、解释、分析、调研。
metadata:
  version: "5.0"
---

# Coder Skill v5.0

## 何时触发 / 何时不触发
（10 行，从 v3.2 继承）

## 7 Phase 路由表（核心）

| Phase | 名字 | 执行者 | 输入 | 输出 | 下一 Phase |
|---|---|---|---|---|---|
| 0 | 需求捕获 | orchestrator | 用户请求 | 意图 + 验收 checklist | 1 |
| 1 | 元数据+架构 | 🌟 3 路并发: explorer + get_architecture + researcher | 意图 | metadata + 热图 | 2 |
| 2 | 语言路由 | orchestrator | metadata | spawn {lang}-coder | 3 或 4 |
| 3 | 设计方案 | 🌟 N oracle 并发（2-4，按复杂度，仅复杂任务）| metadata + 热图 | 2-4 方案 + 推荐 | 4 |
| 4 | 执行 | {lang}-coder（可多语言并发）| 方案 | diff + drift 遥测 | 5 |
| 5 | 验证 | 🌟 3 reviewer 并发 | diff + checklist | 审查报告 | 6 |
| 6 | 持久化 | orchestrator | 全部产出 | memory + MASTER + 索引 | — |

## 硬约束（12 条摘要，每条一行）

1. 意图不清必问  2. 子 agent 必须指定 model  3. token 预算硬性
4. 暴露冲突不折中  5. 先读再写  6. 测试验证意图  7. 长任务检查点
8. 惯例优先  9. 失败显性化  10. 外科手术式修改  11. 简洁优先  12. 编码前先思考

完整版见 `references/hard-constraints.md`。

## references 索引（按需加载）

| 文件 | 何时加载 |
|---|---|
| phase-0-intent-capture.md | Phase 0 触发 AskUserQuestion |
| phase-1-metadata-scan.md | Phase 1 开始 |
| phase-1-super-check.md | Phase 1 S.U.P.E.R 评分 |
| phase-3-design-options.md | Phase 3 复杂任务 |
| phase-4-execution-protocol.md | Phase 4 spawn 子 agent |
| phase-5-verification.md | Phase 5 spawn reviewer |
| phase-6-persistence.md | Phase 6 持久化 |
| codebase-memory-mcp.md | 任 Phase 调 codebase-memory-mcp |
| context-mode-integration.md | 子 agent 读大文件 / 批量命令 |
| memory-tier-strategy.md | Phase 6 写 memory |
| github-integration.md | 任务涉及 issue/PR/上游 |
| context7-integration.md | 子 agent 写库代码 |
| adaptive-control.md | Phase 4 drift ≥ 0.2 |
| hard-constraints.md | 永远加载（orchestrator + 所有子 agent）|
```

**目标**：主体 ≤200 行，任何 phase 触发时按需加载 1-2 个 reference，主 context 始终干净。

---

## 五、Phase 流水线（含并发点 🌟）

### 5.1 Phase 0：需求捕获（orchestrator 内联）

不变（v4.0 设计 OK）。

- 复述用户请求（≤2 句）
- 若意图/验收/范围/边界任一不明确 → AskUserQuestion（总计 ≤2 次）
- 输出意图声明（1-2 句）+ 验收 checklist（3-5 条）
- 跳过条件：用户请求已含明确验收，或单文件 typo

**模板**：`references/phase-0-intent-capture.md`

### 5.2 Phase 1：元数据 + 架构（🌟 3 路并发）

**单条消息 spawn 3 路并发**（互不可见）：

| Agent | model | 任务 | 工具 |
|---|---|---|---|
| `explorer`（扩展） | haiku | 7 维元数据扫描 + 模块清单 | Read/Glob/Grep/Bash + `mcp__codebase-memory-mcp__index_status` |
| orchestrator 直调 MCP | — | `get_architecture(aspects=[file_tree, clusters])` | `mcp__codebase-memory-mcp__get_architecture` |
| `researcher`（触发式） | sonnet | 框架/库调研（仅 unknown framework 时）| searxng + web_reader + github（已具备）|

**3 路完成后**：orchestrator 合并输出 → S.U.P.E.R 评分（内联，需要 Phase 0 context）。

**为什么不并发 S.U.P.E.R**：评分依赖 explorer 给的模块清单 + Phase 0 意图，有数据依赖，必须串行。

### 5.3 Phase 2：语言路由（orchestrator 内联，毫秒级）

按 `metadata.language` 路由到 `{lang}-coder`。子 agent prompt 注入：metadata + S.U.P.E.R 热点 + index_status + 用户意图。

### 5.4 Phase 3：设计方案（🌟 N oracle 并发，核心创新）

**简单任务**判定（4 条全满足）：改动 <3 文件 / 无 public API 变更 / 无跨模块影响 / 无新依赖 → 跳过 Phase 3。

**复杂任务**：**按复杂度动态 spawn 2-4 个 oracle 并发**（决策表见下），每个做一个独立方向：

**oracle 数量决策表**（Q1 已决策：动态）：

| 任务特征 | oracle 数 | 典型场景 |
|---|---|---|
| **2 个** | 跨模块 ≤2 / 改动 3-7 文件 / 无 public API 变更 | "加新字段 + 改对应 handler" |
| **3 个**（默认）| 跨模块 ≥3 / 改动 8-20 文件 / 单接口变更 | "重构 internal/auth 模块" |
| **4 个** | 跨模块 ≥5 / 改动 >20 文件 / 多接口变更 / 涉及 🔴 热点 | "拆 monolith 为 3 个服务" |

**方向分配**（动态 oracle 各自做独立方向，命名约定）：

```
oracle-A: 方向"最小改动"（保持 public API, 内部重构）       [永远存在]
oracle-B: 方向"架构升级"（port-adapter / DDD / 模块拆分）   [2+ 时存在]
oracle-C: 方向"外部替换"（迁移到 pkg/ 或换库）              [3+ 时存在]
oracle-D: 方向"重写/混合"（推翻现有, 重新设计）            [仅 4 时存在]
```

每个 oracle 各自调 `trace_path` + `search_graph`，给出方案 + 风险 + 工作量估算 + S.U.P.E.R 影响。

**N 个 oracle 互不可见**（像 `brainstorm-collider` 的设计），避免趋同。

**orchestrator 合并**：N 方案对比表 → 标注推荐 → 🔒 AskUserQuestion 让用户选。

**为什么不串行 1 个 oracle 出 N 方案**：单 agent 出多方案会趋同（受自己前一方案影响）；并发隔离强制发散，是 Anthropic parallel exploration 的核心价值。

**为什么不固定 3 个**：固定数对简单重构是浪费（2 个就够），对大改又不够发散（需要 4 个）；动态兼顾成本与发散度（Q1 决策）。

### 5.5 Phase 4：执行（{lang}-coder，可多语言并发）

**spawn 前必做（语言知识注入）**：

orchestrator 在 spawn `{lang}-coder` 前，调 `memory_search` 加载该语言的经验（详见 §7.3 检索策略）：

```yaml
memory_search:
  query: "{任务关键词} {lang}"
  tags: ["coding-{lang}-convention", "coding-{lang}-trap",
         "coding-{lang}-tooling", "coding-{lang}-verification",
         "coding-{lang}-gotcha"]
  tier: [project, shared]
  limit: 20
```

查询结果作为"语言上下文"段注入子 agent prompt。

**若结果为空**（首次使用 / memory 未 seed）：
- 提示用户跑 seed 脚本（§7.3.1）
- 用户拒绝则标 ⚠️ + 裸跑（无 convention 注入）
- **绝不静默跳过**（违反 R12）

**子 agent 执行时**：实时调 MCP 4 触达点（§7.1 codebase-memory-mcp + §7.2 context-mode + §7.5 context7）。

**Adaptive Control 遥测**：每个 subtask 完成后返回 drift JSON（§10）。

**跨语言并发**：若任务涉及多语言（如 Go 后端 + Python 脚本 + TS 前端），spawn 多个 `{lang}-coder` 并发，每个独立查自己的 `{lang}-*` memory tags。

### 5.6 Phase 5：验证（🌟 3 reviewer 并发）

**3 路并发 reviewer**（fresh-context，各查独立维度）：

| reviewer | 职责 | 关注点 |
|---|---|---|
| reviewer-正确性 | 验收 checklist 逐条核对 + edge case | 功能正确 |
| reviewer-S.U.P.E.R | 新改动对架构健康的影响 + search_graph 回归 | 模块健康分衰减 |
| reviewer-安全 | 私钥/SQL 注入/权限绕过/PII | OWASP top 10 |

3 路并发 fresh-context 审查，orchestrator 合并报告 → 标注 🔴 阻塞 / 🟡 建议 / 🟢 通过。

### 5.7 Phase 6：持久化（orchestrator 内联）

3 层记忆（§7.3 memory tier）：
- memory MCP 项目级 / 共享级 / 全局级
- MASTER.md 跨 session 进度
- codebase-memory-mcp 增量索引（若 indexed）

---

## 六、并发架构规范

### 6.1 何时并发（强制）vs 何时串行（必须）

**必须并发**（无依赖）：
- Phase 1：explorer + get_architecture + researcher
- Phase 3：3 oracle 各做独立方向
- Phase 5：3 reviewer 各查独立维度
- Phase 4：多语言任务的多 {lang}-coder

**禁止并发**（有依赖）：
- Phase 0 → 1（意图先于扫描）
- Phase 1 S.U.P.E.R 评分（等扫描结果）
- Phase 4 内部 subtask（同文件改动有竞态）
- drift_score ≥ 0.4 时（必须先重新分解）

### 6.2 并发模板（单条消息多 spawn）

```yaml
# orchestrator 在单条消息里 spawn（Claude Code 原生支持）
spawn:
  - subagent_type: oracle
    description: "方案 A: 最小改动"
    prompt: "...独立上下文, 不提及 B/C..."
  - subagent_type: oracle
    description: "方案 B: 架构升级"
    prompt: "...独立上下文, 不提及 A/C..."
  - subagent_type: oracle
    description: "方案 C: 外部替换"
    prompt: "...独立上下文, 不提及 A/B..."
# orchestrator 等齐 3 个结果后合并
```

**Anthropic best practices 强调**：并发子 agent 互不可见，这避免趋同，是 parallel exploration 的核心价值（参考 `brainstorm-collider` 已实现此模式）。

### 6.3 并发失败处理

- 某个并发子 agent 失败 → 其他结果保留，失败的标 ⚠️（符合 R12 失败显性化）
- ≥50% 并发失败 → 整 phase 重试 1 次
- 仍失败 → 降级串行，标 "⚠️ 并发失败，结果可能不完整"

### 6.4 并发 token 预算

- Phase 3（3 oracle opus）：token 成本 3x，但只触发于复杂任务（简单任务跳过）
- Phase 5（3 reviewer sonnet）：成本 3x，但 sonnet 单价低
- Phase 1（1 haiku + 1 MCP + 1 sonnet）：成本可控
- **总预算**：单次 coder 调用并发 spawn 总 token ≤ 100k（超过则降级）

---

## 七、MCP 集成（5 个全覆盖）

### 7.1 codebase-memory-mcp（核心，保留 v4.0 §6 设计）

5 触达点：

| Phase | MCP 工具 | 用途 | 触发 |
|---|---|---|---|
| 1 | `index_status` + `get_architecture` | 项目骨架 + Leiden 社区 | `codebase_indexed=true` |
| 2 | `search_graph(file_pattern=...)` | 目标文件存在 + CALLS 边 | 改现有文件时 |
| 3 | `trace_path(from, to, max_hops=2)` | 影响范围 | 改 public API / 跨模块 |
| 4 | `search_code` + `semantic_query` | 找类似 pattern 复用 | 新增函数/类 |
| 5 | `search_graph(neighbors_of=...)` | 影响节点的测试覆盖 | always |

降级链：调用失败 → grep/glob + 标注 ⚠️（不静默）。

### 7.2 context-mode（v5.0 新增，关键）

| 工具 | 场景 | 替代的旧工具 |
|---|---|---|
| `ctx_execute_file` | 子 agent 读大文件（>500 行）| Read（爆 context）|
| `ctx_batch_execute` | 并行 git log + diff + 多文件读 | 多次 Bash 串行 |
| `ctx_search` | 查历史索引 / 跨 session 经验 | memory_search 补充 |
| `ctx_index` | 索引项目文档 / API spec | — |
| `ctx_fetch_and_index` | 抓 web 文档（结合 researcher）| WebFetch |

**收益**：主 context 节省 60-90% token（官方数据）。**v4.0 零集成，v5.0 必补**。

### 7.3 memory MCP（三层 tier + 语言知识全量存储）

**核心决策（v5.0）**：语言约束 / 踩坑 / 经验**全部存 memory MCP**，不落 references 文件。tier + tag 规范如下。

#### 三层 tier

| Tier | 路径 | 用途 | 例子 | 写入者 |
|---|---|---|---|---|
| 项目级 | project hash | 项目专属 gotcha | "这个 repo 用 gin 不用 echo" | orchestrator / 子 agent |
| 共享级 | shared | 跨项目通用 convention / trap / tooling | "Go error 必须显式返回" | orchestrator only（Phase 6 经验提炼）|
| 全局级 | global | 用户级偏好 | "用户偏好 dry-run 先行" | orchestrator only |

#### tag 规范（替代 v3.2 的 8 个语言 references）

| tag | tier | 来源（v3.2 对应文件） | 粒度 |
|---|---|---|---|
| `coding-{lang}-convention` | 共享级 | go-conventions.md / python-conventions.md | 每条 convention 一条 memory |
| `coding-{lang}-trap` | 共享级 | go-editing-traps.md / python-editing-rules.md | 每个陷阱一条 memory |
| `coding-{lang}-tooling` | 共享级 | go-gopls-strategy.md / python-tooling.md | 每个工具链经验一条 |
| `coding-{lang}-verification` | 共享级 | go-verification-loop.md / python-verification-loop.md | 每个 loop 阶段一条 |
| `coding-{lang}-gotcha` | 项目级 | （新，运行时积累）| 每个项目专属坑一条 |
| `coding-super-decay` | 共享级 | （新，Phase 5 积累）| 每次 S.U.P.E.R 衰减记录 |
| `coding-user-pref` | 全局级 | （新，用户反馈积累）| 每条用户偏好 |
| `coding-audit-finding` | 项目级 | （新，Phase 5 reviewer 产出）| 每个审查发现 |

**{lang} 取值**：`go` / `python` / `typescript` / `rust` / 其他（按 metadata.language 动态）

**子 agent 写入权限**：
- ✅ 子 agent 可写：项目级（gotcha / audit-finding）
- ❌ 子 agent 不可写：共享级 + 全局级（避免污染；由 orchestrator 在 Phase 6 统一提炼写入）

#### 检索策略（子 agent 启动时）

```yaml
# orchestrator spawn {lang}-coder 前，必做：
memory_search:
  query: "{任务关键词} {lang}"
  tags: ["coding-{lang}-convention", "coding-{lang}-trap", "coding-{lang}-tooling",
         "coding-{lang}-verification", "coding-{lang}-gotcha"]
  tier: [project, shared]  # 不查全局级（那是 orchestrator 用的）
  limit: 20
# 结果注入子 agent prompt 的 "语言上下文" 段
```

#### Phase 6 经验提炼（写回 memory）

每次 coder 跑完，orchestrator 判断是否发现新经验：
- 新坑（未在 memory 中）→ 写 `coding-{lang}-gotcha`（项目级）
- 通用坑（跨项目）→ 提议升级到共享级 `coding-{lang}-trap`（🔒 AskUserQuestion 确认）
- 用户反馈偏好 → 写 `coding-user-pref`（全局级）

### 7.3.1 Seed 策略（Q7 已决策：模型告知 + 用户确认）

**问题**：memory MCP 首次使用时是空的，子 agent 查不到任何 convention/trap。

**决策（Q7）**：不自动静默 seed，也不让用户自己想起来。**orchestrator 检测到空 → 告知用户 → 用户确认后才执行 seed**。

**触发流程**（在 Phase 4 spawn {lang}-coder 前）：

```
1. orchestrator 调 memory_search(tags=["coding-{lang}-convention"], tier=shared)
2. 若返回为空（首次使用）：
   → AskUserQuestion:
     "检测到 {lang} 经验库为空。
      我可以从 v3.2 的语言 references（约 N 条 convention/trap/tooling）seed 到 memory MCP。
      seed 后未来所有 {lang} 任务都会自动复用这些经验。
      
      [推荐] 是, seed
             否, 这次裸跑（不注入 convention）
             否, 永不询问（之后跳过此提示）"
3. 用户选 "是" → 跑 scripts/seed-memory.py --lang={lang}
4. 用户选 "否, 这次裸跑" → 标 ⚠️ + 继续 Phase 4（无 convention 注入）
5. 用户选 "否, 永不询问" → 写 memory_user-pref "no-seed-{lang}"，之后不再问
```

**Seed 脚本**：`scripts/seed-memory.py`（待写，步 3.5）
- 输入：`references/legacy/{lang}-*.md`（v3.2 文件备份到此）
- 解析：每个 `##` 或 `- **陷阱 N**` 切一条 memory
- 输出：批量调 `memory_store`，tier=shared，tag 按 §7.3 表
- 去重：seed 前先 `memory_search`，semantic 相似度 ≥0.85 跳过

**Seed 后**：v3.2 references 文件移到 `references/legacy/` 目录（保留历史，不进加载链）。

**关键约束**：
- ❌ 不自动 seed（用户可能想从零积累自己的经验）
- ❌ 不静默跳过（违反 R12 失败显性化）
- ✅ 必须给用户三个明确选项（是 / 这次否 / 永不询问）
- ✅ 用户选"永不询问"后写 memory 持久化此偏好（不每次问）

**降级**：memory MCP 不可用时，seed 脚本无法跑 → orchestrator 标 ⚠️ + 询问用户是否降级裸跑 + 继续。

### 7.4 github MCP（触发式）

**触发**：
- 任务提到 issue / PR 编号
- 修复 bug 需要看 issue 上下文
- 需要查上游 repo 写法（reference impl）

**工具**：`get_file_contents` / `search_code` / `issue_read` / `pull_request_read`

**调用者**：orchestrator（不暴露给编码子 agent，避免误改 remote）。

### 7.5 context7（触发式）

**触发**：
- 子 agent 写库代码（React/Gin/ORM/SDK）
- 用户提到具体 API

**orchestrator 不直调**，在子 agent prompt 里提示"若不确定 API，先调 context7"。

### 7.6 searxng / web_reader（触发式）

**触发**：
- 报错信息不明（查 Stack Overflow）
- unknown 框架调研（spawn `researcher` 子 agent，已具备全套工具）

---

## 八、子 agent 编排总览

### 8.1 复用清单（不新建，coding-rules R8）

| Agent | model | v5.0 用途 | 需扩展工具 |
|---|---|---|---|
| `explorer` | haiku | Phase 1 扫描（1 路并发）| + `mcp__codebase-memory-mcp__index_status` |
| `oracle` | opus | Phase 3 方案（3 路并发）+ drift ≥0.4 重新分解 | + `mcp__codebase-memory-mcp__trace_path` + `search_graph` |
| `reviewer` | sonnet | Phase 5 验证（3 路并发）| + `mcp__codebase-memory-mcp__search_graph` |
| `researcher` | sonnet | Phase 1 触发式调研（unknown 框架）| 已有完整工具（searxng + web_reader + github + context-mode）|
| `go-coder` | sonnet | Phase 4 执行 | + 5 个 codebase-memory-mcp + context-mode + context7 |
| `python-coder` | sonnet | Phase 4 执行 | 同 go-coder |

### 8.2 v4.0 错误决策（v5.0 纠正：不新建）

| v4.0 拟新建 | v5.0 决策 | 理由 |
|---|---|---|
| ❌ verification-subagent | ✅ 复用 `reviewer` | reviewer.md 已注册，model 已对齐 sonnet |
| ❌ architecture-analyzer | ✅ 复用 `explorer` | explorer schema 已覆盖 7 维扫描 |
| ❌ solution-designer | ✅ 复用 `oracle` | oracle opus 级战略推理已具备 |
| ❌ intent-catcher | ✅ orchestrator 内联 | haiku 级轻量任务，不值得 spawn |

### 8.3 子 agent prompt 模板规范

每个子 agent prompt 必须包含 5 段：
1. **角色 + 边界**（做什么 / 不做什么）
2. **输入字段**（明确 schema）
3. **输出 schema**（JSON / YAML / markdown 表格）
4. **失败处理**（降级链 + ⚠️ 标注要求）
5. **工具预算**（token 上限 / 调用次数上限）

模板见 `references/phase-{N}-*.md`。

---

## 九、Progressive Disclosure 加载规则

### 9.1 SKILL.md 主体永远加载

包含：trigger / anti-trigger / 7 phase 路由表 / 12 硬约束摘要 / references 索引。

主体 ≤200 行，保证 orchestrator 启动时 context 干净。

### 9.2 references 按需加载 + memory 查询

**references 加载**（流程性知识，静态）：

| 时机 | 加载 reference |
|---|---|
| Phase 0 触发 AskUserQuestion | `phase-0-intent-capture.md` |
| Phase 1 开始 | `phase-1-metadata-scan.md` + `phase-1-super-check.md` |
| Phase 3 复杂任务 | `phase-3-design-options.md` |
| Phase 4 spawn 子 agent | `phase-4-execution-protocol.md`（不含语言专属，语言知识在 memory）|
| Phase 5 开始 | `phase-5-verification.md` |
| Phase 6 持久化 | `phase-6-persistence.md` + `memory-tier-strategy.md` |
| MCP 调用 | 对应 `*-integration.md` |
| drift_score 计算 | `adaptive-control.md` |

**memory 查询**（经验性知识，动态）：

| 时机 | 查询 |
|---|---|
| Phase 1 元数据扫描后 | `memory_search(tags=["coding-{lang}-gotcha"], tier=project)` → 注入 explorer |
| Phase 4 spawn {lang}-coder 前 | `memory_search(tags=["coding-{lang}-*"], tier=[project, shared])` → 注入子 agent（§5.5 + §7.3）|
| Phase 5 reviewer 审查时 | `memory_search(tags=["coding-super-decay", "coding-audit-finding"])` → 历史经验参考 |
| Phase 6 经验提炼 | 比较"本次发现 vs memory 已有" → 决定是否写新条目 |
| drift ≥ 0.4 spawn oracle 前 | `memory_search(tags=["coding-{lang}-trap"])` → 历史类似坑 |

**关键差异**：references 是"如何执行"，memory 是"执行时知道什么"。前者静态 + 版本化，后者动态 + 持续累积。

### 9.3 子 agent context 隔离

子 agent 只加载该 phase 的 reference，**不加载全本**。

例：Phase 3 spawn oracle 时，prompt 里只嵌入 `phase-3-design-options.md` 的相关段 + 用户意图 + Phase 1 架构热图，不传 SKILL.md 主体。

### 9.4 加载失败处理

reference 文件不存在 → orchestrator 标 ⚠️ + 降级（用 SKILL.md 主体里的摘要）+ 继续。

---

## 十、Adaptive Control（保留 v4.0 §8，决策权改给 oracle）

### 10.1 drift_score 计算（不变）

每个 Phase 4 subtask 完成后，子 agent 返回遥测 JSON：

```json
{
  "estimated_files": 3, "actual_files": 7,
  "estimated_loc": 150, "actual_loc": 420,
  "unplanned_dependencies": ["github.com/new/lib"],
  "super_violations": [{"module": "internal/auth", "principle": "S", "before": "🟢", "after": "🟡"}],
  "test_failures_unexpected": 2
}
```

```
drift_score = 0.4 × file_overrun + 0.3 × loc_overrun + 0.2 × unplanned_deps + 0.1 × super_decay
```

### 10.2 决策表（v5.0 改：spawn oracle）

| drift_score | v4.0 动作 | v5.0 动作 |
|---|---|---|
| `< 0.2` | 继续 | 继续 |
| `0.2 - 0.4` | 加 warning | 加 warning |
| `0.4 - 0.6` | 暂停 + 重新分解 | **🌟 spawn oracle 重新分解**（opus 级推理，fresh context）|
| `> 0.6` | 回 Phase 0 对齐 | **🌟 spawn oracle 回 Phase 0 重新对齐意图** |

**为什么改**：重新分解是战略决策，opus 在 fresh context 下质量最高（§2.2 Anthropic 建议）。

---

## 十一、落地路径（4-6 周，6 步）

| 步 | 内容 | 工作量 | 验收 |
|---|---|---|---|
| **1** | 新建 v5.0 branch；重构 SKILL.md 主体（路由表形态）+ 拆 14 个 references | 3-5 天 | SKILL.md ≤200 行；`wc -l` 验证 |
| **2** | Phase 1/3/5 并发改造 + agent allowed-tools 扩展 | 1 周 | 3 oracle 并发出方案；3 reviewer 并发审查 |
| **3** | MCP 5 个全覆盖（codebase-memory + context-mode + memory + github + context7）| 1 周 | 各 MCP 有触发场景 + 降级链 |
| **3.5** | **语言知识迁移**：v3.2 references → memory MCP；写 `scripts/seed-memory.py`；扩 memory tier tag 规范 | 2-3 天 | seed 后 `memory_search(coding-go-*)` 返回 ≥20 条；legacy 文件归档 |
| **4** | Adaptive Control + drift ≥0.4 自动 spawn oracle | 3 天 | drift 触发 oracle 重新分解 |
| **5** | MASTER.md + memory 三层 tier 完整化 + Phase 6 经验提炼流程 | 3 天 | 跨 session `/clear` 后能续传；新坑能写回 memory |
| **6** | skill-evolver 评分 + 迭代 | 1 周 | v5.0 评分 > v3.2（含并发维度新 rubric）|

每步独立 git commit，可 revert。

**总工作量**：4-6 周（1 人全职）。

---

## 十二、验收标准（v5.0 完成后）

| 场景 | 通过标准 |
|---|---|
| SKILL.md 体量 | `wc -l SKILL.md` ≤ 200 |
| references 加载 | orchestrator 主 context 永远 < 50k token |
| Phase 3 复杂任务 | 3 oracle 并发出方案（单条消息 spawn）|
| Phase 5 验证 | 3 reviewer 并发（正确性/S.U.P.E.R/安全）|
| 模糊需求 | Phase 0 问清 + 验收 checklist |
| 大型重构 | Phase 3 出 2-3 方案 + S.U.P.E.R + trace_path |
| MCP 不可用 | 降级 + 显性化标注 ⚠️ |
| drift_score > 0.4 | 自动 spawn oracle 重新分解 |
| 长任务中断 | MASTER.md 续传 |
| 新代码破坏架构 | S.U.P.E.R 衰减触发 reviewer 深度审计 |
| 跨语言任务 | 多 {lang}-coder 并发 |
| context-mode 集成 | 子 agent 读 >500 行文件用 ctx_execute_file |
| 语言知识在 memory | spawn {lang}-coder 前查 `coding-{lang}-*` tags；首次跑提示 seed |
| memory 写入正确 | 项目级子 agent 可写；共享/全局级 orchestrator 确认后写 |
| memory 不冗余 | Phase 6 提炼前去重；semantic ≥0.85 视为重复 |

---

## 十三、风险与回退

### 13.1 风险（v5.0 特有）

| # | 风险 | 缓解 |
|---|---|---|
| 1 | SKILL.md 拆 references 后加载逻辑复杂 | §9 加载规则表 + 主体清单；orchestrator 启动时打印加载日志 |
| 2 | 并发 oracle token 成本 3x | 简单任务跳过 Phase 3；Phase 5 用 sonnet 不是 opus；§6.4 总预算 |
| 3 | 子 agent prompt 模板维护成本 | 模板进 references，版本化；改模板不改 SKILL.md |
| 4 | 5 个 MCP 同时用，context 互相干扰 | 每个 MCP 明确触发条件（§7）；不并发调多 MCP |
| 5 | adaptive control oracle 决策延迟 | 只在 drift ≥ 0.4 才 spawn |
| 6 | memory 三层 tier 写错位置 | §7.3 tag 规范；子 agent 不能写共享/全局级 |
| 7 | parallel exploration 失败降级 | §6.3 三级降级（保留/重试/串行）|
| 8 | references 依赖循环（phase-3 引用 phase-1 引用 phase-3）| 单向依赖图；写 reference 时强制 DAG |
| 9 | **memory MCP 不可用 / 未 seed**：子 agent 查不到任何 convention/trap | §7.3.1 seed 脚本；检测空结果时提示用户；失败标 ⚠️ 不静默 |
| 10 | **memory 污染**：子 agent 误写共享/全局级 | §7.3 子 agent 写入权限限制（只能项目级）；orchestrator gate |
| 11 | **memory 累积冗余**：同一 convention 重复写 N 条 | Phase 6 提炼前先 `memory_search` 去重；semantic 相似度 ≥0.85 视为重复 |

### 13.2 回退路径

- 步 1 失败 → 回 v3.2（删 v5.0 分支，SKILL.md 完整保留）
- 步 2 失败 → 步 1 + 串行（去掉 Phase 1/3/5 并发）
- 步 3 失败 → 步 2 + 只用 codebase-memory-mcp（其他 MCP 留触发但不集成）
- 步 4 失败 → 步 3 + adaptive 决策改回 orchestrator 内联
- 步 5 失败 → 步 4 + MASTER.md 改放 `~/.cache/coder/`
- 步 6 失败 → 步 5（skill-evolver 评分迭代可延后）

---

## 十四、决策记录（9 个 Open Questions 已全部拍板，2026-06-22）

| # | 问题 | 决策 | 备注 |
|---|---|---|---|
| Q1 | Phase 3 oracle 并发数量 | **动态 2-4 个**（按复杂度） | §5.4 决策表；默认 3，简单 2，超大改 4 |
| Q2 | Phase 5 第 3 路 reviewer 维度 | **正确性 + S.U.P.E.R + 安全** | 3 路并发 reviewer |
| Q3 | MASTER.md 位置 | **项目根 + gitignore** | spec_driven_develop 风格 |
| Q4 | `.coder-metadata.yaml` commit? | **gitignore** | 机器生成，团队 framework 可能异 |
| Q5 | 留 typescript/rust-coder 扩展位? | **是** | `agents/{lang}-coder.md` 命名约定 |
| Q6 | 并发实现方式 | **Claude Code 原生多 spawn** | 单条消息多 tool_use blocks |
| Q7 | v3.2 references 如何 seed 到 memory? | **模型告知 + 用户确认**（混合）| orchestrator 检测空 → AskUserQuestion → 用户选是/否/永不问 → 才执行 §7.3.1 |
| Q8 | 共享级 memory 谁写? | **orchestrator 提议 + 🔒 用户确认** | 项目级可自动写；共享/全局级必须确认 |
| Q9 | memory 失败回退 legacy? | **不回退,裸跑 + ⚠️** | 避免维护两份；符合 R12 |

**所有决策已合并到正文相应章节**（§5.4 / §5.6 / §7.3 / §7.3.1 / §11 / 路由表）。下一步进入步 1 实施。

---

## 十五、参考

### 调研产出（本仓库）
- `web-research/data/20260622-codebase-memory-mcp/`（DeusData MCP 深度调研）
- `web-research/data/20260622-headroom/`（Headroom 压缩对比）
- `web-research/data/20260622-agent-reach/`（Agent-Reach 互联网层）
- `web-research/data/20260618-claude-code-multi-agent-frameworks/`（多 agent 横评）

### 外部
- [Anthropic Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) — parallel exploration + subagent context 隔离 + 4 阶段
- [anthropics/skills](https://github.com/anthropics/skills) — progressive disclosure + SKILL.md 规范
- [SkillEvolver 论文 arXiv:2605.10500](https://arxiv.org/abs/2605.10500) — skill 结构合规 + Auditor 9 检查

### 内部
- `coder/SKILL.md` v3.2（当前生产版本）
- `coder/.deepen/20260618-v3.2/`（v3.1 → v3.2 演进）
- `coder/.deepen/20260622-v4.0/design.md`（v4.0 废弃版，作为 v5.0 对照）
- `agents/oracle.md` / `reviewer.md` / `explorer.md` / `researcher.md`（全复用）
- `~/.claude/CLAUDE.md` coding-rules R3 / R5.1 / R8 / R10 / R12
- `brainstorm/` skill（已实现 3 collider 并发模式，Phase 3 oracle 并发借鉴此设计）

---

## 附：实施检查清单（v5.0 步 1 启动用）

- [x] 用户 review 本设计文档（2026-06-22）
- [x] 决策 §14 九个 Open Questions（2026-06-22，全部已拍板）
- [ ] 创建 v5.0 branch：`git checkout -b coder-v5.0`
- [ ] 备份 v3.2 SKILL.md → `snapshots/SKILL-v3.2.md.bak`
- [ ] 备份 v3.2 语言 references → `references/legacy/`（待 seed）
- [ ] 重写 SKILL.md 主体（路由表形态，≤200 行）
- [ ] 拆 14 个 references（phase-*.md + mcp-*.md，不含语言专属）
- [ ] 更新 `agents/go-coder.md` + `agents/python-coder.md` allowed-tools
- [ ] 扩展 `agents/explorer.md` / `oracle.md` / `reviewer.md` allowed-tools
- [ ] 写并发 prompt 模板（Phase 1 / Phase 3 动态 2-4 / Phase 5）
- [ ] 写 `scripts/seed-memory.py`（步 3.5）
- [ ] 跑 skill-evolver 评分 v5.0 vs v3.2
- [ ] commit + merge
