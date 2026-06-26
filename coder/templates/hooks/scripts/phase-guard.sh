#!/usr/bin/env bash
# phase-guard.sh — coder v6.0 Phase 状态守卫
#
# 拦截违反 Phase 协议的工具调用：
#   PreToolUse Edit/Write: 检查 current_phase 是否允许 Edit（Phase 4 / 4.5 之外 warn）
#   PreToolUse Agent: spawn 前在 state.json 登记 task（task-trace）
#   PostToolUse Agent: spawn 完成后更新 task status
#
# 强制度：默认 warn，CODER_PHASE_GUARD=block 升级，=off 关闭
#
# Claude Code hook 协议：stdin JSON {tool_name, tool_input, tool_response, session_id, cwd}

set -euo pipefail

MODE="${CODER_PHASE_GUARD:-warn}"
[[ "$MODE" == "off" ]] && exit 0

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"
CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
STATE_FILE="${CWD}/.claude/coder-state/current.json"

# 未初始化的项目直接放行（v5.0+ 项目无 state 系统）
[[ -f "$STATE_FILE" ]] || exit 0

# 读 current_phase（jq 失败也放行）
CURRENT_PHASE="$(jq -r '.current_phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"

emit_warn() {
  local msg="$1"
  cat <<EOF | jq -c '.'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "${msg}"}}
EOF
}

emit_block() {
  local msg="$1"
  cat <<EOF | jq -c '.'
{"decision": "block", "reason": "${msg}", "suppress_output": false}
EOF
  exit 2
}

# ---- PreToolUse: Edit / Write ----
# 只在 Phase 4（执行）/ Phase 4.5（交付检查）允许 Edit
# 其他 Phase（如 Phase 0/0.5/1/2/3/5/6/7）做 Edit → warn
case "$TOOL_NAME" in
  Edit|Write|MultiEdit)
    case "$CURRENT_PHASE" in
      "Phase 4"|"Phase 4.5"|"unknown")
        # 允许
        exit 0
        ;;
      *)
        # 在不允许的 Phase 做 Edit
        MSG="⚠️ [coder phase-guard] 当前 ${CURRENT_PHASE}，通常不应做 Edit/Write。代码改动应在 Phase 4（执行）。如果是 Phase 0 文档生成（spec.md / design.md），忽略此提示。"
        if [[ "$MODE" == "block" ]]; then
          emit_block "[coder phase-guard] ${CURRENT_PHASE} 阶段禁止 Edit/Write（除 Phase 4）。当前 phase: ${CURRENT_PHASE}"
        else
          emit_warn "$MSG"
          exit 0
        fi
        ;;
    esac
    ;;

  Agent|Task)
    # PreToolUse Agent: spawn 前在 state.json 登记（task-trace）
    # 但 PreToolUse 阶段无法知道是否成功，所以仅记录"尝试 spawn"
    AGENT_NAME="$(echo "$INPUT" | jq -r '.tool_input.subagent_type // .tool_input.description // "unknown"')"
    SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty')"

    # 异步追加到 trace（不阻塞 spawn）
    TRACE="${CWD}/.claude/coder-state/spawn-trace.jsonl"
    mkdir -p "$(dirname "$TRACE")"
    jq -c -n \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg sid "$SESSION_ID" \
      --arg phase "$CURRENT_PHASE" \
      --arg agent "$AGENT_NAME" \
      --arg event "pre_spawn" \
      '{timestamp: $ts, session_id: $sid, phase: $phase, agent: $agent, event: $event}' \
      >> "$TRACE" 2>/dev/null || true
    exit 0
    ;;
esac

# ---- PostToolUse: Agent 完成后 ----
# hook 配置里这个脚本同时挂在 PreToolUse 和 PostToolUse（用 matcher 区分）
# PostToolUse 时 tool_response 存在
TOOL_RESPONSE="$(echo "$INPUT" | jq -r '.tool_response // empty')"
if [[ -n "$TOOL_RESPONSE" && "$TOOL_NAME" == "Agent" || "$TOOL_NAME" == "Task" ]]; then
  AGENT_NAME="$(echo "$INPUT" | jq -r '.tool_input.subagent_type // .tool_input.description // "unknown"')"
  SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty')"

  TRACE="${CWD}/.claude/coder-state/spawn-trace.jsonl"
  mkdir -p "$(dirname "$TRACE")"
  jq -c -n \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg sid "$SESSION_ID" \
    --arg phase "$CURRENT_PHASE" \
    --arg agent "$AGENT_NAME" \
    --arg event "post_spawn" \
    '{timestamp: $ts, session_id: $sid, phase: $phase, agent: $agent, event: $event}' \
    >> "$TRACE" 2>/dev/null || true
fi

exit 0
