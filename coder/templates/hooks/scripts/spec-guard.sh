#!/usr/bin/env bash
# spec-guard.sh — coder v6.1 spec 守卫（默认 block）
#
# 拦截无 spec 的 Edit/Write：Phase 4 之外做代码 Edit 时，
# 如 .claude/coder-state/current.json 不存在或 spec.md 缺失 → block / warn
#
# 强制度（v6.1 升级）：默认 block（防 §11.6 滑坡）
#   CODER_SPEC_GUARD=warn  → 降级为提示
#   CODER_SPEC_GUARD=off   → 完全关闭
#   CODER_SPEC_GUARD=allow-no-spec  → 显式跳过本次（单 session）
#
# 用途：避免"用户随口说改个东西，agent 直接动手"——必须先走 Phase 0 生成 spec

set -euo pipefail

MODE="${CODER_SPEC_GUARD:-block}"
[[ "$MODE" == "off" || "$MODE" == "allow-no-spec" ]] && exit 0

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

# 只拦代码 Edit / Write（不拦 .claude/coder-state/ 内的文件，那些是 state 自己写的）
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')"

# 不拦 state / hook / agents / .claude/ 内的文件（那些是 init / state 自己管的）
case "$FILE_PATH" in
  */.claude/coder-state/*|*/.claude/hooks/*|*/.claude/agents/*|*/.claude/scripts/*|*/.claude/settings.json)
    exit 0 ;;
esac

# 也不拦 SKILL.md / references / 设计文档（v6 设计本身就是写文档）
case "$FILE_PATH" in
  */SKILL.md|*/modules/*/SKILL.md|*/.deepen/*|*/templates/*|*/specs-active/*|*/specs/*)
    exit 0 ;;
esac

STATE_FILE="${CWD}/.claude/coder-state/current.json"

# 项目没 init（无 state.json 系统）→ 不拦
[[ -f "${CWD}/.claude/.coder-initialized.json" ]] || exit 0

# 项目 init 了但还没 spec
if [[ ! -f "$STATE_FILE" ]]; then
  if [[ "$MODE" == "block" ]]; then
    jq -c -n '{decision: "block", reason: "[coder spec-guard] 无 spec 不允许代码 Edit. 先跑: bash .claude/scripts/coder-state.sh init --slug NAME. 或设 CODER_SPEC_GUARD=warn 降级.", suppress_output: false}'
    exit 2
  else
    jq -c -n '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: "[coder spec-guard] 本次 Edit 无 spec (无 current.json). Phase 4 之外代码改动应先走 Phase 0 生成 spec.md. typo 修复可忽略; feature/refactor 建议先 init --slug NAME."}}'
    exit 0
  fi
fi

# 有 state.json：检查 current_phase 是否允许 Edit
CURRENT_PHASE="$(jq -r '.current_phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown')"
case "$CURRENT_PHASE" in
  "Phase 4"|"Phase 4.5"|"Phase 7"|"unknown")
    # 允许
    ;;
  *)
    # 在 Phase 0/0.5/1/2/3/5/6 做 Edit：通常应该是文档生成，不是代码 Edit
    # 已经被 phase-guard 拦过了，spec-guard 不重复
    ;;
esac

exit 0
