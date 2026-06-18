# P1 缺口诊断（self-deepening）

## 4 维度评分

### Actionability: 3.5/5 ⚠️

**优点**：
- 6 Phase 流程清晰
- references 含具体方法（4 要素 / 3 角色 / 4 维度）
- P4 有 Step 4a-4d + 正反例

**缺口**（关键）：
1. **P2 Domain-Skill Agent prompt 不够具体**：缺"如何记录 expert reasoning gap"的标准格式
2. **P3 分类采集 → Cognitive Apprenticeship 过滤**衔接不清晰：agent 不知道哪个 gap 用哪个要素过滤
3. **P4 4 类段（专家视角/脚手架/案例/do-don't）缺少映射**：哪个 Phase 段落加哪类？没有规则
4. **P5 3 角色评分标准**：references 有清单，但没说"3 分 vs 4 分的边界"

### Scope fit: 4/5

**优点**：
- name / trigger / content 对齐
- 与 skill-evolver / huashu-nuwa / skill-creator 边界清晰

**缺口**：
- "P2 反推通道"对 self-deepening 不适用（无法 spawn 自己跑），但 SKILL.md 没说

### Uniqueness: 5/5 ✓

**优点**：
- 与所有相关 skill 边界清晰
- Cognitive Apprenticeship + Agent-as-a-Judge + ECC 4 维度组合独特

### Currency: 5/5 ✓

**优点**：
- 调研来源 2025-2026 论文
- Anthropic / ECC 都是最新
- 工具名（memory_search / Agent / WebSearch）未过期

## 总分: 17.5/20

## 优先深化方向（基于最低维度）

**Actionability（3.5/5）** 是最大短板。4 个缺口全是 P2-P5 流程内部细节。

1. 补 P2 Domain-Skill Agent prompt 标准格式（含 expert reasoning gap 输出 schema）
2. 补 P3 gap → Cognitive Apprenticeship 要素的映射表
3. 补 P4 Phase 段落 → 4 类内容映射
4. 补 P5 3 角色评分边界（3 vs 4 vs 5）

## 红线检查

- Actionability 3.5 > 2 ✓（不强制 P2）
- Currency 5 > 2 ✓
- 但 Actionability 缺口影响真实可用性 → 仍走 P2

## 下一步

P2 自模拟（self-deepening 合法例外）：
- 主 agent 模拟"用 skill-deepener 深化 coder v3.0"流程
- 记录流程中暴露的"如果真做，哪里会卡"gap
- 不真 spawn（self-deepening 不适用硬约束 5）
