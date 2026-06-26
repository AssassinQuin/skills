---
name: coder-constraints
description: 14 条硬约束完整版（含检查命令 + 例子 + 反例）。orchestrator + 所有子 agent 永远加载。
source: "design.md §2（设计原则）+ v3.2 继承 + v5.0 §11.7 反例 + v7.1 #14 并发上限"
status: skeleton
tokens_estimate: 1700
load_priority: always
load_when: "每次（orchestrator + 所有子 agent）"
keywords: 14 hard constraints R1-R12 coding rules mandatory block concurrent spawn limit
domain: coding
subdomain: protocol
parent_skill: coder
version: "1.1"
license: Apache-2.0
frameworks:
  solid:
    - 单一职责（每个 module/class 只做一件事）
    - 开闭原则（扩展开放，修改封闭）
    - 里氏替换（子类能替换父类）
    - 接口隔离（client 不应被迫依赖未用的接口）
    - 依赖倒置（依赖抽象，不依赖具体）
  twelve_factor:
    - I-XII
  owasp_top_10:
    - OWASP Top 10 全覆盖
  test_pyramid:
    - unit tests（逻辑层）
    - integration tests（IO/DB/外部 API）
  notes: "R1-R12 = 综合（SOLID+12F+OWASP+TP）+ v7.1 #14 并发上限"
---

# 14 条硬约束（完整版）

> **加载时机**：永远加载（orchestrator + 所有子 agent）。

## 1. 意图不清必问（Phase 0）

**规则**：Phase 0 时，4 维度（验收 / 范围 / 边界 / 优先级）任一不明 → AskUserQuestion ≤2 次。

**检查**：`grep -c "AskUserQuestion" trace.log` ≤ 2

**反例**：用户说"加登录"，直接做密码登录，结果用户想要 OAuth。

## 2. 子 agent 必须显式指定 model（R5.1，**不可全部继承主 agent**）

**规则**：
1. 每个 `agents/*.md` frontmatter **必须**有 `model:` 字段（haiku / sonnet / opus）
2. spawn 时 Task tool **必须**显式传 `model:` 参数（即便继承链能兜底）
3. **禁止**一条消息里所有 spawn 用同一个 model（"全部继承主 agent" = 反模式）
4. orchestrator 自身模型 ≠ 子 agent 模型，按职责选模型，不图省事

**映射**（按 coding-rules R5.1）：
- haiku：无推理（扫描 / 定位 / 提取）→ `explorer` / 元数据扫描
- sonnet：推理但非战略（执行 / 审查 / 调研）→ `*-coder-project` / `reviewer` / `researcher`
- opus：战略（方案 / 重分解 / 架构评审）→ `oracle` / adaptive control 重分解

**当前 coder 生态已锁定的 model**（v7.1）：

| Agent | model | 用途 |
|---|---|---|
| `explorer` | haiku | Phase 0.5 / 1 元数据扫描 |
| `researcher` | sonnet | Phase 0.5 / 1 库调研 |
| `oracle` | opus | Phase 0.5 / 3 设计方案 |
| `test-strategist` | sonnet | Phase 3 test-plan |
| `{lang}-coder-project` | sonnet | Phase 4 编码执行 |
| `correctness-reviewer` | sonnet | Phase 5 正确性审查 |
| `project-reviewer` | sonnet | Phase 5 S.U.P.E.R + 惯例审查 |
| `security-reviewer` | sonnet | Phase 5 OWASP 审查 |

**检查**：
- `grep -L "^model:" agents/*.md` → 返回空（所有 agent 都有 model 字段）
- spawn trace 里每条 spawn 都有 `model: {haiku|sonnet|opus}` 字段

**反例**：
- ❌ spawn 5 个 coder 全部 `model: opus`（opus 不该干执行活，浪费 + 慢）
- ❌ spawn 时省 `model:` 参数让它"继承主 agent"（主 agent 是 opus 时所有子 agent 变 opus）
- ❌ 一条消息 spawn 4 个 reviewer 全 sonnet（同 model × 同职责 = 实质串行，浪费并发 slot）

## 3. token 预算硬性

**规则**：单次任务主上下文 ≤30k + 长文件用 ctx_index。

**检查**：`/context-stats` 看 token 消耗。

**反例**：直接 Read 5000 行文件 → 主 context 爆。

## 4. 暴露冲突不折中（R7）

**规则**：代码库有矛盾模式 → 明确指出，等用户决策，不混合。

**反例**：项目一半用 gin 一半用 echo，子 agent 选一个不告诉用户。

## 5. 先读再写（R8）

**规则**：添加代码前，读当前文件 + 其导入关系。已有相同功能函数 → 用，不创建第二个。

**检查**：每个 Edit 前 grep 同名函数。

## 6. 测试验证意图（R9）

**规则**：测试验证有意义的属性（值 / 结构 / 副作用 / 错误类型），不只验证"能跑"。

**反例**：测试只断言 `err == nil`，不验证返回值结构。

## 7. 长任务检查点（R10）

**规则**：超过 3 步或修改超过 3 文件 → 每步总结。某步失败 → 回滚到上一个检查点。

**检查**：trace 里每 N 步有 "checkpoint" 标记。

## 8. 惯例优先于新颖（R11）

**规则**：即使认为自己的写法更好，也遵从现有命名 / 架构惯例。引入第二种模式比任何单一模式都更糟。

**反例**：项目用 sync.Map，子 agent 用 mutex（即使场景适合 mutex）。

## 9. 失败显性化（R12）

**规则**：错误必须抛出 / 返回 / 上报，严禁吞掉。批处理跳过时，跳过数量和原因必须展示。不能 100% 确认成功时必须说明。

**反例**：MCP 调用失败静默降级，不告诉用户。

## 10. 外科手术式修改（R3）

**规则**：只触碰必须修改的地方。不顺便"优化"无关代码 / 注释 / 格式。不重构没坏的东西。

**反例**：用户让改 typo，子 agent 顺便重命名了所有变量。

## 11. 简洁优先（R2）

**规则**：只写能解决问题的最少代码。不写投机性功能；不为单次使用做抽象。资深工程师会觉得过度复杂 → 简化。

## 12. 编码前先思考（R1）

**规则**：明确陈述假设；不确定就提问，不要猜。暴露权衡，列出多种方案的优缺点。如果存在更简单的方法，要反驳当前方案。

## 13. Edit 前 grep 同类模式（R8 扩展）

**规则**：每次 Edit 前 grep 同类模式（修渲染 bug → grep 其他 presenter 同样模式；修字段名 → grep 所有引用；修 URL 构造 → grep 调用方），防"只修一处"漏修。

**检查**：trace 里每个 Edit 前有 grep 同类模式的步骤。

**反例**（fcli 2026-06-23）：修 `gold_presenter.py:217` 的 `curr["date"]` rich 渲染 bug，只改一处，没 grep 其他 `*_presenter.py`。可能漏修 `fund_presenter / gpr_presenter` 的同类 bug。详见 SKILL.md §11.7。

## 14. 单条消息并发子 agent ∈ [3, 5]（v7.1 新）

**规则**：orchestrator 在一条消息里 spawn 子 agent 时，数量**必须在 3-5 之间**。

**为什么是 3-5**：
- < 3 → 切得太粗，应该再拆（parallel exploration 的多样性收益没拿到）
- > 5 → 切得太细，应该合并（token 爆炸 + orchestrator 合并成本指数上升）
- 3-5 是 Anthropic parallel exploration best practice 的甜区

**3-5 上限适用场景**：

| Phase | 推荐数 | 硬上限 | 备注 |
|---|---|---|---|
| Phase 0.5 | 3（固定） | 3 | explorer + researcher + oracle |
| Phase 1 | 3（固定） | 3 | explorer + get_architecture + researcher |
| Phase 3 | 3（默认） / 2-4 | 5 | oracle × N + test-strategist(1) |
| Phase 4 | 3-5（按 slice 数） | 5 | `{lang}-coder-project` × N |
| Phase 5 | 3（固定） | 3 | correctness + project + security reviewer |

**特殊情况**：
- 实在只需 1-2 个 slice（极简任务）→ 走 §2.2 orchestrator 直编，不 spawn
- 实在需 > 5 个 slice → 分批 spawn（先 5 个，等 delivery 后再下一批），并在汇报里 ⚠️ 标"分批 spawn"

**检查**：spawn-count-guard hook 拦截 PostToolUse Agent，统计同一条 assistant 消息里的 spawn 数。超出 [3,5] → block + 要求 orchestrator 重切。

**反例**：
- ❌ 改 7 个文件 → spawn 7 个 coder（超 5 上限）→ 应合并相邻文件为 4-5 个 slice
- ❌ 改 2 个文件 → spawn 2 个 coder（低于 3）→ 应走 orchestrator 直编（§2.2）或合并为 1 个 coder 任务
- ❌ Phase 3 改动跨 6 模块 → spawn 6 oracle（超 5）→ 应分批或选 4 个最发散方向

## 检查清单（每次汇报必填）

```markdown
## 硬约束执行检查
- [✓/✗] 1. 意图不清必问
- [✓/✗] 2. 子 agent model 显式指定（frontmatter + spawn 时双校验）
- [✓/✗] 3. token 预算
- [✓/✗] 4. 暴露冲突
- [✓/✗] 5. 先读再写
- [✓/✗] 6. 测试验证意图
- [✓/✗] 7. 长任务检查点
- [✓/✗] 8. 惯例优先
- [✓/✗] 9. 失败显性化
- [✓/✗] 10. 外科手术式修改
- [✓/✗] 11. 简洁优先
- [✓/✗] 12. 编码前先思考
- [✓/✗] 13. Edit 前 grep 同类模式
- [✓/✗] 14. 单条消息并发 ∈ [3, 5]
```

任一 ✗ 必须在汇报里解释。

## TODO（待 step 2 扩充）

- [ ] 每条约束的 3 个真实 case
- [ ] 子 agent 如何自检这 14 条
- [ ] 与 reviewer 的协作（reviewer 查哪几条）

## 引用

- design.md §2 + §4（SKILL.md §4 摘要）
- `~/.claude/CLAUDE.md` coding-rules.md（R1-R12 原文）
- v7.1 #14 来源：Anthropic parallel exploration best practice + coding-rules R5.1（model 显式）
