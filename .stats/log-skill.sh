#!/bin/bash
# Skill Usage Tracker - logs skill invocations to JSONL
# Triggered by PostToolUse hook (matcher: "Skill")
# stdin: {session_id, transcript_path, tool_name, tool_input, tool_response, ...}
# 2026-09-04 补丁（skill-stats 升级轮）:
#   1. tokens 从 transcript_path 尾部 usage 抽取——hook stdin 本无 tokens 字段（旧版假设错误，227 条全空）
#   2. 增加 outcome（tool_response.isError → fail）与 resp_bytes（响应长度信号）
#   3. skill 名解析双保险 .tool_input.skill // .tool_input.command

INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // .tool_input.command // empty' 2>/dev/null)
[ -z "$SKILL" ] && exit 0

STATS_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$STATS_DIR/usage.jsonl"

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# tokens: 取 transcript 尾部最近一条含 usage 的 assistant 记录（近似本次 skill 调用的实际消耗）
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
USAGE_JSON="null"
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  USAGE_JSON=$(tail -50 "$TRANSCRIPT" 2>/dev/null \
    | jq -c 'select(.message.usage != null) | .message.usage | {input: (.input_tokens // null), output: (.output_tokens // null)}' 2>/dev/null \
    | tail -1)
  [ -z "$USAGE_JSON" ] && USAGE_JSON="null"
fi

echo "$INPUT" | jq -c --arg ts "$TS" --arg skill "$SKILL" --argjson usage "$USAGE_JSON" \
  '{
    ts: $ts,
    type: "skill",
    skill: $skill,
    duration_ms: (.duration_ms // null),
    session_id: (.session_id // null),
    tokens: $usage,
    outcome: (if (.tool_response.isError // false) then "fail" else "success" end),
    resp_bytes: ((.tool_response // "") | tostring | length)
  }' >> "$LOG"
