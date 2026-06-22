# Python 编辑规则

## 缩进

Python 使用 **4 空格缩进**。Edit 工具可正常使用（与 Go 的 tab 问题不同）。

## 编辑后必做

每次修改 .py 文件后，按顺序执行：

```bash
ruff format {file_or_dir}       # 格式化
ruff check --fix {file_or_dir}  # lint + 自动修复（含导入排序）
```

## 文件归属决策

| 文件类型 | 是否可编辑 | 原因 |
|----------|-----------|------|
| `__init__.py` | **谨慎** | 通常只做导出，改前检查是否有自动生成标记 |
| `proto` 生成的 `_pb2.py` | **不可** | 由 protoc/grpcio-tools 自动生成 |
| `migrations/` | **不可** | 数据库迁移文件，由 alembic 管控 |
| `src/` 业务代码 | **可** | 手写业务逻辑 |
| `tests/` | **可** | 手写测试 |
| `py.typed` / `__version__.py` | **谨慎** | 版本标记文件，检查是否有自动生成 |

## 导入排序规则

ruff (默认 isort 兼容) 自动排序：
1. 标准库
2. 第三方库
3. 本地模块

编辑后运行 `ruff check --fix --select I .` 自动排序。

## 操作推荐表

| 操作 | 推荐方式 |
|------|----------|
| 修改函数/类 | Edit 工具（Python 无 tab 问题） |
| 批量重命名 | `sed` + `ruff format` |
| 写新文件 | `Write` 工具 |
| 删除行/块 | Edit 工具 |
| 修改后格式化 | `ruff format` + `ruff check --fix` |

## 反模式

| 反模式 | 正确做法 |
|--------|----------|
| 编辑后不格式化 | 每次编辑后 `ruff format` + `ruff check --fix` |
| 手动排序 import | `ruff check --fix --select I` |
| 编辑生成的 `_pb2.py` | 重新运行 protoc 生成 |
| 用 2 空格缩进 | 4 空格（PEP 8） |
| 混用 tab 和空格 | 永远用空格，`ruff format` 自动统一 |
