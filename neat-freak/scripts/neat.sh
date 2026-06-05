#!/usr/bin/env bash
# neat.sh — neat-freak 辅助脚本
# Usage: source neat.sh && <command>

set -euo pipefail

NEAT_STATE_DIR="/tmp/.neat-freak"

# ===== git 变更追踪 =====

neat-snapshot() {
  # 记录当前 git HEAD hash，供后续 diff
  mkdir -p "$NEAT_STATE_DIR"
  local hash
  hash=$(git rev-parse HEAD 2>/dev/null || echo "NO_GIT")
  echo "$hash" > "$NEAT_STATE_DIR/last-hash"
  echo "SNAPSHOT: $hash"
}

neat-last-hash() {
  cat "$NEAT_STATE_DIR/last-hash" 2>/dev/null || echo "NO_SNAPSHOT"
}

neat-diff-summary() {
  # 输出上次 snapshot 以来的变更摘要
  local last
  last=$(neat-last-hash)
  if [ "$last" = "NO_SNAPSHOT" ] || [ "$last" = "NO_GIT" ]; then
    echo "NO_BASELINE: 无上次 snapshot 记录，将使用对话上下文提取变更"
    return 1
  fi
  echo "=== 变更文件（since $last）==="
  git diff --name-status "$last"..HEAD 2>/dev/null | head -80
  echo ""
  echo "=== 变更统计 ==="
  git diff --stat "$last"..HEAD 2>/dev/null | tail -1
}

neat-diff-grep() {
  # 在变更文件中搜索关键词
  local keyword="$1"
  local last
  last=$(neat-last-hash)
  [ "$last" = "NO_SNAPSHOT" ] && return 1
  git diff "$last"..HEAD --name-only 2>/dev/null | while read -r f; do
    if grep -l "$keyword" "$f" 2>/dev/null; then
      true
    fi
  done
}

# ===== 过期扫描 =====

neat-scan-stale() {
  local paths="${1:-memory/ CLAUDE.md}"
  echo "=== 相对时间 ==="
  grep -rn "今天\|昨天\|最近\|today\|yesterday\|recently" $paths 2>/dev/null || echo "(clean)"
  echo ""
  echo "=== 废弃/TODO ==="
  grep -rn "废弃\|deprecated\|TODO\|FIXME" $paths 2>/dev/null || echo "(clean)"
}

# ===== git 提交 =====

neat-commit() {
  local msg="$1"
  if [ -z "$(git status -s)" ]; then
    echo "NOTHING_TO_COMMIT"
    return 0
  fi
  git add -u
  git commit -m "$(cat <<EOF
neat-freak: $msg

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
  )"
  echo "COMMITTED: $(git log --oneline -1)"
}

neat-push() {
  local branch
  branch=$(git branch --show-current)
  local remote
  remote=$(git remote 2>/dev/null | head -1)
  if [ -z "$remote" ]; then
    echo "NO_REMOTE: 无远程仓库"
    return 1
  fi
  git push "$remote" "$branch" 2>&1 || git push -u "$remote" "$branch" 2>&1
  echo "PUSHED: $branch → $remote"
}
