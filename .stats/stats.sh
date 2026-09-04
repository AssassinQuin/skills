#!/bin/bash
# Skill/Subagent usage report generator
# Usage: stats.sh [--skill <name>] [--since <YYYY-MM-DD>] [--last <N>] [--raw]

LOG="$(dirname "$0")/usage.jsonl"

SKILL_FILTER=""
SINCE=""
LAST=""
RAW=false

while [ $# -gt 0 ]; do
  case "$1" in
    --skill)  SKILL_FILTER="$2"; shift 2;;
    --since)  SINCE="$2"; shift 2;;
    --last)   LAST="$2"; shift 2;;
    --raw)    RAW=true; shift;;
    -h|--help)
      echo "Usage: $(basename "$0") [--skill <name>] [--since <YYYY-MM-DD>] [--last <N>] [--raw]"
      exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

if [ ! -f "$LOG" ]; then
  echo "No usage data at $LOG" >&2
  exit 1
fi

JQ_FILTER='.'
[ -n "$SKILL_FILTER" ] && JQ_FILTER="$JQ_FILTER | select(.skill==\"$SKILL_FILTER\")"
[ -n "$SINCE" ] && JQ_FILTER="$JQ_FILTER | select(.ts >= \"$SINCE\")"

if $RAW; then
  jq -c "$JQ_FILTER" "$LOG" 2>/dev/null
  exit 0
fi

TOTAL=$(jq -c "$JQ_FILTER" "$LOG" 2>/dev/null | grep -c .)

echo "═══ Skill Usage Stats ═══"
echo "Log: $LOG"
echo "Total entries: $TOTAL"
[ -n "$SKILL_FILTER" ] && echo "Filter: skill=$SKILL_FILTER"
[ -n "$SINCE" ] && echo "Filter: since=$SINCE"

[ "$TOTAL" -eq 0 ] && { echo "(no matching entries)"; exit 0; }

echo ""
echo "─── Date range ───"
jq -r "$JQ_FILTER | .ts" "$LOG" 2>/dev/null | sort -u | sed -n '1p;$p' | sed 's/^/  /'

echo ""
echo "─── Top skills（已归一化命名空间前缀，如 superpowers:xxx → xxx）───"
jq -r "$JQ_FILTER | select(.type==\"skill\") | (.skill // \"?\") | split(\":\") | last" "$LOG" 2>/dev/null \
  | sort | uniq -c | sort -rn | head -15 | sed 's/^/  /'

echo ""
echo "─── Subagents ───"
SUB_COUNT=$(jq -r "$JQ_FILTER | select(.type==\"subagent\") | .subagent" "$LOG" 2>/dev/null | grep -c .)
if [ "$SUB_COUNT" -gt 0 ]; then
  jq -r "$JQ_FILTER | select(.type==\"subagent\") | \"\(.subagent) [\(.model // \"?\")]\"" "$LOG" 2>/dev/null \
    | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'
else
  echo "  (no subagent invocations recorded)"
fi

echo ""
echo "─── Recent ${LAST:-5} ───"
N="${LAST:-5}"
jq -r "$JQ_FILTER | \"\(.ts) \(.type) \(.skill // .subagent // \"?\")\"" "$LOG" 2>/dev/null \
  | tail -"$N" | sed 's/^/  /'
