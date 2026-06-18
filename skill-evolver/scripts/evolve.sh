#!/usr/bin/env bash
# evolve.sh — SkillEvolver v8 辅助脚本（精简版）
#
# v8 重构：从 v7 的 13+ 命令精简到 5 个。
# 删除：score(D1-D5)、pp-*、metrics-update、quick-fix-check、diff-budget-check、
#       rejected-edit-record、test-record、branch-check、regression-check、
#       silent-bypass-check、skill-validate、phase-check、phase-start、slow-update-check
# 原因：包装 jq 一行无额外能力；新架构（论文 Algorithm 1）不需要这些概念。
#
# 用法: source evolve.sh && <command>

set -euo pipefail

# ============ Trace 记录（替代 v7 的 pp-*/test-record/rejected-edit-record）============
# 所有进化过程的结构化数据都写入 traces.jsonl，主 agent 直接 jq 操作
trace-record() {
  local dir="${1:?skill dir required}"
  local type="${2:?type required (trial|audit|deployment)}"
  local data="${3:?json data required}"

  local file="$dir/.evolve/traces.jsonl"
  mkdir -p "$(dirname "$file")"

  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"$ts\",\"type\":\"$type\",$data}" >> "$file"
  echo "trace recorded: type=$type"
}

# ============ Git 操作 ============
_git-root() {
  local dir="${1:-.}"
  dir=$(cd "$dir" && pwd)
  git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo ""
}

git-setup() {
  local skill="${1:?skill name required}"
  local skill_dir="${2:-.}"
  local branch="evolve/${skill}/$(date +%Y%m%d)"
  local git_root; git_root=$(_git-root "$skill_dir")

  if [ -z "$git_root" ]; then
    echo "WARN: $skill_dir is not in a git repo. Operating in CWD." >&2
    git_root="$(pwd)"
  fi

  local existing; existing=$(git -C "$git_root" branch --list "$branch" | tr -d ' ')
  if [ -n "$existing" ]; then
    echo "ERROR: Branch $branch already exists in $git_root." >&2
    echo "Delete first: git -C $git_root branch -D $branch" >&2
    return 1
  fi

  git -C "$git_root" checkout -b "$branch"
  echo "Repo: $git_root"
  echo "Branch: $branch"
}

git-checkpoint() {
  local msg="${1:?commit message required}"
  local skill_dir="${2:-.}"
  local git_root; git_root=$(_git-root "$skill_dir")

  if [ -z "$git_root" ]; then
    echo "WARN: not in a git repo, skipping commit" >&2
    return 0
  fi

  git -C "$git_root" add -A "$skill_dir"
  if git -C "$git_root" diff --cached --quiet; then
    echo "No changes to commit"
    return 0
  fi

  git -C "$git_root" commit -m "$msg"
  echo "Committed: $msg"
}

# ============ 快照保存 ============
snapshot-save() {
  local dir="${1:?skill dir required}"
  local label="${2:-BEFORE}"  # BEFORE | v1 | v2 | ... | vSTAR
  local skill_name; skill_name=$(basename "$dir")
  local snap_dir="$dir/.evolve/snapshots"
  local snap_file="$snap_dir/${skill_name}-${label}.md"

  [ -f "$dir/SKILL.md" ] || { echo "ERROR: SKILL.md not found in $dir" >&2; return 1; }

  mkdir -p "$snap_dir"
  cp "$dir/SKILL.md" "$snap_file"

  # 多文件 skill 时同时保存 manifest
  local manifest_file="$snap_dir/${skill_name}-${label}-manifest.txt"
  find "$dir" -not -path '*/.evolve/*' -not -path '*/.git/*' -type f | \
    sed "s|$dir/||" | sort | while read -r f; do
      lines=$(wc -l < "$dir/$f" 2>/dev/null || echo "?")
      printf "%-6s %s\n" "$lines" "$f"
    done > "$manifest_file"

  # latest symlink（仅 BEFORE）
  if [ "$label" = "BEFORE" ]; then
    ln -sf "$snap_file" "$snap_dir/${skill_name}-latest.md"
    ln -sf "$manifest_file" "$snap_dir/${skill_name}-latest-manifest.txt"
  fi

  echo "Snapshot saved: $snap_file"
}

# ============ v* 选择（论文 Algorithm 1 line 13）============
# 从 traces.jsonl 统计每轮 trial 的通过率，输出 argmax
v-star-select() {
  local dir="${1:?skill dir required}"
  local file="$dir/.evolve/traces.jsonl"

  [ -f "$file" ] || { echo "ERROR: traces.jsonl not found" >&2; return 1; }

  # 只统计 type=trial 的记录，按 round 分组算 pass_rate
  jq -s '
    [ .[] | select(.type == "trial") ]
    | group_by(.round)
    | map({
        round: .[0].round,
        total: length,
        pass: [.[] | select(.y == 1 or .y == "1" or .y == true)] | length,
        fail: [.[] | select(.y == 0 or .y == "0" or .y == false)] | length,
        unverified: [.[] | select(.y == "UNVERIFIED" or .y == null)] | length
      })
    | map(.pass_rate = (if .total > 0 then (.pass / .total) else 0 end))
    | sort_by(-.pass_rate)
    | .[0]
  ' "$file"
}

# ============ 自检（source 时打印可用命令）============
evolve-help() {
  cat <<'EOF'
SkillEvolver v8 commands:

  trace-record <dir> <type> <json>     Record a trace to traces.jsonl
                                        types: trial | audit | deployment
  git-setup <skill> [dir]              Create evolve branch
  git-checkpoint <msg> [dir]           Stage + commit
  snapshot-save <dir> [label]          Save SKILL.md snapshot
                                        labels: BEFORE | v1 | v2 | ... | vSTAR
  v-star-select <dir>                  Pick v* = argmax pass_rate(traces.jsonl)
  evolve-help                          This message

Removed in v8 (use jq directly or main agent handles):
  score, pp-create/resolve/regress, metrics-update, quick-fix-check,
  diff-budget-check, rejected-edit-record, test-record, branch-check,
  regression-check, silent-bypass-check, skill-validate, phase-check,
  phase-start, slow-update-check
EOF
}
