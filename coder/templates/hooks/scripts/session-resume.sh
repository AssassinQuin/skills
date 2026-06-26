#!/usr/bin/env bash
# session-resume.sh — coder v7.4 SessionStart hook（集成 state machine）
#
# 检测 .claude/coder-state/current.json：
#   - 存在 → 输出 additionalContext 显示：
#     * state_machine（v7.4 新）
#     * spec_id / current_phase
#     * state_history 末尾 3 条（v7.4 新）
#     * needs_info 暂停态提示（v7.4 新）
#     * 进度统计 + drift 提示
#     * AskUserQuestion 续跑/重开指令
#   - 不存在 → 走 v5.0+ 的 session-load.sh
#
# 强制度：默认 hint（不 block），CODER_RESUME_MODE=off 关闭

set -euo pipefail

MODE="${CODER_RESUME_MODE:-hint}"
[[ "$MODE" == "off" ]] && exit 0

CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_FILE="${CWD}/.claude/coder-state/current.json"

# 未初始化的项目直接放行
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# 读 state 关键字段
SPEC_ID="$(jq -r '.spec_id // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"
SPEC_SLUG="$(jq -r '.spec_slug // "?"' "$STATE_FILE" 2>/dev/null || echo "?")"
CURRENT_PHASE="$(jq -r '.current_phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"
STATE_MACHINE="$(jq -r '.state_machine // "new"' "$STATE_FILE" 2>/dev/null || echo "new")"
STARTED_AT="$(jq -r '.started_at // "?"' "$STATE_FILE" 2>/dev/null || echo "?")"
LAST_ACTIVE="$(jq -r '.last_active // "?"' "$STATE_FILE" 2>/dev/null || echo "?")"

# state emoji mapping
state_emoji() {
  case "$1" in
    new) echo "🆕" ;;
    triaging) echo "🔍" ;;
    designing) echo "🎨" ;;
    implementing) echo "🔧" ;;
    reviewing) echo "🔬" ;;
    delivered) echo "📦" ;;
    archived) echo "🗄️" ;;
    needs_info) echo "❓" ;;
    abandoned) echo "💀" ;;
    *) echo "❓" ;;
  esac
}
STATE_EMOJI=$(state_emoji "$STATE_MACHINE")

# state_history 末尾 3 条
HISTORY_LINES=$(jq -r '
  (.state_history // []) | .[-3:][] |
  "  \(.ts[0:19])  \(.from) → \(.to)\(if .note then "  // \(.note)" else "" end)"
' "$STATE_FILE" 2>/dev/null || echo "  （无历史）")

# needs_info 提示
NEEDS_INFO_HINT=""
if [[ "$STATE_MACHINE" == "needs_info" ]]; then
  PREV_STATE=$(jq -r '.needs_info_prev_state // "?"' "$STATE_FILE" 2>/dev/null || echo "?")
  LAST_NOTE=$(jq -r '(.state_history // []) | last | .note // "(无备注)"' "$STATE_FILE" 2>/dev/null || echo "(无备注)")
  NEEDS_INFO_HINT="

⚠️ **NEEDS_INFO 暂停态**（来自 ${PREV_STATE}）
   待回答: ${LAST_NOTE}
   恢复命令: bash .claude/scripts/coder-state.sh state-machine transition --target resume"
fi

# 进度统计
COMPLETED=$(jq -r '[.phases // {} | to_entries[] | select(.value.status == "completed")] | length' "$STATE_FILE" 2>/dev/null || echo 0)
SKIPPED=$(jq -r '(.skipped_phases // []) | length' "$STATE_FILE" 2>/dev/null || echo 0)
TOTAL=$((COMPLETED + SKIPPED))

# tasks 进度
TASKS_TOTAL=$(jq -r '(.tasks // []) | length' "$STATE_FILE" 2>/dev/null || echo 0)
TASKS_DONE=$(jq -r '[.tasks // [] | .[] | select(.status == "completed")] | length' "$STATE_FILE" 2>/dev/null || echo 0)

# 上次活跃距今
LAST_ACTIVE_MIN=$(python3 -c "
from datetime import datetime, timezone
import sys
try:
    last = datetime.fromisoformat('$LAST_ACTIVE'.replace('Z', '+00:00'))
    now = datetime.now(timezone.utc)
    print(int((now - last).total_seconds() / 60))
except: print('?')
" 2>/dev/null || echo "?")

# 输出 hint
CONTEXT="🔄 检测到未完成 spec

${STATE_EMOJI} **state**: ${STATE_MACHINE}
📋 **spec**: ${SPEC_ID} (${SPEC_SLUG})
📍 **current phase**: ${CURRENT_PHASE}
⏰ started: ${STARTED_AT} | last active: ${LAST_ACTIVE} (~${LAST_ACTIVE_MIN} 分钟前)
📊 progress: ${COMPLETED} phases done / ${TOTAL} total | ${TASKS_DONE}/${TASKS_TOTAL} tasks${NEEDS_INFO_HINT}

📜 **最近 state 转换**:
${HISTORY_LINES}

---

**MUST DO（v6+ §15）**: orchestrator 应立即 AskUserQuestion 让用户选：
- 续跑（从 ${CURRENT_PHASE} 继续）
- 查看进度（bash .claude/scripts/coder-state.sh show）
- 重新开始（bash .claude/scripts/coder-state.sh abandon --reason 'restart'）
- 永不问（写 memory MCP coder-user-pref tag）

用户未选之前，**禁止**进入 Phase 0 新 spec。"

jq -c -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'

exit 0
