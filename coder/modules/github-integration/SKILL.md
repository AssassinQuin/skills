---
name: github-integration
description: github MCP 集成 — issues/PR/code search 触发条件 + 工具白名单（仅 orchestrator）。
source: "design.md §7.4"
status: skeleton
tokens_estimate: 600
load_priority: on-demand
load_when: "任务涉及 issue/PR/上游"
keywords: github MCP PR issue release upstream
domain: coding
subdomain: mcp
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  notes: "Git workflow + PR/issue tracking"
---

# github MCP 集成（触发式）

> **加载时机**：任务涉及 issue/PR 编号 / 修 bug 需看 issue / 查上游写法。

## 触发条件

- 任务提到 issue / PR 编号（"修复 #123" / "合并 PR #45"）
- 修复 bug 需要看 issue 上下文
- 需要查上游 repo 写法（reference impl）
- 任务跨多 repo

## 工具清单

| 工具 | 用途 |
|---|---|
| `get_file_contents` | 拉上游 repo 文件（参考实现）|
| `search_code` | 跨 repo 搜代码模式 |
| `issue_read` (method=get / get_comments) | 读 issue 详情 + 评论 |
| `pull_request_read` (method=get / get_diff / get_files) | 读 PR 详情 + diff |
| `list_issues` / `list_pull_requests` | 批量查 |
| `search_repositories` | 找相关 repo |

## 调用者（仅 orchestrator）

**不暴露给编码子 agent**（避免误改 remote）。

orchestrator 调用后，把结果作为"上下文"注入子 agent prompt。

## 典型场景

### 场景 1: 修复 issue

```
用户: "修复 #123 的崩溃"

orchestrator:
  1. issue_read(owner, repo, 123, method="get")
  2. issue_read(..., method="get_comments")
  3. 综合为 issue 上下文
  4. 注入 Phase 0 意图声明
  5. 进入 Phase 1
```

### 场景 2: 查上游写法

```
用户: "我们这个 auth 模块实现的对吗？"

orchestrator:
  1. search_repositories("auth gin golang")
  2. 找到参考 repo
  3. get_file_contents 拉参考实现
  4. 注入 Phase 3 oracle prompt 作为参考
```

### 场景 3: PR 审查

```
用户: "review PR #45"

orchestrator:
  1. pull_request_read(..., method="get_diff")
  2. pull_request_read(..., method="get_files")
  3. 用 Phase 5 流程（3 reviewer 并发）
  4. 产出审查报告
  5. 可选: add_comment_to_pending_review
```

## 降级

| 场景 | 降级 |
|---|---|
| github MCP 不可用 | 提示用户手动看 issue / PR + ⚠️ |
| 无网络 | ⚠️ + 继续（不依赖 github）|

## 权限注意

- 只读操作（read / list / search）：默认安全
- 写操作（comment / merge / close）：🔒 必须用户确认（CLAUDE.md "Actions visible to others"）

## TODO（待 step 2 扩充）

- [ ] 5 个典型场景的完整 prompt 模板
- [ ] github token 权限要求清单
- [ ] 与 code-review skill 的边界

## 引用

- design.md §7.4
- `phase-0-intent-capture.md`（issue 上下文注入意图）
- `phase-5-verification.md`（PR 审查走 reviewer 并发）
