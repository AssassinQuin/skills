#!/usr/bin/env bash
# model-binding-guard.sh — coder v6.1 spawn 必须显式指定 model（R5.1）
#
# PreToolUse Agent/Task：检查 spawn 是否声明了 model
#
# 强制度：默认 warn，CODER_MODEL_GUARD=block 升级，=off 关闭

set -euo pipefail

MODE="${CODER_MODEL_GUARD:-warn}"
[[ "$MODE" == "off" ]] && exit 0

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

[[ "$TOOL_NAME" == "Agent" || "$TOOL_NAME" == "Task" ]] || exit 0

SUBAGENT_TYPE="$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')"
PROMPT="$(echo "$INPUT" | jq -r '.tool_input.prompt // empty')"
EXPLICIT_MODEL="$(echo "$INPUT" | jq -r '.tool_input.model // empty')"

# 已显式传 model 字段 → 放行
[[ -n "$EXPLICIT_MODEL" ]] && exit 0

# 检查 prompt 是否含 model 指令（use sonnet/opus/haiku）
if echo "$PROMPT" | grep -qiE '(use\s+(sonnet|opus|haiku)|model:\s*(sonnet|opus|haiku))'; then
  exit 0
fi

# 已知 agent（在 frontmatter 声明 model）→ 放行
KNOWN_MODEL_AGENTS_REGEX='^(explorer|researcher|oracle|reviewer|correctness-reviewer|project-reviewer|security-reviewer|test-strategist|brainstorm-collider|domain-skill-agent|evolver-auditor|evolver-explorer)$'
if [[ -n "$SUBAGENT_TYPE" ]] && echo "$SUBAGENT_TYPE" | grep -qE "$KNOWN_MODEL_AGENTS_REGEX"; then
  exit 0
fi

# 项目 lang-coder-project（含 frontmatter model）→ 放行
if [[ "$SUBAGENT_TYPE" == *-coder-project ]]; then
  exit 0
fi

# 未声明 model
MSG="[coder model-binding-guard R5.1] spawn subagent=${SUBAGENT_TYPE:-unknown} 未显式声明 model. 建议: 1) prompt 加 'use sonnet/opus/haiku' 2) spawn 已知 agent 3) tool_input 显式传 model. 判定: 不需推理->haiku, 推理非战略->sonnet, 战略->opus"

if [[ "$MODE" == "block" ]]; then
  jq -c -n --arg msg "$MSG" '{decision: "block", reason: $msg, suppress_output: false}'
  exit 2
else
  jq -c -n --arg msg "$MSG" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $msg}}'
  exit 0
fi
