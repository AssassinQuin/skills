#!/usr/bin/env bash
# git-guard.sh — coder PreToolUse hook for Bash
#
# 拦截 Claude Code 执行的危险 git 命令，避免不可逆操作：
#   - git push --force / -f 到 protected branch（main / master / release/*）
#   - git push --force-without-lease（任何分支）
#   - git reset --hard
#   - git clean -fdx / -fd
#   - git branch -D / --delete --force
#   - git checkout . / git restore .
#   - git commit --no-verify / --no-gpg-sign
#   - git rebase -i（interactive）
#   - git filter-branch / git reflog expire --expire-unreachable
#
# 强制度：默认 block，CODER_GIT_GUARD=warn 降级，=off 关闭
# 白名单：CODER_GIT_GUARD_ALLOW=<regex> 允许特定命令（如 dev 仓库）
#
# Claude Code hook 协议：
#   stdin JSON: {tool_name, tool_input: {command: "..."}, session_id, cwd}
#   exit 2 + stdout JSON {decision: "block", reason: "..."} → block
#   exit 0 + stdout JSON {hookSpecificOutput: {additionalContext: "..."}} → warn hint

set -euo pipefail

MODE="${CODER_GIT_GUARD:-block}"
[[ "$MODE" == "off" ]] && exit 0

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

[[ "$TOOL_NAME" == "Bash" ]] || exit 0

CMD="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"
[[ -n "$CMD" ]] || exit 0

# 只关心含 git 的命令
echo "$CMD" | grep -qE '(^|;|&&|\|\|)\s*git\s' || exit 0

# ---- 白名单 ----
if [[ -n "${CODER_GIT_GUARD_ALLOW:-}" ]]; then
  if echo "$CMD" | grep -qE "$CODER_GIT_GUARD_ALLOW"; then
    exit 0
  fi
fi

# ---- 危险命令检测 ----
# 违规级别：critical（block）/ warning（warn）
VIOLATION=""
SEVERITY=""
REASON=""

# Helper: 检测命令里是否有 pattern
matches() {
  echo "$CMD" | grep -qE "$1"
}

# 1. force push 到 protected branch
PROTECTED='(main|master|release/[^ ]+|prod|production)'
if matches "git\s+push\s+.*(-f|--force|--force-without-lease).*\s+(origin\s+)?(${PROTECTED})(\s|$)"; then
  VIOLATION="force-push-protected"
  SEVERITY="critical"
  REASON="force push 到 protected branch（${PROTECTED}）。这会覆盖远端历史，可能丢失他人提交。"
elif matches "git\s+push\s+.*--force-without-lease"; then
  VIOLATION="force-without-lease"
  SEVERITY="critical"
  REASON="--force-without-lease 已禁用（即使在 feature 分支也建议改用 --force-with-lease）。"
elif matches "git\s+push\s+.*(-f|--force)(\s|$)"; then
  # 普通分支 force push：warn（不是 block）
  VIOLATION="force-push"
  SEVERITY="warning"
  REASON="force push 会覆盖远端历史。确认远端没有他人新提交？建议 --force-with-lease。"
fi

# 2. reset --hard
if [[ -z "$VIOLATION" ]] && matches "git\s+reset\s+--hard"; then
  VIOLATION="reset-hard"
  SEVERITY="critical"
  REASON="git reset --hard 会丢弃所有未提交改动且不可恢复。建议先 bash .claude/scripts/git/branch.sh save <label> 备份。"
fi

# 3. clean -fd / -fdx
if [[ -z "$VIOLATION" ]] && matches "git\s+clean\s+.*-(-force|f).*[fd]"; then
  VIOLATION="clean-force"
  SEVERITY="critical"
  REASON="git clean -f 会删除未跟踪文件（不可恢复）。如 -x 还会删 gitignore 的文件。"
fi

# 4. branch -D（force delete）
if [[ -z "$VIOLATION" ]] && matches "git\s+branch\s+.*-D\b"; then
  VIOLATION="branch-force-delete"
  SEVERITY="critical"
  REASON="git branch -D 强制删除分支（即使有未合并 commits）。建议先用 git branch --merged 检查，再用 -d（小写）安全删除。"
fi

# 5. checkout . / restore .
if [[ -z "$VIOLATION" ]] && matches "git\s+(checkout|restore)\s+\.\s*$"; then
  VIOLATION="discard-worktree"
  SEVERITY="critical"
  REASON="git checkout . / restore . 丢弃所有未提交改动（不可恢复）。建议先 commit 到 WIP 分支或 stash。"
fi

# 6. commit --no-verify / --no-gpg-sign
if [[ -z "$VIOLATION" ]] && matches "git\s+commit\s+.*(--no-verify|--no-gpg-sign|-c\s+commit\.gpgsign=false)"; then
  VIOLATION="skip-hooks"
  SEVERITY="critical"
  REASON="跳过 pre-commit hook / 签名。hooks 存在是有原因的（lint / 类型检查 / 安全扫描），跳过可能导致 CI 失败或安全漏洞。"
fi

# 7. rebase -i（interactive）
if [[ -z "$VIOLATION" ]] && matches "git\s+rebase\s+.*-i\b.*--no-edit"; then
  VIOLATION="rebase-interactive-no-edit"
  SEVERITY="critical"
  REASON="git rebase --no-edit 是无效组合（rebase -i 需要交互编辑器）。"
elif [[ -z "$VIOLATION" ]] && matches "git\s+rebase\s+.*\s-i\b"; then
  VIOLATION="rebase-interactive"
  SEVERITY="warning"
  REASON="git rebase -i 在自动化环境里不可用（需要交互编辑器）。改用非交互式 rebase 或 git rebase --onto。"
fi

# 8. filter-branch / reflog expire
if [[ -z "$VIOLATION" ]] && matches "git\s+filter-branch"; then
  VIOLATION="filter-branch"
  SEVERITY="critical"
  REASON="git filter-branch 会重写历史（已废弃，建议 git filter-repo）。"
fi
if [[ -z "$VIOLATION" ]] && matches "git\s+reflog\s+expire\s+.*--expire-unreachable"; then
  VIOLATION="reflog-expire"
  SEVERITY="critical"
  REASON="reflog expire --expire-unreachable 会丢失 unreachable commits（reset --hard 后唯一恢复途径）。"
fi

# 9. update-ref / symbolic-ref（覆盖 HEAD）
if [[ -z "$VIOLATION" ]] && matches "git\s+update-ref\s+.*HEAD"; then
  VIOLATION="update-ref-head"
  SEVERITY="critical"
  REASON="git update-ref HEAD 直接覆盖 HEAD 引用。用 git checkout / git switch 更安全。"
fi

# ---- 输出决策 ----
if [[ -z "$VIOLATION" ]]; then
  exit 0
fi

if [[ "$SEVERITY" == "critical" ]]; then
  if [[ "$MODE" == "block" ]]; then
    cat <<EOF | jq -c '.'
{
  "decision": "block",
  "reason": "[coder git-guard ${VIOLATION}] ${REASON}\n\n如果你想继续，可以：\n  1. 改用安全替代方案（见上述提示）\n  2. 临时降级：CODER_GIT_GUARD=warn claude-code\n  3. 加入白名单：CODER_GIT_GUARD_ALLOW='${VIOLATION}' claude-code\n  4. 完全关闭：CODER_GIT_GUARD=off claude-code",
  "suppress_output": false
}
EOF
    exit 2
  else
    # warn 模式
    cat <<EOF | jq -c '.'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "⚠️ [coder git-guard ${VIOLATION} warn] ${REASON}"}}
EOF
    exit 0
  fi
else
  # warning 级别：始终 hint（不 block）
  cat <<EOF | jq -c '.'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "⚠️ [coder git-guard ${VIOLATION}] ${REASON}"}}
EOF
  exit 0
fi
