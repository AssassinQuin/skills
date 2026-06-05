---
name: neat-freak
version: 3.0.0
description: >
  Session-end knowledge sync — reconciles CLAUDE.md, docs/, and agent memory
  against code changes. Tracks git diff for precise incremental mode.
  Auto-commits and pushes changes. Script-driven with templates.
  Triggers: "sync up", "tidy", "/neat", "收尾", "neat-freak"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
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

# 洁癖 v3.0.0 — Knowledge Base Neat-Freak

你是**知识库编辑**，不是记录员。编辑审查全局、合并重复、修正过期、删除废弃。

**受众规则**：
- Agent 记忆 → 自己跨会话复用（偏好、决策、规范）
- CLAUDE.md/AGENTS.md → 自己下次在这个项目复用（约定、结构、红线）
- docs/ + README → **其他人**接入和运维（指南、架构、手册）

CLAUDE.md 提醒自己；docs/ 教别人。功能变更时**两处都改**。

## 脚本工具箱

```bash
source scripts/neat.sh && <command>
```

| 命令 | 用途 | 阶段 |
|------|------|------|
| `neat-snapshot` | 记录当前 git HEAD hash | Step 0 |
| `neat-last-hash` | 读取上次记录的 hash | Step 1 |
| `neat-diff-summary` | 输出 snapshot 以来的变更摘要 | Step 1 |
| `neat-diff-grep <kw>` | 在变更文件中 grep 关键词 | Step 1 |
| `neat-scan-stale` | 过期/相对时间/TODO 扫描 | Step 1 |
| `neat-commit <msg>` | git add -A + commit | Step 5 |
| `neat-push` | git push 当前分支 | Step 5 |

## 执行流程

### Step 0: 模式选择 + Git 锚定

| 触发词含 | 模式 | 范围 |
|----------|------|------|
| "全量" / "full" | 全量 | 完整 Steps 1-6 |
| 其他 | **增量（默认）** | 仅变更涉及的文件 |

**Git 锚定**（v3.0 新增）：

```bash
source scripts/neat.sh && neat-snapshot
```

记录当前 HEAD hash 到 `/tmp/.neat-freak/last-hash`。后续步骤基于此 hash 精确追踪变更范围。

**首次运行检测**：若 `/tmp/.neat-freak/last-hash` 不存在，输出 "首次运行，无 git 基线，将使用对话上下文"。

### Step 1: 变更提取 + 定位

**禁止启动 Explore/搜索类 agent 做记忆审查。** 记忆文件是短文本，grep 精准且快。

#### 1a. Git diff 变更清单（v3.0 核心）

```bash
source scripts/neat.sh && neat-diff-summary
```

输出上次 snapshot 以来的变更文件列表。此列表作为事实变更的**客观基础**。

结合对话上下文补充 git diff 无法捕获的变更（如 MCP 操作、memory 写入等）。

**变更模板**（v3.0 新增）：

```
| 变更项 | 类型 | 来源 | 目标文件 |
|--------|------|------|---------|
| {具体变更} | 新增/修改/删除 | git diff / 对话 | {CLAUDE.md, memory/xxx.md, docs/} |
```

无 git 基线时 → 纯对话提取。

#### 1b. grep 定位受影响文件

根据变更清单 + git diff 输出，用 grep 定位需要检查的记忆/文档文件：

```bash
# 过时引用
grep -rn "旧关键词" memory/ CLAUDE.md

# 相对时间
grep -rn "今天\|昨天\|最近\|today\|yesterday\|recently" memory/ CLAUDE.md

# 旧技术名/旧路径
grep -rn "旧技术名" memory/
```

**增量优化**（v3.0）：先用 `neat-diff-grep <关键词>` 限定搜索范围到变更文件。

grep 结果为空的文件 → **跳过，不读**。

#### 1c. 过期/冲突扫描（强制）

```bash
source scripts/neat.sh && neat-scan-stale
```

**增量和全量都执行**。全量模式额外：
- `ls memory/` → 逐个 Read 检查
- `find . -maxdepth 2 -name "*.md"` → 项目级文件枚举
- `ls docs/ 2>/dev/null` → docs 枚举

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

从变更清单映射到目标文件：

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

**docs/ 新增能力时四补**：integration-guide → architecture → runbook → handoff/CHANGELOG。

> 全局配置（`~/.claude/CLAUDE.md`）只有用户明确表达跨项目核心原则才动。

### Step 4: 自检（7 项必过）

- [ ] git diff 变更清单中每项：已反映到对应文件或确认不需要
- [ ] 对话上下文补充变更：已反映
- [ ] 新增 API/环境变量/数据库表：docs 和 CLAUDE.md 都出现
- [ ] 无相对时间残留（`neat-scan-stale` 清零）
- [ ] 无过时引用残留（grep 清零）
- [ ] 全局配置未被项目细节污染
- [ ] 变更摘要输出完整（Step 5 模板）

不过 → 回去补。

### Step 5: Git 提交 + 推送（v3.0 新增）

**前提**：Step 4 自检全部通过。

```bash
source scripts/neat.sh
neat-commit "同步记忆+文档: {本次主要变更概括}"
neat-push
```

**提交信息模板**：

```
neat-freak: 同步记忆+文档: {概括}

{变更详情列表，每行一个}

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
```

**推送失败处理**：推送失败时输出错误信息，**不重试**，告知用户手动 `git push`。

**无变更时**：`neat-commit` 返回 "NOTHING_TO_COMMIT" → 跳过提交和推送，直接输出 Step 6。

**用户确认**：提交前展示 `git status -s` + `git diff --stat`，用户确认后才执行。用户拒绝 → 跳过提交。

### Step 6: 变更摘要

改完后输出：

```
## 同步完成

### Git 变更
- 基线: {hash} → 最新: {hash}
- 变更文件: {N} 个

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
| `neat-diff-summary` + grep 定位 | ~1-2K | **默认** |
| 启动 agent 扫描记忆文件 | ~20-50K | **禁止** |
| 全量 Read 所有记忆文件 | ~15-30K | 仅全量模式 |
| 无条件扫描 docs/ | ~5-10K | 按变更类型决定 |

**增量模式目标**：≤10K tokens。**全量模式目标**：≤25K tokens。

## 关键约束

1. **git hash 锚定** — Step 0 必须记录，Step 5 必须基于此追踪
2. **脚本驱动** — git 操作必须通过 `scripts/neat.sh`，不手写 git 命令
3. **提交前确认** — 展示变更，用户确认后才 commit+push
4. **推送失败不重试** — 报错让用户处理
5. **无变更不提交** — `neat-commit` 返回 NOTHING_TO_COMMIT 时跳过
6. **禁止 agent 扫描记忆** — grep 优先，记忆文件是短文本

---

## 参考资料

- [references/sync-matrix.md](references/sync-matrix.md) — 变更类型 → 目标文件映射表
- [references/agent-paths.md](references/agent-paths.md) — 各平台记忆与配置路径
- [scripts/neat.sh](scripts/neat.sh) — git 追踪 + 提交 + 过期扫描脚本
