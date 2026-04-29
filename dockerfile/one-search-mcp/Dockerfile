# ============================================================
# one-search-mcp (Mac Apple Silicon 专用)
# ============================================================
# 基础镜像: ghcr.io/yokingma/one-search-mcp:latest (amd64)
# 平台: linux/amd64 (通过 Rosetta 2 模拟运行)
# 说明: Apple Silicon (arm64) 上需指定 --platform linux/amd64
#       镜像内无浏览器，需额外安装 chromium-browser
# 工具: one_search, one_scrape, one_map, one_extract
# 搜索引擎: searxng, duckduckgo, tavily, bing, google, zhipu, exa, bocha, local
# ============================================================

FROM --platform=linux/amd64 ghcr.io/yokingma/one-search-mcp:latest
USER root
# 基础镜像用户是 pwuser(1000)，没有 node 用户，需手动创建
RUN useradd -m -u 1001 -s /bin/bash node && \
    apt-get update && apt-get install -y chromium-browser && rm -rf /var/lib/apt/lists/*
USER node
