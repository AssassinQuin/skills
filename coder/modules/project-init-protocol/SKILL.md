---
name: project-init-protocol
description: 项目初始化协议（v5.0+ 2026-06-25）。三层架构 / init 命令 / 智能合并 / hook 强制清单 / git 分支管理。
source: ".deepen/20260625-project-init/design.md"
status: active
tokens_estimate: 2500
load_priority: on-demand
load_when: "项目 init / 查 init 协议"
keywords: project init three-layer intelligent-merge oh-story-claude hooks scripts branch.sh
domain: coding
subdomain: protocol
parent_skill: coder
version: "1.0"
license: Apache-2.0
frameworks:
  twelve_factor:
    - I. Codebase - 一份 codebase 多部署
    - V-config
  notes: "oh-story-claude intelligent merge + 项目级配置"
---

# 项目初始化协议（v5.0+）

> SKILL.md §12 的完整版。

## 1. 三层金字塔

```
coder skill (最小本体, ≤400 行 router)
  ↓ scripts/init-project.{sh,py}
项目 .claude/ (智能合并生成，git-trackable)
  ↓ 跨 session 沉淀
memory MCP (coder-protocol / coding-{lang}-*)
```

## 2. 何时触发 init

| 场景 | 行为 |
|---|---|
| 显式：用户跑 `bash coder/scripts/init-project.sh` | 全量生成 / 智能合并 |
| 隐式：coder 第一次在某项目跑且 `.coder-initialized.json` 不存在 | orchestrator AskUserQuestion："是否生成项目配置？" |

## 3. init 生成内容

| 文件 | 用途 | 智能合并策略 |
|---|---|---|
| `.claude/agents/{lang}-coder-project.md` | 项目语言 agent | markers 之间合并 |
| `.claude/agents/project-reviewer.md` | 项目特定 reviewer | markers 之间合并 |
| `.claude/hooks/*.sh`（9 个） | 强制流程 hook | 直接覆盖 |
| `.claude/scripts/git/branch.sh` | git 分支管理 | 直接覆盖 |
| `.claude/scripts/coder-state.{sh,py}` | v6.0 state 管理 | 直接覆盖 |
| `.claude/scripts/validate-delivery.py` | Phase 4.5 校验 | 直接覆盖 |
| `.claude/settings.json` | hooks 配置 | JSON patch（按 command 去重） |
| `CLAUDE.md` | 项目级最小流程 | markers 之间合并 |
| `.claude/.coder-initialized.json` | init 元数据 | 直接覆盖 |
| `.claude/coder-state/{specs-active,archive}/` | state 目录 | mkdir |

## 4. 智能合并策略（参考 oh-story-claude）

### 4.1 markers 合并（CLAUDE.md / agent 文件）

```markdown
<!-- coder-init: project-context start -->
（init 管理，可重新生成）
<!-- coder-init: project-context end -->

（用户内容，保留）
```

### 4.2 settings.json 合并

`jq` patch：按 command 字段去重，backup 后合并。

### 4.3 幂等性

重复跑 init 不覆盖用户改动（markers 之外保留）。

## 5. Hook 强制清单（v5.0+ + v6.0）

| Hook | 强制度 | 作用 |
|---|---|---|
| `edit-guard.sh` | block（可降级） | 拦违反 §2.2 / 硬约束 #13 |
| `git-guard.sh` | block（critical）/ warn | 拦危险 git 命令 |
| `phase-guard.sh` | warn（可升级 block） | Phase 状态守卫 + spawn trace |
| `spec-guard.sh` | warn（可升级 block） | 无 spec 拦代码 Edit |
| `signature-guard.sh` | 强制（必签 Phase） | Phase 完成前检查签字 |
| `task-progress-guard.sh` | warn（可升级 block） | spawn 前 task 登记 |
| `spawn-trace.sh` | hint | 记录 spawn + grep |
| `session-resume.sh` | hint | v6.0 断点续跑检测 |
| `session-load.sh` | hint | v5.0+ 项目元信息 |

## 6. Git 分支管理（v5.0+ §12.9）

### 6.1 分支命名规范

| Type | 命名 | 场景 |
|---|---|---|
| `feature/{issue-id}-{slug}` | `feature/PROJ-123-add-login` | 新功能 |
| `fix/{issue-id}-{slug}` | `fix/456-null-pointer` | bug 修复 |
| `hotfix/{slug}` | `hotfix/security-patch` | 紧急修复 |
| `release/{version}` | `release/v2.0` | 发布分支 |
| `experiment/{slug}` | `experiment/try-new-lib` | 实验性（先 `save` 备份） |

### 6.2 branch.sh 入口

`bash .claude/scripts/git/branch.sh <command>`：

| Command | 作用 |
|---|---|
| `new <type> <slug> [--from <base>]` | 创建分支（强制命名 + require_clean_worktree） |
| `switch <name>` | 安全切换（支持简写 / 模糊匹配） |
| `merge <branch> [--no-ff\|--squash]` | 合并（默认 --no-ff + 主干二次确认） |
| `cleanup [--remote]` | 清理已合并（交互确认 + 可选 prune） |
| `status` | 健康检查（ahead/behind/merged + 未提交 + stash） |
| `save <label>` | 备份（tag + stash，reset 前必须用） |
| `restore <label>` | 从备份恢复 |
| `list` | 列出所有分支 + backup/* tags |

### 6.3 git-guard.sh 拦截规则

| 命令 pattern | 级别 |
|---|---|
| `git push --force/-f` 到 protected | **critical** |
| `git push --force-without-lease` | **critical** |
| `git push --force/-f`（feature 分支） | warning |
| `git reset --hard` | **critical** |
| `git clean -f/-fd/-fdx` | **critical** |
| `git branch -D` | **critical** |
| `git checkout .` / `git restore .` | **critical** |
| `git commit --no-verify/--no-gpg-sign` | **critical** |
| `git rebase -i` | warning |
| `git filter-branch` | **critical** |
| `git reflog expire --expire-unreachable` | **critical** |
| `git update-ref HEAD` | **critical** |

## 7. 项目 agent 继承

项目 agent（如 `go-coder-project.md`）**继承** coder 自带的通用 agent（`agents/go-coder.md`）：
- 通用规则自动生效
- 项目 agent 只声明项目特定差异
- 通用 agent 升级时项目自动受益

Phase 2 语言路由：
- 项目 `.claude/agents/{lang}-coder-project.md` 存在 → spawn 项目版
- 不存在 → spawn 通用版（`agents/{lang}-coder.md`）

## 8. memory MCP 沉淀

| tag | tier | 何时写 |
|---|---|---|
| `coder-protocol` | 共享级 | init 哲学 + 三层架构（init 时写一次） |
| `coder-user-pref` | 全局级 | 用户偏好（hook 强制度 / 是否提示 init） |
| `coder-execution-drift` | 共享级 | 每次执行的协议偏离 |
| `coding-{lang}-gotcha` | 项目级 | reviewer 发现的项目特定坑 |

## 9. 卸载

```bash
rm -rf .claude/  # 删除所有 init 生成物
# CLAUDE.md markers 之间内容手动清理
```

## 10. init 命令完整用法

```bash
bash ~/.claude/skills/coder/scripts/init-project.sh [project_dir] [flags]

# flags
--dry-run        # 只打印，不写文件
--force          # 强制覆盖 managed section
--lang=<X>       # 覆盖语言检测（go/python/typescript/rust）
```
