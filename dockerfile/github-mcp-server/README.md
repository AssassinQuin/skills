# github-mcp-server

## 基本信息

| 项目 | 值 |
|------|-----|
| 镜像 | `ghcr.io/github/github-mcp-server` (官方，直接使用) |
| 平台 | **通用 (amd64 + arm64 原生支持)** |
| GitHub | https://github.com/github/github-mcp-server |
| 需构建 | ❌ 直接使用官方镜像 |

## opencode.jsonc 配置

```jsonc
"github": {
  "type": "local",
  "command": [
    "docker", "run", "-i", "--rm",
    "--name", "github-mcp-opencode",
    "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
    "ghcr.io/github/github-mcp-server"
  ],
  "environment": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "{file:~/.secrets/github-token}"
  }
}
```
