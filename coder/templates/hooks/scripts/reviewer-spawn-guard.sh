#!/usr/bin/env bash
# reviewer-spawn-guard.sh — coder v6.1 Phase 5 ≥1 reviewer 强制
#
# PreToolUse Bash：检测 coder-state.sh update-phase "Phase 5" completed 命令
# 检查 spawn-trace.jsonl 是否含至少 1 个 reviewer subagent
# 不达标 → block
#
# 防止 "测试过就算验证通过"（§11.3）和 "Phase 5 简化自审"（§11.6）

set -euo pipefail

MODE="${CODER_REVIEWER_GUARD:-block}"
[[ "$MODE" == "off" ]] && exit 0

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

[[ "$TOOL_NAME" == "Bash" ]] || exit 0

CMD="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"

# 只拦 coder-state.sh update-phase "Phase 5" completed
if ! echo "$CMD" | grep -qE 'coder-state(\.sh|\.py)\s+(update-phase|update_phase)'; then
  exit 0
fi
if ! echo "$CMD" | grep -qE 'Phase\s*5'; then
  exit 0
fi
if ! echo "$CMD" | grep -qE 'completed'; then
  exit 0
fi

CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty')"
STATE_FILE="${CWD}/.claude/coder-state/current.json"
TRACE_FILE="${CWD}/.claude/coder-state/spawn-trace.jsonl"

# 无 state 系统 → 放行（v5.0 项目）
[[ -f "$STATE_FILE" ]] || exit 0

# 检查 spawn-trace：本 session 内是否 spawn 过 reviewer
REVIEWER_COUNT=0
if [[ -f "$TRACE_FILE" ]]; then
  REVIEWER_COUNT=$(jq -r --arg sid "$SESSION_ID" '
    select(.session_id == $sid)
    | select(.agent | test("reviewer|correctness-reviewer|project-reviewer|security-reviewer"))
    | .timestamp
  ' "$TRACE_FILE" 2>/dev/null | wc -l | tr -d ' ')
fi

if [[ $REVIEWER_COUNT -ge 1 ]]; then
  exit 0
fi

# 不达标 → block
cat <<EOF | jq -c '.'
{"decision": "block", "reason": "[coder reviewer-spawn-guard] Phase 5 completed 前必须 spawn 至少 1 个 reviewer 子 agent。当前 session 0 个 reviewer spawn。这是 R12（失败显性化）+ §11.3 反例防范。请先 spawn reviewer（correctness-reviewer / project-reviewer / security-reviewer），跑完再 update-phase。", "suppress_output": false}
EOF
exit 2
