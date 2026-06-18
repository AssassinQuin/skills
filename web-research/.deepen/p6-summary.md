# web-research v2.1 → v2.2 Self-Deepening 总结

## 流程
- P1 6 维度诊断: Content Depth 2.5/5（最大短板）+ Trigger Precision 3/5
- P2 Domain-Skill Agent 跑 Rust vs Go microservice 模拟: 7 个 expert reasoning gaps
- P4 7 处补丁: 信号组合矩阵 / 主题类型分类 / 跑偏信号清单 / 灵感评分矩阵 / 预算分桶 / MCP 三级失败 / 证据等级 + frontmatter
- P5 audit ACCEPT_WITH_WARNINGS: Check 2+6（训练案例）+ Check 10（行数 1.51x）
- Fix targeted patch: Check 2+6 全清，Check 10 留 v2.3

## 改动
- SKILL.md: 233 → 351 行 (+118, 1.51x)
- version 2.1 → 2.2
- 加 skill_type: research
- 加隐式 trigger + DO/DON'T

## v2.3 候选（未做）
- 拆 SKILL.md 6 个表格到 references/deep-research-tactics.md（Check 10）
- references/agent-prompt.md + tool-specs.md 协调更新（gap 6 三处协调）
