#!/usr/bin/env bash
# =============================================================================
# search-mcp-benchmark.sh — 搜索 MCP/skill 标准基准测试流程
# =============================================================================
# 用法:
#   ./scripts/search-mcp-benchmark.sh                    # 跑内置标准查询集
#   ./scripts/search-mcp-benchmark.sh my-queries.txt    # 自定义查询集
#   BENCH_LANES="zhihu,cn" ./scripts/search-mcp-benchmark.sh  # 只跑指定 lane
#
# 查询集格式: 每行 "lane|query"
#   lane ∈ cn(中文直连) | glb(海外走代理) | zhihu(知乎体) | any(全引擎)
#
# 被测引擎 (CLI 可直调的 5 个):
#   searxng  — 本地 SearXNG API (localhost:8888)
#   ows-cn   — open-webSearch 中文路 (baidu 直连)
#   ows-glb  — open-webSearch 海外路 (startpage+ddg, USE_PROXY)
#   zhihu    — zhihu-search skill (知乎开放平台 API)
#   gsearch  — global-search skill (多源聚合)
# MCP 类引擎 (prime/WebSearch) 无法从 shell 直调 → 报告末尾自动生成补测清单,
#   在 Claude Code 会话中用同一查询集调用后人工填分。
#
# 输出: reports/benchmarks/bench-<timestamp>.md
#   脚本只负责采集: top-4 标题 + 延迟 + 返回体积 (token 维度实测基础)
#   0-2 相关性评分由评审 (模型/人) 填写: 2=前4条全相关 1=部分相关 0=无关/空
#   完整流程与评分规则见 reports/2026-09-03-search-mcp-benchmark.md
# =============================================================================
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/reports/benchmarks"
mkdir -p "$OUT_DIR"
TS=$(date +%Y%m%d-%H%M%S)
OUT="$OUT_DIR/bench-$TS.md"
BENCH_LANES="${BENCH_LANES:-cn,glb,zhihu}"
PROXY_URL="${PROXY_URL:-http://127.0.0.1:7890}"
SEARXNG_URL="${SEARXNG_URL:-http://localhost:8888}"

# --- 内置标准查询集 (可被参数文件覆盖) --------------------------------------
DEFAULT_QUERIES=$(cat <<'EOF'
cn|赛力斯 2026 半年报 亏损
cn|Claude Code MCP server 配置教程
glb|MCP model context protocol vs function calling
glb|OpenAI latest model release September 2026
glb|トヨタ 2026年3月期 決算
glb|Bundesbank Leitzins Prognose 2026
zhihu|如何看待赛力斯 2026 半年报 亏损
zhihu|Claude Code MCP 配置
EOF
)
if [[ $# -ge 1 && -f "$1" ]]; then QUERIES=$(cat "$1"); else QUERIES="$DEFAULT_QUERIES"; fi

lane_enabled() { echo ",$BENCH_LANES," | grep -q ",$1,"; }

# --- 引擎实现: 每个函数 echo "标题列表", 失败时 echo "[FAIL] 原因" ----------
run_searxng() { # $1=query $2=lang
  local f; f=$(mktemp)
  if ! curl -s --noproxy '*' -m 25 -G "$SEARXNG_URL/search" \
      --data-urlencode "q=$1" --data-urlencode 'format=json' \
      --data-urlencode "language=$2" -o "$f" 2>/dev/null; then
    echo "[FAIL] curl 无法连接 $SEARXNG_URL"; rm -f "$f"; return; fi
  local n; n=$(jq -r '.results | length' "$f" 2>/dev/null)
  if [[ -z "$n" || "$n" == "0" ]]; then echo "[FAIL] 0 结果"; rm -f "$f"; return; fi
  echo "n=$n bytes=$(wc -c < "$f" | tr -d ' ')"
  jq -r '[.results[:4][].title[0:60]] | .[]' "$f" 2>/dev/null
  rm -f "$f"
}

run_ows() { # $1=query $2=engines $3=use_proxy
  local f; f=$(mktemp)
  if [[ "$3" == "proxy" ]]; then
    USE_PROXY=true PROXY_URL="$PROXY_URL" npx -y open-websearch@latest search "$1" \
      --engines "$2" --limit 5 --json > "$f" 2>/dev/null
  else
    npx -y open-websearch@latest search "$1" \
      --engines "$2" --limit 5 --json > "$f" 2>/dev/null
  fi
  if [[ ! -s "$f" ]]; then echo "[FAIL] 空结果 (引擎风控/网络)"; rm -f "$f"; return; fi
  echo "bytes=$(wc -c < "$f" | tr -d ' ')"
  jq -r '[.. | objects | select(.title?) | .title[0:60]] | .[0:4][]' "$f" 2>/dev/null
  rm -f "$f"
}

run_py_skill() { # $1=script_rel_path $2=json_arg
  local out; out=$(python3 "$ROOT/$1" "$2" 2>&1)
  if ! echo "$out" | jq -e '.code == 0' >/dev/null 2>&1; then
    echo "[FAIL] $(echo "$out" | head -c 200)"; return; fi
  local f; f=$(mktemp); echo "$out" > "$f"
  echo "n=$(jq -r '.item_count' "$f") bytes=$(wc -c < "$f" | tr -d ' ')"
  jq -r '[.items[:4][] | (.title[0:60] + "  [" + (.author_name // "?") + "]")] | .[]' "$f" 2>/dev/null
  rm -f "$f"
}

timed() { # $1=引擎名 $2=lane 剩余为命令
  local eng="$1" t0 t1
  shift
  t0=$(date +%s); "$@"; t1=$(date +%s)
  echo "  <b>$eng</b> 耗时 $((t1-t0))s"
}

# --- 主循环 -------------------------------------------------------------------
{
  echo "# 搜索基准采集 $TS"
  echo ""
  echo "- lanes: $BENCH_LANES  proxy: $PROXY_URL  searxng: $SEARXNG_URL"
  echo "- 评分列 [ ] 由评审填写: 2/1/0 (规则见 reports/2026-09-03-search-mcp-benchmark.md)"
  echo ""
  while IFS='|' read -r lane query; do
    [[ -z "$lane" || "$lane" == \#* ]] && continue
    lane_enabled "$lane" || continue
    echo "## [$lane] $query"
    case "$lane" in
      cn)
        timed searxng  run_searxng "$query" zh-CN
        timed ows-cn   run_ows "$query" "baidu" direct
        timed gsearch  run_py_skill "global-search/scripts/global-search.py" "{\"query\":\"$query\",\"count\":5,\"search_db\":\"all\"}"
        ;;
      glb)
        timed searxng  run_searxng "$query" en
        timed ows-glb  run_ows "$query" "startpage,duckduckgo" proxy
        ;;
      zhihu)
        timed zhihu    run_py_skill "zhihu-search/scripts/zhihu-search.py" "{\"query\":\"$query\",\"count\":5}"
        timed gsearch  run_py_skill "global-search/scripts/global-search.py" "{\"query\":\"$query\",\"count\":5,\"search_db\":\"all\"}"
        timed ows-cn   run_ows "$query" "sogou" direct
        ;;
      any)
        timed searxng  run_searxng "$query" zh-CN
        timed ows-cn   run_ows "$query" "baidu" direct
        timed ows-glb  run_ows "$query" "startpage,duckduckgo" proxy
        timed zhihu    run_py_skill "zhihu-search/scripts/zhihu-search.py" "{\"query\":\"$query\",\"count\":5}"
        ;;
    esac
    echo "  <b>prime / WebSearch</b> [ ] ← MCP 类，会话内补测"
    echo ""
  done <<< "$QUERIES"
  echo "---"
  echo "**补测清单** (MCP 类, 在 Claude Code 会话中按上方查询集逐条调用后填分):"
  echo "\`mcp__web-search-prime__web_search_prime\` / 内置 WebSearch × 全部查询"
} > "$OUT"

echo "✅ 采集完成: $OUT"
echo "   下一步: 将 $OUT 交给评审(模型/人)填 0-2 分, 汇总进基准报告"
