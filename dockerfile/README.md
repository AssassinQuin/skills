# Docker MCP 构建文件目录

统一管理 opencode 中使用的 Docker 容器构建文件。

## 目录结构

```
dockerfile/
├── one-search-mcp/      # 🔴 Mac Apple Silicon 专用 (amd64 via Rosetta)
│   ├── Dockerfile       # 自定义镜像，含 chromium-browser
│   └── README.md        # 配置说明
├── github-mcp-server/   # 🟢 通用 (amd64 + arm64)
│   ├── Dockerfile       # 仅作记录，直接用官方镜像
│   └── README.md        # 配置说明
└── README.md            # 本文件
```

## 平台标记说明

| 标记 | 含义 | 镜像来源 |
|------|------|---------|
| 🔴 Mac 专用 | 需要 `--platform linux/amd64` 或自定义构建 | 通常镜像仅提供 amd64 |
| 🟢 通用 | 原生支持 amd64 + arm64 | 官方多架构镜像 |

## 构建所有自定义镜像

```bash
# one-search-mcp (Mac Apple Silicon)
docker build --platform linux/amd64 \
  -t one-search-mcp:with-chromium \
  /Users/ganjie/skills/dockerfile/one-search-mcp/

# github-mcp-server 无需构建，直接使用官方镜像
```
