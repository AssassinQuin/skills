# Python 验证循环

## 验证链

每阶段改动后必须通过：

```
ruff check (快) → pyright (中) → pytest (慢)
```

| 阶段 | 工具 | 时机 |
|------|------|------|
| 即时 | `ruff check --fix {file}` | 每次编辑后立即验证 |
| 阶段 | `pyright {file_or_dir}` | 每阶段结束后类型检查 |
| 最终 | `pytest` | 最终验证功能正确性 |
| 全量 | `ruff check .` + `ruff format --check .` | 最终全量 lint + 格式检查 |

## 运行环境

优先用 `uv run` 确保在正确虚拟环境中：

```bash
uv run ruff check .
uv run pyright
uv run pytest
```

如果项目用 poetry/pip，先检测虚拟环境：

```bash
# 检测 venv
ls .venv/bin/python 2>/dev/null || ls venv/bin/python 2>/dev/null
# 激活（如果需要）
source .venv/bin/activate
```

## 区分预存测试失败

```bash
# 检查测试文件最近是否被其他 commit 修改但断言未更新
git log --oneline -5 -- path/to/test_file.py
```

如果最近 commit 修改了被测代码但测试断言未同步 → 预存问题，不计入当前改动失败。

## 反模式

| 反模式 | 正确做法 |
|--------|----------|
| 大爆炸式重构 | 分阶段，每阶段独立验证 |
| 跳过 pyright 直接跑 pytest | 类型错误比运行时错误更早暴露 |
| 不检查 ruff format | 编辑后必须 format，否则 diff 噪音 |
| stash 测试预存失败 | 查 git log 识别预存问题 |
