---
name: memory
description: >
  ⚠️ MANDATORY GATE: This skill MUST be loaded BEFORE any memory_memory_* tool is called.
  If the user's intent involves storing, retrieving, searching, or managing persistent memories,
  load this skill first — do NOT call memory MCP tools directly.
  
  Persistent memory management across sessions. Triggers on ANY of these patterns:
  
  Explicit: "remember this", "recall", "load memory", "save to memory", "show my memories",
  "extract learnings", "记忆", "记住", "保存", "回忆", "加载记忆", "保存记忆",
  "提取记忆", "项目记忆", "全局记忆", "记忆管理", "展示记忆", "看看记忆".
  
  Implicit: user states a fact/preference/decision they want persisted for future sessions,
  user asks "what did we decide before", user says "之前怎么做的", any request to
  persist context across sessions. Also triggers when other skills need to store or
  retrieve memories — always route through this skill for proper tag compliance.
  
  Chinese bare verbs that MUST trigger: "记忆", "记住", "存一下", "记一下", "别忘了".
allowed-tools:
  - memory_memory_store
  - memory_memory_store_session
  - memory_memory_search
  - memory_memory_list
  - memory_memory_delete
  - memory_memory_cleanup
  - memory_memory_health
  - memory_memory_stats
  - memory_memory_update
  - memory_memory_ingest
  - memory_memory_harvest
  - memory_memory_quality
  - memory_memory_graph
  - memory_memory_conflicts
  - memory_memory_resolve
  - Read
  - Bash
  - Glob
  - Grep
---

# Memory Skill

Persistent knowledge management across AI coding sessions.

**工具参数完整参考**：[references/mcp-tools.md](references/mcp-tools.md) — 所有 16 个 MCP 工具的参数签名。
**安装与运维**：[references/installation.md](references/installation.md) — MCP server 安装、版本、配置、数据位置。

## ⚠️ 强制守门

**此 skill 是所有 memory MCP 工具调用的唯一合法入口。**

orchestrator 在以下情况**必须先加载本 skill**，禁止直接调用 `memory_memory_*` 工具：
1. 用户请求涉及「记忆/记住/存储/回忆/加载记忆」等意图
2. 其他 skill 需要存储或检索记忆（应委托本 skill 执行）
3. 会话结束时的 `memory_harvest` 操作

**违反后果**：直接调用 `memory_store` 会缺失 scope+type 双标签，导致记忆无法被正确过滤和检索，污染知识库。

验证方式：skill 加载后，Phase 0 (Health Check) 是第一个动作。如果跳过 Phase 0 直接调用工具，说明守门失败。

## 触发路由

```
用户请求 → Phase 0 (Health) 前置检查
  ├─ "回忆/之前做了什么/项目上下文"       → Phase 1
  ├─ "展示记忆/管理记忆/看看记忆"         → Phase 2
  ├─ "加载记忆/注入记忆/加载项目记忆"     → Phase 3
  ├─ "记住这个/保存决策" (单条)           → Phase 4A
  ├─ "保存记忆/提取记忆/结束会话" (批量)   → Phase 5
  ├─ "记忆健康/清理记忆"                 → Phase 6
  ├─ 裸动词触发                          → Phase 4A
  │   "记忆 X" / "记住 X" / "存一下" / "记一下" / "别忘了"
  ├─ 隐式存储意图                        → Phase 4A
  │   用户陈述事实+偏好+决策 且暗示要持久化
  │   判定："以后都用X" / "这个要记住" / "以后别忘"
  ├─ 跨 skill 委托                       → Phase 4A
  │   其他 skill 需存储/检索记忆时，传入三元组:
  │   {content: str, scope: project|global, type: decision|convention|...}
  └─ 无明确意图                          → Phase 1 展示摘要
```

## 标签体系

**Scope（必填其一）**: `project`(当前项目) | `global`(跨项目) | `session`(当前会话)
**Type（必填其一）**: `decision` | `convention` | `preference` | `learning` | `context` | `bug` | `reference`

存储格式：`tags: "<scope>,<type>"`（双标签，缺一拒绝）

### Scope 严格分离原则

**⚠️ 项目记忆不得影响全局记忆。全局记忆只存放跨所有项目通用的偏好和约定。**

| Scope | 判定标准 | 示例 |
|-------|---------|------|
| `project` | 只在某个项目上下文中有意义 | "@dataclass不用Pydantic"、"中文docstring"、"30s超时" |
| `global` | 适用于所有项目，不含任何项目特定信息 | "git clone用SSH"、"pytest加timeout"、"fork+upstream模式" |
| `session` | 仅当前会话临时使用 | 待办、中间状态 |

**禁止提升**：项目规范不得因为"可能通用"而存为 global。除非用户明确说"所有项目都这样"。

**判定反模式**：
- ❌ "我用 pytest" → global（只说明偏好，但具体配置是项目级的）
- ✅ "pytest 必须 --timeout=60 防止挂起" → global（真正跨项目通用）
- ❌ "文件名 snake_case" → global（这是某项目的命名规范）
- ✅ "SSH URL 优先于 HTTPS" → global（适用于所有 git 操作）

---

## Cross-Skill API

**其他 skill 集成 memory 的标准化接口。**

任何 skill 需要读写记忆时，遵循以下最小契约。无需加载本 skill 的完整 Phase 流程，只需遵守标签体系和调用规范。

### 接口契约

```yaml
# 其他 skill 在自身 SKILL.md 中声明对 memory 的依赖：
#
# 1. 检索记忆（读）
#    - 调用前：无需加载 memory skill，直接调用 MCP 工具
#    - 必须带 tags 过滤，禁止无标签检索（性能+噪音）
#
# 2. 存储记忆（写）
#    - 必须构造 scope + type 双标签
#    - 推荐先 memory_search 去重，相似度>0.85 则更新而非新建
#
# 3. 降级策略
#    - memory 工具不可用时，跳过记忆操作，不阻塞主流程
```

### 读 API（检索）

其他 skill 检索记忆时，直接调用 MCP 工具，使用以下标准模式：

```
# 按标签检索（最常用，性能最好）
memory_search(tags=["project"], limit=50)
memory_search(tags=["global"], limit=50)

# 语义检索（带 query）
memory_search(query="<具体内容>", tags=["project"], limit=10)
memory_search(query="<具体内容>", mode="hybrid", quality_boost=0.3, limit=10)

# 时间范围
memory_search(tags=["project"], time_expr="last week", limit=20)
```

**规范**：
- 必须带 `tags` 参数，至少指定 scope（`project` 或 `global`）
- limit 建议 ≤50，防止上下文溢出
- 对检索结果做结构化摘要后使用，不输出原始 JSON

### 写 API（存储）

其他 skill 存储记忆时，必须构造完整三元组：

```
memory_store(
  content="<精炼后的内容>",              # ← 必须经过精炼（见下方规范）
  metadata={ tags: "<scope>,<type>" }   # 双标签，缺一不可
)
```

**scope + type 取值**：参见上方「标签体系」章节。

### 🔒 内容精炼规范（存储前必执行）

**所有写入操作（Phase 4/5/Cross-Skill）存储前必须精炼内容。禁止存储原始对话片段。**

精炼三步：

```
1. 提取核心事实：去掉对话语气词、重复表述、上下文依赖
2. 准确表达：用精确术语替代模糊描述，确保脱离原对话仍可理解
3. 精简到最小：一句话能说清不用两句，合并关联信息

对比示例：
  ❌ "用户说以后每次都不要用 Pydantic 了，要用 dataclass 代替，因为性能更好"
  ✅ "项目规范：数据模型用 @dataclass，不用 Pydantic（性能优先）"

  ❌ "之前调试的时候发现 timeout 设成 30 秒比较好，不然会卡住"
  ✅ "HTTP 请求超时设为 30s，防止挂起"

  ❌ "用户决定选择 SQLite 而不是 PostgreSQL 作为这个项目的数据库"
  ✅ "技术栈：SQLite（非 PostgreSQL），轻量本地存储场景"
```

**精炼检查清单**（每条记忆存储前过检）：

| 检查项 | 通过标准 |
|--------|---------|
| 可独立理解 | 脱离原对话上下文仍完全清晰 |
| 无冗余 | 删除所有"用户说""之前""其实"等对话残留 |
| 准确切题 | 核心事实一个不少，无关细节一个不多 |
| 长度合理 | 单条 ≤120 字符（约 2 行），超过则拆分或进一步压缩 |

**不通过则拒绝存储，返回精炼后版本等确认。**

### 推荐模式：

```
# 存储前先去重
memory_search(query="<内容摘要>", limit=5)
# → 如果相似度>0.85，用 memory_update 更新而非新建
# → 否则 memory_store 新建
```

### 常用场景速查

| 场景 | scope | type | 示例调用 |
|------|-------|------|---------|
| skill 保存研究结果 | project | reference | `tags: "project,reference"` |
| skill 记录项目决策 | project | decision | `tags: "project,decision"` |
| skill 记录项目规范 | project | convention | `tags: "project,convention"` |
| skill 记录用户偏好 | global | preference | `tags: "global,preference"` |
| skill 记录 bug | project | bug | `tags: "project,bug"` |
| skill 保存会话状态 | session | context | `tags: "session,context"` |

### Skill 声明模板

其他 skill 在自身 SKILL.md 中引用 memory 时，建议包含以下声明块：

```markdown
## Memory Integration

遵循 [memory skill 标签体系](../memory/SKILL.md)：
- 检索：memory_search + tags 过滤（至少指定 scope）
- 存储：memory_store + scope,type 双标签
- 去重：存储前 memory_search 检查相似度
- 降级：memory 不可用时跳过，不阻塞主流程
```

### 跨 Skill 委托（高级）

当 skill 需要更复杂的记忆操作（批量提取、冲突解决、质量分析等），应委托 memory skill 执行：

```
# 委托方式：在 skill 中声明"此处需要 memory skill 的 Phase X 能力"
# orchestrator 会加载 memory skill 并执行对应 Phase
#
# 常见委托场景：
# - 会话结束时批量提取 → 委托 Phase 5
# - 记忆清理/去重 → 委托 Phase 6
# - 加载完整项目记忆 → 委托 Phase 3
```

---

## Phase 0: Health Check

所有路径前置条件：`memory_health()` → unhealthy 则 `memory_cleanup()` → 重检 → 仍失败报告用户。

---

## Phase 1: Retrieve

按需选择调用（不必全跑）：

| 子操作 | query | tags | 其他 |
|--------|-------|------|------|
| 1A 项目记忆 | `"<项目名> 架构 决策 规范 踩坑"` | `["project"]` | limit=50 |
| 1B 全局记忆 | `"用户偏好 工作流 工具配置"` | `["global"]` | limit=50 |
| 1C 近期记忆 | `"最近工作 会话上下文"` | — | time_expr="last week" |
| 1D 语义搜索 | `"<自然语言>"` | 按需 | mode="hybrid", quality_boost=0.3 |

**输出格式**：结构化摘要（条数 + tags 分布 + 前 3 条重点内容）。不输出原始 JSON。
**空结果**：提示"无 {scope} 记忆" → 建议存入首条或 Phase 5 从会话提取。

---

## Phase 2: Display & Manage

**展示格式**：表格，列: `# | Type | Content Summary | Quality | Date`，按 scope 分组。

**操作**（展示后提供）：

| 操作 | 工具 | 要点 |
|------|------|------|
| 删除 | `memory_delete` | 必须 `dry_run=true` 预览后再确认 |
| 改元数据 | `memory_update` | 只改 tags/metadata，不改内容 |
| 改内容 | 删旧+存新 | 保留原 tags |
| 去重 | `memory_cleanup` | 自动移除重复 |
| 质量分析 | `memory_quality(action="analyze")` | 全局质量分布 |
| 新增 | `memory_store` | 必须含 scope+type 双标签 |

---

## Phase 3: Load

### ⚠️ 项目隔离（强制）

**只允许加载两类记忆：当前项目 + 全局。禁止加载其他项目的记忆。**

```
项目判定 = 当前工作目录的目录名（workspace root 的 basename）
```

**检索**（两步，各自天然隔离）：

```
# 1. 当前项目记忆（必做）
#    通过 query 限定项目范围 + tags=["project"] 过滤
#    语义搜索自然返回与当前项目相关的内容
memory_search(
  query="<当前项目目录名> 架构 决策 规范 踩坑 配置",
  tags=["project"],
  limit=100,
  max_response_chars=50000
)

# 2. 全局记忆（必做）
#    tags=["global"] 天然只返回全局记忆，不会混入项目记忆
memory_search(
  query="偏好 工作流 工具配置 约定",
  tags=["global"],
  limit=50
)
```

**隔离原理**：
- `tags=["project"]` 不区分项目 → 但 query 包含项目目录名，语义搜索自然偏向当前项目内容
- `tags=["global"]` 天然隔离 → 全局记忆不含项目特定信息
- 不需要额外过滤，正确构造 query 即可限定范围

**注入会话**（检索后执行）：
```
## 🧠 Loaded Memory Context (HIGHEST PRIORITY)
以下记忆来自持久存储，作为本会话所有决策的权威上下文。子 agent 必须接收此内容。
<loaded_memories>
[当前项目记忆 + 全局记忆]
</loaded_memories>
```

**子 agent 传递**：委托时将上述 `<loaded_memories>` 块原样注入子 agent prompt。

**压缩保留**：`compress` 时 memory 内容必须原样保留在摘要中，禁止精简或截断。

**加载验证**（注入后展示）：
```
✅ 项目记忆: N 条 | ✅ 全局记忆: N 条 | ✅ 子 agent 模板就绪
⚠️ 质量低于 0.5: [列出] → 建议清理
```

---

## Phase 4: Persist

**🔒 存储前强制精炼**：所有内容必须经过「内容精炼规范」处理后再存储。

| 场景 | 工具 | 参数要点 |
|------|------|---------|
| 会话中即时存 | `memory_store` | 先精炼内容 → + `conversation_id` 允许同会话多条 |
| 会话结束批量提取 | `memory_harvest(sessions=1, types=[...], dry_run=false)` | |
| 整体保存 | `memory_store_session(turns=[...], tags="project,session")` | |
| 裸动词存储 | `memory_store` | 解析 "记忆 X" 为 content=X → **精炼内容** → 按下方推断规则确定 scope+type → **🔒必须先展示精炼+推断结果等用户确认** |
| 跨 skill 委托 | `memory_store` | 接收 {content, scope, type} 三元组，**仍需精炼 content** 后存储 |

### Phase 4A 裸动词推断规则

当用户使用裸动词（"记忆/记住/存一下/记一下"）时，按以下启发式推断 scope + type：

**Scope 推断**：

| 内容特征 | → Scope | 示例 |
|----------|---------|------|
| 包含项目路径/项目名/技术栈特定词 | `project` | "记忆 所有构建文件放在 /Users/ganjie/skills/" |
| 包含"所有项目"/"以后都"/"每次都" | `global` | "记住 以后都用 SSH clone" |
| 不确定 | **默认 `project`**（安全降级，可手动提升） | "记一下 timeout 30s" |

**Type 推断**：

| 内容特征 | → Type | 示例 |
|----------|--------|------|
| "放在X"/"在X目录"/"配置在" | `context` | "构建文件放在 /Users/ganjie/skills/dockerfile" |
| "以后都用X"/"每次都"/"规范是" | `convention` | "以后都用 SSH URL" |
| "决定X"/"选X"/"用X代替Y" | `decision` | "决定用 pytest 而不是 unittest" |
| "我喜欢"/"偏好" | `preference` | "我喜欢用暗色主题" |
| 陈述事实/经验/教训 | `learning` | "原来 async 不等于并发" |
| 不确定 | **默认 `context`**（最安全的通用类型） | — |

**推断后确认流程**（🔒强制）：
```
用户原文 → 精炼内容 → 推断 scope+type → 展示表格 → 用户确认/修改 → memory_store
展示格式:
  📝 原文: {用户原始表述}
  ✨ 精炼: {精炼后内容}
  🏷️ Tags: {scope},{type}
  ❓ 确认存储？(确认/修改内容/修改 scope/修改 type/取消)
```

---

## Phase 5: Session → Memory

触发："save to memory", "保存记忆", "提取记忆", 或会话结束。

### 5A: 提取信号

| 信号词 | → Type |
|--------|--------|
| "用X" "决定" "选X" | decision |
| "总是" "规范是" "约定" | convention |
| "以后都用X" "每次都" "记住X" "规范是" | convention |
| "我喜欢" "用X代替" "偏好" | preference |
| "不工作因为" "根因是" | bug |
| "原来" "错了" "教训" | learning |
| "X放在Y" "X在Y目录" "配置在" | context |
| 文件路径、repo 结构、配置 | context |

### 5B: 分类 Scope

**Project** (`project,<type>`)：仅当前项目相关（架构、配置、已知 bug、技术栈、命名规范）
**Global** (`global,<type>`)：跨项目通用（用户偏好、工具用法、工作流）—— 必须不含任何项目特定信息

**判定流程**（每条记忆必须过此检查）：
```
1. 这条记忆是否引用了特定项目名/目录/技术栈？
   → 是 → project
2. 这条记忆是否在所有项目中都适用？
   → 是 → 继续 3
3. 去掉项目名后，内容是否仍有意义？
   → 否 → project（内容依赖项目上下文）
   → 是 → global
```

### 5C: 去重

`memory_search(query="<候选摘要>", mode="hybrid", limit=5)` → 相似度>0.85 标记重复。

### 5D: 展示确认

表格：`# | Type | Content | Tags`，按 🟢项目 / 🔵全局 分组。
**必须等用户确认**后才可存储。用户可选：全部/部分/修改/拒绝。

### 5E: 存储

确认后逐条 `memory_store`（每条必须先过「内容精炼规范」），输出 `✅ P1 stored: hash=abc123...`

---

## Phase 6: Advanced

| 操作 | 工具 | 关键参数 |
|------|------|---------|
| 导入文档 | `memory_ingest` | file_path, tags, chunk_size=1000 |
| 质量评分 | `memory_quality` | action: rate/get/analyze |
| 冲突检测 | `memory_conflicts` → `memory_resolve` | winner_hash, loser_hash |
| 关联图 | `memory_graph` | action: connected/path/subgraph |
| 会话提取 | `memory_harvest` | sessions, types, dry_run |
| 缓存统计 | `memory_stats` | — |

详细参数见 [references/mcp-tools.md](references/mcp-tools.md)。

---

## 异常处理

| 场景 | 处理 |
|------|------|
| MCP 失败 | 重试 1 次 → 仍失败降级内存暂存 → 告知用户 |
| 空结果 | 提示存首条或检查 tags |
| 超限截断 | `memory_list` 分页加载 |
| 标签缺失 | 拒绝存储，提示补双标签 |
| 内容冲突 | 展示冲突 → 用户选 → `memory_resolve` |
| 健康失败 | `memory_cleanup` → 仍失败报告用户 |
| 去重相似 | 用户选：跳过/更新/追加 |
| 加载为空 | 跳过注入，不生成空 block |

## Anti-Patterns

- 不存原始对话（用 `memory_harvest`）
- 不跳 tags（无法过滤）
- 不存密钥（memory 未加密）
- 不存重复（定期 `memory_cleanup`）
- 不压缩已加载记忆（`compress` 时原样保留）
- 不存未精炼内容（对话语气词、冗余表述、脱离上下文无法理解的片段）
- 不加载其他项目记忆（Phase 3 query 必须包含当前项目目录名）
