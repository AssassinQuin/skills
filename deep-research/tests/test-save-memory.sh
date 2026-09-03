#!/usr/bin/env bash
# save-memory.sh 单元测试（4 用例）
set -u
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$DIR/scripts/save-memory.sh"
TMP=$(mktemp -d); MEM="$TMP/mem.json"; R="$TMP/r.json"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

echo '[{"title":"t1","url":"u1","snippet":"s1"}]' > "$R"

# Case 1: 保存新条目
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "赛力斯 财报" --lane cn --ttl short --task "reports/research/x/" --results "$R" 2>/dev/null)
jq -e --arg k "赛力斯 财报|cn" --arg d "$(date +%F)" '.[$k].fetched_at==$d and .[$k].ttl_class=="short" and (.[$k].results|length)==1 and .[$k].task=="reports/research/x/"' "$MEM" >/dev/null \
  && ok "保存新条目结构完整" || bad "Case1 out=$out file=$(cat "$MEM")"

# Case 2: 同 key 再存 = 更新不重复
echo '[{"title":"t2","url":"u2","snippet":"s2"},{"title":"t3","url":"u3","snippet":"s3"}]' > "$R"
SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "赛力斯 财报" --lane cn --ttl long --task "reports/research/y/" --results "$R" >/dev/null 2>&1
n=$(jq '. | length' "$MEM"); rn=$(jq '.["赛力斯 财报|cn"].results | length' "$MEM")
[ "$n" = "1" ] && [ "$rn" = "2" ] && ok "同key更新不重复" || bad "Case2 keys=$n results=$rn"

# Case 3: results 非法 JSON → exit 2
echo 'not json' > "$TMP/bad.json"
SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "q" --lane cn --ttl short --task "t/" --results "$TMP/bad.json" >/dev/null 2>&1
[ $? -eq 2 ] && ok "非法JSON报错exit2" || bad "Case3"

# Case 4: 缺参数 → exit 2
SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "q" --lane cn >/dev/null 2>&1
[ $? -eq 2 ] && ok "缺参数报错exit2" || bad "Case4"

echo "----"; echo "pass=$pass fail=$fail"
rm -rf "$TMP"
[ "$fail" -eq 0 ]
