# Coder-Debug

**Phase 0.6 Bug 诊断子流程**（v6.3 新增，from mattpocock diagnose）。6 步循环：复现 → 最小化 → 假设 → 插桩 → 修复 → 回归测试。

## Trigger

- 进入 coder 流水线 Phase 0.6（bug 类任务，spec 未生）
- 用户报告 bug / 异常 / 性能回归
- 含 "为什么 X 报错" / "X 坏了" / "突然不工作了"

## Quick Start

```
/coder-debug 用户登录偶尔 500，没复现步骤
```

## Workflow

1. 复现：建立稳定 repro（最小步骤）
2. 最小化：bisect 缩小到最小触发条件
3. 假设：列 3-5 个 falsifiable hypotheses
4. 插桩：加 log/metric 验证假设
5. 修复：改最小代码 + 加回归 test
6. 回归测试：跑 test 确认 fix 不破坏其他

## Directory Structure

```
SKILL.md / scripts/{repro-template,hypothesis-tracker} / README.md
```

## Output Format

```
bug-report.md（minimal repro + 3-5 ranked hypotheses + fix diff + 回归 test 结果）
```

## See Also

coder-spec (Phase 0) / coder-reuse (Phase 0.5) / coder-constraints (#12 编码前先思考) / coder (主 router) / mattpocock diagnose (灵感来源)
