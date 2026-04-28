---
name: memory
description: >
  Persistent memory management across sessions. Use when user wants to recall past decisions,
  save learnings, review project context, load memories into active session, manage knowledge
  base, or extract session learnings into structured memories. Triggers: "remember this",
  "what did we decide", "recall", "load memory", "save to memory", "show my memories",
  "save session to memory", "extract learnings", "项目记忆", "全局记忆", "记忆管理",
  "加载记忆", "保存记忆", "提取记忆".
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

## 触发路由

```
用户请求 → Phase 0 (Health) 前置检查
  ├─ "回忆/之前做了什么/项目上下文"     → Phase 1
  ├─ "展示记忆/管理记忆/看看记忆"       → Phase 2
  ├─ "加载记忆/注入记忆/加载项目记忆"   → Phase 3
  ├─ "记住这个/保存决策" (单条)         → Phase 4A
  ├─ "保存记忆/提取记忆/结束会话" (批量) → Phase 5
  ├─ "记忆健康/清理记忆"               → Phase 6
  └─ 无明确意图                        → Phase 1 展示摘要
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

**检索**：
```
memory_search(query="<项目路径> 所有记忆", tags=["project"], limit=100, max_response_chars=50000)
memory_search(query="偏好 工作流", tags=["global"], limit=50)
```

**注入会话**（加载后必须执行）：
```
## 🧠 Loaded Memory Context (HIGHEST PRIORITY)
以下记忆来自持久存储，作为本会话所有决策的权威上下文。子 agent 必须接收此内容。
<loaded_memories>
[检索到的全部记忆]
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

| 场景 | 工具 | 参数要点 |
|------|------|---------|
| 会话中即时存 | `memory_store` | + `conversation_id` 允许同会话多条 |
| 会话结束批量提取 | `memory_harvest(sessions=1, types=[...], dry_run=false)` | |
| 整体保存 | `memory_store_session(turns=[...], tags="project,session")` | |

---

## Phase 5: Session → Memory

触发："save to memory", "保存记忆", "提取记忆", 或会话结束。

### 5A: 提取信号

| 信号词 | → Type |
|--------|--------|
| "用X" "决定" "选X" | decision |
| "总是" "规范是" "约定" | convention |
| "我喜欢" "用X代替" "偏好" | preference |
| "不工作因为" "根因是" | bug |
| "原来" "错了" "教训" | learning |
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

确认后逐条 `memory_store`，输出 `✅ P1 stored: hash=abc123...`

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
