#!/usr/bin/env bash
# spawn-trace.sh — coder PostToolUse hook for Agent (子 agent spawn)
#
# 每次子 agent 完成后记录到 .claude/coder-trace.jsonl
# 用途：edit-guard.sh 检查"最近是否有对应 spawn"
#
# Claude Code hook 协议：stdin JSON {tool_name, tool_input, tool_response, session_id, cwd}

set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

# 只记录 Agent 调用 + Bash grep（用于 edit-guard 检查 #13）
case "$TOOL_NAME" in
  Agent|Task)
    AGENT_NAME="$(echo "$INPUT" | jq -r '.tool_input.subagent_type // .tool_input.description // "unknown"')"
    LOG_ENTRY=$(jq -n \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg sid "$(echo "$INPUT" | jq -r '.session_id // empty')" \
      --arg cwd "$(echo "$INPUT" | jq -r '.cwd // empty')" \
      --arg tool "$TOOL_NAME" \
      --arg agent "$AGENT_NAME" \
      --argjson duration_ms "$(echo "$INPUT" | jq -r '.tool_response.duration_ms // 0')" \
      '{timestamp: $ts, session_id: $sid, cwd: $cwd, tool: $tool, agent_name: $agent, duration_ms: $duration_ms}')
    ;;
  Bash)
    CMD="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"
    # 只记录含 grep/rg/ag 的 Bash（用于 edit-guard #13 检查）
    if echo "$CMD" | grep -qE '(^| )grep( |$)|(^| )rg( |$)|(^| )ag( |$)'; then
      LOG_ENTRY=$(jq -n \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg sid "$(echo "$INPUT" | jq -r '.session_id // empty')" \
        --arg cwd "$(echo "$INPUT" | jq -r '.cwd // empty')" \
        --arg tool "$TOOL_NAME" \
        --arg command "$CMD" \
        '{timestamp: $ts, session_id: $sid, cwd: $cwd, tool: $tool, command: $command}')
    else
      exit 0
    fi
    ;;
  *) exit 0 ;;
esac

CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
TRACE_DIR="${CWD}/.claude"
TRACE_FILE="${TRACE_DIR}/coder-trace.jsonl"

mkdir -p "$TRACE_DIR"
echo "$LOG_ENTRY" >> "$TRACE_FILE"

# 轮转：超过 1MB 截断保留最后 5000 行
if [[ -f "$TRACE_FILE" ]]; then
  SIZE=$(wc -c < "$TRACE_FILE" | tr -d ' ')
  if [[ $SIZE -gt 1048576 ]]; then
    TMP="$(mktemp)"
    tail -5000 "$TRACE_FILE" > "$TMP" && mv "$TMP" "$TRACE_FILE"
  fi
fi

exit 0
