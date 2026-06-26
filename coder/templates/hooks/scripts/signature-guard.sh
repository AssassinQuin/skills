#!/usr/bin/env bash
# signature-guard.sh — coder v6.0 用户签字守卫
#
# 拦截 Phase 0/3/5/6 完成（update-phase ... completed）时未签字：
# state.json phases[X].user_signed_hash 必须存在
#
# 用途：避免 orchestrator "我自己看过了就算确认"，强制用户主导
#
# 这个 hook 不挂在 PreToolUse（不是拦工具调用），而是 orchestrator 内联检查。
# orchestrator 跑 update-phase ... completed 之前必须先验证签字。
# 本脚本提供 orchestrator 调用的 check 函数。
#
# Usage:
#   signature-guard.sh check <phase>
#     → 检查 state.json phases[<phase>].user_signed_hash 是否存在
#     → rc=0 通过，rc=1 未签字
#   signature-guard.sh sign <phase>
#     → 计算当前 spec 内容 hash + 写入 state.json

set -euo pipefail

PHASE="${2:-}"

if [[ "$1" == "check" ]]; then
  [[ -n "$PHASE" ]] || { echo "Usage: signature-guard.sh check <phase>" >&2; exit 2; }

  CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
  STATE_FILE="${CWD}/.claude/coder-state/current.json"
  [[ -f "$STATE_FILE" ]] || { echo "ERROR: 无 state.json" >&2; exit 2; }

  SIGNED="$(jq -r --arg p "$PHASE" '.phases[$p].user_signed_hash // ""' "$STATE_FILE")"
  if [[ -n "$SIGNED" ]]; then
    echo "✅ ${PHASE} 已签字: ${SIGNED}"
    exit 0
  else
    echo "❌ ${PHASE} 未签字（用户必须显式确认）" >&2
    echo "   签字命令: bash $0 sign $PHASE" >&2
    exit 1
  fi

elif [[ "$1" == "sign" ]]; then
  [[ -n "$PHASE" ]] || { echo "Usage: signature-guard.sh sign <phase>" >&2; exit 2; }

  CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
  STATE_FILE="${CWD}/.claude/coder-state/current.json"
  [[ -f "$STATE_FILE" ]] || { echo "ERROR: 无 state.json" >&2; exit 2; }

  SPEC_DIR="$(jq -r '.spec_dir // ""' "$STATE_FILE")"
  # fallback：state.json 无 spec_dir 时，用 spec_id 推断
  if [[ -z "$SPEC_DIR" ]]; then
    SPEC_ID="$(jq -r '.spec_id // ""' "$STATE_FILE")"
    if [[ -n "$SPEC_ID" ]]; then
      SPEC_DIR=".claude/coder-state/specs-active/${SPEC_ID}"
    else
      echo "ERROR: state.json 无 spec_dir 且无 spec_id" >&2
      exit 2
    fi
  fi

  # 计算签字 hash：user + ts + spec 内容前 500 字符
  USER="${USER:-unknown}"
  TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  SPEC_CONTENT=""
  case "$PHASE" in
    "Phase 0")
      SPEC_FILE="${CWD}/${SPEC_DIR}/spec.md"
      [[ -f "$SPEC_FILE" ]] && SPEC_CONTENT="$(head -c 500 "$SPEC_FILE")"
      ;;
    "Phase 3")
      DESIGN_FILE="${CWD}/${SPEC_DIR}/design.md"
      [[ -f "$DESIGN_FILE" ]] && SPEC_CONTENT="$(head -c 500 "$DESIGN_FILE")"
      ;;
    "Phase 5")
      REVIEW_FILE="${CWD}/${SPEC_DIR}/review-report.md"
      [[ -f "$REVIEW_FILE" ]] && SPEC_CONTENT="$(head -c 500 "$REVIEW_FILE")"
      ;;
    "Phase 6")
      DELIVERY_FILE="${CWD}/${SPEC_DIR}/delivery-checklist.md"
      [[ -f "$DELIVERY_FILE" ]] && SPEC_CONTENT="$(head -c 500 "$DELIVERY_FILE")"
      ;;
  esac
  HASH="$(printf "%s|%s|%s" "$USER" "$TS" "$SPEC_CONTENT" | shasum -a 256 | cut -c1-16)"

  # 写入 state.json
  jq --arg p "$PHASE" --arg h "$HASH" --arg ts "$TS" \
    '.phases[$p].user_signed_hash = $h | .phases[$p].signed_at = $ts' \
    "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

  echo "✅ ${PHASE} 已签字: ${HASH} (at ${TS})"
  exit 0

elif [[ "$1" == "verify" ]]; then
  # verify: 检查所有必签 Phase（0/3/5/6）是否都已签字（在 archive 前用）
  CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
  STATE_FILE="${CWD}/.claude/coder-state/current.json"
  [[ -f "$STATE_FILE" ]] || { echo "ERROR: 无 state.json"; exit 2; }

  ALL_OK=true
  for p in "Phase 0" "Phase 3" "Phase 5" "Phase 6"; do
    STATUS="$(jq -r --arg p "$p" '.phases[$p].status // ""' "$STATE_FILE")"
    SIGNED="$(jq -r --arg p "$p" '.phases[$p].user_signed_hash // ""' "$STATE_FILE")"
    if [[ "$STATUS" == "completed" && -z "$SIGNED" ]]; then
      echo "❌ $p completed 但未签字" >&2
      ALL_OK=false
    fi
  done

  if $ALL_OK; then
    echo "✅ 所有必签 Phase 已签字"
    exit 0
  else
    exit 1
  fi
fi

cat <<'EOF' >&2
Usage:
  signature-guard.sh check <phase>     # 检查 phase 是否签字
  signature-guard.sh sign <phase>      # 签字（写入 state.json）
  signature-guard.sh verify            # 检查所有必签 Phase（0/3/5/6）

Phases requiring signature: Phase 0 / Phase 3 / Phase 5 / Phase 6
EOF
exit 2
