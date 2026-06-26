---
phase: 4
name: coder-execute
description: Phase 4 执行协议 — vertical tracer-bullet slice 分组（v6.2） + {lang}-coder spawn + memory 注入 + MCP 4 触达点 + drift 遥测 schema + v7.1 [3,5] 上限 + model 显式。
source: "design.md §5.5 + §6 + §10 + mattpocock-optimization.md 优化 2 + v7.1 §4 #14"
status: active
tokens_estimate: 1800
load_priority: on-demand
load_when: "进入 Phase 4"
keywords: vertical slice tracer-bullet lang-coder spawn HITL AFK memory injection MCP drift spawn limit model explicit
domain: coding
subdomain: phase
parent_skill: coder
version: "1.1"
license: Apache-2.0
frameworks:
  solid:
    - 单一职责（每个 module/class 只做一件事）
  twelve_factor:
    - I. Codebase - 一份 codebase 多部署
    - VII. Port Binding - 自包含服务
  notes: "vertical slice = 单一职责的 user behavior + v7.1 [3,5] 上限"
---

# Phase 4: 执行（vertical slice 分组，可多 slice 并发）

> **加载时机**：Phase 3 用户选定方案后（或简单任务直接从 Phase 2 进入）。
> **v6.2 升级**：task 分解从"按文件"改为"按 vertical tracer-bullet slice"（from mattpocock to-issues）。

## v6.2 核心变化：vertical slice 分组（反 horizontal）

### 旧方式（v6.0/v6.1，按文件 = horizontal）

```
❌ Task A: 改所有 schema 文件
   Task B: 改所有 API 文件
   Task C: 改所有 logic 文件
   Task D: 写所有 test
```

**问题**：每个 task 是单层切片，不能独立 demo。Task A 改完不知道对不对，要等 Task D 完才能验证。

### 新方式（v6.2，vertical slice = tracer bullet）

```
✅ Task 1 (slice "用户登录"): schema(users) + API(POST /login) + logic(LoginService) + tests
   Task 2 (slice "用户登出"): 配套 slice，独立 demoable
   Task 3 (slice "密码重置"): 配套 slice
```

**优势**：
- 每个 slice 完整 demoable（用户能验证"我能登录了"）
- test 响应 impl 实际行为（不预设）
- 失败范围小（一个 slice 失败不阻塞其他）

### slice 规则（from mattpocock to-issues + v7.1 硬约束）

- 每个 slice 是 **完整 user 行为**（不是技术切片）
- 贯穿所有层（schema + API + logic + tests）
- 独立 demoable / verifiable
- "Prefer many thin slices over few thick ones"
- **硬性 [3, 5] 个 slice 并发**（v7.1 §4 #14，旧版"上限 5"已收紧为"区间 3-5"）
  - < 3 slice → 切得太粗，应再拆（或走 §2.2 orchestrator 直编）
  - \> 5 slice → 切得太细，应合并相邻 slice，或分批 spawn（先 5，等 delivery 后再下一批 + ⚠️ 标注）

### spawn 模板（v7.1：每个 spawn 必显式 model）

```yaml
spawn:
  - subagent_type: go-coder-project   # 或 python-coder-project / 通用
    model: sonnet                     # ← v7.1 必填（执行性任务 sonnet）
    description: "slice 1: 用户登录"
    prompt: "${SLICE_PROMPT_1}"
  - subagent_type: go-coder-project
    model: sonnet
    description: "slice 2: 用户登出"
    prompt: "${SLICE_PROMPT_2}"
  - subagent_type: go-coder-project
    model: sonnet
    description: "slice 3: 密码重置"
    prompt: "${SLICE_PROMPT_3}"
# 总数 = 3 ✓（最低边界）
# orchestrator 等齐 → Phase 4.5
```

**Model 选择理由**：
- `{lang}-coder-project` = sonnet：编码执行是工程性推理，sonnet 性价比最高
- **禁止** spawn coder 时用 opus（opus 该留给 oracle，不浪费在执行）
- **禁止** spawn coder 时省略 `model:`（默认继承主 agent 会变成 opus → 浪费 + 慢）

### HITL vs AFK 标注（每个 slice 必填）

| 类型 | 含义 | 何时用 |
|---|---|---|
| **AFK**（Away From Keyboard） | 可独立完成 + merge，不需人决策 | 默认偏好 |
| **HITL**（Human In The Loop） | 需要人决策（架构 / 设计 review） | 必要时 |

**"Prefer AFK over HITL"**：能 AFK 的不要标 HITL。

## spawn 前必做（语言知识注入）

```yaml
memory_search:
  query: "{任务关键词} {lang}"
  tags: ["coding-{lang}-convention", "coding-{lang}-trap",
         "coding-{lang}-tooling", "coding-{lang}-verification",
         "coding-{lang}-gotcha"]
  tier: [project, shared]
  limit: 20
```

结果作为"语言上下文"段注入子 agent prompt。

**若结果为空**：触发 seed 流程（见 `memory-tier-strategy.md`）。
**绝不静默跳过**（R12）。

## MCP 4 触达点（执行时实时调）

| 触发 | MCP 工具 | 用途 |
|---|---|---|
| 改现有文件前 | `search_graph(file_pattern=...)` | 确认 CALLS 边 |
| 新增函数时 | `semantic_query` | 找类似 pattern 复用 |
| 改 public API | `trace_path` | 验证影响范围 |
| 改测试时 | `search_code` | 找相关 test cases |

## Adaptive Control 遥测（每 subtask 后返回）

```json
{
  "estimated_files": 3, "actual_files": 7,
  "estimated_loc": 150, "actual_loc": 420,
  "unplanned_dependencies": ["github.com/new/lib"],
  "super_violations": [{"module": "internal/auth", "principle": "S", "before": "🟢", "after": "🟡"}],
  "test_failures_unexpected": 2
}
```

drift_score 计算 + 决策见 `adaptive-control.md`。

## 跨语言并发

任务涉及多语言（Go 后端 + Python 脚本 + TS 前端）→ spawn 多个 `{lang}-coder` 并发。
每个独立查自己的 `coding-{lang}-*` memory tags。

## 子 agent prompt 模板（5 段规范）

1. **角色 + 边界**：做什么 / 不做什么
2. **输入字段**：明确 schema
3. **输出 schema**：JSON / diff / 文件列表
4. **失败处理**：降级链 + ⚠️ 标注
5. **工具预算**：token 上限 / 调用次数

## 编排模式（v3.2 继承，语言无关）

| 用户意图 | skill 链 |
|---|---|
| 重构 / 重组 | coder → (可选 simplify) |
| 新功能 | coder → tdd |
| 写测试 | coder + tdd |
| 修 bug | coder → diagnose |
| 审查代码 | coder → code-review |
| 审计代码 | coder 子 agent + code-audit-protocol |

## 跨模块一致性策略（v3.2 继承）

```
副作用（audit log / 通知 / 缓存）vs 主操作:
├── 必须强一致（金融/合规）→ 同事务 + DB audit + tx.Err()
├── 允许最终一致（行为日志/监控）→ 异步 sink + 幂等重试
└── 允许丢失（调试日志）→ stdout/file logger
```

## 子 agent allowed-tools 扩展（go-coder / python-coder）

新增：
- `mcp__codebase-memory-mcp__search_graph`
- `mcp__codebase-memory-mcp__search_code`
- `mcp__codebase-memory-mcp__trace_path`
- `mcp__codebase-memory-mcp__semantic_query`
- `mcp__codebase-memory-mcp__get_code_snippet`
- `mcp__context-mode__ctx_execute_file`
- `mcp__context-mode__ctx_batch_execute`
- `mcp__context7__query-docs`（写库代码时）

## TODO（待 step 2 扩充）

- [ ] go-coder / python-coder prompt 完整模板
- [ ] drift 遥测 schema 校验
- [ ] 跨语言并发的冲突处理

## 引用

- design.md §5.5 + §6.1 + §10
- `adaptive-control.md`（drift 决策）
- `memory-tier-strategy.md`（spawn 前 memory 注入）
- `codebase-memory-mcp.md` + `context-mode-integration.md` + `context7-integration.md`
