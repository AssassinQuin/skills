# P1 缺口诊断（web-research v2.1）

## 6 维度评分

### 1. Actionability: 4/5

**优点**：6 Phase 流程清晰，每 Phase 有具体步骤、表格、阈值（如"30 次预算"）
**缺口**：
- Phase 2 "六角度" 的 query 模板太通用，缺深度定制
- Phase 3.3 prompt 注入只说"读 agent-prompt.md"，没说"如果 agent 跑偏了怎么纠"

### 2. Scope fit: 5/5 ✓

name / trigger / content 对齐良好

### 3. Uniqueness: 4/5

与 skill-search 区分清晰。但 "💡 灵感" 角度可能与 brainstorm skill 部分重叠

### 4. Currency: 4/5

MCP 工具列表都未过期。但 "6 角度" 方法论是 2024 设计，可能 newer methodology（如 reasoning models 影响调研方式）

### 5. Content Depth: 2.5/5 ⚠️ 最大短板

**严重缺口**：
- 缺真实失败案例库（没 references/case-library.md）
- 缺"为什么 6 角度不是 5 或 7"的 expert reasoning
- 缺"调研深度 vs 广度"判断标准
- 缺 query 设计方法论（只给模板，没说"如何根据主题调整 query"）
- 缺"agent 跑偏纠错"协议

### 6. Trigger Precision: 3/5 ⚠️

**缺口**：
- 有显式 trigger（调研/研究/web research/对比分析/方案选型/文献/literature review/deep dive）
- 缺**隐式 trigger**（"how do I do X" 类能力缺口识别）
- 缺 do/don't 边界（什么场景不该用 web-research）

## 总分: 22.5/30

## Verdict: **Improve**（Content Depth ≤ 3 + Trigger Precision ≤ 3）

## 优先深化方向（P2-P4 重点）

1. **Content Depth 2.5 → 4+**（P2 反推通道重点）：
   - 补真实失败案例库
   - 补 query 设计方法论
   - 补 agent 跑偏纠错协议

2. **Trigger Precision 3 → 4+**：
   - 加隐式 trigger（能力缺口识别）
   - 加 do/don't 边界

3. **Actionability 4 → 5**：
   - Phase 2 query 深度定制方法
   - Phase 3 跑偏纠错协议

## 下一步

P2 反推通道：spawn Domain-Skill Agent 跑真实调研任务，萃取出 web-research 在实战中的 expert reasoning gaps。
