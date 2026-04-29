# one-search-mcp

## 基本信息

| 项目 | 值 |
|------|-----|
| 镜像 | `ghcr.io/yokingma/one-search-mcp:latest` |
| 来源 | 官方 GHCR，内置 Chromium（基于 Playwright 镜像） |
| 平台 | linux/amd64 only（Apple Silicon 通过 Rosetta 2 模拟） |
| GitHub | https://github.com/yokingma/one-search-mcp |
| 版本 | 1.2.1 |

## 工具列表

| 工具 | 功能 | 浏览器依赖 |
|------|------|-----------|
| `one_search` | 多引擎网页搜索 | ❌ |
| `one_scrape` | 网页抓取/爬取 | ✅ chromium（内置） |
| `one_map` | 网站结构发现 | ✅ chromium（内置） |
| `one_extract` | 多URL内容提取 | ⚠️ 部分功能 |

## 拉取镜像

```bash
docker pull --platform linux/amd64 ghcr.io/yokingma/one-search-mcp:latest
```

## opencode.jsonc 配置

```jsonc
"one-search": {
  "type": "local",
  "command": [
    "docker", "run", "-i", "--rm",
    "--platform", "linux/amd64",
    "--label", "mcp-server=true",
    "--name", "one-search-mcp",
    "-e", "SEARCH_PROVIDER=searxng",
    "-e", "SEARCH_API_URL=http://host.docker.internal:8080",
    "ghcr.io/yokingma/one-search-mcp:latest"
  ]
}
```

## 搜索引擎配置

通过 `SEARCH_PROVIDER` 环境变量切换：

| Provider | API Key | API URL | 说明 |
|----------|---------|---------|------|
| `local` | ❌ | ❌ | 免费，浏览器自动化 |
| `duckduckgo` | ❌ | ❌ | 免费 |
| `searxng` | ❌ | ✅ | 当前配置，需自建实例 |
| `tavily` | ✅ | ❌ | |
| `bing` | ✅ | ❌ | |
| `google` | ✅ | ✅ | |
| `zhipu` | ✅ | ❌ | 智谱 AI |
| `exa` | ✅ | ❌ | |
| `bocha` | ✅ | ❌ | 博查 AI |
