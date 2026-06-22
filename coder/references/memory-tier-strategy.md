---
name: memory-tier-strategy
description: memory MCP 三层 tier（项目/共享/全局）+ tag 规范 + seed 策略 + 写入权限。
source: "design.md §7.3 + §7.3.1"
status: skeleton
---

# memory MCP 三层 tier 策略

> **加载时机**：Phase 6 写 memory；Phase 4 spawn 子 agent 前查 memory。

## 三层 tier

| Tier | 路径 | 用途 | 写入者 |
|---|---|---|---|
| **项目级** | project hash | 项目专属 gotcha | orchestrator / 子 agent |
| **共享级** | shared | 跨项目通用 convention / trap / tooling | orchestrator only（🔒 用户确认）|
| **全局级** | global | 用户级偏好 | orchestrator only（🔒 用户确认）|

## tag 规范（v3.2 8 个 references 的替代）

| tag | tier | 来源（v3.2 对应文件）| 粒度 |
|---|---|---|---|
| `coding-{lang}-convention` | 共享级 | go/python-conventions.md | 每条 convention 一条 |
| `coding-{lang}-trap` | 共享级 | go/python-editing-traps.md | 每个陷阱一条 |
| `coding-{lang}-tooling` | 共享级 | go-gopls-strategy / python-tooling.md | 每个工具链经验一条 |
| `coding-{lang}-verification` | 共享级 | go/python-verification-loop.md | 每个 loop 阶段一条 |
| `coding-{lang}-gotcha` | 项目级 | （新，运行时积累）| 项目专属坑 |
| `coding-super-decay` | 共享级 | （新，Phase 5 积累）| 每次衰减记录 |
| `coding-audit-finding` | 项目级 | （新，Phase 5 reviewer）| 每个审查发现 |
| `coding-user-pref` | 全局级 | （新，用户反馈）| 每条偏好 |

**{lang} 取值**：`go` / `python` / `typescript` / `rust` / 其他（按 metadata.language）

## 写入权限（Q8 已决策）

**子 agent 可写**：
- 项目级（`coding-{lang}-gotcha` / `coding-audit-finding`）

**子 agent 不可写**（必须 orchestrator + 🔒 用户确认）：
- 共享级（convention / trap / tooling / verification / super-decay）
- 全局级（user-pref）

理由：共享/全局级跨项目生效，影响大，必须用户确认。

## 检索策略（子 agent 启动时）

```yaml
memory_search:
  query: "{任务关键词} {lang}"
  tags: ["coding-{lang}-convention", "coding-{lang}-trap",
         "coding-{lang}-tooling", "coding-{lang}-verification",
         "coding-{lang}-gotcha"]
  tier: [project, shared]  # 不查全局级
  limit: 20
```

结果注入子 agent prompt 的"语言上下文"段。

## Seed 策略（Q7 已决策：模型告知 + 用户确认）

### 触发流程

```
1. orchestrator spawn {lang}-coder 前查 memory
2. 若返回空（首次使用）:
   AskUserQuestion:
     "检测到 {lang} 经验库为空。
      可以从 v3.2 references（约 N 条）seed 到 memory MCP。
      seed 后所有 {lang} 任务都会自动复用。
      
      [推荐] 是, seed
             否, 这次裸跑
             否, 永不询问"
3. 用户选 "是" → 跑 scripts/seed-memory.py --lang={lang}
4. 用户选 "这次裸跑" → ⚠️ + 继续 Phase 4
5. 用户选 "永不询问" → 写 memory_user-pref "no-seed-{lang}"
```

### Seed 脚本（待 step 3.5 写）

`scripts/seed-memory.py`：
- 输入：`references/legacy/{lang}-*.md`（v3.2 文件备份）
- 解析：每个 `##` 或 `- **陷阱 N**` 切一条 memory
- 输出：批量 `memory_store`，tier=shared
- 去重：seed 前 `memory_search`，semantic ≥0.85 跳过

### Seed 后

v3.2 references 移到 `references/legacy/`（保留历史，不进加载链）。
seed 完成后可删 `references/legacy/`（用户决定）。

## 降级（Q9 已决策：不回退 legacy）

memory MCP 不可用 / seed 失败：
- 子 agent 查 memory 失败 → 标 ⚠️ + 裸跑（无 convention 注入）
- 汇报里标注 "⚠️ 无语言经验注入，结果可能不符 convention"
- **不回退** legacy references（避免维护两份）

## TODO（待 step 3.5 扩充）

- [ ] `scripts/seed-memory.py` 完整实现
- [ ] 各语言的 seed 输入文件路径表
- [ ] memory 清理流程（去重 / 过期）

## 引用

- design.md §7.3 + §7.3.1
- `phase-4-execution-protocol.md`（spawn 前 memory 注入）
- `phase-6-persistence.md`（写回 memory）
