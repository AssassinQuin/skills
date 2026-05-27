#!/bin/bash
# Skill Usage Tracker - logs skill invocations to JSONL
# Triggered by PostToolUse hook in settings.json
INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)
[ -z "$SKILL" ] && exit 0
STATS_DIR="$(dirname "$0")"
LOG="$STATS_DIR/usage.jsonl"
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"skill\":\"$SKILL\"}" >> "$LOG"
