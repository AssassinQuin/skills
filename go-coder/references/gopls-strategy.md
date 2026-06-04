# gopls 工具策略

## 优先级原则

能用 gopls 的不用 grep/Read。gopls 提供语义理解，grep 只提供文本匹配。

## 工具选择表

| 操作 | 首选 | 降级 |
|------|------|------|
| 查找符号 | `go_search` | grep -rn |
| 查找引用 | `go_symbol_references` | grep -rn |
| 理解包 API | `go_package_api` | Read 每个文件 |
| 包依赖关系 | `go_file_context` | grep import |
| 重命名 | `go_rename_symbol` → sed 应用 | 手动 Edit 链 |
| 编辑后验证 | `go_diagnostics` | go build ./... |
| 全局健康检查 | `go_workspace` | go vet |

## go_rename_symbol 实战注意

返回 diff 预览但**不自动应用**。手动 sed 执行：

```bash
# 声明文件（去掉包前缀）
sed -i '' 's/\bOldName\b/NewName/g' path/to/declare.go
# 引用文件（带包前缀）
sed -i '' 's/pkg\.OldName/pkg.NewName/g' path/to/ref1.go path/to/ref2.go
# 验证
# → go_diagnostics
```

## 跨文件批量替换

```bash
# 用 grep 定位文件列表，sed 批量替换
grep -rln 'consts\.OldName' --include='*.go' . | xargs sed -i '' 's/consts\.OldName/consts.NewName/g'
# → go_diagnostics 验证零错误
```

## 反模式

| 反模式 | 正确做法 |
|--------|----------|
| grep 找引用再手动数 | `go_symbol_references` |
| 手动逐文件 Edit 改名 | `sed` 批量替换 |
| 猜测标识符是否被引用 | `go_symbol_references` 确认后再删 |
