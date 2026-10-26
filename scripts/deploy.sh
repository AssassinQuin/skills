#!/usr/bin/env bash
# deploy.sh — Active Catalog deployment audit for symlink-based skill runtimes.
# Principle: /Users/ganjie/skills is the active source; runtimes consume symlinks.
# Exit: 0 healthy; 1 broken/missing topology or malformed skill; 2 usage error.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0

echo "═══ Skill deployment audit ═══"
echo "Active source: $REPO"
echo

audit_link() {
  local link="$1"
  if [ -L "$link" ]; then
    local target
    target=$(readlink "$link")
    if [ "$target" = "$REPO" ]; then
      echo "  ✓ $link → $REPO"
    else
      echo "  ✗ $link → $target (expected $REPO)"
      FAIL=1
    fi
  elif [ -d "$link" ] && [ "$(cd "$link" && pwd -P)" = "$REPO" ]; then
    echo "  ✓ $link resolves to $REPO"
  else
    echo "  ✗ $link is missing or is an independent directory"
    FAIL=1
  fi
}

echo "─── Runtime adapters ───"
audit_link "$HOME/.claude/skills"
audit_link "$HOME/.codex/skills"
audit_link "$HOME/.agents/skills"
echo

echo "─── Vendor-backed wrappers ───"
EXT=0
for d in "$REPO"/*/; do
  [ -L "${d%/}" ] || continue
  NAME="${d%/}"; NAME="${NAME##*/}"
  LINK=$(readlink "${d%/}")
  if [ -e "${d%/}" ]; then
    echo "  → $NAME → $LINK"
  else
    echo "  ✗ $NAME → $LINK (broken vendor wrapper)"
    FAIL=1
  fi
  EXT=$((EXT+1))
done
[ "$EXT" -eq 0 ] && echo "  (none)"
echo

echo "─── Active SKILL.md integrity ───"
MISS=0
for d in "$REPO"/*/; do
  name="${d%/}"; name="${name##*/}"
  [ -d "$d" ] || continue
  [ -L "${d%/}" ] && continue
  case "$name" in
    .*|scripts|reports|datastore|data|docs|config|tests|node_modules) continue ;;
  esac
  if [ ! -f "$d/SKILL.md" ]; then
    echo "  ✗ $name/ is an active directory but has no SKILL.md"
    MISS=$((MISS+1)); FAIL=1
  fi
done
[ "$MISS" -eq 0 ] && echo "  ✓ all active skill directories have SKILL.md"
echo

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: single active source + symlink adapters"
  exit 0
fi
echo "FAIL: deployment audit found errors"
exit 1
