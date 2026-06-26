# Python 工具策略

## 优先级原则

能用语言服务器的不用 grep/Read。语义理解 > 文本匹配。

## 工具选择表

| 操作 | 首选 | 降级 |
|------|------|------|
| 查找符号 | LSP `workspaceSymbol` | grep -rn |
| 查找引用 | LSP `findReferences` | grep -rn |
| 理解模块 API | LSP `documentSymbol` | Read 每个文件 |
| 跳转定义 | LSP `goToDefinition` | grep -rn |
| 类型检查 | `pyright` | mypy |
| 重命名 | LSP `rename` → 手动应用 | sed 批量替换 |
| Lint | `ruff check` | pylint/flake8 |
| 格式化 | `ruff format` | black |
| 导入排序 | `ruff check --fix --select I` | isort |
| 依赖管理 | `uv` | pip/poetry |

## pyright 使用注意

- `pyright --verifytypes {module}` 验证类型覆盖率
- `pyright {file.py}` 检查单文件类型错误
- 无 LSP 时用 `pyright` CLI 替代语义导航

## ruff 操作速查

```bash
# Lint + 自动修复
ruff check --fix .

# 格式化
ruff format .

# 仅排序导入
ruff check --fix --select I .

# 检查单文件
ruff check path/to/file.py

# 查看规则列表
ruff rule {rule_name}
```

## uv 操作速查

```bash
# 安装依赖
uv sync

# 添加依赖
uv add {package}

# 运行命令（自动激活 venv）
uv run python {script}
uv run pytest
uv run ruff check .

# 创建新项目
uv init {project_name}
```

## 跨文件批量替换

```bash
# grep 定位 + sed 替换
grep -rln 'old_name' --include='*.py' . | xargs sed -i '' 's/\bold_name\b/new_name/g'
# → ruff check --fix . 验证
```

## 反模式

| 反模式 | 正确做法 |
|--------|----------|
| grep 找引用再手动数 | LSP `findReferences` |
| 手动逐文件 Edit 改名 | `sed` 批量替换 + `ruff check` 验证 |
| 猜测标识符是否被引用 | LSP `findReferences` 确认后再删 |
| 手动排序 import | `ruff check --fix --select I` |
| 不运行 ruff format 就提交 | 编辑后必须 `ruff format` |
