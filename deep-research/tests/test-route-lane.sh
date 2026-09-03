#!/usr/bin/env bash
# route-lane.sh 单元测试（8 用例）
set -u
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$DIR/scripts/route-lane.sh"
TMP=$(mktemp -d); MEM="$TMP/mem.json"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }

# Case 1: 空缓存 → search + cn 工具
echo '{}' > "$MEM"
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "赛力斯 财报" --lane cn 2>/dev/null)
echo "$out" | jq -e '.action=="search" and .lane=="cn" and .tool=="mcp__websearch-cn__search"' >/dev/null \
  && ok "空缓存返回 search+cn 工具" || bad "Case1 输出: $out"

# Case 2: 命中未过期 → reuse
today=$(date +%F)
jq -n --arg d "$today" '{("老查询|cn"): {fetched_at:$d, ttl_class:"short", results:[{title:"t",url:"u",snippet:"s"}], task:"x/"}}' > "$MEM"
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "老查询" --lane cn 2>/dev/null)
echo "$out" | jq -e '.action=="reuse" and .key=="老查询|cn" and (.results|length)==1' >/dev/null \
  && ok "缓存命中返回 reuse" || bad "Case2 输出: $out"

# Case 3: short 过期（40 天前）→ search
old=$(jq -nr 'now - 40*86400 | strftime("%Y-%m-%d")')
jq -n --arg d "$old" '{("旧闻|glb"): {fetched_at:$d, ttl_class:"short", results:[], task:"x/"}}' > "$MEM"
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "旧闻" --lane glb 2>/dev/null)
echo "$out" | jq -e '.action=="search"' >/dev/null && ok "short 过期重搜" || bad "Case3 输出: $out"

# Case 4: permanent 永不过期
jq -n --arg d "$old" '{("史实|glb"): {fetched_at:$d, ttl_class:"permanent", results:[{title:"t",url:"u",snippet:"s"}], task:"x/"}}' > "$MEM"
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "史实" --lane glb 2>/dev/null)
echo "$out" | jq -e '.action=="reuse"' >/dev/null && ok "permanent 不过期" || bad "Case4 输出: $out"

# Case 5: --refresh 强制重搜
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "史实" --lane glb --refresh 2>/dev/null)
echo "$out" | jq -e '.action=="search"' >/dev/null && ok "refresh 强制重搜" || bad "Case5 输出: $out"

# Case 6: 非法 lane → exit 2 + stderr
SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "q" --lane badlane >/dev/null 2>"$TMP/err"; rc=$?
[ "$rc" -eq 2 ] && [ -s "$TMP/err" ] && ok "非法 lane 报错 exit2" || bad "Case6 rc=$rc"

# Case 7: --lane 缺参数值 → exit 2 + 中文 stderr
SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "q" --lane >/dev/null 2>"$TMP/err2"; rc=$?
[ "$rc" -eq 2 ] && grep -q "缺少参数" "$TMP/err2" && ok "--lane缺值报错exit2+中文" || bad "Case7 rc=$rc"

# Case 8: github lane → search + github 工具
echo '{}' > "$MEM"
out=$(SEARCH_MEMORY_FILE="$MEM" "$SCRIPT" "claude skills ecosystem" --lane github 2>/dev/null)
echo "$out" | jq -e '.action=="search" and .lane=="github" and .tool=="mcp__github__search_repositories"' >/dev/null \
  && ok "github lane 路由正确" || bad "Case8 输出: $out"

echo "----"; echo "pass=$pass fail=$fail"
rm -rf "$TMP"
[ "$fail" -eq 0 ]
