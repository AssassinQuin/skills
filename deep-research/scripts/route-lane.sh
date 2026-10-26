#!/usr/bin/env bash
# route-lane.sh — 查询级缓存查表 + lane 工具路由（确定性逻辑，R5）
# 用法: route-lane.sh "<query>" --lane <cn|glb|zhihu|prime|github> [--refresh]
# 输出: stdout JSON，action=reuse（带缓存结果）或 action=search（带工具配置）
# 退出: 0 正常；2 用法/内部错误（stderr 显式说明，R12）
# TTL: short=7天 long=90天 permanent=永不过期；--refresh 强制 bypass
set -u
DIR_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MEM_FILE="${SEARCH_MEMORY_FILE:-$DIR_ROOT/datastore/search-memory.json}"

query=""; lane=""; refresh=0
usage_err() { echo "route-lane.sh: $1" >&2; echo "用法: route-lane.sh \"<query>\" --lane <cn|glb|zhihu|prime|github> [--refresh]" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --lane)     [ $# -ge 2 ] || usage_err "--lane 缺少参数"; lane="$2"; shift 2 ;;
    --refresh)  refresh=1; shift ;;
    *)          query="$1"; shift ;;
  esac
done
[ -n "$query" ] || usage_err "缺少查询词"
case "$lane" in cn|glb|zhihu|prime|github) ;; *) usage_err "非法 lane: $lane" ;; esac

# 归一化：压缩空白（与 save-memory.sh 保持同一规则，key 才能对上）
qnorm=$(printf '%s' "$query" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')
key="${qnorm}|${lane}"

# lane → 工具路由表（与 SKILL.md §Phase2 的分工一致）
routing() {
  case "$1" in
    cn)    jq -cn '{action:"search",lane:"cn",tool:"mcp__websearch-cn__search",tool_params:{engines:["sogou"],limit:5},fallback:{tool:"mcp__websearch-cn__search",tool_params:{engines:["sogou","csdn","juejin","linuxdo"],limit:5}},note:"中文事实/新闻；baidu 引擎间歇 302 不路由"}' ;;
    glb)   jq -cn '{action:"search",lane:"glb",tool:"mcp__websearch-cn__search",tool_params:{engines:["bing"],limit:5},fallback:{tool:"mcp__websearch-cn__search",tool_params:{engines:["bing","duckduckgo","brave"],limit:5}},note:"外文事实/技术文档；非英文查询先翻译；websearch-cn 已统一承载中文/外文引擎"}' ;;
    zhihu) jq -cn '{action:"search",lane:"zhihu",tool:"cli:zhihu-search",tool_params:{count:3},fallback:{tool:"mcp__websearch-cn__search",tool_params:{engines:["sogou"],limit:5}},note:"观点/体验/中文争议；首选 CLI 原生知乎检索；MCP fallback 时查询追加 site:zhihu.com；限额≤4次/任务串行"}' ;;
    prime) jq -cn '{action:"search",lane:"prime",tool:"mcp__web-search-prime__web_search_prime",tool_params:{count:5},fallback:null,note:"仅 deep 模式高价值查询；主会话直调≤3次；贵"}' ;;
    github) jq -cn '{action:"search",lane:"github",tool:"cli:gh-search",tool_params:{kind:"repos",limit:10,sort:"stars"},fallback:{tool:"cli:gh-search",tool_params:{kind:"issues",limit:10}},note:"仓库指标/issue/代码检索；优先 {baseDir}/scripts/github-search.sh，可按查询类型选 repos/issues/code；≤8次/任务"}' ;;
  esac
}

ttl_days() { case "$1" in short) echo 7 ;; long) echo 90 ;; permanent) echo -1 ;; *) echo 0 ;; esac; }

if [ -f "$MEM_FILE" ] && [ "$refresh" -eq 0 ]; then
  if hit=$(jq --arg k "$key" '.[$k] // empty' "$MEM_FILE" 2>/dev/null) && [ -n "$hit" ]; then
    days=$(ttl_days "$(printf '%s' "$hit" | jq -r '.ttl_class')")
    fresh=$(jq --arg k "$key" --argjson d "$days" '
      (.[$k].fetched_at | strptime("%Y-%m-%d") | mktime) as $t |
      if $d < 0 then true elif $t > (now - $d * 86400) then true else false end
    ' "$MEM_FILE" 2>/dev/null)
    if [ "$fresh" = "true" ]; then
      jq --arg k "$key" '{action:"reuse",key:$k} * .[$k]' "$MEM_FILE"
      exit 0
    fi
  fi
fi
routing "$lane"
