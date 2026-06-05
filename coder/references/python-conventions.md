# Python 项目惯例

## 项目结构

```
# src layout（推荐）
{project}/
├── pyproject.toml
├── src/{package}/
│   ├── __init__.py
│   ├── {module}.py
│   └── ...
├── tests/
│   ├── __init__.py
│   ├── test_{module}.py
│   └── ...
└── .venv/

# flat layout（简单项目）
{project}/
├── pyproject.toml
├── {package}/
│   ├── __init__.py
│   └── ...
└── tests/
```

## 类型注解

Python 3.10+ 语法（不用 `typing.X` 别名）：

```python
# 正确
def func(items: list[str], mapping: dict[str, int]) -> str | None:

# 错误
def func(items: List[str], mapping: Dict[str, int]) -> Optional[str]:
```

- 公开函数必须有类型注解和 docstring
- 内部函数类型注解推荐但不强制
- 用 `pyright --verifytypes {module}` 检查覆盖率

## 错误处理

```python
# 自定义异常层级
class AppError(Exception):
    """应用基础异常"""

class ValidationError(AppError):
    """输入验证失败"""

class NotFoundError(AppError):
    """资源未找到"""

# 使用
raise ValidationError(f"Invalid config: {key}")
```

- 禁止裸 `except:` 或 `except Exception:`
- 异常消息必须包含上下文（哪个字段/哪个操作）
- 用 `logging.exception()` 记录完整堆栈

## 测试

```python
# pytest + parametrize
import pytest

@pytest.mark.parametrize("input,expected", [
    ("normal", "NORMAL"),
    ("", ""),
    ("already", "ALREADY"),
])
def test_transform(input, expected):
    assert transform(input) == expected

# fixture
@pytest.fixture
def db_connection():
    conn = create_connection()
    yield conn
    conn.close()
```

- 测试文件：`tests/test_{module}.py`
- 测试函数：`test_{behavior}`
- 用 `pytest.mark.parametrize` 做数据驱动测试
- fixture 管理测试依赖（数据库、mock 对象）
- 覆盖：正常路径 + 边界值 + 错误路径

## 依赖管理

检测项目使用的工具：

```bash
# uv（优先检测）
ls uv.lock && echo "uv"

# poetry
ls poetry.lock && echo "poetry"

# pip
ls requirements*.txt && echo "pip"
```

## 虚拟环境

```bash
# 检测
test -d .venv && echo ".venv"
test -d venv && echo "venv"

# uv 自动管理，无需手动激活
uv run {command}
```

## 代码风格

- `ruff format` 替代 black（兼容 black 风格）
- 行宽默认 88（black 兼容），可在 pyproject.toml 调整
- 单引号或双引号均可，`ruff format` 自动统一
- 尾逗号：多行结构必须有，`ruff format` 自动添加
