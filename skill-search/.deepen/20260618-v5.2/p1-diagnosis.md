# P1 缺口诊断（skill-search v5.1.1 → v5.2）

## 7 维度评分

### 1. Actionability: 4/5
**优点**：6 Phase + 14 硬约束 + E1 模式分支 + 四维质量门
**缺口**：P2 5 个 Scout 子 agent 分工（Scout-GH/BuiltIn/Market/Community/Expand）但 prompt 模板没拆，agent 内部知识全在 search-templates.md（273 行）

### 2. Scope fit: 4/5
**优点**：name/trigger/content 对齐
**缺口**：与 web-research v2.3 边界（web-research 调研主题 / skill-search 评估 skill）尚未在 description 显式说明

### 3. Uniqueness: 5/5 ✓
与 skill-creator/skill-evolver/skill-deepener 边界清晰

### 4. Currency: 4/5
**优点**：skillsmp.com / skills.sh / openagentskill.com 都未过期
**缺口**：未知 2026 H2 是否有新 skill 平台（tecnhology radar 需要刷新）

### 5. Content Depth: 3/5 ⚠️ 最大短板
**严重缺口**：
- 缺真实失败案例库（如评估 revfactory/harness 时 SearXNG 韩文盲区案例未沉淀进 references）
- 5 个 Scout 子 agent 角色定义全在 SKILL.md 流程里（没拆 agents/）
- 缺"评估不同类型 skill 的差异化方法"（执行型 vs 研究型 vs 文档型评估标准应不同）

### 6. Trigger Precision: 4/5
**优点**：显式 + 隐式 trigger 齐全（v5.1 加了 6 类隐式）
**缺口**：与 web-research 重叠场景未标 DO/DON'T（如"评估这个仓库"是 skill-search 还是 web-research？）

### 7. Size Discipline: 3/5 ⚠️
**当前**：SKILL.md 291 行
**预测深化后**：
- 加 5 个 Scout agent 文件 → 不进 SKILL.md（agents/ 各 80-100 行）
- 加 skill 类型差异化评估 → SKILL.md +30 行 + references 1 个新文件
- 加 DO/DON'T 边界 → description +10 行
- 加失败案例库 → references/case-library.md（不进 SKILL.md）
- **预测 SKILL.md 深化后 ~330 行（1.14x）**
- 但接近阈值，**必须执行 Step 4e 分发架构建议**

**Step 4e 预判**：skill-search 已是元 skill（编排型），应该按"评估模式"拆垂直子 agent：
- single-repo-evaluator（E1 单仓库评估）
- multi-source-discoverer（多源发现 + 粗筛）
- skill-class-evaluator（按 skill 类型差异化评估）

类似 web-research v2.3 / coder v3.2 模式。

## 总分: 27/35

## Verdict: **Improve**（Content Depth ≤ 3 + Size Discipline ≤ 3）

## 优先深化方向

1. **Content Depth 3 → 4+**：
   - 拆 5 个 Scout 为 agents/ 子文件
   - 加 skill 类型差异化评估协议（execution/research/document）
   - 沉淀失败案例库

2. **Size Discipline 3 → 4+**：
   - **强制 P4 Step 4e 拆分**（按评估模式路由子 agent）

3. **Scope fit 4 → 5**：
   - 加与 web-research DO/DON'T 边界

## 关键决策

按 Step 4e 建议，本次 v5.2 拆 3 个垂直子 agent：
- **agents/single-repo-evaluator.md**（E1 模式，用户给具体仓库）
- **agents/multi-source-discoverer.md**（P2 多源发现 + P3 粗筛）
- **agents/skill-class-evaluator.md**（按 skill 类型差异化评估）

SKILL.md 精简为元 skill（路由 + 综合协议），目标 ~180-200 行。
