# Coder Skill v4.0 重设计方案

**日期**：2026-06-22
**作者**：Quin + Claude（基于 5 源调研）
**版本**：v3.2 → v4.0（增量 3 个小版本）
**状态**：design pending review

---

## TL;DR

v3.2 是**语言路由分发架构**（编排 + 综合），v4.0 升级为**全流程编码引擎**——加 3 层（需求捕获 / 架构分析 / 持久化）+ codebase-memory-mcp 5 触达点 + S.U.P.E.R 健康评估 + Adaptive Control。保留元+子 agent 分发核心不变。

---

## 一、背景

### 1.1 当前 v3.2 状态（2026-06-18 deepen 产出）

```
Phase 1: 语言检测（go/python，其他回退）
Phase 2: 复杂度评估（语言无关骨架）
Phase 3: 分发到垂直 agent（spawn sonnet）
Phase 4: 编排模式（tdd / diagnose / code-review 串联）
+ 审查门控（自审 + 深度审计）
+ 经验总结（memory store）
```

**核心资产**：
- orchestrator SKILL.md（语言无关骨架）
- 2 个垂直 agent（go-coder / python-coder）
- 11 个 references（conventions / editing / tooling / verification）
- 审查 + token 预算 + 硬约束 3 套机制

### 1.2 触发本次升级的 4 个外部发现

1. **Anthropic 官方 best practices 明确 4 阶段**（Explore → Plan → Code → Verify）—— v3.2 缺前 2 个
2. **spec_driven_develop（905 star）** 证明 6 阶段 + S.U.P.E.R + Adaptive Control 工程化可行
3. **codebase-memory-mcp 已全局安装**（v0.8.1，257MB 单二进制，14 MCP 工具）—— v3.2 零集成
4. **Anthropic 官方 `anthropics/skills` 不提供通用 coder**——v3.2 占据生态空白，有空间做深

---

## 二、调研发现（5 源对比）

### 2.1 Anthropic 官方哲学：**不做通用 coder skill**

`anthropics/skills` 16 个官方 skill 全是**垂直场景**（pdf / docx / pptx / xlsx / mcp-builder / frontend-design / skill-creator / claude-api 等），**无通用编程 skill**。官方主张：编程太依赖项目上下文，应该用 CLAUDE.md + 工具配置。

→ **我们的 coder 是社区创新**，有空间做差异化。

### 2.2 Anthropic Best Practices 四阶段

| 阶段 | 工具 | v3.2 对应 |
|---|---|---|
| Explore | plan mode 读文件 | ❌ 缺 |
| Plan | 详细实现计划 | ❌ 缺 |
| Code | 实施 | ✅ Phase 3-4 |
| Verify | 三层验证（prompt / `/goal`+Stop hook / verification subagent）| ⚠️ 只 checklist |

**官方关键观点**：context window 是最重要资源；subagent 做研究保持主 context 干净；对抗式审查（fresh context）。

### 2.3 spec_driven_develop（zhu1090093659，905 star）

**6 阶段流水线**：
```
Phase 0  Quick Intent Capture      → 1-2 句方向
Phase 1  Deep Analysis             → 架构 + 模块清单 + S.U.P.E.R 健康分
Phase 2  Intent Refinement         → AskUserQuestion 确认范围
Phase 3  Task Decomposition        → 分解 + GitHub Issues + Milestones
Phase 4  Progress Tracking         → MASTER.md 跨 session
Phase 5  Confirm & Execute         → adaptive control 反馈环
Phase 6  Archive                   → 工件保留
```

**S.U.P.E.R 设计原则**（每个模块 🟢🟡🔴 评分）：
- **S**ingle Purpose（单一职责）
- **U**nidirectional Flow（单向数据流，无环依赖）
- **P**orts over Implementation（接口先于实现）
- **E**nvironment-Agnostic（无硬编码）
- **R**eplaceable Parts（可替换性）

**Adaptive Control**（工程控制论）：
- 每 task 后采 drift_score（实际 vs 估算 + 未计划依赖 + S.U.P.E.R 违规）
- drift ≥20% 警告 / ≥40% 重新分解 / ≥60% 回 Phase 2

### 2.4 ai-maestro（23blocks-OS，718 star）

**三层智能**：Memory + **Code Graph**（ts-morph + CozoDB，delta indexing）+ auto-docs。

→ 我们的 codebase-memory-mcp 提供等价能力（HNSW + Cypher + Leiden 社区）。

### 2.5 codebase-memory-mcp（DeusData，10.5K star，v0.8.1）

**14 个 MCP 工具**（已全局安装到 `~/.claude.json`）：

| 类别 | 工具 | 用途 |
|---|---|---|
| 索引 | `index_repository` / `index_status` / `list_projects` / `delete_project` | 项目索引管理 |
| 搜索 | `search_code`（图增强）/ `search_graph` / `semantic_query`（向量）| 三模搜索 |
| 图谱 | `query_graph`（Cypher）/ `trace_path` | 图查询 + 影响分析 |
| 架构 | `get_architecture`（file_tree + Leiden）/ `get_graph_schema` | 模块边界 |
| 代码 | `get_code_snippet` | 片段提取 |
| 元数据 | `manage_adr` | ADR 管理 |

---

## 三、当前 v3.2 的 7 个 Gap

| # | Gap | 影响 | 证据 |
|---|---|---|---|
| 1 | **无 Phase 0 需求捕获** | 用户说"加 X 功能"时不问验收标准，做完才发现理解错 | Anthropic Explore + spec Phase 0 都有 |
| 2 | **无架构分析** | 不知道模块健康度，可能在烂架构上堆代码 | spec S.U.P.E.R 健康分 |
| 3 | **codebase-memory-mcp 零集成** | 14 工具未用，全靠 grep/glob 硬扫，token 浪费 | 已全局装但未用 |
| 4 | **元数据单维** | 只有 `language`，不知道 framework / test / lint / arch | 影响子 agent 加载正确 references |
| 5 | **无 adaptive control** | 计划错了死执行到底，小问题滚成大返工 | spec drift_score |
| 6 | **验证弱** | 只 checklist，无 fresh-context 对抗式审查 | Anthropic 强烈推荐 |
| 7 | **无跨 session 续传** | 长任务被打断后无法接续 | spec MASTER.md |

---

## 四、v4.0 目标架构

### 4.1 7 Phase 流水线（v3.2 的 4 Phase + 新增 3 Phase）

```
┌──────────────────────────────────────────────────────────────────┐
│ Phase 0: 需求捕获（新增，orchestrator 内联）                     │
│   AskUserQuestion ≤2 次 → 意图声明 + 验收 checklist              │
├──────────────────────────────────────────────────────────────────┤
│ Phase 1: 元数据 + 架构分析（新增，spawn explorer）               │
│   explorer(haiku) → 7 维扫描 + MCP get_architecture（机械工作） │
│   orchestrator → S.U.P.E.R 模块健康分（🟢🟡🔴，需 context）     │
│   产出：.coder-metadata.yaml + 架构热图                          │
├──────────────────────────────────────────────────────────────────┤
│ Phase 2: 语言路由（v3.2 保留，强化）                              │
│   按 language 路由到 {lang}-coder                                │
│   注入：metadata + S.U.P.E.R 热点 + index_status                 │
├──────────────────────────────────────────────────────────────────┤
│ Phase 3: 设计方案（新增，条件触发，spawn oracle）                │
│   简单任务（<3 文件 / 无 public API 改动）：跳过                  │
│   复杂任务：spawn oracle(opus) → 方案 + trace_path + 推荐        │
│   🔒 orchestrator AskUserQuestion 让用户选                       │
├──────────────────────────────────────────────────────────────────┤
│ Phase 4: 执行（v3.2 保留 + MCP 4 触达点）                        │
│   {lang}-coder(sonnet) 子 agent 执行                             │
│   实时调 search_graph / trace_path / search_code / semantic_query│
├──────────────────────────────────────────────────────────────────┤
│ Phase 5: 验证（v3.2 强化，复用 reviewer）                        │
│   自审（orchestrator）+ 深度审计（spawn reviewer fresh-context） │
│   + reviewer 跑 search_graph 回归（影响节点的测试覆盖）          │
├──────────────────────────────────────────────────────────────────┤
│ Phase 6: 持久化（v3.2 强化）                                     │
│   memory_store 经验（保留，三层 tier 详见 §4.8）                 │
│   + MASTER.md 跨 session 进度                                    │
│   + 触发 codebase-memory-mcp 增量索引（若装了）                  │
└──────────────────────────────────────────────────────────────────┘

**触发式调研层**（不在主流水线，按需 spawn）：
- `researcher`(sonnet) — 未知框架/库的快速调研（github + searxng + context-mode 自带）
- `context7` MCP — 子 agent 写 React/Gin/ORM 等库代码时查 API
```

### 4.2 Phase 0: 需求捕获（新增）

**触发**：用户任何"加/改/修/重构/修复"类请求进入 coder skill 时。

**流程**：
1. 复述用户请求（≤2 句）
2. 若以下任一**不明确**，AskUserQuestion（**总计 ≤2 次**）：
   - 验收标准（"做完后用什么检查？"）
   - 范围限定（"只改 X 还是 X+Y？"）
   - 边界排除（"不动 API/DB schema/公共接口 吗？"）
3. 输出 **意图声明**（1-2 句）+ **验收 checklist**（3-5 条）

**跳过条件**（直接进 Phase 1）：
- 用户请求已含明确验收（"按 X spec 实现，跑 Y 测试通过"）
- 单文件小改动（"改第 N 行的 typo"）

**Anti-pattern**：意图不清直接进 Phase 3（会产出泛泛代码，违反硬约束 #1 "意图不清必问"）。

### 4.3 Phase 1: 元数据 + 架构分析（新增，spawn explorer）

**分工**（符合 §2.2 Anthropic 建议：subagent 做研究保持主 context 干净）：

| 子任务 | 执行者 | 理由 |
|---|---|---|
| 7 维元数据扫描 + MCP `index_status` / `get_architecture` | **spawn `explorer`(haiku)** | 机械扫描，无推理，输出固定 schema |
| S.U.P.E.R 模块健康分（🟢🟡🔴 × 5） | **orchestrator** | 需要 Phase 0 意图 context 判断"单一职责"等主观维度 |

**explorer** 输出固定 schema（与 `agents/explorer.md` 约定一致）：
```yaml
metadata:
  language: go
  framework: {primary: gin, secondary: [gorm, logger]}
  test_runner: go test
  linter: golangci-lint
  arch_pattern: layered  # cmd/ internal/ pkg/
  build_tool: make
  codebase_indexed: true
  indexed_at: 2026-06-22T13:00:00Z
modules:
  - path: internal/auth
    loc: 245
    incoming: 2
    outgoing: 3
index_status:
  ready: true
  clusters_count: 8
```

**explorer 工具扩展**（allowed-tools 新增）：
- `mcp__codebase-memory-mcp__index_status`
- `mcp__codebase-memory-mcp__get_architecture`

**codebase-memory-mcp 探测**（若 `codebase_indexed=false`）：
```
search_graph(file_pattern="**/*.go")  # 看是否有索引
若空 → 提示用户："建议跑 codebase-memory-mcp cli index_repository，否则降级 grep"
不自动索引（大项目耗时 + 改用户环境）
```

**S.U.P.E.R 模块健康评估**（详见 §7）：
- orchestrator 基于 explorer 给的 `modules` 清单，对 Phase 0 涉及的模块逐个评分
- 识别"违规热点"（🔴 多的模块）
- 产出架构热图（markdown 表格）

**输出**：
- `.coder-metadata.yaml`（持久）
- 架构热图（进 orchestrator context，不持久）
- `index_ready: bool`（影响后续 MCP 调用）

**为什么不新建 architecture-analyzer**（符合 coding-rules R8 先读再写）：
`explorer` 已在 `skills/agents/` 注册，被 `programmer` 复用；其 schema（技术栈/文件清单/代码风格）天然覆盖 7 维扫描需求，只需扩展工具，不新建。

### 4.4 Phase 2: 语言路由（v3.2 保留 + 强化）

保留 v3.2 的 `agents/{lang}-coder.md` spawn 机制。

**强化点**：子 agent prompt 注入新增 3 字段：
```yaml
# 旧（v3.2）
- 用户原始请求 + 澄清答案
- 可用工具 + 调用参数
- 预算

# 新（v4.0）
+ metadata.yaml 内容
+ S.U.P.E.R 热点模块列表
+ codebase_indexed 状态 + 可用 MCP 工具清单
```

### 4.5 Phase 3: 设计方案（新增，条件触发，spawn oracle）

**简单任务判定**（全部满足才简单）：
- 改动 <3 文件
- 无 public API / 接口签名变更
- 无跨模块影响（search_graph 确认 CALLS 边只在本模块内）
- 无新依赖

→ 简单任务**跳过 Phase 3**，直接 Phase 4。

**复杂任务流程**（spawn `oracle`(opus)，fresh context 做战略推理）：

1. orchestrator 把 Phase 0/1 产出打包给 oracle：
   - 需求意图 + 验收 checklist
   - `.coder-metadata.yaml`
   - S.U.P.E.R 架构热图
   - Phase 0 涉及模块清单
2. oracle 调 `trace_path` 拉影响范围（谁调用、被谁调用，2 跳）
3. oracle 调 `search_graph` 查 CALLS 边确认跨模块影响
4. oracle 输出 **2-3 个候选方案**（每个含：实现思路 / 风险 / 工作量估算 / S.U.P.E.R 影响 / 是否改善 🔴 热点）
5. oracle 标注**推荐方案** + 理由（opus 级战略推理，不塞进 orchestrator context）
6. 🔒 **orchestrator 用 AskUserQuestion 让用户选**（决策权归用户）
7. 用户选定后写 `PLAN.md`（可选）

**oracle 工具扩展**（allowed-tools 新增）：
- `mcp__codebase-memory-mcp__trace_path`
- `mcp__codebase-memory-mcp__search_graph`

**为什么用 oracle 不用 orchestrator 内联**：
- §2.2 Anthropic 官方："subagent 做研究保持主 context 干净"
- 方案对比需要 opus 级深度推理（对照 coding-rules R5.1：战略性 → opus）
- oracle 已在 `skills/agents/` 注册，被 `programmer` / `darwin-skill` 复用
- 决策权仍在用户（§4.5 第 6 步）

### 4.6 Phase 4: 执行（v3.2 保留 + MCP 4 触达点）

子 agent 执行时**实时调 MCP**（详见 §6）：
- 改现有文件前：`search_graph(file_pattern=...)` 确认 CALLS 边
- 新增函数时：`semantic_query` 找类似 pattern 复用
- 改 public API 时：`trace_path` 验证影响范围
- 改测试时：`search_code` 找相关 test cases

**Adaptive Control 遥测**（详见 §8）：子 agent 每完成一个 subtask，返回：
```json
{
  "estimated_files": 3, "actual_files": 7,
  "estimated_loc": 150, "actual_loc": 420,
  "unplanned_dependencies": ["new_lib_X"],
  "super_violations": ["S🟡 module Y now does 2 things"],
  "drift_score": 0.45
}
```

orchestrator 按 drift_score 决策（见 §8 决策表）。

### 4.7 Phase 5: 验证（v3.2 强化，复用 reviewer）

**三层验证**（Anthropic best practices 风格，复用 reviewer）：

| 层 | v3.2 | v4.0 |
|---|---|---|
| 自审 checklist | orchestrator | 保留（orchestrator 内联）|
| 深度审计 protocol | orchestrator | **spawn `reviewer`(sonnet)** — fresh-context，只看 diff + 验收 checklist |
| search_graph 回归 | ❌ | **reviewer 跑**：新改动影响的所有 CALLS 节点，检查测试覆盖 |

**为什么复用 reviewer 不新建 verification-subagent**（符合 coding-rules R8）：
- `agents/reviewer.md` 已在 `skills/agents/` 注册，被 darwin-skill / code-review / fin-code-review 复用
- reviewer model = sonnet（与 §12 原 Open Question 4 推荐一致，该 question 已废弃）
- reviewer 已有 `Read/Glob/Grep/Bash/memory_search`，只需加一个 codebase-memory-mcp 工具

**reviewer 工具扩展**（allowed-tools 新增）：
- `mcp__codebase-memory-mcp__search_graph`

**reviewer prompt 模板**（fresh-context 对抗式审查）：
```
你是 fresh-context reviewer。只看以下 diff 和验收 checklist，
不看实现推理过程。报告：
1. 每条验收 checklist 是否满足（✅/❌ + 证据）
2. diff 范围外的意外改动
3. 缺失的 edge case 测试
4. search_graph 回归：diff 影响节点的测试覆盖情况
不要报告风格偏好。
```

### 4.8 Phase 6: 持久化（v3.2 强化）

| 动作 | v3.2 | v4.0 |
|---|---|---|
| memory_store 经验 | ✅ | 保留（coding-{lang}-gotcha / convention / toolchain / audit tags）|
| **MASTER.md 进度** | ❌ | **新增**：跨 session 续传（spec_driven_develop 风格）|
| **codebase-memory-mcp 增量索引** | ❌ | **新增**：若 `codebase_indexed=true`，触发 `index_repository` 增量更新 |

MASTER.md 格式：
```markdown
# Coder Progress — {project}

## Current Task
- [ ] task N: {description} — in_progress

## Completed
- [x] task N-1: {description} — 2026-06-22

## Blocked
- [ ] task X: blocked by {reason}

## Notes
- {key decisions}
```

---

## 五、元数据策略

### 5.1 7 维元数据

| 维度 | 类型 | 用途 |
|---|---|---|
| `language` | enum | 路由到 {lang}-coder |
| `framework.primary` | string | 加载框架专属 references |
| `framework.secondary` | list | 避免 anti-pattern（如同时用 gin 和 echo）|
| `test_runner` | enum | 决定 verification loop 命令 |
| `linter` | enum | 决定 lint 命令 + 规则集 |
| `arch_pattern` | enum | S.U.P.E.R 评分基线 |
| `build_tool` | enum | 决定 build 命令 |
| `codebase_indexed` | bool | 是否调 codebase-memory-mcp |
| `indexed_at` | ISO date | 索引新鲜度 |

### 5.2 扫描命令映射

| 维度 | Go | Python | TypeScript |
|---|---|---|---|
| framework | `grep -E "gin\|echo\|fiber" go.mod` | `pyproject.toml [tool.poetry.dependencies]` 或 `[project.dependencies]` | `package.json dependencies` |
| test_runner | `go test`（默认）| `pyproject.toml [tool.pytest]` | `vitest.config.* / jest.config.*` |
| linter | `.golangci.*` | `ruff.toml / pyproject [tool.ruff]` | `.eslintrc.* / biome.json` |
| arch_pattern | `ls internal/ cmd/ pkg/`（layered） / `ls cmd/ internal/ service/`（clean）| `ls src/{domain,app,infra}/`（ddd）/ `ls src/ tests/`（flat）| `ls src/features/`（feature-based）/ `src/components/`（component）|
| build_tool | `Makefile / justfile` | `uv.lock / poetry.lock` | `package.json scripts` |

### 5.3 缓存策略

- **存储**：项目根 `.coder-metadata.yaml`
- **失效**：以下任一触发重扫：
  - manifest 文件 mtime 变化（`go.mod / pyproject.toml / package.json`）
  - `.coder-metadata.yaml` 不存在
  - 用户手动 `coder refresh-metadata`
- **gitignore**：加 `.coder-metadata.yaml`（机器生成，不 commit）

### 5.4 降级策略

| 场景 | 降级 |
|---|---|
| manifest 文件不存在 | 跳过对应维度，标 `unknown` |
| 扫描失败 | 用 default（go-coder 默认 layered + golangci + go test）|
| metadata.yaml 损坏 | 重扫覆盖 |

---

## 六、codebase-memory-mcp 集成

### 6.1 5 触达点（按 Phase）

| Phase | MCP 工具 | 用途 | 触发条件 |
|---|---|---|---|
| **1 元数据** | `index_status` + `get_architecture(aspects=[file_tree])` | 项目骨架感知 + Leiden 社区 | `codebase_indexed=true` |
| **2 路由确认** | `search_graph(file_pattern="**/target.{ext}")` | 目标文件存在 + CALLS 边 | 改现有文件时 |
| **3 设计** | `trace_path(from=A, to=B, max_hops=2)` | 影响范围（谁调用 / 被谁调用）| 改 public API / 跨模块时 |
| **4 执行** | `search_code` + `semantic_query` | 找类似 pattern 复用，避免重造 | 新增函数/类时 |
| **5 验证** | `search_graph(neighbors_of=changed_nodes)` | 影响节点的测试覆盖检查 | always |

### 6.2 子 agent allowed-tools 更新

`agents/go-coder.md` 和 `agents/python-coder.md` 的 allowed-tools 新增：
```yaml
allowed-tools:
  # 现有
  - Read / Write / Edit / Bash / Glob / Grep
  # 新增（v4.0）
  - mcp__codebase-memory-mcp__search_graph
  - mcp__codebase-memory-mcp__search_code
  - mcp__codebase-memory-mcp__trace_path
  - mcp__codebase-memory-mcp__semantic_query
  - mcp__codebase-memory-mcp__get_code_snippet
```

**不暴露**（避免误用 / 高开销）：
- `index_repository`（orchestrator 提示用户手动跑）
- `delete_project`（破坏性）
- `query_graph`（Cypher 原生查询，子 agent 可能写错）

### 6.3 降级链（MCP 不可用时）

```
codebase-memory-mcp 调用失败
    ↓
检测是否 indexed（index_status）
    ↓ 未索引 / 超时
降级 grep + glob + Read
    ↓
在汇报里标注 "⚠️ MCP 降级，影响分析可能不全"
```

**绝不静默降级**（违反硬约束 #12 "失败必须显性化"）。

---

## 七、S.U.P.E.R 健康评估

### 7.1 5 原则（抄 spec_driven_develop）

| 原则 | 含义 | 检测信号 |
|---|---|---|
| **S**ingle Purpose | 一模块一职责 | 模块内函数语义聚类度；文件行数 > 500 警告 |
| **U**nidirectional Flow | 数据单向，无环 | `trace_path` 检测循环依赖 |
| **P**orts over Implementation | 接口先于实现 | abstract/interface 类型比例；公开 API 文档化率 |
| **E**nvironment-Agnostic | 无硬编码 | grep 硬编码 URL/path/key/secret |
| **R**eplaceable Parts | 可替换 | 模块入度/出度比；swap 成本估算 |

### 7.2 评分规则

每个相关模块在 Phase 1 评估，输出：
```
module: internal/auth
  S 🟢  (245 行，单一职责)
  U 🟡  (依赖 internal/user，但 user 反向引用 auth 的 1 个工具函数)
  P 🟢  (LoginPort interface 定义清晰)
  E 🔴  (hardcoded "localhost:5432" in dev fallback)
  R 🟢  (swap 成本低，2 个入度)
```

**汇总热图**：
```
🔴 热点：internal/auth (E🔴), internal/payment (S🔴 U🔴)
🟡 观察：internal/user (U🟡)
🟢 健康：其他 12 个模块
```

### 7.3 与审查门控整合

v3.2 审查门控只查"代码本身质量"。v4.0 加一条：
- **若新改动让某模块从 🟢 降到 🟡/🔴 → 强制深度审计**
- **若新改动未改善已存在的 🔴 热点 → 标注技术债**（不阻塞，但汇报）

---

## 八、Adaptive Control

### 8.1 drift_score 计算

每个 Phase 4 subtask 完成后，子 agent 返回遥测：

```json
{
  "estimated_files": 3,
  "actual_files": 7,
  "estimated_loc": 150,
  "actual_loc": 420,
  "unplanned_dependencies": ["github.com/new/lib"],
  "super_violations": [
    {"module": "internal/auth", "principle": "S", "before": "🟢", "after": "🟡"}
  ],
  "test_failures_unexpected": 2
}
```

orchestrator 计算：
```
drift_score = 0.4 × file_overrun + 0.3 × loc_overrun + 0.2 × unplanned_deps + 0.1 × super_decay

file_overrun = max(0, actual_files - estimated_files) / max(estimated_files, 1)
loc_overrun  = max(0, actual_loc - estimated_loc) / max(estimated_loc, 1)
unplanned_deps = len(unplanned_dependencies) / 5  (cap 1.0)
super_decay = count(🟢→🟡/🔴) / total_principles_checked
```

### 8.2 决策表

| drift_score | 动作 | 用户交互 |
|---|---|---|
| `< 0.2` | 继续 | 无 |
| `0.2 - 0.4` | 下个 subtask 加 warning annotation | 无 |
| `0.4 - 0.6` | 暂停执行，重新分解剩余 tasks | 🔒 展示新计划 + 确认 |
| `> 0.6` | 回 Phase 0/1 重新和用户对齐意图 | 🔒 强制澄清 |

### 8.3 约束

- drift_score 计算需要子 agent 配合（必须返回遥测 JSON）
- 子 agent 若不返回 → drift_score=0（乐观），但 orchestrator 标注 "⚠️ 无遥测"
- 用户可在汇报后手动 override drift 决策

---

## 九、落地路径（3 个增量版本）

### 9.1 v3.3（最小可用，2-3 天）

**目标**：装好 MCP + 加 Phase 0 + 元数据扫描。

**改动清单**：
1. `coder/SKILL.md` 加 Phase 0 段（AskUserQuestion ≤2 次 + 验收 checklist）
2. 新建 `coder/references/metadata-scan.md`（7 维扫描命令 + 降级）
3. 新建 `coder/references/codebase-memory-mcp-integration.md`（5 触达点）
4. `agents/go-coder.md` + `agents/python-coder.md` allowed-tools 加 5 个 MCP 工具
5. `metadata.version: "3.2" → "3.3"`

**验收**：
- 跑 "在 skills/coder 里加一个 typescript-coder 的 stub" → 应该 Phase 0 问清"装多少框架 / 是否带 react / 测试 runner"
- metadata.yaml 正确生成
- MCP 调用不静默失败

### 9.2 v3.4（架构 + 验证，1 周）

**目标**：S.U.P.E.R + Phase 3 设计方案 + verification subagent。

**改动清单**：
1. 新建 `coder/references/super-check.md`（5 原则 + 评分规则）
2. `SKILL.md` 加 Phase 3 段（条件触发 + trace_path + 🔒 确认）
3. 新建 `coder/references/verification-subagent.md`（fresh-context 模板）
4. `SKILL.md` Phase 5 加 verification subagent 触发条件
5. `metadata.version: "3.3" → "3.4"`

**验收**：
- 跑 "重构 internal/auth 模块" → 应该出 Phase 3 方案 + S.U.P.E.R 热点 + verification subagent 报告

### 9.3 v4.0（自适应 + 持久化，2 周）

**目标**：Adaptive Control + MASTER.md + 增量索引。

**改动清单**：
1. 新建 `coder/references/adaptive-control.md`（drift_score + 决策表）
2. `SKILL.md` Phase 4 加遥测字段约定
3. 新建 `coder/references/master-md.md`（跨 session 格式）
4. `SKILL.md` Phase 6 加 MASTER.md 更新 + MCP 增量索引触发
5. `metadata.version: "3.4" → "4.0"`

**验收**：
- 长任务被打断后 `/clear` + 新 session 能从 MASTER.md 续传
- drift_score > 0.4 时正确暂停 + 重新分解

---

## 十、验收标准（v4.0 完成后）

| 场景 | 通过标准 |
|---|---|
| 模糊需求（"加个登录"）| Phase 0 问清 OAuth/密码/2FA + 验收 |
| 大型重构（"拆 internal/monolith"）| Phase 3 出 2-3 方案 + S.U.P.E.R 评分 + trace_path |
| 单文件 typo | Phase 0/1/3 跳过，直达 Phase 4 |
| 计划跑偏（预估 3 文件实际 10）| drift_score > 0.4 暂停 + 重新分解 |
| MCP 不可用 | 降级 grep + 汇报标注 ⚠️ |
| 长任务中断 | MASTER.md 存在 + 下个 session 可续 |
| 新代码破坏现有架构 | S.U.P.E.R 衰减触发深度审计 |

---

## 十一、风险与回退

### 11.1 风险

| # | 风险 | 缓解 |
|---|---|---|
| 1 | Phase 0-3 让简单任务变慢 | 跳过条件明确（简单任务直达 Phase 4）|
| 2 | codebase-memory-mcp 大项目索引慢 | 不自动索引，提示用户手动 + 提供降级 |
| 3 | drift_score 子 agent 不配合 | 约定 JSON schema + 子 agent 违规视为 drift=0 + 标注 |
| 4 | S.U.P.E.R 主观 | 每个信号有具体检测命令（行数/依赖/grep），不是凭感觉 |
| 5 | MASTER.md 污染项目 | 加 .gitignore；或改放 `~/.cache/coder/{hash}.md`（v4.1 再决定）|
| 6 | 元数据扫描误判 | 降级到 unknown + 让子 agent 自适应 |

### 11.2 回退路径

若 v4.0 任何一 Phase 出问题：
- v3.3 失败 → 回 v3.2（删 Phase 0 + metadata）
- v3.4 失败 → 回 v3.3（删 S.U.P.E.R + verification subagent）
- v4.0 失败 → 回 v3.4（删 adaptive control + MASTER.md）

每个版本独立 git commit，回退 = `git revert`。

---

## 十二、Open Questions（待用户决策）

1. **`.coder-metadata.yaml` 是否 commit？**
   - A. commit（团队共享，但机器生成）
   - B. gitignore（每机器独立，但无团队一致性）
   - **推荐 B**（机器生成 + 团队成员可能 framework 不同）

2. **MASTER.md 放项目根还是 `~/.cache/coder/`？**
   - A. 项目根（可见性高，但污染）
   - B. cache（干净，但跨 session 要 lookup）
   - **推荐 A** + gitignore（spec_driven_develop 风格，可见性更重要）

3. **S.U.P.E.R 评分是 Phase 1 全量还是按需？**
   - A. Phase 1 全量评估所有模块（慢但全）
   - B. 只评估 Phase 0 涉及的模块（快但可能漏）
   - **推荐 B**（按需，避免 token 爆炸）

4. **verification subagent 用什么 model？**
   - A. sonnet（和执行 agent 同）
   - B. opus（更深度但贵）
   - **推荐 A**（fresh-context 已经够，opus 留给战略决策）

---

## 十三、参考

### 调研产出（本次）
- `web-research/data/20260622-codebase-memory-mcp/`（DeusData MCP 深度调研）
- `web-research/data/20260622-headroom/`（Headroom 压缩对比）
- `web-research/data/20260622-agent-reach/`（Agent-Reach 互联网层）

### 外部
- [Anthropic Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) — 4 阶段官方哲学
- [anthropics/skills](https://github.com/anthropics/skills) — 官方 skill 仓库（无通用 coder）
- [zhu1090093659/spec_driven_develop](https://github.com/zhu1090093659/spec_driven_develop)（905 star）— 6 Phase + S.U.P.E.R + Adaptive Control
- [23blocks-OS/ai-maestro](https://github.com/23blocks-OS/ai-maestro)（718 star）— Code Graph 集成范本
- [DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)（10.5K star）— 已全局安装

### 内部
- `coder/SKILL.md` v3.2（当前）
- `coder/.deepen/20260618-v3.2/snapshots/BEFORE-v3.1.md`（v3.1 → v3.2 演进）
- `web-research/data/20260618-claude-code-multi-agent-frameworks/`（多 agent 框架横评）

---

## 附：实施检查清单（v3.3 启动用）

- [ ] 用户 review 本设计文档
- [ ] 决策 §12 四个 Open Questions
- [ ] 创建 v3.3 branch：`git checkout -b coder-v3.3`
- [ ] 改 `SKILL.md` 加 Phase 0
- [ ] 写 `references/metadata-scan.md`
- [ ] 写 `references/codebase-memory-mcp-integration.md`
- [ ] 更新 `agents/go-coder.md` + `agents/python-coder.md` allowed-tools
- [ ] 跑 skill-evolver 评分 v3.3 vs v3.2
- [ ] commit + merge
