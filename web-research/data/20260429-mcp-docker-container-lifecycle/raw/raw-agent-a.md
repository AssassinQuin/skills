# Raw Agent A: MCP Docker 生命周期管理调研

> 工具: @librarian (代码考古 + 文档检索)
> 调研时间: 2026-04-29
> 搜索范围: MCP 规范、TypeScript SDK、Python SDK、参考服务器实现、社区实现

---

## 搜索结果

### 来源 1: MCP 官方规范 — 传输层生命周期
- **工具**: @librarian (GitHub 代码考古)
- **相关性**: 高
- **摘要**: MCP 规范定义了三个生命周期阶段：初始化 (initialize)、运行 (operation)、关闭 (shutdown)。stdio 传输关闭时客户端关闭输入流，服务器收到 EOF 后退出。

### 来源 2: MCP 官方参考服务器 — Docker 运行模式
- **工具**: @librarian (GitHub 代码考古)
- **相关性**: 高
- **摘要**: 所有官方 MCP 参考服务器（filesystem, sequentialthinking, everything, fetch, git, time）统一使用 `docker run --rm -i` 模式。`--rm` 保证容器退出后自动删除，`-i` 保持 stdin 开放用于 JSON-RPC 通信。

### 来源 3: MCP TypeScript SDK — onclose 钩子
- **工具**: @librarian (GitHub 代码考古)
- **相关性**: 高
- **摘要**: TypeScript SDK 提供 `server.server.onclose` 回调，在连接关闭时触发。用于释放数据库连接、刷缓冲区等应用级资源清理。Everything Server 还实现了 `cleanup()` 函数模式。

### 来源 4: MCP Streamable HTTP — DELETE 端点
- **工具**: @librarian (GitHub 代码考古)
- **相关性**: 中
- **摘要**: HTTP 传输支持可选的 `DELETE` 请求用于显式会话终止。服务器可关闭连接单方面终止。适用于 HTTP 长连接型 MCP 服务器。

### 来源 5: 社区实现 — MongoDB/Dashlane/Vercel 等
- **工具**: @librarian (GitHub 代码考古)
- **相关性**: 中
- **摘要**: MongoDB MCP 服务器、Dashlane CLI、Vercel MCP handler、ProfessionalWiki MediaWiki 等均实现了 onclose 钩子进行清理。

---

## 关键发现

### 1. MCP 标准 Docker 运行模式
```bash
docker run --rm -i <image> [args]
```
- `--rm`: 容器退出后自动删除
- `-i`: 保持 stdin 开放 (stdio 传输核心)
- 无需 `-t`: 不需要 TTY，通过 stdin/stdout 交换 JSON-RPC

### 2. stdio 传输关闭流程
```
Client 关闭 stdin → Server 收到 EOF → Server 退出 → Docker 删除容器 (--rm)
```

### 3. SDK 级别清理钩子
- `server.server.onclose`: 连接关闭回调
- `cleanup()`: 用户定义清理函数
- `taskStore.cleanup()`: 清理定时器

### 4. 关键结论
**`docker run --rm -i` + MCP 协议生命周期钩子 = 自动、可靠的容器清理**
