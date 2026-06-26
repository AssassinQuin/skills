#!/usr/bin/env bash
# edit-guard.sh — coder PreToolUse hook for Edit / Write
#
# 拦截违反 coder 协议的 Edit/Write 调用：
#   1. 硬约束 #13：Edit 前需有 grep 同类模式痕迹
#   2. §2.2 orchestrator 直编限制：>1 文件 / >20 行 无 spawn → block
#   3. §11.6 简单任务滑坡：连续 Edit 无 Phase 1 → warn
#
# 强制度：默认 block，CODER_HOOK_MODE=warn 降级为 warn，=off 关闭
#
# Claude Code hook 协议：
#   - stdin: JSON with tool_name, tool_input, session_id, cwd
#   - exit 2 + stdout JSON {"decision": "block", "reason": "..."} → block
#   - exit 0 + stdout JSON {"hookSpecificOutput": {...}} → passthrough with hint

set -euo pipefail

MODE="${CODER_HOOK_MODE:-block}"

# 关闭模式直接放行
[[ "$MODE" == "off" ]] && exit 0

# 读 stdin
INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

# 只拦 Edit / Write / MultiEdit
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty')"
TRACE_FILE="${CWD}/.claude/coder-trace.jsonl"
EDIT_COUNT_FILE="${CWD}/.claude/.coder-edit-counter"

# 没初始化的项目不拦（未跑 coder init）
[[ -f "${CWD}/.claude/.coder-initialized.json" ]] || exit 0

# ---- 检查 1：本次会话 Edit 文件数 / spawn 数 ----
# 用 session_id 隔离的 edit-counter（v6.1 强化，避免多 session 串扰）
mkdir -p "${CWD}/.claude"
EDIT_COUNT_FILE="${CWD}/.claude/.coder-edit-counter-${SESSION_ID}"

EDIT_COUNT=0
[[ -f "$EDIT_COUNT_FILE" ]] && EDIT_COUNT=$(cat "$EDIT_COUNT_FILE" 2>/dev/null || echo 0)
EDIT_COUNT=$((EDIT_COUNT + 1))
echo "$EDIT_COUNT" > "$EDIT_COUNT_FILE"

# 统计本次会话 spawn 数（trace 文件按 session_id 过滤）
SPAWN_COUNT=0
if [[ -f "$TRACE_FILE" ]]; then
  SPAWN_COUNT=$(jq -r --arg sid "$SESSION_ID" 'select(.session_id == $sid) | .agent_name' "$TRACE_FILE" 2>/dev/null | wc -l | tr -d ' ')
fi

# ---- 决策（v6.1 强化梯度）----
# - 第 1-2 次 Edit 无 spawn → 不拦（容忍单文件 typo）
# - 第 3 次 Edit 无 spawn → block（§11.6 滑坡防范）
# - >5 次 + 0 spawn → block + drift 提示
VIOLATION=""
REASON=""

if [[ $EDIT_COUNT -ge 3 && $SPAWN_COUNT -lt 1 ]]; then
  VIOLATION="section-2.2"
  if [[ $EDIT_COUNT -ge 3 && $EDIT_COUNT -le 5 ]]; then
    REASON="本次会话已连续 ${EDIT_COUNT} 次 Edit 但未 spawn 任何子 agent（§11.6 简单任务滑坡）。coder §2.2：>1 文件 / >20 行 MUST spawn {lang}-coder 子 agent。请 spawn 子 agent 后再继续；或单文件 typo 显式设 CODER_HOOK_MODE=off 跳过。"
  else
    REASON="本次会话已 Edit ${EDIT_COUNT} 次但未 spawn 任何子 agent。严重违反 §2.2，必须 spawn 子 agent。如继续直编 → 主上下文污染 + reviewer 无法独立审查（§11.2 反例）。"
  fi
fi

# ---- 检查 2：硬约束 #13（Edit 前 grep）—— 简化版：检查会话历史有 Bash grep 痕迹 ----
# 完整实现需要 hook context 注入 conversation 历史，这里先放 warn 级
if [[ -z "$VIOLATION" ]]; then
  # 检查 trace 文件最近 5 分钟内是否有 grep 痕迹（spawn-trace 也记录 Bash 调用）
  RECENT_GREP=0
  if [[ -f "$TRACE_FILE" ]]; then
    RECENT_GREP=$(jq -r --arg sid "$SESSION_ID" '
      select(.session_id == $sid)
      | select(.tool == "Bash")
      | select(.command | test("grep|rg |ag "))
      | .timestamp' "$TRACE_FILE" 2>/dev/null | tail -5 | wc -l | tr -d ' ')
  fi
  # 不强制 block（历史数据不全），只在 EDIT_COUNT 较大时 warn
  if [[ $EDIT_COUNT -ge 3 && $RECENT_GREP -lt 1 ]]; then
    REASON="⚠️ 提示：连续 ${EDIT_COUNT} 次 Edit 但未观察到 grep 同类模式（硬约束 #13）。建议 Edit 前 grep 一下横向排查。"
    # warn 级，不 block
    if [[ "$MODE" == "warn" || "$MODE" == "block" ]]; then
      cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "${REASON}"}}
EOF
      exit 0
    fi
  fi
fi

# ---- 输出决策 ----
if [[ -n "$VIOLATION" ]]; then
  if [[ "$MODE" == "block" ]]; then
    # block
    cat <<EOF
{"decision": "block", "reason": "[coder §${VIOLATION}] ${REASON}", "suppress_output": false}
EOF
    exit 2
  else
    # warn 模式：放行但提示
    cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "⚠️ [coder §${VIOLATION} warn] ${REASON}"}}
EOF
    exit 0
  fi
fi

exit 0
