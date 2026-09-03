#!/usr/bin/env bash
# validate-findings.sh — findings.json schema 校验（R12：失败显式报错，不静默）
# 用法: validate-findings.sh <findings.json>
# 退出: 0 PASS；1 FAIL（stdout 列出全部违规）；2 用法错误
set -u
f="${1:-}"
if [ -z "$f" ] || [ ! -f "$f" ]; then
  echo "validate-findings.sh: 缺少/不存在文件: $f" >&2
  exit 2
fi
jq -e . "$f" >/dev/null 2>&1 || { echo "FAIL: $f"; echo "  - 不是合法 JSON"; exit 1; }

errs=$(jq -r '
  [
    (if (.topic | type) != "string" then "topic 缺失或非字符串" else empty end),
    (if ((.date // "") | test("^\\d{4}-\\d{2}-\\d{2}$") | not) then "date 非 YYYY-MM-DD: \(.date)" else empty end),
    ((.mode // "") as $m | (if (($m == "quick" or $m == "deep") | not) then "mode 非法: \($m)" else empty end)),
    (if (.sub_questions | type) != "array" or (.sub_questions | length) == 0 then "sub_questions 需非空数组" else empty end),
    ( .sub_questions[]? |
      (if ((.id // "") == "") then "sub_questions[] 缺 id" else empty end),
      (if ((.question // "") == "") then "sub_questions[] 缺 question" else empty end),
      ((.tier // "") as $t | (if (($t == "core" or $t == "background") | not) then "sub_questions[\(.id)].tier 非法: \($t)" else empty end)),
      ((.status // "") as $s | (if (($s == "answered" or $s == "partial" or $s == "unanswered") | not) then "sub_questions[\(.id)].status 非法: \($s)" else empty end))
    ),
    (if (.findings | type) != "array" then "findings 需数组" else empty end),
    ( .findings[]? |
      (if ((.claim // "") == "") then "findings[] 缺 claim" else empty end),
      (if ((.sub_question // "") == "") then "findings[] 缺 sub_question" else empty end),
      ((.confidence // "") as $c | (if (($c == "high" or $c == "medium" or $c == "low") | not) then "findings[].confidence 非法: \($c)" else empty end)),
      ( .evidence[]? |
        (if ((.url // "") == "") then "evidence[] 缺 url" else empty end),
        ((.lane // "") as $l | (if (($l == "cn" or $l == "glb" or $l == "zhihu" or $l == "prime" or $l == "human") | not) then "evidence.lane 非法: \($l)" else empty end))
      )
    ),
    ( ([.sub_questions[]?.id]) as $ids |
      .findings[]? |
      select((.sub_question) as $s | ($ids | index($s)) == null) |
      "findings 引用不存在的 sub_question: \(.sub_question)"
    ),
    (if (.strongest_objection | type) != "string" then "strongest_objection 需字符串（可为「未发现」）" else empty end),
    (if (.gaps | type) != "array" then "gaps 需数组" else empty end),
    ( (.meta // {}) |
      (if (has("requested_mode") | not) then "meta 缺 requested_mode" else empty end),
      (if (has("effective_mode") | not) then "meta 缺 effective_mode" else empty end),
      (if (has("reused_queries") | not) then "meta 缺 reused_queries" else empty end),
      (if (has("fresh_queries") | not) then "meta 缺 fresh_queries" else empty end),
      (if (has("contrarian_run") | not) then "meta 缺 contrarian_run" else empty end)
    )
  ] | join("\n")
' "$f" 2>&1)

if [ -n "$errs" ]; then
  echo "FAIL: $f"
  printf '%s\n' "$errs" | while IFS= read -r line; do [ -n "$line" ] && echo "  - $line"; done
  exit 1
fi
echo "PASS: $f"
