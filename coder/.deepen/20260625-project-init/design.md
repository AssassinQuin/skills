# Coder 项目初始化系统 — 设计文档

**日期**：2026-06-25
**作者**：Quin（参考 oh-story-claude 的 intelligent-merge 模式）
**状态**：设计完成，待实现

---

## 0. 设计目标

**对齐用户需求**：
> 类似 oh-story-claude，初始化 coder 后，可以生成项目级 agent / hook / 强制流程，通用记忆保存到 memory 跨 session，完善 coder 编程思维流程，保留一套最小标准流程，根据项目 agent 给出不同语言项目自己的 agent。

**核心问题**（当前 v5.0 痛点）：
1. SKILL.md 协议**靠 orchestrator 自觉执行**——13 条硬约束 / §11 Anti-pattern 全是事后反思，没有运行时拦截
2. **项目特定知识无处安放**——`~/.claude/agents/` 是全局的；项目 codestyle / 模块边界只能靠 memory MCP（隐性）
3. **新项目冷启动成本高**——每次跑都得 Phase 1 重新扫，没有"项目 onboard 一次性沉淀"
4. **不同语言混用同一套 agent**——go-coder / python-coder 是通用的，无法表达"这个 Go 项目用 biz 包布局，禁止跨包 import"

---

## 1. 三层金字塔架构

```
                    ┌─────────────────────────────────────┐
                    │  coder skill (最小标准流程)          │
                    │  SKILL.md ≤200 行 router            │
                    │  references/ 通用 Phase 协议         │
                    │  agents/{lang}-coder.md 通用语言版   │
                    └─────────────────┬───────────────────┘
                                      │ scripts/init-project.sh
                                      │ （智能合并，不覆盖）
                                      ▼
                    ┌─────────────────────────────────────┐
                    │  项目 .claude/ (项目差异化)          │
                    │  ├── agents/{lang}-coder.md         │ ← 项目语言 agent（继承+覆盖）
                    │  ├── agents/project-reviewer.md     │ ← 项目特定审查
                    │  ├── settings.json → hooks          │ ← 强制流程
                    │  ├── CLAUDE.md                      │ ← 项目级最小流程
                    │  └── .coder-initialized.json        │ ← init 元数据
                    └─────────────────┬───────────────────┘
                                      │ 跨 session 沉淀
                                      ▼
                    ┌─────────────────────────────────────┐
                    │  memory MCP (通用编程思维)           │
                    │  tags:                              │
                    │  - coder-protocol (跨项目协议经验)   │
                    │  - coding-{lang}-convention/trap    │
                    │  - coding-{lang}-gotcha (项目级)    │
                    │  - coding-super-decay               │
                    └─────────────────────────────────────┘
```

**层次职责**：
- **coder 本体**：通用标准流程，所有项目共用，保持最小
- **项目 .claude/**：项目特定差异，init 时按语言/框架生成，git-trackable
- **memory MCP**：跨 session 的隐性经验（协议执行 drift、踩坑、用户偏好）

---

## 2. init 触发方式（双触发）

| 触发场景 | 行为 |
|---|---|
| **显式**：用户跑 `/coder init` 或 `bash coder/scripts/init-project.sh` | 全量生成 / 智能合并 |
| **隐式**：coder skill 第一次在某项目跑，且 `.claude/.coder-initialized.json` 不存在 | orchestrator AskUserQuestion：「检测到首次使用，是否生成项目配置？（是 / 这次否 / 永不问）」 |

**永不问**flag 写到 `~/.claude/memory/` 的 `coder-user-pref` tag（全局级）。

**幂等性**：重复跑 init 不会覆盖用户改动——所有合并走 §3 智能合并策略。

---

## 3. 智能合并策略（intelligent merge，参考 oh-story-claude）

### 3.1 Agent 文件合并

**目标文件存在时**：
- 文件头检测 marker `<!-- managed-by: coder-init -->`
  - 存在 → 判断 hash 是否变化，变化则**只更新 managed section**，用户自定义 section 保留
  - 不存在 → 在文件头插入 marker + 提示用户「已有自定义 agent，跳过；如要强制覆盖用 --force」
- 文件不存在 → 直接写模板

**Agent 内部结构**（模板强制）：
```markdown
---
name: {lang}-coder
description: ...
---

<!-- managed-by: coder-init {version} -->
<!-- managed-section: start -->
（coder init 生成的项目特定内容，可被重新生成）
<!-- managed-section: end -->

<!-- user-section: 自定义内容写这里，init 不会覆盖 -->
```

### 3.2 settings.json hooks 合并

用 `jq` 做 JSON patch：
- 已有 `hooks.PreToolUse` → 追加（去重，按 command 哈希）
- 已有 `hooks.SessionStart` → 同上
- 不动其他字段

**rollback**：合并前备份到 `.claude/.settings-backup-{timestamp}.json`。

### 3.3 CLAUDE.md 合并

markers：
```markdown
<!-- coder-init: project-context start -->
（init 生成的项目元信息：语言 / 框架 / 常用命令 / 模块边界）
<!-- coder-init: project-context end -->

（用户自己的内容）
```

只在 markers 之间替换，其他保留。

---

## 4. 项目语言 agent 差异化（按语言路由）

| 项目信号 | 生成的项目 agent | 项目特定内容 |
|---|---|---|
| `go.mod` 存在 | `agents/go-coder.md` | go version / module path / cmd-vs-internal 布局 / 常用 make targets |
| `pyproject.toml` / `setup.py` | `agents/python-coder.md` | python version / 依赖管理（poetry/uv/pip）/ 包布局 / pytest 配置 |
| `package.json` | `agents/ts-coder.md`（template 内标记 WIP） | node version / pkg manager / monorepo? |
| `Cargo.toml` | `agents/rust-coder.md`（WIP） | edition / workspace 布局 |
| 多语言混合 | 都生成 + CLAUDE.md 标注"主语言" | 主语言由 init 时 AskUserQuestion 决定 |

**继承 vs 覆盖**：项目 agent **继承** coder 自带的通用 agent（通过「spawn 通用 → 注入项目 agent 的差异段」），不是完全覆盖。这样：
- 通用 agent 升级时，项目自动受益
- 项目只声明差异（"本项目禁止跨包 import internal/"），不重复通用规则

---

## 5. Hook 清单（强制流程）

### 5.1 PreToolUse: Edit / Write（block 模式）

`edit-guard.sh` 拦截：
1. **硬约束 #13**：Edit 前 grep 同类模式——检查前序 conversation 是否有 grep 痕迹
2. **§2.2 orchestrator 直编限制**：当前会话已 Edit 的文件数 >1 或 LOC >20 且无 spawn 子 agent → block
3. **§11.6 简单任务滑坡**：连续第 3 次 Edit 而无 Phase 1 / memory_search → warn

输出（exit code 2 + JSON）：
```json
{
  "decision": "block",
  "reason": "Edit #6 在本次会话中无 spawn 子 agent 痕迹，违反 §2.2（>1 文件 / >20 行）。请 spawn {lang}-coder 子 agent。",
  "suppress_output": false
}
```

### 5.2 PostToolUse: Agent（记录 spawn trace）

`spawn-trace.sh`：
- 记录每次 spawn 到 `.claude/coder-trace.jsonl`
- 字段：timestamp / agent_name / model / phase / caller_context_hash
- 用途：edit-guard.sh 检查「最近 N 次 Edit 是否有对应 spawn」

### 5.3 SessionStart（加载项目 memory）

`session-load.sh`：
- 读 `.claude/.coder-initialized.json` 显示项目元信息
- 调 `memory_search(tags=["coding-{lang}-gotcha", "project:{path-hash}"])` 注入项目特定坑
- 显示上次会话未完任务（从 `.claude/coder-trace.jsonl` 推断 drift）

### 5.4 强制度梯度（block / warn / hint）

| Hook | 默认强制度 | 可调 |
|---|---|---|
| edit-guard.sh | **block**（违反 §2.2 / 硬约束 #13） | `CODER_HOOK_MODE=warn` 降级 |
| spawn-trace.sh | hint（仅记录） | — |
| session-load.sh | hint（仅显示） | — |

用户在 `~/.claude/memory/coder-user-pref` 可写"本项目 edit-guard = warn"覆盖默认。

---

## 6. memory MCP 沉淀策略

### 6.1 通用协议经验（跨项目）

| tag | tier | 内容 |
|---|---|---|
| `coder-protocol` | 共享级 | init 哲学 / 三层架构 / 智能合并原则 / hook 梯度 |
| `coder-execution-drift` | 共享级 | 每次执行的协议偏离记录（§11 Anti-pattern 的持续补充） |
| `coder-user-pref` | 全局级 | 用户偏好（hook 强制度 / 是否提示 init） |

### 6.2 语言知识（已有，保持）

`coding-{lang}-convention/trap/tooling/verification` 不动，继续走共享级。

### 6.3 项目特定（init 时 seed）

| tag | tier | 何时写 |
|---|---|---|
| `coding-{lang}-gotcha` | 项目级 | init 扫描发现的项目特定坑（如"biz 包禁止跨 import"） |
| `coding-audit-finding` | 项目级 | reviewer 子 agent 发现的新坑（已有） |

**项目级 memory 路径隔离**：用项目路径 hash 做 namespace，避免多项目污染。

---

## 7. 最小标准流程（coder SKILL.md 保持的"最小"）

coder 本体只保留：
1. **7 Phase 路由表**（§2）— 通用流水线
2. **13 条硬约束摘要**（§4）— 通用契约
3. **语言路由**（§3）— spawn 决策
4. **降级策略**（§8）— 失败显性化
5. **references 索引**（§7）— progressive disclosure

**不在 coder 本体**：
- 项目特定 codestyle（→ 项目 CLAUDE.md）
- 项目特定 agent（→ 项目 .claude/agents/）
- 协议执行经验（→ memory MCP）
- 项目 onboard 详细步骤（→ references/project-init.md，按需加载）

---

## 8. 实现里程碑

| M | 内容 | 文件 |
|---|---|---|
| M1 | 设计文档 | `.deepen/20260625-project-init/design.md`（本文） |
| M2 | init 脚本 | `scripts/init-project.sh` |
| M3 | CLAUDE.md + agents 模板 | `templates/CLAUDE.md.template`、`templates/agents/{lang}-coder.template.md` |
| M4 | 3 个 hook 脚本 + settings 片段 | `templates/hooks/scripts/*.sh`、`templates/hooks/settings.json.fragment` |
| M5 | SKILL.md §12 项目初始化协议 | `SKILL.md` |
| M6 | memory 沉淀 | `memory_store(content=..., tags=["coder-protocol"])` |
| M7（可选） | init 项目 onboard agent | `coder/agents/project-onboard.md`（opus） |

---

## 9. Tradeoffs / 待用户决策

### 9.1 强制 hook vs 提示 hook

**默认 block**（推荐）→ 协议严守，但新手可能被烦
**默认 warn** → 友好但不强制
**默认 hint** → 形同虚设

**当前选择**：edit-guard 默认 block（§2.2 + 硬约束 #13），可 `CODER_HOOK_MODE=warn` 降级。

### 9.2 项目 agent 继承 vs 覆盖

**继承**（推荐）→ 项目 agent 只声明差异，通用 agent 升级自动受益
**覆盖** → 项目独立，但通用升级需手动同步

**当前选择**：继承。spawn 时通用 agent 是 base，项目 agent 是 override patch。

### 9.3 init 是 slash command 还是隐式触发

**slash command** → 可控，但用户得记着跑
**隐式** → 自动化，但可能打扰

**当前选择**：双触发。隐式只问一次（"永不问"可关），之后只能显式跑。

### 9.4 项目 memory 的隔离

**项目路径 hash namespace**（推荐）→ 多项目不污染
**全局共享** → 简单但会串

**当前选择**：path-hash namespace。

---

## 10. 与 v5.0 的兼容性

- v5.0 的 7 Phase 流水线**不变**
- v5.0 的 references/ 14 个文件**不动**
- v5.0 的 `agents/go-coder.md` / `agents/python-coder.md` **保留作为通用 base**
- 新增 `scripts/init-project.sh` + `templates/` + SKILL.md §12

向后兼容：未跑 init 的项目，coder 继续按 v5.0 跑（无项目 agent，无 hook 强制）。

---

## 11. 风险

| 风险 | 缓解 |
|---|---|
| hook block 误判，卡住正常工作 | `CODER_HOOK_MODE=warn` 降级 + 默认只 block 明确违规（>1 文件 / >20 行） |
| 智能合并不完美，覆盖用户改动 | markers 严格 + 合并前自动 backup |
| init 模板过时（语言版本升级） | init 时记录 `coder-version`，跑 init 自检更新 |
| memory MCP 路径 hash 冲突 | SHA-256 前 16 位，足够 |
| 项目 agent 与全局 agent 名字冲突 | 项目 agent 名字加 `-project` 后缀（`go-coder-project`） |
