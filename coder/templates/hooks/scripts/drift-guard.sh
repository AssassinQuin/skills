#!/usr/bin/env bash
# drift-guard.sh — coder v6.1 drift ≥ 0.4 强制 adaptive control
#
# PostToolUse Bash：检测 validate-delivery.py 调用
# 解析输出找 drift_score，≥0.4 → block + 提示回 Phase 3
#
# 防 "drift 累积不触发 adaptive"（AP-10）

set -euo pipefail

MODE="${CODER_DRIFT_GUARD:-block}"
[[ "$MODE" == "off" ]] && exit 0

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

[[ "$TOOL_NAME" == "Bash" ]] || exit 0

CMD="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"

# 只拦 validate-delivery.py
echo "$CMD" | grep -qE 'validate-delivery(\.py)?' || exit 0

# 读 tool_response（PostToolUse 有）
TOOL_RESPONSE="$(echo "$INPUT" | jq -r '.tool_response // empty')"
[[ -n "$TOOL_RESPONSE" ]] || exit 0

# 用 -r 安全提取（避免 control char parse error）
STDOUT="$(echo "$TOOL_RESPONSE" | jq -r '.stdout // empty')"
EXIT_CODE="$(echo "$TOOL_RESPONSE" | jq -r '.exit_code // 0')"

# 如果 validate-delivery 自己已经 block（rc != 0），不重复拦
[[ "$EXIT_CODE" == "0" ]] || exit 0

# 找 drift 数字
# validate-delivery 输出格式："   drift: 0.45"
DRIFT_VALUE="$(echo "$STDOUT" | grep -E '^[[:space:]]*drift:' | head -1 | sed -E 's/.*drift:[[:space:]]*([0-9.]+).*/\1/')"

if [[ -z "$DRIFT_VALUE" ]]; then
  # 没找到 drift，不拦
  exit 0
fi

# 比较是否 ≥ 0.4
OVER=$(python3 -c "print('YES' if float('${DRIFT_VALUE}') >= 0.4 else 'NO')" 2>/dev/null || echo "NO")

if [[ "$OVER" == "YES" ]]; then
  if [[ "$MODE" == "block" ]]; then
    cat <<EOF | jq -c '.'
{"decision": "block", "reason": "[coder drift-guard] drift_score=${DRIFT_VALUE} ≥ 0.4，触发 adaptive control。不返工子 agent，回 Phase 3 让 oracle 重新分解（可能拆更细 / 改方案）。用户重新确认 design 后再走 Phase 4。这是 AP-10 反例防范 + R10（长任务检查点）+ v6-execution-protocol.md §10。", "suppress_output": false}
EOF
    exit 2
  else
    MSG="⚠️ [coder drift-guard] drift_score=${DRIFT_VALUE} ≥ 0.4，应触发 adaptive control（回 Phase 3）。当前 warn 模式放行，建议手动返工。"
    cat <<EOF | jq -c '.'
{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "${MSG}"}}
EOF
    exit 0
  fi
fi

exit 0
