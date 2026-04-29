# ============================================================
# github-mcp-server (通用版本)
# ============================================================
# 基础镜像: ghcr.io/github/github-mcp-server (多架构: amd64/arm64)
# 平台: 通用 (amd64 + arm64 原生支持)
# 说明: 官方 GitHub MCP Server，无需额外构建
#       此 Dockerfile 仅用于记录配置，直接使用官方镜像即可
# 工具: github_* (搜索/PR/Issue/代码等全套 GitHub 操作)
# ============================================================

# 官方镜像已支持多架构，无需自定义构建
# 如需定制（如添加 CA 证书），取消注释下方 Dockerfile:
#
# FROM ghcr.io/github/github-mcp-server:latest
# # 示例: 添加自定义 CA
# # USER root
# # COPY ca-cert.pem /usr/local/share/ca-certificates/
# # RUN update-ca-certificates
# # USER node
