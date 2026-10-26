#!/usr/bin/env bash
# One gate for the layered agent stack: Git, skills, MCP manifest, secrets, CC Switch boundary.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0
step() { printf '\n═══ %s ═══\n' "$1"; }
fail() { printf '✗ %s\n' "$1" >&2; FAILED=1; }
ok() { printf '✓ %s\n' "$1"; }

step 'Git recovery point'
if git -C "$ROOT" diff --quiet && git -C "$ROOT" diff --cached --quiet; then
  ok "clean work tree at $(git -C "$ROOT" branch --show-current)"
else
  fail 'Git work tree is dirty; changes are not a recovery point'
fi

step 'Skill deployment topology'
if ! bash "$ROOT/scripts/deploy.sh"; then fail 'skill deployment topology'; fi

step 'Skill health ledger'
if ! bash "$ROOT/scripts/ledger.sh" | tail -8; then fail 'skill ledger'; fi

step 'MCP manifest'
if ! python "$ROOT/scripts/sync_mcp.py" --check; then fail 'MCP manifest/live adapter drift'; fi

step 'MCP generator tests'
if ! python -m pytest -q "$ROOT/tests/test_sync_mcp.py"; then fail 'MCP generator tests'; fi

step 'Inventory secret scan'
if grep -RInE 'sk-[A-Za-z0-9_-]{16,}|Bearer [A-Za-z0-9._~+/=-]{12,}|gh[pousr]_[A-Za-z0-9_]{16,}' "$ROOT/config/mcp" "$ROOT/scripts/sync_mcp.py"; then
  fail 'literal credential pattern in tracked MCP config'
else
  ok 'no literal credential patterns'
fi

step 'CC Switch permissions and MCP boundary'
CC="$HOME/.cc-switch/cc-switch.db"
if [ "$(find "$HOME/.cc-switch" -type f ! -perm 600 | wc -l | tr -d ' ')" != 0 ]; then
  fail 'CC Switch contains files looser than 0600'
else
  ok 'all CC Switch files are 0600'
fi
if [ "$(find "$HOME/.cc-switch" -type d ! -perm 700 | wc -l | tr -d ' ')" != 0 ]; then
  fail 'CC Switch contains directories looser than 0700'
else
  ok 'all CC Switch directories are 0700'
fi
if [ ! -f "$CC" ]; then
  fail 'CC Switch database missing'
elif ! integrity=$(sqlite3 "file:$CC?mode=ro" 'pragma integrity_check'); then
  fail 'CC Switch SQLite integrity check failed'
elif [ "$integrity" != ok ]; then
  fail "CC Switch SQLite integrity: $integrity"
else
  ok 'CC Switch SQLite integrity is ok'
  enabled=$(sqlite3 "file:$CC?mode=ro" "select count(*) from mcp_servers where enabled_claude=1 or enabled_codex=1 or enabled_gemini=1 or enabled_opencode=1 or enabled_hermes=1 or enabled_grokbuild=1 or enabled_mcode=1 or enabled_pi=1;")
  if [ "$enabled" != 0 ]; then
    fail "$enabled CC Switch MCP sync flags remain enabled; provider-only boundary is not frozen"
  else
    ok 'CC Switch MCP sync flags are disabled'
  fi
fi

step 'Recent encrypted-or-local recovery snapshot'
latest=$(find "$HOME/backups" -path '*/agent-stack-*/cc-switch.db' -type f -mtime -2 -print 2>/dev/null | sort | tail -1 || true)
if [ -n "$latest" ]; then
  ok "fresh snapshot: $latest"
else
  fail 'no agent-stack snapshot newer than 48h'
fi

if [ "$FAILED" -ne 0 ]; then
  printf '\nFAIL: agent stack audit\n' >&2
  exit 1
fi
printf '\nPASS: agent stack audit\n'
