# P1 缺口诊断（coder v3.0 → v3.1）

## 7 维度评分

### 1. Actionability: 4/5

**优点**：决策树清晰 + 复杂度判据明确 + references 加载表 + 工具链探测
**缺口**：
- Phase 4 "执行" 段对"重构/新需求/Bug修复/简化/生成目录"5 类任务，每类只有 1 行流程
- references/ 加载时机表明确，但**没说哪段引用哪个 reference 的哪段**

### 2. Scope fit: 5/5 ✓

name "coder" + trigger "写代码/实现/重构/修复" + content 多语言编码流程对齐良好

### 3. Uniqueness: 5/5 ✓

与 programmer / tdd / diagnose / code-review 边界清晰（编排表明确）

### 4. Currency: 4/5

**优点**：gopls / ruff / pyright 都未过期
**缺口**：
- references/go-editing-traps.md 33 行（Tab/sed 陷阱），但 2026 年新陷阱（如 AI 工具生成的代码 GoFrame gf gen 错位）未覆盖
- AI coding 工具流行后的"agent 自己生成 vs 框架生成"边界

### 5. Content Depth: 3/5 ⚠️

**严重缺口**：
- 缺真实失败案例库（references/case-library.md 不存在）
- 缺"为什么这个复杂度判据"的 expert reasoning
- 缺"工具链探测后如何决定手动 vs 自动生成"的判断标准
- 缺"审查门控触发条件"的边界场景

### 6. Trigger Precision: 4/5

**优点**：trigger 词丰富 + agent-compatible 标注
**缺口**：缺隐式 trigger（如"修这个 bug" / "加个 X 功能" / "重构这块"）

### 7. Size Discipline: 4/5（v1.3 新增）

**当前**：SKILL.md 272 行
**预测深化后**：
- 加真实案例库 → references/case-library.md（新增 ~150 行，不进 SKILL.md）
- 加 expert reasoning 段 → SKILL.md +50-80 行
- 加隐式 trigger → description +20 行
- 预测 SKILL.md 深化后 ~340-370 行（1.25-1.36x，**未超 1.5x 阈值**）
- **verdict**：4/5，P4 可直接写入，但接近阈值需 Step 4e 警惕

## 总分: 25/35

## Verdict: **Improve**（Content Depth ≤ 3，触发 P2 反推）

## 优先深化方向

1. **Content Depth 3 → 4+**（最大短板）：
   - 新建 references/case-library.md（失败案例沉淀）
   - 加 expert reasoning 段（"为什么这个复杂度判据"）
   - 加工具链探测后的判断标准（手动 vs 自动生成）

2. **Trigger Precision 4 → 5**：
   - 加隐式 trigger（"修这个 bug" / "加个 X 功能" / "重构这块"）

3. **Actionability 4 → 5**：
   - Phase 4 5 类任务每类补 2-3 行 expert 视角

## Size Discipline 自检

✅ 深化后预测 340-370 行（< 1.5x 阈值）
⚠️ 但接近阈值，P4 必须执行 Step 4e 评估是否需要拆元+子 agent

**Step 4e 预判**：coder 已是元 skill（编排型），但当前没有垂直子 agent。
建议（v3.1 候选）：拆 go-coder / python-coder / typescript-coder 子 agent。
但本次 v3.1 聚焦内容深化（不拆架构），架构拆分留 v3.2。

## 下一步

P2 反推通道：spawn Domain-Skill Agent 跑真实编码任务，萃取 expert reasoning gaps。
