#!/usr/bin/env bash
# validate-findings.sh 单元测试（6 用例：1 合法 + 5 违规）
set -u
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$DIR/scripts/validate-findings.sh"
FIX="$DIR/tests/fixtures/findings-valid.json"
TMP=$(mktemp -d)
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

# Case 1: 合法文件 → PASS exit 0
out=$("$SCRIPT" "$FIX" 2>/dev/null); rc=$?
[ "$rc" -eq 0 ] && echo "$out" | grep -q "^PASS:" && ok "合法文件通过" || bad "Case1 rc=$rc out=$out"

# Case 2: 缺 topic → FAIL 且指明
jq 'del(.topic)' "$FIX" > "$TMP/t2.json"
out=$("$SCRIPT" "$TMP/t2.json" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && echo "$out" | grep -q "topic" && ok "缺topic被拒" || bad "Case2 rc=$rc out=$out"

# Case 3: mode 非法 → FAIL
jq '.mode="fast"' "$FIX" > "$TMP/t3.json"
out=$("$SCRIPT" "$TMP/t3.json" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && echo "$out" | grep -q "mode" && ok "非法mode被拒" || bad "Case3 rc=$rc"

# Case 4: findings 引用不存在的 sub_question → FAIL
jq '.findings[0].sub_question="qX"' "$FIX" > "$TMP/t4.json"
out=$("$SCRIPT" "$TMP/t4.json" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && echo "$out" | grep -q "sub_question" && ok "悬空引用被拒" || bad "Case4 rc=$rc"

# Case 5: evidence.lane 非法 → FAIL
jq '.findings[0].evidence[0].lane="twitter"' "$FIX" > "$TMP/t5.json"
out=$("$SCRIPT" "$TMP/t5.json" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && echo "$out" | grep -q "lane" && ok "非法lane被拒" || bad "Case5 rc=$rc"

# Case 6: meta 缺字段 → FAIL
jq '.meta |= del(.contrarian_run)' "$FIX" > "$TMP/t6.json"
out=$("$SCRIPT" "$TMP/t6.json" 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && echo "$out" | grep -q "contrarian_run" && ok "meta缺字段被拒" || bad "Case6 rc=$rc"

echo "----"; echo "pass=$pass fail=$fail"
rm -rf "$TMP"
[ "$fail" -eq 0 ]
