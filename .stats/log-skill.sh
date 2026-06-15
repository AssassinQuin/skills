#!/bin/bash
# Skill Usage Tracker - logs skill invocations to JSONL
# Triggered by PostToolUse hook (matcher: "Skill")
# stdin: {session_id, tool_name, tool_input, tool_output, duration_ms, tokens, ...}

INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)
[ -z "$SKILL" ] && exit 0

STATS_DIR="$(dirname "$0")"
LOG="$STATS_DIR/usage.jsonl"

# 解析 hook 提供的元数据
DURATION=$(echo "$INPUT" | jq -r '.duration_ms // null' 2>/dev/null)
TOKENS_IN=$(echo "$INPUT" | jq -r '.tokens.input // null' 2>/dev/null)
TOKENS_OUT=$(echo "$INPUT" | jq -r '.tokens.output // null' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // null' 2>/dev/null)

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# 构建记录（兼容旧格式：缺少字段为 null）
echo "$INPUT" | jq -c --arg ts "$TS" --arg skill "$SKILL" \
  '{
    ts: $ts,
    type: "skill",
    skill: $skill,
    duration_ms: (.duration_ms // null),
    session_id: (.session_id // null),
    tokens: ((.tokens // null) | if . then {input: (.input // null), output: (.output // null)} else null end)
  }' >> "$LOG"
