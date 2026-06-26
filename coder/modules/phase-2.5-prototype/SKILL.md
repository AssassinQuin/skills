---
phase: 2.5
name: phase-2.5-prototype
description: Phase 2.5 throwaway prototype（v6.3 新增，from mattpocock prototype）。复杂度极高或设计不确定时触发。throwaway code 验证 design 关键假设。6 rules 强制。Phase 3 design 之后、Phase 4 执行之前。
source: ".deepen/20260625-execution-flow/mattpocock-optimization.md 优化 7 + mattpocock prototype skill"
status: active
tokens_estimate: 1500
load_priority: on-demand
load_when: "复杂任务 / 设计不确定时"
keywords: throwaway prototype 6 rules one-command no-persistence skip-polish surface-state delete-or-absorb
domain: coding
subdomain: phase
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  notes: "tracer-bullet + fail-fast + validate-assumptions"
---

# Phase 2.5: Throwaway Prototype（v6.3 新增）

> **加载时机**：Phase 3 design 完成后，复杂度极高或设计不确定时。
> **来源**：mattpocock `prototype` skill。
> **核心**：throwaway code that answers a question——不是 production code。

## 触发条件（任一命中即触发）

| 信号 | 触发？ |
|---|---|
| design.md 标"高风险"（数据库迁移 / 跨服务重构 / 新协议） | ✅ |
| 涉及新技术栈（团队未用过） | ✅ |
| >5 文件 + 涉及核心业务逻辑 | ✅ |
| 用户说"我不确定这样行不行" / "能先验证下吗" | ✅ |
| spec.md budget ≥ 半天 | ✅ |
| 简单 typo 修复 / 1 文件 <20 行 | ❌ |

## 6 Rules（强制）

### Rule 1: Throwaway from day one, clearly marked

- 代码放靠近使用处（next to 模块 / 页面）
- 文件名 / 目录名必须含 `prototype/` / `proto_` 前缀
- 不放生产代码路径（src/ 主路径外）
- README 头部标注 `**PROTOTYPE — THROWAWAY**`

### Rule 2: One command to run

- 用项目已有 task runner（pnpm / python / bun / make）
- 用户一条命令启动：`pnpm proto:login-flow`
- 不需额外配置 / 安装

### Rule 3: No persistence by default

- 状态在内存
- 如果问题是"DB schema 这样合理吗"→ 用 scratch DB（命名 `prototype_wipe_me`）
- 不依赖 production DB

### Rule 4: Skip the polish

- ❌ 无测试
- ❌ 无错误处理（只让 runnable）
- ❌ 无抽象
- 目的：**学点东西然后删**

### Rule 5: Surface the state

- 每次操作后 print / render 完整相关状态
- 用户能看到"什么变了"
- UI 变体切换时也要 surface

### Rule 6: Delete or absorb when done

- 验证完 design 假设后：
  - **delete**：直接删 prototype 代码
  - **absorb**：把验证过的决策折回真实代码（不是 prototype 整体搬，是"学到的"折回）
- **禁止**：把 prototype 留在 repo 腐烂

## 两种 prototype 分支

### Branch A: Terminal App（state / business logic 问题）

跑：
```bash
python prototype/login_state_machine.py
# 或
bun prototype/prototype-tracer-bullet.ts
```

- 用户输入 → 程序输出当前状态
- 验证：状态机 / 数据流 / 业务逻辑

### Branch B: UI Variations（多个不同 UI 设计）

- 一个路由，多个变体（query string 切换）
- 用户手动切换看哪个好
- 验证：UX 设计

## Workflow（4 步）

```
1. 用户 + oracle 确定"要回答什么问题"
   例："异步 login 在并发 100 用户下能稳定吗？"

2. spawn prototype-coder (sonnet) 写 throwaway code
   - 严格遵循 6 rules
   - 1 命令启动
   - surface state

3. 用户跑 prototype，观察
   - 是否回答了问题？
   - 是否暴露新问题？

4. 决策：
   - 假设验证 → 折回 design.md（update），删 prototype
   - 假设推翻 → 回 Phase 3 重选 alternative
   - 部分验证 → 补 property test 到 test-plan.md
```

## 输出契约

返回 markdown 块：

```markdown
## Prototype Report

### 问题（要回答的）
{一句话}

### Prototype 实现
- 路径: prototype/{name}/
- 启动命令: {pnpm proto:login / bun prototype/x.ts}
- 行数: {N}

### 观察结果
- 假设 1（"async login 100 并发稳定"）: ✅ 验证 / ❌ 推翻
- 暴露的新问题: ...

### 决策
- [ ] 假设验证，折回 design.md，删 prototype
- [ ] 假设推翻，回 Phase 3
- [ ] 部分验证，补 test-plan.md

### 清理
- [ ] prototype 代码已删 / 折回
- [ ] 无遗留依赖
```

## Anti-pattern（避免）

### ❌ "prototype 写得太好舍不得删"
**正确**：throwaway from day one，标记清楚，到点就删。

### ❌ "prototype 直接上线"
**正确**：验证后**折回**真实代码（重新写在 src/），不是搬 prototype。

### ❌ "prototype 不 surface state"
**正确**：每次操作 print 完整状态，用户能看到变化。

### ❌ "prototype 引新依赖"
**正确**：用 stdlib / 项目已有依赖。引新依赖违背 throwaway 原则。

### ❌ "prototype 测了所有 edge case"
**正确**：skip polish。只验证关键假设。

## 与其他 Phase 的关系

| Phase | 关系 |
|---|---|
| Phase 3（design） | 完成后，如果触发条件命中 → 进 Phase 2.5 |
| Phase 4（执行） | Phase 2.5 完成后进 Phase 4（含验证后的 design） |
| Phase 5（验证） | Phase 2.5 的 prototype 不进 Phase 5（已删） |

## 跳过场景

| 场景 | 跳过 Phase 2.5？ |
|---|---|
| 简单 typo / 1 文件小改 | ✅ 跳 |
| 已验证过的设计模式 | ✅ 跳 |
| spec.md budget < 30 分钟 | ✅ 跳 |
| 新技术栈 / 跨服务重构 | ❌ 必跑 |

## 引用

- 来源：mattpocock `prototype` skill（[skills/prototype/SKILL.md](../../prototype/SKILL.md)）
- 设计：[`.deepen/20260625-execution-flow/mattpocock-optimization.md`](../.deepen/20260625-execution-flow/mattpocock-optimization.md) 优化 7
- 上游：[`phase-3-design-options.md`](phase-3-design-options.md)
- 下游：[`phase-4-execution-protocol.md`](phase-4-execution-protocol.md)

## Verification（如何确认本 Phase 成功）

- [ ] prototype 代码已跑过
- [ ] 问题（"要回答什么"）已有明确答案
- [ ] 决策已记录（验证 / 推翻 / 部分）
- [ ] design.md 已根据决策更新（如验证）
- [ ] prototype 代码已删 / 折回（不留 repo 腐烂）
- [ ] 无遗留依赖（spec.allowed_deps 未变）
