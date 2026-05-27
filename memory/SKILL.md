---
name: memory
description: >
  Persistent memory across sessions. Triggers: "remember", "recall", "memory",
  "记忆", "记住", "存一下", "记一下", "别忘了", "回忆", "加载记忆", "保存",
  "之前怎么做的", or when other skills need to store/retrieve memories.
  MUST load before any memory_memory_* tool call.
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

Persistent knowledge management across sessions.
**工具参数**: [references/mcp-tools.md](references/mcp-tools.md)

## 动作路由

| 用户意图 | 动作 | 步骤 |
|----------|------|------|
| 回忆/之前/项目上下文 | LOAD | health→search→summarize |
| 展示/管理/看看记忆 | MANAGE | list→table→operate |
| 记住/保存/存一下/记一下 | SAVE | refine→tag→dedup→confirm→store |
| 加载记忆/注入记忆 | LOAD | full load→compress→inject |
| 清理/健康/进化 | MANAGE | cleanup→expire→quality |
| 裸动词 "记忆 X" | SAVE | parse→refine→tag→confirm→store |
| 隐式（陈述事实/偏好） | SAVE | detect→refine→tag→confirm→store |
| 无明确意图 | LOAD | show summary |
| 跨 skill 委托 | SAVE | accept {content,scope,type}→refine→store |

---

## LOAD

**前置**: `memory_health()` → unhealthy 则 `memory_cleanup()` → 仍失败报告用户。

**三级检索**（项目名 = workspace root basename）:

```
memory_search(query="<项目名> 架构 决策 规范", tags=["project:<项目名>"], limit=30)
memory_search(query="技术方案 模式 最佳实践", tags=["shared"], limit=20)
memory_search(query="偏好 工作流 配置", tags=["global"], limit=10)
```

**输出格式**（硬上限 2000 字符，每条 ≤80 字符摘要）:

```
✅ 项目: N条 | 共享: N条 | 全局: N条
📌 重点记忆:
  1. [decision] 选了 SQLite 而非 PostgreSQL
  2. [convention] 数据模型用 @dataclass
⚠️ 过期/低质(<0.5): N条 → 建议清理
```

**注入会话**: 包裹为 `<loaded_memories>` block。子 agent 委托时原样传递。compress 时原样保留。

---

## SAVE

### 标签（存储必填，缺一拒绝）

| Scope | 含义 | Type | 含义 |
|-------|------|------|------|
| `project` | 项目专属（自动追加 `project:<名>`） | `decision` | 技术选型 |
| `shared` | 跨项目通用技术知识 | `convention` | 编码规范 |
| `global` | 用户偏好/工具配置 | `preference` | 用户偏好 |
| `session` | 临时会话状态 | `learning` | 经验教训 |
| | | `context` | 事实信息 |
| | | `bug` | 已知问题 |
| | | `reference` | 文档参考 |
| | | `pattern` | 可复用模式 |

存储格式: `tags=["<scope>", "<type>"]`

### 精炼（存储前强制）

1. 提取核心事实 — 去掉对话语气词、重复、上下文依赖
2. 精确表达 — 脱离原对话仍可理解
3. 压缩到 ≤120 字符

```
❌ "用户说以后每次都不要用 Pydantic 了，要用 dataclass"
✅ "项目规范：数据模型用 @dataclass（性能优先）"
```

不通过则拒绝存储，返回精炼后版本等确认。

### 存储流程（5 步强制检查链）

```
1. 精炼内容（上一步）
2. 推断 scope+type:
   scope: 含项目路径→project | 通用技术→shared | "以后都用"→global | 不确定→project
   type: "决定/选X"→decision | "规范是"→convention | "喜欢"→preference | 经验→learning | 不确定→context
3. 去重: memory_search(query="<精炼内容>", mode="hybrid", limit=5)
   → 相似度>0.85: memory_update 更新
   → 否则: 继续
4. 展示确认:
   📝 精炼: {内容}
   🏷️ Tags: {scope},{type}
   ❓ 确认存储？(确认/修改/取消)
5. 用户确认后 memory_store(tags=["<scope>", "<type>"])
   scope=project 时自动追加 "project:<项目名>"
```

### 过期规则（MANAGE 时强制执行）

| 条件 | 操作 |
|------|------|
| session 类型 >24h | 自动归档 |
| >30 天未访问 | 自动归档为 archived |
| archived >90 天 | 自动删除 |
| quality <0.5 | 标记建议清理 |

### 批量提取

触发："保存记忆", "提取记忆", 会话结束。
工具: `memory_harvest(sessions=1, types=[...], dry_run=false)` — 逐条过精炼+标签检查。

---

## MANAGE

**展示**: 表格 `# | Type | Content(≤80字) | Quality | Age`，按 scope 分组。

| 操作 | 工具 | 要点 |
|------|------|------|
| 删除 | `memory_delete` | `dry_run=true` 预览后确认 |
| 改标签 | `memory_update` | 只改 tags/metadata |
| 改内容 | 删旧+存新 | 保留原 tags |
| 去重 | `memory_cleanup` | 自动移除重复 |
| 质量分析 | `memory_quality(action="analyze")` | 全局分布 |
| 压缩合并 | search→merge→delete | 同主题≥3条则合并 |
| 文档导入 | `memory_ingest` | file_path + tags |
| 冲突解决 | `memory_conflicts` → `memory_resolve` | 展示→用户选→resolve |

**定期维护**（每次 MANAGE 执行）:
```
1. memory_cleanup()                    → 去重
2. memory_conflicts()                  → 冲突检测
3. memory_quality(action="analyze")    → 质量分布
4. 过期清理（见过期规则）               → 自动归档+删除
5. quality<0.5 → 压缩或清理
6. 输出维护报告:
   🔧 去重: N条 | 过期: 归档N条, 删除N条 | 质量: N条<0.5
```

---

## Cross-Skill API

其他 skill 读写记忆的稳定接口。

**读**: `memory_search(query="<主题>", tags=["<别名>"], limit=50)` — 必须带 tags。
**写**: `memory_store(content="<精炼内容>", metadata={tags:"<别名>,<type>"})` — 双标签。
**去重**: 存前 `memory_search` 检查相似度>0.85 → 更新而非新建。
**降级**: memory 不可用 → 跳过，不阻塞主流程。

---

## 异常处理

| 场景 | 处理 |
|------|------|
| MCP 失败 | 重试1次 → 降级跳过 → 告知用户 |
| 空结果 | "无{scope}记忆，建议先存" |
| 标签缺失 | 拒绝存储，提示补双标签 |
| 内容冲突 | 展示冲突 → 用户选 → `memory_resolve` |
| 健康失败 | `memory_cleanup` → 仍失败报告用户 |
| 加载为空 | 跳过注入，不生成空 block |
| 去重相似 | 用户选：跳过/更新/追加 |

## Anti-Patterns

- 不存原始对话 — 精炼后再存
- 不跳 tags — 无法过滤检索
- 不存密钥 — memory 未加密
- 不存重复 — 定期 `memory_cleanup`
- 不混用 scope — 项目记忆不用 shared/global
- 不 dump 原始 JSON — LOAD 必须摘要输出
