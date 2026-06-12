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
  mkdir -p "$(dirname "$pp")"

  # printf 比 echo 安全（不解释转义序列）
  local desc_json symptom_json
  desc_json=$(printf '%s' "$desc" | jq -Rs .)
  symptom_json=$(printf '%s' "$symptom" | jq -Rs .)

  printf '{"id":"%s","skill":"%s","description":%s,"symptom":%s,"source":"%s","status":"open","created_at":"%s","resolved_at":null,"resolved_by":null,"round":%s,"regression_count":0}\n' \
    "$id" "$(basename "$dir")" "$desc_json" "$symptom_json" "$source" "$ts" "$round" >> "$pp"
}

pp-resolve() {
  local dir="${1:?skill dir}" id="$2" resolved_by="$3"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local pp="$dir/.evolve/pain-points.jsonl"

  [ -f "$pp" ] || { echo "ERROR: $pp not found" >&2; return 1; }

  # --slurp 一次性读取所有行，-c '.[]' 逐条输出回 JSONL
  jq --arg id "$id" --arg by "$resolved_by" --arg ts "$ts" \
    --slurp -c '.[] | if .id == $id then .status = "resolved" | .resolved_at = $ts | .resolved_by = $by else . end' \
    "$pp" > "${pp}.tmp" && mv "${pp}.tmp" "$pp"
}

pp-regress() {
  local dir="${1:?skill dir}" id="$2"
  local pp="$dir/.evolve/pain-points.jsonl"

  [ -f "$pp" ] || { echo "ERROR: $pp not found" >&2; return 1; }

  jq --arg id "$id" \
    --slurp -c '.[] | if .id == $id then .status = "regressed" | .regression_count += 1 else . end' \
    "$pp" > "${pp}.tmp" && mv "${pp}.tmp" "$pp"
}

# ============ Git 操作 ============

# 检测 skill 所在的 git repo root。不在 skill_dir 内时返回空。
_git-root() {
  local dir="${1:?directory required}"
  git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo ""
}

git-setup() {
  local skill="${1:?skill name required}"
  local skill_dir="${2:-.}"
  local branch="evolve/${skill}/$(date +%Y%m%d)"
  local git_root
  git_root=$(_git-root "$skill_dir")

  if [ -z "$git_root" ]; then
    echo "WARN: $skill_dir is not in a git repo. Operating in CWD." >&2
    git_root="$(pwd)"
  fi

  local existing
  existing=$(git -C "$git_root" branch --list "$branch" | tr -d ' ')

  if [ -n "$existing" ]; then
    echo "ERROR: Branch $branch already exists in $git_root. Delete first: git -C $git_root branch -D $branch" >&2
    return 1
  fi

  git -C "$git_root" checkout -b "$branch"
  echo "Repo: $git_root"
  echo "Branch: $branch"
}

git-checkpoint() {
  local msg="${1:?commit message required}"
  local skill_dir="${2:-.}"
  local git_root
  git_root=$(_git-root "$skill_dir")

  if [ -z "$git_root" ]; then
    echo "WARN: No git repo detected for $skill_dir. Operating in CWD." >&2
    git_root="$(pwd)"
  fi

  git -C "$git_root" add -A
  git -C "$git_root" commit -m "$msg"
  echo "Committed to repo: $git_root"
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

# ============ Silent-bypass 检测 ============
# 检查 skill 是否被实际调用，而非仅存在于 SKILL.md 中
silent-bypass-check() {
  local dir="${1:?skill dir required}"
  local skill_name
  skill_name=$(basename "$dir")
  local evolve_dir="$dir/.evolve"
  local issues=0

  echo "=== Silent-bypass Check: $skill_name ==="

  # Check 1: SKILL.md 有触发词但无执行标记
  if [ -f "$dir/SKILL.md" ]; then
    local has_triggers
    has_triggers=$(grep -c "Trigger:" "$dir/SKILL.md" 2>/dev/null || echo "0")
    local has_markers
    has_markers=$(find "$evolve_dir" -name "*.marker" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$has_triggers" -gt 0 ] && [ "$has_markers" -eq 0 ]; then
      echo "WARN: Skill has triggers but no execution markers. Never evolved?" >&2
      issues=$((issues + 1))
    fi
  fi

  # Check 2: 约束是否只有文字声明，无执行层保障
  if [ -f "$dir/SKILL.md" ]; then
    local hard_constraints
    hard_constraints=$(grep -cE "(硬约束|不可跳过|MUST|mandatory)" "$dir/SKILL.md" 2>/dev/null || echo "0")
    local script_enforced
    script_enforced=$(grep -c "phase-check\|AskUserQuestion\|silent-bypass" "$dir/SKILL.md" 2>/dev/null || echo "0")

    if [ "$hard_constraints" -gt "$script_enforced" ]; then
      echo "WARN: $((hard_constraints - script_enforced)) constraint(s) declared but not script-enforced" >&2
      issues=$((issues + 1))
    fi
  fi

  # Check 3: 阶段标记完整性（缺中间阶段 = 可能被跳过）
  if [ -d "$evolve_dir" ]; then
    local markers
    markers=$(ls "$evolve_dir"/.*.marker 2>/dev/null | wc -l | tr -d ' ')
    if [ "$markers" -gt 0 ] && [ "$markers" -lt 3 ]; then
      echo "WARN: Only $markers phase markers found (expected 5 for full evolution). Phases may have been skipped." >&2
      issues=$((issues + 1))
    fi
  fi

  # Check 4: evolution-log 存在但无 round 记录
  if [ -f "$evolve_dir/evolution-log.jsonl" ]; then
    local rounds
    rounds=$(wc -l < "$evolve_dir/evolution-log.jsonl" | tr -d ' ')
    if [ "$rounds" -eq 0 ]; then
      echo "WARN: evolution-log.jsonl exists but has no round records" >&2
      issues=$((issues + 1))
    fi
  fi

  if [ "$issues" -eq 0 ]; then
    echo "OK: No silent-bypass signals detected"
  else
    echo "FOUND: $issues silent-bypass signal(s)"
  fi
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
      local git_root
      git_root=$(_git-root "$dir")
      if [ -n "$git_root" ]; then
        git -C "$git_root" diff --quiet HEAD 2>/dev/null && \
          { echo "ERROR: no uncommitted changes to audit in $git_root (commit first)" >&2; return 1; }
      else
        git diff --quiet HEAD 2>/dev/null && \
          { echo "ERROR: no uncommitted changes to audit (commit first)" >&2; return 1; }
      fi
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

# ============ 轻量质量验证（Mode H / 编辑后触发） ============
skill-validate() {
  local dir="${1:?skill dir required}"
  local skill_name
  skill_name=$(basename "$dir")
  local issues=0

  echo "=== Skill Validate: $skill_name ==="

  # Check 1: SKILL.md exists
  [ -f "$dir/SKILL.md" ] || { echo "ERROR: SKILL.md not found in $dir" >&2; return 1; }

  # Check 2: Frontmatter required fields
  local has_name has_desc
  has_name=$(grep -c "^name:" "$dir/SKILL.md" 2>/dev/null || echo "0")
  has_desc=$(grep -c "^description:" "$dir/SKILL.md" 2>/dev/null || echo "0")
  [ "$has_name" -ge 1 ] || { echo "ERROR: frontmatter missing 'name'" >&2; issues=$((issues + 1)); }
  [ "$has_desc" -ge 1 ] || { echo "ERROR: frontmatter missing 'description'" >&2; issues=$((issues + 1)); }

  # Check 3: Bloat detection
  local lines
  lines=$(wc -l < "$dir/SKILL.md" | tr -d ' ')
  if [ "$lines" -gt 200 ]; then
    echo "WARN: SKILL.md is $lines lines (>200 = bloat threshold)" >&2
    issues=$((issues + 1))
  fi

  # Check 4: Reference files count
  if [ -d "$dir/references" ]; then
    local refs
    refs=$(find "$dir/references" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$refs" -gt 10 ]; then
      echo "WARN: $refs reference files (>10 = bloat threshold)" >&2
      issues=$((issues + 1))
    fi
  fi

  # Check 5: Silent-bypass
  silent-bypass-check "$dir" 2>/dev/null || issues=$((issues + 1))

  # Check 6: Constraint count
  local constraints
  constraints=$(grep -cE "^\d+\.\s" "$dir/SKILL.md" 2>/dev/null || echo "0")
  if [ "$constraints" -gt 15 ]; then
    echo "WARN: $constraints constraints (>15 = constraint bloat)" >&2
    issues=$((issues + 1))
  fi

  # Summary
  if [ "$issues" -eq 0 ]; then
    echo "OK: All quality checks passed ($lines lines)"
  else
    echo "FOUND: $issues issue(s) — consider running full evolution (/skill-evolver 进化 $skill_name)"
  fi
  return $issues
}
