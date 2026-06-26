# Coder-Verify

**Phase 5 验证** — 3 reviewer 并发（correctness / project / security）+ fresh-context 对抗式审查 + v7.1 model 显式 + [3,5] 上限。

## Trigger

- Phase 4.5 delivery 全部合格
- 需要审查 diff 的正确性 / S.U.P.E.R / 安全 3 维度

## Quick Start

```
（自动触发，不需要用户调用）
```

## Workflow

1. 并发 spawn 3 reviewer（每个 sonnet，独立 agent 文件）
2. correctness-reviewer：验收 checklist + edge case
3. project-reviewer：S.U.P.E.R 衰减 + 项目惯例
4. security-reviewer：OWASP top 10
5. orchestrator 合并报告 + signature-guard 签字

## Directory Structure

```
SKILL.md / README.md
```

## Output Format

```
review-report.md（3 维问题清单 + BLOCKER/MAJOR/MINOR 标签）
```

## See Also

coder-deliver (Phase 4.5 前驱) / coder-persist (Phase 6 后继) / coder-constraints (#2 model 显式) / agents/{correctness,project,security}-reviewer.md / coder (主 router)
