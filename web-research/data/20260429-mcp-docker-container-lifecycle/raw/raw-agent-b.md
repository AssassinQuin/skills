# Raw Agent B: Docker 容器自动清理方法全景调研

> 工具: @librarian (Docker 文档 + 社区实践)
> 调研时间: 2026-04-29
> 搜索范围: Docker 官方文档、GitHub 实现模式、进程管理最佳实践

---

## 搜索结果

### 来源 1: Docker `--rm` 标志
- **工具**: @librarian
- **相关性**: 高
- **摘要**: 容器退出后自动删除文件系统和匿名卷。任何退出码（正常/异常/信号终止）都触发清理。
- **命令**: `docker run --rm -i image`

### 来源 2: Docker HEALTHCHECK
- **工具**: @librarian
- **相关性**: 中
- **摘要**: 周期性健康检查，检测不健康容器。需外部监控脚本配合才能自动清理。适合 HTTP 长连接型服务。
- **示例**:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost/ || exit 1
```

### 来源 3: PID 1 信号传播
- **工具**: @librarian
- **相关性**: 高
- **摘要**: SIGTERM 发送至 PID 1，需正确转发。exec 形式 CMD/ENTRYPOINT 能正确处理信号，shell 形式会被 bash 拦截。
- **最佳实践**: 使用 `CMD ["python", "app.py"]` (exec 形式) 而非 `CMD python app.py` (shell 形式)

### 来源 4: Docker Event API
- **工具**: @librarian
- **相关性**: 中
- **摘要**: 实时监听 Docker 事件流（die, stop, destroy），可按 label 过滤。需要运行常驻事件监听进程。
- **示例**:
```python
for event in client.events(decode=True):
    if event['Type'] == 'container' and event['Action'] == 'die':
        container.remove(force=True)
```

### 来源 5: 容器 Label + 定时清理
- **工具**: @librarian
- **相关性**: 高
- **摘要**: 启动时标记 label，定期扫描孤儿容器。可记录 parent-pid 并检查是否存活。通过 cron/systemd timer 定期执行。
- **示例**:
```bash
# 启动时
docker run --label mcp-server=true --label parent-pid=$$ image
# 定时清理
docker ps --filter "label=mcp-server=true" -q | xargs docker rm -f
```

### 来源 6: Docker Compose auto_remove / stop_grace_period
- **工具**: @librarian
- **相关性**: 中
- **摘要**: Compose 支持 `stop_grace_period` 配置优雅关闭等待时间。`auto_remove` 仅在 `compose run` 时生效。

### 来源 7: systemd 进程管理
- **工具**: @librarian
- **相关性**: 中
- **摘要**: 将 Docker 容器作为 systemd service 管理。`ExecStopPost` 在停止后自动执行清理命令。
```ini
ExecStart=/usr/bin/docker run --name=mcp-%i image
ExecStop=/usr/bin/docker stop mcp-%i
ExecStopPost=/usr/bin/docker rm -f mcp-%i
```

### 来源 8: supervisord 进程管理
- **工具**: @librarian
- **相关性**: 低
- **摘要**: `stopasgroup=true` + `killasgroup=true` 确保子进程组一起终止。

### 来源 9: Tini / dumb-init
- **工具**: @librarian
- **相关性**: 高
- **摘要**: 轻量级 init 进程，正确转发信号 + 回收僵尸进程。Docker 1.13+ 内置 Tini (`--init` 标志)。
- **命令**: `docker run --init image`

### 来源 10: Docker `--init` 标志
- **工具**: @librarian
- **相关性**: 高
- **摘要**: Docker 1.13+ 内置支持，自动插入 Tini 作为 PID 1。无需修改镜像即可获得正确信号处理。

---

## 方法对比矩阵

| 方法 | 自动清理 | 自定义逻辑 | 复杂度 | MCP 适用性 |
|------|---------|-----------|--------|-----------|
| `--rm` | ✅ | ❌ | ⭐ 简单 | ⭐⭐⭐⭐⭐ |
| MCP onclose | ⚠️ 部分 | ✅ | ⭐⭐ 中等 | ⭐⭐⭐⭐ |
| HEALTHCHECK | ❌ 需外部 | ⚠️ 有限 | ⭐⭐⭐ 复杂 | ⭐⭐ |
| Label + 定时清理 | ⚠️ 延迟 | ✅ | ⭐⭐⭐ 复杂 | ⭐⭐⭐ (兜底) |
| Docker Event API | ⚠️ 需常驻 | ✅ | ⭐⭐⭐ 复杂 | ⭐⭐ |
| systemd | ✅ | ✅ | ⭐⭐⭐⭐ 很复杂 | ⭐⭐ |
| Tini/--init | ✅ 信号 | ❌ | ⭐ 简单 | ⭐⭐⭐⭐ |
