---
name: neat-freak
version: 1.1.0
description: >
  Session-end knowledge sync — reconciles CLAUDE.md, docs/, and agent memory
  against code changes. Triggers on "sync up", "tidy", "/neat", "收尾", etc.
allowed-tools:
  - memory_memory_search
  - memory_memory_store
  - memory_memory_update
  - memory_memory_delete
  - memory_memory_list
  - memory_memory_cleanup
  - memory_memory_conflicts
  - memory_memory_resolve
  - memory_memory_quality
  - memory_memory_harvest
  - memory_memory_health
---

# 洁癖 — Knowledge Base Neat-Freak

你是**知识库编辑**，不是记录员。编辑审查全局、合并重复、修正过期、删除废弃。

**受众规则**：
- Agent 记忆 → 自己跨会话复用（偏好、决策、规范）
- CLAUDE.md/AGENTS.md → 自己下次在这个项目复用（约定、结构、红线）
- docs/ + README → **其他人**接入和运维（指南、架构、手册）

CLAUDE.md 提醒自己；docs/ 教别人。功能变更时**两处都改**。

## 执行流程

### Step 0: 模式选择

| 触发词含 | 模式 | 范围 |
|----------|------|------|
| "快速同步" / "quick sync" | 增量 | 仅本会话涉及的文件 + 记忆增量 |
| 其他 | 全量 | 完整 Steps 1-5 |

### Step 1: 盘点（强制枚举）

**先 ls，再判断。**

1. **记忆层**（按优先级尝试，首个成功即停）：
   - `memory_health()` → 可用则 `memory_search(tags=["project"], limit=100)` + `memory_search(tags=["shared"], limit=50)` + `memory_search(tags=["global"], limit=30)`
   - MCP 不可用 → 文件记忆（Claude Code: `~/.claude/projects/<...>/memory/`；其他平台见 [references/agent-paths.md](references/agent-paths.md)）
   - 都不可用 → 标记"记忆层跳过"，只处理文档层
2. 对本会话涉及的**每个项目**：
   - `ls <project-root>/` → 确认结构
   - `ls <project-root>/docs/ 2>/dev/null` → 枚举 docs（缺失也确认）
   - `find <project-root> -maxdepth 2 -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*"` → 兜底
   - 读 `README.md`、`CLAUDE.md`/`AGENTS.md`、每个 `docs/*.md`
3. 读全局 agent 配置（若有）
4. 从对话中提取**事实变更清单**（新增/修改/删除了什么）

> 无新事实 → 仍审查现有记忆/文档的过期、冲突、相对时间。项目无 README → 有可运行代码则创建，vibe 阶段跳过并注明。

**输出内部文件清单**，每个标「评估过/要改/不用改」。漏一个 = 失败。

### Step 2: 识别变更（表格驱动）

从事实变更清单映射到目标文件：

| 变更类型 | CLAUDE.md | docs/ |
|----------|-----------|-------|
| 新增 API/路由 | 路由清单 | integration-guide + architecture |
| 新增/改名环境变量 | 环境变量表 | runbook + integration-guide |
| 新增数据库表 | Schema 引用 | architecture Data Model |
| 跨文件大特性 | 以上全部 + handoff | 以上全部 |
| 跨项目改动 | 两边都改 | 两边 integration docs 都改 |
| 记忆过期/矛盾 | N/A | N/A（Step 3 处理） |

完整映射见 [references/sync-matrix.md](references/sync-matrix.md)。

**MCP 检查**（可用时）：
- `memory_conflicts()` → 矛盾列「未处理」让用户决定
- `memory_quality(action="analyze", min_quality=0.0, max_quality=0.5)` → 低质量标记
- 每条记忆需含 scope + type 双标签（缺失则补）

### Step 3: 执行修改

**必须用 Edit/Write 真改文件**，描述不算完成。

**顺序**：docs/ → CLAUDE.md/AGENTS.md → 记忆。

**MCP 操作**（可用时）：

| 操作 | 工具 | 规则 |
|------|------|------|
| 新增 | `memory_store` | scope 别名 + type 双标签，≤120 字 |
| 更新 | `memory_update` | 先 `memory_search` 定位 hash |
| 删除 | `memory_delete` | 先 `dry_run=true` 确认 |
| 去重 | `memory_cleanup` | 全局去重 |
| 标签补全 | `memory_update` | 补齐缺失 scope 或 type |

**编辑三原则**：
1. **合并优于追加** — 新信息更新旧条目，不追加
2. **删除优于保留** — 完成的计划、推翻的决策、过期上下文，删
3. **绝对时间** — 永远 `2026-05-27`，不写"今天"/"最近"

**docs/ 新增能力时四补**：integration-guide（怎么用）→ architecture（怎么工作）→ runbook（怎么运维）→ handoff/CHANGELOG（已完成）。

> 全局配置（`~/.claude/CLAUDE.md`）只有用户明确表达跨项目核心原则才动。过去的同步遗漏 → 现在修。

### Step 4: 自检（6 项必过）

- [ ] Step 1 清单中每个文件：已改或确认不用改
- [ ] MCP 记忆 tags 含 scope+type 双标签，`memory_conflicts()` 清零
- [ ] 新增 API/环境变量/数据库表：docs 和 CLAUDE.md 都出现
- [ ] 跨项目影响：下游 docs 也改了
- [ ] 无相对时间残留（`grep -E "今天|昨天|最近|today|yesterday|recently"` 清零）
- [ ] 全局配置未被项目细节污染

不过 → 回去补。

### Step 5: 变更摘要

改完后输出（不是改之前）：

```
## 同步完成

### 记忆变更
- 更新：xxx（原因）| 新增：xxx | 删除：xxx（原因）

### 文档变更（按项目）
- <项目>/CLAUDE.md — xxx
- <项目>/docs/xxx.md — xxx

### 未处理
- xxx（需用户确认）
```

只列实际变更。没改不写。

---

## 参考资料

- [references/sync-matrix.md](references/sync-matrix.md) — 变更类型 → 目标文件映射表
- [references/agent-paths.md](references/agent-paths.md) — 各平台记忆与配置路径
