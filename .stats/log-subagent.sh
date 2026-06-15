#!/bin/bash
# Subagent Usage Tracker - logs subagent invocations to JSONL
# Triggered by SubagentStop hook in settings.json
# stdin: {session_id, subagent_name, model, duration_ms, tokens, tool_output, ...}
# 环境变量: CLAUDE_SESSION_ID, CLAUDE_TOOL_NAME, CLAUDE_TOOL_INPUT, CLAUDE_TOOL_OUTPUT

INPUT=$(cat)
STATS_DIR="$(dirname "$0")"
LOG="$STATS_DIR/usage.jsonl"

# SubagentStop 可能用 subagent_name 或从 tool_input 提取
AGENT_NAME=$(echo "$INPUT" | jq -r '.subagent_name // .agent_name // empty' 2>/dev/null)
if [ -z "$AGENT_NAME" ]; then
  AGENT_NAME=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null)
fi
[ -z "$AGENT_NAME" ] && exit 0

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "$INPUT" | jq -c --arg ts "$TS" --arg agent "$AGENT_NAME" \
  '{
    ts: $ts,
    type: "subagent",
    subagent: $agent,
    model: (.model // .tool_input.model // null),
    duration_ms: (.duration_ms // null),
    session_id: (.session_id // null),
    tokens: ((.tokens // null) | if . then {input: (.input // null), output: (.output // null)} else null end)
  }' >> "$LOG"
