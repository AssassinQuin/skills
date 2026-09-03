#!/usr/bin/env bash
# save-memory.sh — 查询结果写回 search-memory 注册表（Phase 5 记忆固化用）
# 用法: save-memory.sh "<query>" --lane <cn|glb|zhihu|prime> --ttl <short|long|permanent> \
#         --task <任务目录相对路径> --results <results.json（数组文件）>
# 退出: 0 成功；2 用法/IO/JSON 错误（stderr 显式说明，R12）
set -u
DIR_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MEM_FILE="${SEARCH_MEMORY_FILE:-$DIR_ROOT/datastore/search-memory.json}"

query=""; lane=""; ttl=""; task=""; results=""
usage_err() { echo "save-memory.sh: $1" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --lane)    [ $# -ge 2 ] || usage_err "--lane 缺少参数"; lane="$2"; shift 2 ;;
    --ttl)     [ $# -ge 2 ] || usage_err "--ttl 缺少参数"; ttl="$2"; shift 2 ;;
    --task)    [ $# -ge 2 ] || usage_err "--task 缺少参数"; task="$2"; shift 2 ;;
    --results) [ $# -ge 2 ] || usage_err "--results 缺少参数"; results="$2"; shift 2 ;;
    *)         query="$1"; shift ;;
  esac
done
[ -n "$query" ]   || usage_err "缺少查询词"
case "$lane" in cn|glb|zhihu|prime|github) ;; *) usage_err "非法 lane: $lane" ;; esac
case "$ttl"  in short|long|permanent) ;; *) usage_err "非法 ttl: $ttl" ;; esac
[ -n "$task" ]    || usage_err "缺少 --task"
[ -n "$results" ] && [ -f "$results" ] || usage_err "缺少/不存在 --results 文件: $results"
jq -e 'type == "array"' "$results" >/dev/null 2>&1 || usage_err "results 不是合法 JSON 数组: $results"

# 归一化规则与 route-lane.sh 一致
qnorm=$(printf '%s' "$query" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')
key="${qnorm}|${lane}"
today=$(date +%F)

mkdir -p "$(dirname "$MEM_FILE")"
[ -f "$MEM_FILE" ] || printf '{}' > "$MEM_FILE"
jq -e 'type == "object"' "$MEM_FILE" >/dev/null 2>&1 || usage_err "注册表已损坏（非 JSON 对象）: $MEM_FILE"

tmp=$(mktemp) || usage_err "mktemp 失败"
jq --arg k "$key" --arg d "$today" --arg ttl "$ttl" --arg t "$task" --slurpfile r "$results" \
  '.[$k] = {fetched_at:$d, ttl_class:$ttl, task:$t, results:($r[0])}' "$MEM_FILE" > "$tmp" \
  && mv "$tmp" "$MEM_FILE" || usage_err "写回失败: $MEM_FILE"
echo "saved: $key ($ttl, $today)"
