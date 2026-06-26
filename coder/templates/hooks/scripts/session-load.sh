#!/usr/bin/env bash
# session-load.sh — coder v7.4 SessionStart hook（v5.0+ 项目元信息 + drift 检测）
#
# 显示项目元信息 + v7.4 加 state_machine 协同（needs_info 提示）
# 与 session-resume.sh 配合：
#   - session-resume：检测 state.json（v6+）+ 续跑 hint
#   - session-load：项目元信息 + drift 检测（v5.0+ + v6+）
#
# 输出会作为 additionalContext 注入 conversation

set -euo pipefail

CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
INIT_FILE="${CWD}/.claude/.coder-initialized.json"
STATE_FILE="${CWD}/.claude/coder-state/current.json"

# 未初始化的项目：提示是否跑 init
if [[ ! -f "$INIT_FILE" ]]; then
  cat <<'EOF'
{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "📁 本项目尚未跑 coder init. 运行 `bash ~/.claude/skills/coder/scripts/init-project.sh` 生成项目级 agent + hook + 流程配置."}}
EOF
  exit 0
fi

# 读 init 元数据
PROJECT_NAME="$(jq -r '.project_name // "unnamed"' "$INIT_FILE")"
PRIMARY_LANG="$(jq -r '.primary_lang // "unknown"' "$INIT_FILE")"
LANG_VERSION="$(jq -r '.lang_version // "?"' "$INIT_FILE")"
INIT_DATE="$(jq -r '.init_date // "?"' "$INIT_FILE")"
CODER_VERSION="$(jq -r '.coder_version // "?"' "$INIT_FILE")"

# v7.4 新：state_machine（如存在）
STATE_MACHINE_HINT=""
if [[ -f "$STATE_FILE" ]]; then
  STATE_MACHINE=$(jq -r '.state_machine // "new"' "$STATE_FILE" 2>/dev/null || echo "new")
  case "$STATE_MACHINE" in
    needs_info)
      PREV_STATE=$(jq -r '.needs_info_prev_state // "?"' "$STATE_FILE" 2>/dev/null || echo "?")
      LAST_NOTE=$(jq -r '(.state_history // []) | last | .note // "(无备注)"' "$STATE_FILE" 2>/dev/null || echo "(无备注)")
      STATE_MACHINE_HINT=" | ⚠️ needs_info (from ${PREV_STATE}): ${LAST_NOTE}"
      ;;
    abandoned)
      STATE_MACHINE_HINT=" | 💀 abandoned"
      ;;
    *)
      STATE_MACHINE_HINT=" | ${STATE_MACHINE}"
      ;;
  esac
fi

# 统计 trace 文件最近 24h 内的 spawn / edit
TRACE_FILE="${CWD}/.claude/coder-trace.jsonl"
RECENT_SPAWN=0
RECENT_EDIT=0
if [[ -f "$TRACE_FILE" ]]; then
  CUTOFF=$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)
  RECENT_SPAWN=$(jq -r --arg c "$CUTOFF" 'select(.timestamp > $c) | select(.tool == "Agent" or .tool == "Task") | .timestamp' "$TRACE_FILE" 2>/dev/null | wc -l | tr -d ' ')
  RECENT_EDIT=$(jq -r --arg c "$CUTOFF" 'select(.timestamp > $c) | select(.tool == "Edit" or .tool == "Write") | .timestamp' "$TRACE_FILE" 2>/dev/null | wc -l | tr -d ' ')
fi

# 检查 drift：edit 远多于 spawn
DRIFT_HINT=""
if [[ $RECENT_EDIT -gt 10 && $RECENT_SPAWN -lt 1 ]]; then
  DRIFT_HINT="

⚠️ **协议 drift 检测**：最近 24h Edit ${RECENT_EDIT} 次 / spawn ${RECENT_SPAWN} 次。疑似 orchestrator 直编滑坡（§11.6），建议本次会话严格 spawn 子 agent."
fi

# 输出项目上下文 hint
CONTEXT="📂 coder 项目: ${PROJECT_NAME}（${PRIMARY_LANG} ${LANG_VERSION}）
📅 init: ${INIT_DATE}（coder v${CODER_VERSION}）${STATE_MACHINE_HINT}
📊 最近 24h: ${RECENT_SPAWN} spawn / ${RECENT_EDIT} edit${DRIFT_HINT}

编码任务建议用 coder skill（13 Phase 流水线）。项目特定 agent: ./.claude/agents/."

jq -c -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'

exit 0
