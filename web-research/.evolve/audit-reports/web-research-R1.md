## Audit Report: web-research Round 1

### 标记验证
- BEFORE: 292 行
- AFTER: 307 行 (+15)
- 状态: 正常

### 审计结果

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Framing | PASS | 范围合适，Phase 2 约束了 query 质量防止百科级结果 |
| 2 | Literals | PASS | 工具名与 frontmatter allowed-tools 一致，路径可达 |
| 3 | Script bloat | PASS | 无新增脚本，增加的是指导性内容 |
| 4 | Untraceable imperative | PASS | Phase 2 query 构造有模板+示例+禁止规则；Phase 4 综合有6步方法论 |
| 5 | Shape-bake | PASS | 格式约束是软性的，留有选择空间 |
| 6 | Coverage | PASS | 所有 BEFORE 功能保留，新增知识空白/可信度/深度要求 |
| 7 | X-ref | PASS | references/tool-specs.md, agent-prompt.md, mcp-probe.sh 均存在 |
| 8 | Under-abstraction | PASS | 无大段重复，query 构造指南集中在 Phase 2.1 |
| 9 | Silent-bypass | PASS | 🔴 强制约束标记保留，新增信息密度检查不可绕过 |
| 10 | Overfit | PASS | T_val V1(sleep-divorce)和 V2(SQLite并发)均可被新流程处理 |

### Summary: 10/10 PASS, 0 FAIL
### Verdict: PASS

### 变更摘要
1. Phase 2: 6角度模板 → 学术级 query 构造方法（6策略表+禁止规则+双语query）
2. Phase 3.3.1: 新增 URL 质量过滤
3. Phase 3.3.3: Agent prompt 加深度要求和零密度禁令
4. Phase 4: 模糊综合 → 6步方法论（提取+交叉验证+可信度+知识空白+灵感+撰写）
5. tool-specs: maxLength 5000→15000 + 多段提取
6. agent-prompt: 同步提取深度和信息密度要求
