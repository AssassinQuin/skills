# Coder-Prototype

**Phase 2.5 throwaway prototype**（v6.3 新增，from mattpocock prototype）。复杂度极高或设计不确定时触发。throwaway code 验证 design 关键假设。6 rules 强制。

## Trigger

- Phase 3 design 之后、Phase 4 执行之前
- 设计含 ≥3 个未知：数据模型 / 状态机 / 外部 API 行为
- 用户说 "先做个 prototype 看看" / "let me play with it"

## Quick Start

```
/coder-prototype 验证订单状态机的边缘 case
```

## Workflow

1. 识别关键不确定性（≤3 个）
2. throwaway 实现（不要求 production quality）
3. 用户验证 prototype 行为
4. 结论：可行 → 进 Phase 4 / 不可行 → 回 Phase 3 重设计
5. 丢弃 prototype 代码（archive 不 merge）

## Directory Structure

```
SKILL.md / README.md
```

## Output Format

```
prototype 验证报告（含 6 rules 强制 checklist）
```

## See Also

coder-design (Phase 3 前驱) / coder-execute (Phase 4 后继) / mattpocock prototype (灵感来源) / coder (主 router)
