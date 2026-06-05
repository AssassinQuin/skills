#!/usr/bin/env bash
# evolve-ops.sh — skill-evolver 标准化操作脚本
# 用法: source evolve-ops.sh && <command>
# 命令: score, metrics-init, metrics-update, pp-create, pp-resolve, pp-regress, git-setup, git-checkpoint

set -euo pipefail

# ============ 评分计算 ============
# 用法: score D1 D2 D3 D4 D5
# 输出: 加权总分(0-10)
score() {
  local d1="${1:?D1 required (0-10)}"
  local d2="${2:?D2 required (0-10)}"
  local d3="${3:?D3 required (0-10)}"
  local d4="${4:?D4 required (0-10)}"
  local d5="${5:?D5 required (0-10)}"

  # 验证范围
  for d in "$d1" "$d2" "$d3" "$d4" "$d5"; do
    if (( $(echo "$d < 0 || $d > 10" | bc -l) )); then
      echo "ERROR: dimension $d out of range [0,10]" >&2; return 1
    fi
  done

  # Score = D1×0.10 + D2×0.20 + D3×0.15 + D4×0.20 + D5×0.35
  echo "scale=1; ($d1*0.10 + $d2*0.20 + $d3*0.15 + $d4*0.20 + $d5*0.35)" | bc
}

# ============ Metrics 更新 ============
# 用法: metrics-update <skill_dir> <round> <strategy> <score_before> <score_after> <d1> <d2> <d3> <d4> <d5> [T_train_rate] [T_val_rate]
metrics-update() {
  local dir="${1:?skill dir required}"
  local round="$2" strategy="$3" before="$4" after="$5"
  local d1="$6" d2="$7" d3="$8" d4="$9" d5="${10}"
  local t_train="${11:-null}" t_val="${12:-null}"
  local metrics="$dir/.evolve/metrics.json"

  if [ ! -f "$metrics" ]; then
    echo '{"total_rounds":0,"history":[]}' > "$metrics"
  fi

  # 用 jq 更新
  local delta
  delta=$(echo "scale=1; $after - $before" | bc)
  local date
  date=$(date +%Y-%m-%d)

  jq --arg round "$round" --arg strategy "$strategy" \
     --arg before "$before" --arg after "$after" --arg delta "$delta" \
     --arg date "$date" \
     --arg d1 "$d1" --arg d2 "$d2" --arg d3 "$d3" --arg d4 "$d4" --arg d5 "$d5" \
     --arg t_train "$t_train" --arg t_val "$t_val" \
  '
    .total_rounds += 1 |
    .last_round = {date: $date, strategy: $strategy, score: ($after | tonumber)} |
    .history += [{
      round: ($round | tonumber),
      date: $date,
      strategy: $strategy,
      score_before: ($before | tonumber),
      score_after: ($after | tonumber),
      delta: ($delta | tonumber)
    }]
  ' "$metrics" > "${metrics}.tmp" && mv "${metrics}.tmp" "$metrics"
}

# ============ Pain Points CRUD ============
# 创建: pp-create <skill_dir> <id> <description> <symptom> <source> <round>
pp-create() {
  local dir="${1:?skill dir}" id="$2" desc="$3" symptom="$4" source="$5" round="$6"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local pp="$dir/.evolve/pain-points.jsonl"

  echo "{\"id\":\"$id\",\"skill\":\"$(basename "$dir")\",\"description\":$(echo "$desc" | jq -Rs .),\"symptom\":$(echo "$symptom" | jq -Rs .),\"source\":\"$source\",\"status\":\"open\",\"created_at\":\"$ts\",\"resolved_at\":null,\"resolved_by\":null,\"round\":$round,\"regression_count\":0}" >> "$pp"
}

# 解决: pp-resolve <skill_dir> <id> <resolved_by>
pp-resolve() {
  local dir="${1:?skill dir}" id="$2" resolved_by="$3"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local pp="$dir/.evolve/pain-points.jsonl"

  # 原地更新 status + resolved_at + resolved_by
  local tmp
  tmp=$(mktemp)
  while IFS= read -r line; do
    echo "$line" | jq --arg id "$id" --arg by "$resolved_by" --arg ts "$ts" \
      'if .id == $id then .status = "resolved" | .resolved_at = $ts | .resolved_by = $by else . end' >> "$tmp"
  done < "$pp"
  mv "$tmp" "$pp"
}

# 回归: pp-regress <skill_dir> <id>
pp-regress() {
  local dir="${1:?skill dir}" id="$2"
  local pp="$dir/.evolve/pain-points.jsonl"

  local tmp
  tmp=$(mktemp)
  while IFS= read -r line; do
    echo "$line" | jq --arg id "$id" \
      'if .id == $id then .status = "regressed" | .regression_count += 1 else . end' >> "$tmp"
  done < "$pp"
  mv "$tmp" "$pp"
}

# ============ Git 操作 ============
# git-setup <skill_name> — 创建 evolve 分支
git-setup() {
  local skill="${1:?skill name required}"
  local branch="evolve/${skill}/$(date +%Y%m%d)"
  local existing
  existing=$(git branch --list "$branch" | tr -d ' ')

  if [ -n "$existing" ]; then
    echo "ERROR: Branch $branch already exists. Delete first: git branch -D $branch" >&2
    return 1
  fi

  git checkout -b "$branch"
  echo "Branch: $branch"
}

# git-checkpoint <message> — 标准 commit
git-checkpoint() {
  local msg="${1:?commit message required}"
  git add -A
  git commit -m "$msg"
}

# ============ 验证 ============
# verify-metrics <skill_dir> — 检查 metrics.json 评分一致性
verify-metrics() {
  local dir="${1:?skill dir}"
  local metrics="$dir/.evolve/metrics.json"

  if [ ! -f "$metrics" ]; then
    echo "ERROR: $metrics not found" >&2; return 1
  fi

  # 检查所有 score 在 0-10 范围
  local invalid
  invalid=$(jq '[.history[].score_before, .history[].score_after, .last_round.score] | map(select(. < 0 or . > 10)) | length' "$metrics")

  if [ "$invalid" -gt 0 ]; then
    echo "ERROR: Found $invalid scores outside [0,10] range in $metrics" >&2
    return 1
  fi

  echo "OK: All scores in [0,10] range"
}
