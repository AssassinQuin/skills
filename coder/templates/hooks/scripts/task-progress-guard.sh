#!/usr/bin/env bash
# task-progress-guard.sh — coder v6.0 task 进度守卫
#
# PreToolUse Agent: spawn 子 agent 前在 state.json 检查对应 task_id 是否登记
# PostToolUse Agent: spawn 完成后自动更新 task status
#
# 用途：避免"orchestrator 没登记 task 就 spawn"，让 task 追踪始终准确
#
# 强制度：默认 warn，CODER_TASK_GUARD=block 升级，=off 关闭

set -euo pipefail

MODE="${CODER_TASK_GUARD:-warn}"
[[ "$MODE" == "off" ]] && exit 0

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

[[ "$TOOL_NAME" == "Agent" || "$TOOL_NAME" == "Task" ]] || exit 0

CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
STATE_FILE="${CWD}/.claude/coder-state/current.json"

# 无 state 系统：放行
[[ -f "$STATE_FILE" ]] || exit 0

AGENT_NAME="$(echo "$INPUT" | jq -r '.tool_input.subagent_type // .tool_input.description // "unknown"')"
CURRENT_PHASE="$(jq -r '.current_phase // "unknown"' "$STATE_FILE")"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty')"
TOOL_RESPONSE="$(echo "$INPUT" | jq -r '.tool_response // empty')"

# ---- PreToolUse: spawn 前 ----
if [[ -z "$TOOL_RESPONSE" ]]; then
  # Phase 4 spawn lang-coder：检查是否有对应 pending task
  if [[ "$CURRENT_PHASE" == "Phase 4" ]] && [[ "$AGENT_NAME" == *coder-project* ]]; then
    PENDING_COUNT=$(jq -r --arg sa "$AGENT_NAME" \
      '[.tasks[] | select(.subagent == $sa and .status == "pending")] | length' \
      "$STATE_FILE" 2>/dev/null || echo 0)
    if [[ $PENDING_COUNT -eq 0 ]]; then
      MSG="⚠️ [coder task-guard] spawn ${AGENT_NAME} 但 state.json 无 pending task。orchestrator 应先 bash .claude/scripts/coder-state.sh add-task --task-id <id> --phase Phase 4 --subagent ${AGENT_NAME}。"
      if [[ "$MODE" == "block" ]]; then
        cat <<EOF | jq -c '.'
{"decision": "block", "reason": "[coder task-guard] spawn 前必须登记 task。", "suppress_output": false}
EOF
        exit 2
      else
        cat <<EOF | jq -c '.'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "${MSG}"}}
EOF
        exit 0
      fi
    fi
  fi

  # 记录 spawn 尝试
  TRACE="${CWD}/.claude/coder-state/spawn-trace.jsonl"
  mkdir -p "$(dirname "$TRACE")"
  jq -c -n \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg sid "$SESSION_ID" \
    --arg phase "$CURRENT_PHASE" \
    --arg agent "$AGENT_NAME" \
    '{timestamp: $ts, session_id: $sid, phase: $phase, agent: $agent, event: "pre_spawn"}' \
    >> "$TRACE" 2>/dev/null || true
  exit 0
fi

# ---- PostToolUse: spawn 完成后 ----
# 自动更新对应 task 状态（根据 delivery 内容）
SUCCESS="$(echo "$TOOL_RESPONSE" | jq -r '.success // true' 2>/dev/null || echo true)"

# 简化：spawn 成功 → task 标 in_progress（如果还是 pending）
# 真正 completed 由 orchestrator 在 validate-delivery 通过后手动标
if [[ "$SUCCESS" == "true" ]]; then
  # 找匹配的 pending task（同 subagent + pending），标 in_progress
  python3 - "$STATE_FILE" "$AGENT_NAME" <<'PYEOF' 2>/dev/null || true
import json, sys
state_file, agent = sys.argv[1:3]
with open(state_file) as f:
    state = json.load(f)
tasks = state.get("tasks", [])
updated = False
for t in tasks:
    if t.get("subagent") == agent and t.get("status") == "pending":
        t["status"] = "in_progress"
        updated = True
        break
if updated:
    with open(state_file, "w") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)
PYEOF
fi

# 记录 spawn 完成
TRACE="${CWD}/.claude/coder-state/spawn-trace.jsonl"
mkdir -p "$(dirname "$TRACE")"
jq -c -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg sid "$SESSION_ID" \
  --arg phase "$CURRENT_PHASE" \
  --arg agent "$AGENT_NAME" \
  --argjson success "$SUCCESS" \
  '{timestamp: $ts, session_id: $sid, phase: $phase, agent: $agent, event: "post_spawn", success: $success}' \
  >> "$TRACE" 2>/dev/null || true

exit 0
