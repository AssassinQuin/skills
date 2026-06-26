# Coder-Deliver

**Phase 4.5 子 agent delivery 校验协议**。orchestrator 收集所有 subagent delivery → 跑 validate-delivery.py → 不合格返工。

## Trigger

- Phase 4 所有子 agent delivery 已返回
- 需要校验 delivery-schema 合规性 + drift < 0.4

## Quick Start

```
（自动触发，不需要用户调用）
```

## Workflow

1. 收集所有子 agent delivery YAML
2. 跑 validate-delivery.py（schema + 必填字段 + drift 阈值）
3. 不合格 → 返工子 agent（带具体反馈）
4. drift ≥ 0.4 → 触发 coder-adaptive 重分解
5. 全部合格 → 进 Phase 5

## Directory Structure

```
SKILL.md / scripts/validate-delivery.py / assets/delivery-schema.yaml / README.md
```

## Output Format

```
校验报告（每 agent PASS/FAIL + drift score）
```

## See Also

coder-execute (Phase 4 前驱) / coder-verify (Phase 5 后继) / coder-adaptive (drift 触发) / coder (主 router)
