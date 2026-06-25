# Programmer

Full-stack programming assistant with progressive memory. Accumulates project conventions, constraints, and insights across sessions. Combines coding execution with persistent project knowledge.

## Trigger

program、编程、开发功能、写代码、实现需求

## Quick Start

```
/programmer 实现用户注册流程
/programmer 给订单模块加缓存
/programmer 重构数据库访问层
```

## Workflow

1. **Load Context** — Read project constraints from memory (conventions, pitfalls, decisions)
2. **Understand** — Parse the requirement, identify affected modules
3. **Plan** — Generate task plan using `references/task-plan-template.md`
4. **Execute** — Implement with verification loops
5. **Insight Capture** — Extract and store new patterns/constraints discovered during work

## Key Features

### Progressive Memory

Learns project-specific knowledge over time:
- **Conventions** — Naming, structure, error handling patterns
- **Constraints** — Business rules, API limitations, performance budgets
- **Insights** — Discovered pitfalls, optimization opportunities
- **Evolution** — Conventions update as project matures

### Convention Sources

- Code patterns in existing files
- Developer instructions during sessions
- Failed attempts and their root causes

## Directory Structure

```
SKILL.md                        # Core instructions
references/
  task-plan-template.md         # Structured task planning template
```

## See Also

- coder — Lighter-weight coding without progressive memory
- skill-evolver — Optimize this skill
