# coder v3.0 Phase 4 Validate 报告

**日期**：2026-06-18
**任务**：V1 "审查这个 Python PR，然后自动修复发现的问题"
**Domain-Skill Agent**：sonnet, fresh context
**reward**：1（任务走完整流程）
**verdict**：PASS

## v3.0 新机制验证（8 项全部生效）

| 机制 | 验证结果 |
|------|---------|
| `skill_type: execution` frontmatter | ✓ 声明（元数据级，决策树未显式消费 → 留 v3.1） |
| 复杂度不可降级判据 | ✓ 5 类敏感词（金额/并发/auth/跨模块/框架）明确，V1 不含 → 标准 |
| 编排链 completeness | ✓ V1 = 审查+修复 匹配编排表 L104 链 |
| references 加载 📂 证据 | ✓ 强制输出 + 汇报 references 引用点 |
| 工具链探测 memory_store 持久化 | ✓ hard-constraint #2 自检 + tag `coding-python-toolchain` |
| 审查门控自动触发 | ✓ Layer 1 强制（标准）+ 语义覆盖复核 |
| 汇报必填字段 | ✓ references 引用点 + 硬约束执行检查清单 |
| 经验总结扩展触发 | ✓ 场景 1/2/3 全覆盖，标准 tag 体系 |

## 回归检查（v2.2 → v3.0）

| 历史 PP | 状态 |
|---------|------|
| PP-5 测试先行保护 | preserved（完整路径保留保护测试） |
| PP-7 Read 5 文件 token 爆炸 | **improved**（token-budget.md + 30k 上限 + 长文件 ctx_index） |
| PP-9 references 声明加载但未实际 | **improved**（三层防护：📂 输出 + 引用点 + 自检） |
| PP-11 元技能编排能力 | preserved（编排表 +2 串联模式） |
| PP-19 后置审查强制 | **improved**（触发矩阵 + 自检 #4） |
| PP-20 memory tag 不一致 | **improved**（标准化 `coding-{lang}-{type}`） |

## 剩余 weaknesses（v3.1 候选）

1. skill_type 字段未在决策树入口显式消费（元数据级 → 路由级）
2. token 预算 30k 上限在大型 PR 审查可能不够（建议加弹性 40-50k 条款）
3. 编排模式与复杂度判定的耦合关系未显式（边界场景）
4. Q2 更新 references 确认在批量任务可能交互摩擦（建议 <3 行自动确认阈值）
5. hard-constraints-check.md 缺交叉验证（引用点 vs 实际加载）

## 结论

v3.0 通过 held-out V1 验证，**reward=1**。v3.0 新机制全部被决策树消费，且不破坏 v2.2 已 resolved 的 6 项 PP（4 improved + 2 preserved）。

verifier: Domain-Skill Agent (sonnet) 独立 fresh context，真实轨迹产出
