# Coder-Design

**Phase 3 设计方案 + test-plan**。2-4 oracle(opus) + 1 test-strategist(sonnet) 并发模板（硬上限 5）。parallel exploration 实施细节。

## Trigger

- 复杂任务（4 条简单条件全不满足）
- 改动 ≥3 文件 / public API 变更 / 跨模块 / 新依赖
- 含 "重构" "统一" "重新设计"

## Quick Start

```
/coder-design 重构 internal/auth 模块
```

## Workflow

1. oracle 数量决策（2/3/4，按复杂度）
2. 并发 spawn N 个 oracle(opus) + 1 test-strategist(sonnet)
3. 每个 oracle 独立方向（互不可见，避免趋同）
4. orchestrator 合并方案对比表
5. AskUserQuestion 让用户选 + signature-guard 签字

## Directory Structure

```
SKILL.md / README.md
```

## Output Format

```
design.md（N 方案对比 + 选定）+ test-plan.md（vertical cycle）
```

## See Also

coder-metadata (Phase 1 输入) / coder-execute (Phase 4 后继) / coder-constraints (#2 model 显式) / coder (主 router)
