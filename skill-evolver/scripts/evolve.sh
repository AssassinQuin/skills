#!/usr/bin/env bash
# evolve.sh — skill-evolver 标准化操作 + 流程控制
# 用法: source evolve.sh && <command>

set -euo pipefail

# ============ 评分计算 ============
# 公式唯一定义于此。其他文件引用本命令。
score() {
  local d1="${1:?D1 required (0-10)}"
  local d2="${2:?D2 required (0-10)}"
  local d3="${3:?D3 required (0-10)}"
  local d4="${4:?D4 required (0-10)}"
  local d5="${5:?D5 required (0-10)}"

  for d in "$d1" "$d2" "$d3" "$d4" "$d5"; do
    if (( $(echo "$d < 0 || $d > 10" | bc -l) )); then
      echo "ERROR: dimension $d out of range [0,10]" >&2; return 1
    fi
  done

  echo "scale=1; ($d1*0.10 + $d2*0.20 + $d3*0.15 + $d4*0.20 + $d5*0.35)" | bc
}

# ============ Metrics 更新 ============
metrics-update() {
  local dir="${1:?skill dir required}"
  local round="$2" strategy="$3" before="$4" after="$5"
  local d1="$6" d2="$7" d3="$8" d4="$9" d5="${10}"
  local t_train="${11:-null}" t_val="${12:-null}"
  local metrics="$dir/.evolve/metrics.json"

  if [ ! -f "$metrics" ]; then
    echo '{"total_rounds":0,"history":[]}' > "$metrics"
  fi

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
pp-create() {
  if [ $# -lt 6 ]; then
    echo "Usage: pp-create <skill_dir> <id> <desc> <symptom> <source> <round>" >&2
    return 1
  fi
  local dir="${1:?skill dir}" id="$2" desc="$3" symptom="$4" source="$5" round="$6"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local pp="$dir/.evolve/pain-points.jsonl"

  echo "{\"id\":\"$id\",\"skill\":\"$(basename "$dir")\",\"description\":$(echo "$desc" | jq -Rs .),\"symptom\":$(echo "$symptom" | jq -Rs .),\"source\":\"$source\",\"status\":\"open\",\"created_at\":\"$ts\",\"resolved_at\":null,\"resolved_by\":null,\"round\":$round,\"regression_count\":0}" >> "$pp"
}

pp-resolve() {
  local dir="${1:?skill dir}" id="$2" resolved_by="$3"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local pp="$dir/.evolve/pain-points.jsonl"

  local tmp
  tmp=$(mktemp)
  while IFS= read -r line; do
    echo "$line" | jq --arg id "$id" --arg by "$resolved_by" --arg ts "$ts" \
      'if .id == $id then .status = "resolved" | .resolved_at = $ts | .resolved_by = $by else . end' >> "$tmp"
  done < "$pp"
  mv "$tmp" "$pp"
}

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

git-checkpoint() {
  local msg="${1:?commit message required}"
  git add -A
  git commit -m "$msg"
}

# ============ 验证 ============
verify-metrics() {
  local dir="${1:?skill dir}"
  local metrics="$dir/.evolve/metrics.json"

  if [ ! -f "$metrics" ]; then
    echo "ERROR: $metrics not found" >&2; return 1
  fi

  local invalid
  invalid=$(jq '[.history[].score_before, .history[].score_after, .last_round.score] | map(select(. < 0 or . > 10)) | length' "$metrics")

  if [ "$invalid" -gt 0 ]; then
    echo "ERROR: Found $invalid scores outside [0,10] range in $metrics" >&2
    return 1
  fi

  echo "OK: All scores in [0,10] range"
}

# ============ 流程控制（新增） ============

# 前置条件检查：验证阶段可执行
phase-check() {
  local phase="${1:?phase required: baseline|exploration|application|audit|deployment}"
  local dir="${2:?skill dir required}"
  local evolve_dir="$dir/.evolve"

  case "$phase" in
    baseline)
      [ -f "$dir/SKILL.md" ] || { echo "ERROR: SKILL.md not found in $dir" >&2; return 1; }
      ;;
    exploration)
      [ -f "$evolve_dir/.baseline.marker" ] || { echo "ERROR: baseline phase not completed" >&2; return 1; }
      ;;
    application)
      [ -f "$evolve_dir/.exploration.marker" ] || [ -f "$evolve_dir/.quick-fix.marker" ] || \
        { echo "ERROR: exploration or quick-fix phase not completed" >&2; return 1; }
      ;;
    audit)
      git diff --quiet HEAD 2>/dev/null && \
        { echo "ERROR: no uncommitted changes to audit (commit first)" >&2; return 1; }
      ;;
    deployment)
      [ -f "$evolve_dir/.audit.marker" ] || { echo "ERROR: audit phase not completed" >&2; return 1; }
      ;;
    *)
      echo "ERROR: unknown phase '$phase'" >&2; return 1
      ;;
  esac
  echo "OK: $phase preconditions met"
}

# 阶段开始：写标记文件
phase-start() {
  local phase="${1:?phase required}"
  local dir="${2:?skill dir required}"
  local evolve_dir="$dir/.evolve"

  mkdir -p "$evolve_dir"
  echo "{\"phase\":\"$phase\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$evolve_dir/.$phase.marker"
  echo "Phase started: $phase"
}

# Quick Fix 判定
quick-fix-check() {
  local dir="${1:?skill dir required}"
  local pp="$dir/.evolve/pain-points.jsonl"

  if [ ! -f "$pp" ] || [ ! -s "$pp" ]; then
    echo "FULL_EVOLUTION"
    return 0
  fi

  local open_count
  open_count=$(grep -c '"status":"open"' "$pp" 2>/dev/null || true)

  if [ "$open_count" -eq 0 ]; then
    echo "FULL_EVOLUTION"
    return 0
  fi

  # 有 open 痛点 → 检查是否可走 Quick Fix
  # 判定标准：有明确痛点描述 + 用户直接提供了痛点
  local has_user_stated
  has_user_stated=$(grep -c '"source":"user-stated"' "$pp" 2>/dev/null || true)

  if [ "$has_user_stated" -gt 0 ]; then
    echo "QUICK_FIX_OK"
  else
    echo "FULL_EVOLUTION"
  fi
}
