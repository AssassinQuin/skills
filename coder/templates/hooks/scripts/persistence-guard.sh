#!/usr/bin/env bash
# persistence-guard.sh — coder v6.1 归档前检查产出完整
#
# PreToolUse Bash：检测 coder-state.sh archive 命令
# 检查：
#   1. delivery-checklist.md 存在
#   2. state.json 所有必签 Phase（0/3/5/6）已签字
#   3. 至少 1 个 memory MCP 写入（blocker / 决策 / drift）
# 不达标 → block

set -euo pipefail

MODE="${CODER_PERSISTENCE_GUARD:-block}"
[[ "$MODE" == "off" ]] && exit 0

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

[[ "$TOOL_NAME" == "Bash" ]] || exit 0

CMD="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"

# 只拦 coder-state.sh archive
echo "$CMD" | grep -qE 'coder-state(\.sh|\.py)\s+archive' || exit 0

CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
STATE_FILE="${CWD}/.claude/coder-state/current.json"

[[ -f "$STATE_FILE" ]] || { echo "ERROR: 无 state.json" >&2; exit 2; }

SPEC_DIR_REL="$(jq -r '.spec_dir // empty' "$STATE_FILE")"
[[ -n "$SPEC_DIR_REL" ]] || { echo "ERROR: state.json 无 spec_dir" >&2; exit 2; }
SPEC_DIR="${CWD}/${SPEC_DIR_REL}"

VIOLATIONS=()

# ---- 检查 1：delivery-checklist.md 存在 ----
if [[ ! -f "${SPEC_DIR}/delivery-checklist.md" ]]; then
  VIOLATIONS+=("delivery-checklist.md 不存在（Phase 6 未完成）")
fi

# ---- 检查 2：所有必签 Phase 已签字 ----
MUST_SIGN_PHASES=("Phase 0" "Phase 3" "Phase 5" "Phase 6")
for phase in "${MUST_SIGN_PHASES[@]}"; do
  STATUS=$(jq -r --arg p "$phase" '.phases[$p].status // ""' "$STATE_FILE")
  SIGNED=$(jq -r --arg p "$phase" '.phases[$p].user_signed_hash // ""' "$STATE_FILE")
  # 跳过的 phase 不要求签字
  SKIPPED=$(jq -r --arg p "$phase" '(.skipped_phases // []) | index($p) != null' "$STATE_FILE")
  if [[ "$SKIPPED" == "true" ]]; then
    continue
  fi
  if [[ "$STATUS" == "completed" && -z "$SIGNED" ]]; then
    VIOLATIONS+=("${phase} completed 但未签字（用户主导失效）")
  fi
done

# ---- 检查 3：至少 1 个 memory 写入（通过 spawn-trace 找 mcp__memory_store 调用）----
# spawn-trace 不直接记录 MCP 工具调用，但记录 Bash 命令 + Agent。
# 简化：检查 spec_dir 下是否有 delivery-*.yaml（间接证据 Phase 4 跑过）
DELIVERY_COUNT=$(ls "${SPEC_DIR}"/delivery-*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [[ $DELIVERY_COUNT -lt 1 ]]; then
  VIOLATIONS+=("无 delivery-*.yaml 文件（Phase 4 未 spawn 子 agent？）")
fi

# ---- 检查 4：spec.md 存在 ----
if [[ ! -f "${SPEC_DIR}/spec.md" ]]; then
  VIOLATIONS+=("spec.md 不存在（Phase 0 未完成）")
fi

# ---- 输出 ----
if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
  MSG="[coder persistence-guard] 归档前检查失败（${#VIOLATIONS[@]} 项）："
  for v in "${VIOLATIONS[@]}"; do
    MSG="${MSG}\n  - ${v}"
  done
  MSG="${MSG}\n\n请先补全产出，或设 CODER_PERSISTENCE_GUARD=off 强制归档（不推荐）。"

  if [[ "$MODE" == "block" ]]; then
    jq -c -n --arg msg "$MSG" '{decision: "block", reason: $msg, suppress_output: false}'
    exit 2
  else
    jq -c -n --arg msg "$MSG" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $msg}}'
    exit 0
  fi
fi

echo "✅ persistence-guard 通过"
exit 0
