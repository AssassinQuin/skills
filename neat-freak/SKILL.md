---
name: neat-freak
version: 2.0.0
description: >
  Session-end knowledge sync — reconciles CLAUDE.md, docs/, and agent memory
  against code changes. Default: incremental. Full scan requires explicit trigger.
  Triggers on "sync up", "tidy", "/neat", "收尾", etc.
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
| "全量" / "full" | 全量 | 完整 Steps 1-5 |
| 其他 | **增量（默认）** | 仅本会话事实变更涉及的文件 |

### Step 1: 提取变更 + 定位（grep 优先）

**禁止启动 Explore/搜索类 agent 做记忆审查。** 记忆文件是短文本，grep 精准且快。

#### 1a. 提取事实变更清单

从对话中提取本会话的**事实变更**（新增/修改/删除了什么）。无新事实 → 跳到 1c 做过期扫描。

#### 1b. grep 定位受影响文件（增量模式核心）

根据变更清单，用 grep 定位需要检查的文件。常见搜索模式：

```bash
# 过时引用（如工具数、模型名、旧路径）
grep -rn "旧关键词" memory/ CLAUDE.md codemap.md

# 相对时间
grep -rn "今天\|昨天\|最近\|today\|yesterday\|recently" memory/

# 旧模型/库名
grep -rn "旧技术名" memory/
```

grep 结果为空的文件 → **跳过，不读**。

#### 1c. 过期/冲突扫描（3 条 grep）

**增量和全量都执行**，这是最轻量的全量检查：

```bash
grep -rn "今天\|昨天\|最近\|today\|yesterday\|recently" memory/ CLAUDE.md
grep -rn "废弃\|deprecated\|TODO\|FIXME" memory/ CLAUDE.md
```

全量模式额外执行：
- `ls memory/` → 枚举全部文件，逐个 Read 检查内容
- `find . -maxdepth 2 -name "*.md"` → 枚举项目级文件
- `ls docs/ 2>/dev/null` → 枚举 docs

#### 1d. docs/ 按需扫描

**不要无条件扫描 docs/。** 按变更类型决定：

| 变更类型 | 扫描 docs/ | 原因 |
|----------|-----------|------|
| 新增 API/工具/路由 | **是** | 需更新 integration-guide |
| 新增/改名环境变量 | **是** | 需更新 runbook |
| 新增数据库表 | **是** | 需更新 architecture Data Model |
| 内部重构/审计/bug修复 | **否** | 不影响对外文档 |
| 记忆/文档层自身变更 | **否** | 已在 1b 处理 |
| 跨文件大特性 | **是** | 需全面更新 |

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

### Step 4: 自检（5 项必过）

- [ ] 事实变更清单中每项：已反映到对应文件或确认不需要
- [ ] 新增 API/环境变量/数据库表：docs 和 CLAUDE.md 都出现
- [ ] 无相对时间残留（grep 清零）
- [ ] 无过时引用残留（grep 清零）
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

## Token 效率守则

| 做法 | Token 消耗 | 推荐度 |
|------|-----------|--------|
| grep 定位 → 只读命中文件 | ~1-2K | **默认** |
| 启动 agent 扫描记忆文件 | ~20-50K | **禁止** |
| 全量 Read 所有记忆文件 | ~15-30K | 仅全量模式 |
| 无条件扫描 docs/ | ~5-10K | 按变更类型决定 |

**增量模式目标**：≤10K tokens。**全量模式目标**：≤25K tokens。

---

## 参考资料

- [references/sync-matrix.md](references/sync-matrix.md) — 变更类型 → 目标文件映射表
- [references/agent-paths.md](references/agent-paths.md) — 各平台记忆与配置路径
