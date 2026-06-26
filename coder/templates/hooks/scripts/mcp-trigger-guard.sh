#!/usr/bin/env bash
# mcp-trigger-guard.sh — coder v6.1 防 "我熟悉" 跳 Phase 1
#
# PreToolUse Edit/Write：多文件改动前检查 session 是否调过 codebase-memory-mcp
# 防止 §11.1 "我熟悉项目" 反例
#
# 触发逻辑：
#   - 本次 session 内已 Edit ≥2 个不同文件
#   - 且本次 session 内未观察到 codebase-memory-mcp 调用
#   - 且未观察到 memory_search（项目历史决策）
#   → warn / block

set -euo pipefail

MODE="${CODER_MCP_GUARD:-warn}"
[[ "$MODE" == "off" ]] && exit 0

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

[[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "MultiEdit" ]] || exit 0

CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty')"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')"

# 不拦 .claude/ 内文件（state / hook / agent 自身）
case "$FILE_PATH" in
  */.claude/*|*/SKILL.md|*/modules/*/SKILL.md|*/.deepen/*|*/templates/*|*/specs-active/*|*/specs/*)
    exit 0 ;;
esac

# 项目未 init → 放行
[[ -f "${CWD}/.claude/.coder-initialized.json" ]] || exit 0

STATE_FILE="${CWD}/.claude/coder-state/current.json"
TRACE_FILE="${CWD}/.claude/coder-state/spawn-trace.jsonl"

# 追踪本次 session Edit 过的文件（用临时文件 + session_id 隔离）
EDIT_TRACK="${CWD}/.claude/coder-state/edit-track-${SESSION_ID}.txt"
mkdir -p "$(dirname "$EDIT_TRACK")"

# 追加当前 file（去重）
if [[ -n "$FILE_PATH" ]]; then
  echo "$FILE_PATH" >> "$EDIT_TRACK"
fi

# 统计本次 session Edit 过的不同文件数
UNIQUE_FILES=$(sort -u "$EDIT_TRACK" 2>/dev/null | wc -l | tr -d ' ')

# 检查本次 session 是否调过 codebase-memory-mcp 或 memory_search
MCP_TRIGGERED=0
if [[ -f "$TRACE_FILE" ]]; then
  # spawn-trace 含 mcp 调用记录（spawn-trace.sh 记录 Agent + Bash grep）
  # 这里简化：检查 trace 中是否有 codebase-memory 相关字样
  MCP_TRIGGERED=$(grep -E 'codebase-memory|memory_search|mcp__codebase' "$TRACE_FILE" 2>/dev/null | wc -l | tr -d ' ')
fi

# 还需要检查 PostToolUse 记录的 MCP 工具调用（spawn-trace 只记 Bash + Agent）
# 更准确：读 .claude/coder-trace.jsonl（spawn-trace.sh 同时写的另一个文件）
V5_TRACE="${CWD}/.claude/coder-trace.jsonl"
if [[ -f "$V5_TRACE" ]]; then
  V5_MCP=$(jq -r --arg sid "$SESSION_ID" '
    select(.session_id == $sid)
    | select(.command // "" | test("codebase-memory|memory_search|mcp__codebase|get_architecture"))
  ' "$V5_TRACE" 2>/dev/null | wc -l | tr -d ' ')
  MCP_TRIGGERED=$((MCP_TRIGGERED + V5_MCP))
fi

# 判定：≥2 文件改动 且 0 MCP 触发
if [[ $UNIQUE_FILES -ge 2 && $MCP_TRIGGERED -eq 0 ]]; then
  MSG="⚠️ [coder mcp-trigger-guard] 本次 session 改动 ${UNIQUE_FILES} 个文件但未触发 codebase-memory-mcp / memory_search。
'我熟悉这个项目' 不构成跳过 MCP 的理由（§11.1 反例）。
建议：
  1. 跑 mcp__codebase-memory-mcp__get_architecture 看依赖图
  2. 跑 memory_search(tags=[\"coding-{lang}-*\"]) 注入历史决策
  3. 或显式设 CODER_MCP_GUARD=off 表明已确认风险"

  if [[ "$MODE" == "block" ]]; then
    cat <<EOF | jq -c '.'
{"decision": "block", "reason": "[coder mcp-trigger-guard] 多文件改动前必须触发 codebase-memory-mcp 或 memory_search。${MSG}", "suppress_output": false}
EOF
    exit 2
  else
    cat <<EOF | jq -c '.'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "${MSG}"}}
EOF
    exit 0
  fi
fi

exit 0
