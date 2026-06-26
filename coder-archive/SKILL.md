---
phase: 7
name: coder-archive
description: Phase 7 归档（含 post-mortem + handoff 段）。orchestrator 收尾：signature 终验 + archive.md 生成 + state 清除 + memory MCP 沉淀 + MASTER.md 索引。
source: "v6-execution-protocol/SKILL.md §11 + coder/SKILL.md §2 Phase 7 行（v7.2 抽出为独立 first-class skill）"
status: active
tokens_estimate: 800
load_priority: on-demand
load_when: "进入 Phase 7（orchestrator 全流程收尾）"
keywords: archive post-mortem handoff signature state cleanup memory persistence
domain: coding
subdomain: phase
parent_skill: coder
version: "1.1"
license: Apache-2.0
frameworks:
  twelve_factor:
    - V. Build/Release/Run - 严格分离三阶段
  notes: "Phase 7 = Build（archive）→ Release（memory MCP）→ Run（下次任务复用）"
---

# Coder-Archive: Phase 7 归档（v7.2 从 v6-execution-protocol §11 抽出）

> **加载时机**：Phase 6 用户在 delivery-checklist 签字后，orchestrator 进入 Phase 7。
> v7.2：从 v6-execution-protocol §11 抽出为独立 first-class skill。

## 6 步归档流程

```
1. signature-guard.sh verify（检查所有必签 Phase 都已签：0 / 3 / 5 / 6）
2. 生成 archive.md（Phase 历史 + tasks 摘要 + handoff 段 + post-mortem 段）
3. mv specs-active/{ts}-{slug}/ archive/
4. 清除 current.json（释放"当前任务"指针）
5. 更新 MASTER.md 索引（追加本次 task + 链接到 archive.md）
6. memory MCP 写关键决策（shared tag）+ 失败教训（gotcha tag）
```

## archive.md 必含段（v6.3 from mattpocock handoff）

```markdown
# Archive: {ts}-{slug}

## Task 摘要
- 用户请求: {原话}
- 实际改动: {N 文件 / M LOC / 语言}
- Phase 跳过: {列表 + 原因}

## Phase 历史
| Phase | 输出 | 签字 |
|---|---|---|
| 0 | spec.md | ✓ |
| 3 | design.md | ✓ |
| 5 | review-report.md | ✓ |
| 6 | delivery-checklist.md | ✓ |

## Handoff（交接给下次任务/接手人）
- 当前状态: {stable / partial / blocked}
- 未做完: {列表}
- 已知 issue: {列表}
- 关键文件: {入口路径}

## Post-mortem（v6.3 from mattpocock）
- 做对了: {3-5 条}
- 做错了: {1-3 条，含根因}
- 下次再做类似任务: {建议}
```

## signature-guard 必签清单

| Phase | 必签条件 |
|---|---|
| 0 | spec.md 已生成 + 用户在 spec-signature.json 签字 |
| 3 | design.md 已生成 + 用户选定方案（非简单任务才必签） |
| 5 | ≥1 reviewer 跑完 + 用户在 review-signature.json 签字 |
| 6 | delivery-checklist 所有项满足 + 用户在 final-signature.json 签字 |

未签 → archive **不允许**进行（persistence-guard hook 拦截）。

## memory MCP 沉淀规则

**写**（shared tier）：
- `coding-{lang}-convention` / `-trap` / `-tooling` / `-verification`：本次发现的新 convention/trap
- `coding-super-decay`：S.U.P.E.R 衰减记录
- `coding-user-pref`：用户偏好（如"不喜欢某命名风格"）

**写**（project tier）：
- `coding-{lang}-gotcha`：项目专属坑
- `coding-audit-finding`：reviewer 发现

**禁止**：把 ephemeral task 细节写入 memory（仅 archive.md 记）。

## 降级

| 场景 | 降级 | 标注 |
|---|---|---|
| memory MCP 不可用 | 跳过 step 6 | ⚠️ "本次未沉淀到 memory" |
| signature-guard 报告缺签 | **不允许降级** | 🔒 严禁静默 archive |
| archive 目录权限不足 | 暂存到 /tmp + ⚠️ | 用户手动 mv |

**绝不静默降级**（R12）。

## Verification（如何确认本 Phase 成功）

- [ ] 所有必签 Phase 都已签字（signature-guard verify PASS）
- [ ] archive.md 已生成（含 handoff + post-mortem 段）
- [ ] specs-active/{ts}-{slug}/ 已 mv 到 archive/
- [ ] current.json 已清除
- [ ] MASTER.md 索引已更新
- [ ] memory MCP 已写关键决策（或显式标注 fallback）

## 引用

- v6-execution-protocol/SKILL.md §11（v7.2 之前的原始位置）
- coder/SKILL.md §2 Phase 7 行
- coder-persist（Phase 6 持久化，本 Phase 的前驱）
- mattpocock handoff skill（archive.md 模板来源）
