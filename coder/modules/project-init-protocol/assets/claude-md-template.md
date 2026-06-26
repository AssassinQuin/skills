# CLAUDE.md — {{PROJECT_NAME}}

> 由 coder init 生成于 {{DATE}}（coder v{{CODER_VERSION}}）。
> markers 之间的内容由 init 管理，其他内容可以自由编辑。

---

<!-- coder-init: project-context start -->

## 项目元信息

- **主语言**：{{PRIMARY_LANG}}
- **语言版本**：{{LANG_VERSION}}
- **包管理**：{{PKG_MANAGER}}
- **主框架**：{{FRAMEWORK}}
- **测试命令**：{{TEST_CMD}}
- **lint 命令**：{{LINT_CMD}}
- **构建命令**：{{BUILD_CMD}}

## 项目模块边界

{{MODULE_BOUNDARIES}}

## 常用 make/script targets

{{COMMON_TARGETS}}

## 项目特定硬约束

{{PROJECT_HARD_CONSTRAINTS}}

<!-- coder-init: project-context end -->

---

## 编码流程（v6.0 11 Phase 流水线）

本项目的编码任务**必须**走 coder skill 的 11 Phase 流水线：

```
Phase -1: 断点检测（SessionStart 自动）
Phase 0:  需求确认（多轮 AskUserQuestion + spec.md + 用户签字）
Phase 0.5: 复用 + 替代分析（explorer + researcher + oracle 并发）
Phase 1:  元数据 + 架构（explorer + get_architecture + researcher 并发）
Phase 2:  语言路由
Phase 3:  设计方案 + test-plan（N oracle 并发，复杂任务）
Phase 4:  执行（多 {lang}-coder-project 并发，按文件分组）
Phase 4.5: 子 agent 交付检查（validate-delivery.py）
Phase 5:  验证（3 reviewer 并发 + test-runner）
Phase 6:  持久化 + delivery-checklist（用户验收）
Phase 7:  归档
```

**用户主导**（Phase 0/3/5/6 必签字）：
- Phase 0 完成 → 用户确认 spec.md
- Phase 3 完成 → 用户选 design + test-plan
- Phase 5 完成 → 用户确认通过
- Phase 6 完成 → 用户验收 delivery-checklist

**Phase 4 执行**：
- 改动 >1 文件 或 >20 行 → MUST spawn `{lang}-coder-project` 子 agent（项目版）
- 多文件改动 → 按文件分组并发 spawn（上限 5 个）
- 每个子 agent 必须返回 `delivery-schema.yaml` 格式
- 改动 1 文件 <20 行 且 无第三方库语法 → orchestrator 可直编，但**必须**即时标注 `⚠️ orchestrator_direct_coding`

**Phase 4.5 子 agent 交付检查**：
- 每个子 agent 的 delivery 跑 `python3 .claude/scripts/validate-delivery.py`
- 7 条校验规则（字段齐全 / files vs git diff / drift < 0.4 / verification PASS / deps / caveats / focus_areas）
- 不合格 → 返工

**Phase 5 验证**：
- MUST spawn 至少 1 个 `project-reviewer` 子 agent（项目特定 reviewer，知道本项目的 codestyle）
- 测试通过 ≠ 验证通过
- test-runner 按 Phase 3 的 `test-plan.md` 跑测试

**Edit 前**：
- MUST grep 同类模式（硬约束 #13）：`grep -rn '{pattern}' {{SOURCE_DIR}}/`
- 防止「只修一处」漏修

**断点续跑**（v6.0）：
- 所有进度持久化到 `.claude/coder-state/current.json`
- SessionStart hook 自动检测并提示续跑
- 手动：`bash .claude/scripts/coder-state.sh show / resume / archive / abandon`
- 状态命令：`bash .claude/scripts/coder-state.sh <init|show|update-phase|add-task|update-task|checkpoint|resume|archive|abandon>`

---

## 项目特定踩坑（init 时扫描 + 持续沉淀）

{{INITIAL_GOTCHAS}}

> 后续 reviewer 发现的新坑，写到 memory MCP `coding-{{PRIMARY_LANG}}-gotcha` tag。

---

## Hook 配置（强制流程）

本项目启用了以下 hook（见 `.claude/settings.json`）：

| Hook | 强制度 | 作用 |
|---|---|---|
| PreToolUse Edit/Write | **block** | 违反 §2.2（orchestrator 直编限制）或硬约束 #13（Edit 前 grep）时阻断 |
| PreToolUse Bash (git-guard) | **block** | 拦截危险 git 命令：force push / reset --hard / clean -fd / branch -D / commit --no-verify / checkout . / rebase -i 等 |
| PostToolUse Agent | hint | 记录 spawn trace 到 `.claude/coder-trace.jsonl` |
| SessionStart | hint | 自动加载项目 memory + 显示上次未完任务 |

降级：
- edit-guard: `CODER_HOOK_MODE=warn` 把 block 降为 warn
- git-guard: `CODER_GIT_GUARD=warn` 降级，`=off` 关闭
- git-guard 白名单: `CODER_GIT_GUARD_ALLOW='<regex>'` 允许特定命令

---

## Git 分支管理（由 coder init 提供）

**分支命名规范**（强制）：

```
feature/{issue-id}-{slug}     # 新功能（例：feature/PROJ-123-add-login）
fix/{issue-id}-{slug}         # bug 修复（例：fix/456-null-pointer）
hotfix/{slug}                 # 紧急修复（例：hotfix/security-patch）
release/{version}             # 发布分支（例：release/v2.0）
experiment/{slug}             # 实验性，可丢弃（例：experiment/try-new-lib）
```

**统一入口**：`bash .claude/scripts/git/branch.sh <command>`

| Command | 作用 |
|---|---|
| `new <type> <slug> [--from <base>]` | 创建分支（强制命名规范 + 安全检查未提交改动） |
| `switch <name>` | 安全切换（支持简写 / 模糊匹配，未提交改动会先报错） |
| `merge <branch> [--no-ff\|--squash]` | 合并（默认 `--no-ff` 保留 merge commit） |
| `cleanup [--remote]` | 清理已合并的本地分支（交互确认 + 可选 prune remote） |
| `status` | 分支健康检查（每个分支与 main 的 ahead/behind/merged 关系） |
| `save <label>` | 备份当前状态（branch + tag + stash，不可恢复操作前用） |
| `restore <label>` | 从备份恢复（reset --hard 前必须有备份） |
| `list` | 列出所有分支 + 备份 tags |

**典型工作流**：

```bash
# 1. 开始新 feature
bash .claude/scripts/git/branch.sh new feature PROJ-123-add-login

# 2. 写代码（hook 自动拦截危险 git）

# 3. 合并前先 status 看分支关系
bash .claude/scripts/git/branch.sh status

# 4. 切回 main 合并
bash .claude/scripts/git/branch.sh switch main
bash .claude/scripts/git/branch.sh merge feature/PROJ-123-add-login

# 5. 清理已合并分支
bash .claude/scripts/git/branch.sh cleanup

# experiment 前先备份
bash .claude/scripts/git/branch.sh save before-rewrite
# ... 做 experiment ...
bash .claude/scripts/git/branch.sh restore before-rewrite
```

**禁止**（git-guard 拦截）：
- `git push --force` 到 main / master / release/*
- `git reset --hard`（先 `branch.sh save` 备份）
- `git clean -fd` / `git branch -D`
- `git commit --no-verify`（跳过 hooks）
- `git checkout .` / `git restore .`（丢弃工作区）

---

## 与 coder skill 的关系

- **coder skill 本体**：通用 7 Phase + 13 硬约束（不变）
- **本项目 CLAUDE.md（本文件）**：项目特定差异 + 项目级流程
- **项目 memory**：跨 session 的项目踩坑（在 memory MCP）

coder 在本项目跑时，会自动加载本文件作为项目上下文。
