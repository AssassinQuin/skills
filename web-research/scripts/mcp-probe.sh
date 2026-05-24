#!/usr/bin/env bash
# mcp-probe.sh — MCP 配置变化检测 + 缓存管理
# 用法: bash mcp-probe.sh [cache_dir]
# 原理: hash MCP server 列表 → 变化才更新缓存，否则复用
# 可用性: 由实际调用时自然发现，失败沿降级链切换

set -euo pipefail

CACHE_DIR="${1:-$HOME/.claude/skills/web-research/data}"
CACHE_FILE="$CACHE_DIR/.mcp-cache.json"
mkdir -p "$CACHE_DIR"

# Step 1: 获取当前 MCP server 列表并 hash
get_current_hash() {
    claude mcp list 2>/dev/null | grep -E -o '^[A-Za-z0-9_-]+' | sort -u | tr '\n' ',' | md5 | cut -c1-12
}

CURRENT_HASH=$(get_current_hash)

# Step 2: 检查缓存
if [ -f "$CACHE_FILE" ]; then
    CACHED_HASH=$(python3 -c "
import json
try:
    with open('$CACHE_FILE') as f: d = json.load(f)
    print(d.get('mcp_hash', ''))
except: print('')
")
    if [ "$CACHED_HASH" = "$CURRENT_HASH" ] && [ -n "$CURRENT_HASH" ]; then
        echo "缓存命中: hash=$CURRENT_HASH 未变化"
        exit 0
    fi
    echo "配置变化: $CACHED_HASH → $CURRENT_HASH"
else
    echo "无缓存，创建新缓存"
fi

# Step 3: 解析 server 列表，生成工具映射
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S")

python3 << PYEOF
import json

server_tools = {
    "searxng": ["mcp__searxng__searxng_web_search", "mcp__searxng__web_url_read"],
    "crawl4ai-mcp": ["mcp__crawl4ai-mcp__scrape", "mcp__crawl4ai-mcp__crawl", "mcp__crawl4ai-mcp__crawl_site", "mcp__crawl4ai-mcp__crawl_sitemap"],
    "web-reader": ["mcp__web_reader__webReader"],
    "web-search-prime": ["mcp__web-search-prime__web_search_prime"],
    "github": ["mcp__github__search_repositories", "mcp__github__search_code", "mcp__github__get_file_contents"],
    "context7": ["mcp__context7__resolve-library-id", "mcp__context7__query-docs"],
    "memory": ["mcp__memory__memory_search", "mcp__memory__memory_store"],
    "zread": ["mcp__zread__search_doc", "mcp__zread__read_file"],
}

# 从 claude mcp list 获取已注册 server
import subprocess, re
result = subprocess.run(["claude", "mcp", "list"], capture_output=True, text=True)
registered = set(re.findall(r'^([\w-]+)', result.stdout, re.MULTILINE))

available = ["WebSearch", "WebFetch"]  # 内置工具始终可用
unavailable = []

for srv, tools in server_tools.items():
    # 模糊匹配：claude mcp list 的名字可能和 key 略有不同
    found = any(srv in r or r in srv for r in registered)
    if found:
        available.extend(tools)
    else:
        unavailable.extend(tools)

cache = {
    "updated": "$TIMESTAMP",
    "mcp_hash": "$CURRENT_HASH",
    "available": available,
    "unavailable": unavailable,
    "fallback": "WebSearch + WebFetch",
    "note": "可用性由实际调用时验证，失败沿降级链切换"
}
with open("$CACHE_FILE", "w") as f:
    json.dump(cache, f, indent=2, ensure_ascii=False)
print(json.dumps(cache, indent=2, ensure_ascii=False))
PYEOF

echo ""
echo "缓存已写入: $CACHE_FILE"
