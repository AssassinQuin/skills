# P2 自模拟（self-deepening 合法例外）

**说明**：self-deepening 无法真 spawn Domain-Skill Agent 跑自己（循环依赖）。改为主 agent 模拟走流程，记录"如果真做，哪里会卡"。

## 模拟场景：用 skill-deepener 深化 coder v3.0（缺方法论）

### 模拟 P1 诊断 coder v3.0

按 gap-diagnosis.md 4 维度评 coder v3.0：
- Actionability: 4/5（多数可执行）
- Scope fit: 5/5
- Uniqueness: 4/5
- Currency: 5/5

→ **暴露 gap 1**：coder v3.0 总分 18/20，但"缺方法论"用户痛点对应不到 4 维度任一低分。**4 维度不能直接捕获"缺方法论"**。

### 模拟 P2 反推通道

假设 spawn Domain-Skill Agent 跑 coder T3：
- 需要给 Domain-Skill Agent 明确的"如何记录 expert reasoning gap"输出格式
- **当前 SKILL.md P2 只给"输出 JSON：trajectory + reward + expert_reasoning_gaps"**，但 expert_reasoning_gaps 的字段没定义

→ **暴露 gap 2**：P2 expert reasoning gap 输出 schema 不完整。Domain-Skill Agent 不知道每个 gap 该写哪些字段。

### 模拟 P3 内容采集

假设 P2 暴露 3 个 gap：
- gap A: "缺框架工具链探测方法论"
- gap B: "缺 memory tag 跨语言一致性"
- gap C: "缺 agent 自己 vs 委托 skill 边界判断"

按 P3 分类：
- gap A 缺方法论 → web-research
- gap B 缺判断标准 → 主 agent 综合
- gap C 缺思维框架 → huashu-nuwa

每个 gap 用 Cognitive Apprenticeship 4 要素过滤——但 **gap A 该用哪个要素？SKILL.md 没说**。

→ **暴露 gap 3**：P3 缺 gap 类型 → Cognitive Apprenticeship 要素的映射。

### 模拟 P4 内容重写

P4 给 4 类段：
- 专家出声思考段（Modeling）
- 脚手架问题段（Scaffolding）
- 失败案例库段（来自 P2）
- do/don't 判断标准段

**但 SKILL.md coder 的哪个 Phase 段加哪类？** 没规则。

→ **暴露 gap 4**：P4 缺"哪个 Phase 段落加哪类内容"映射。

### 模拟 P5 多专家评审

3 角色评分清单已给，但 **3 分 vs 4 分 vs 5 分的边界？**
- 方法论严谨者 5/5 = "方法论清晰可证伪 + 反例齐全 + 5 why 不破"
- 方法论严谨者 4/5 = ?（references 没写）

→ **暴露 gap 5**：P5 缺每个角色的评分边界细则。

## 萃取的 expert reasoning gaps（5 个）

| Gap # | 缺口 | 影响 Phase |
|-------|------|-----------|
| 1 | P1 4 维度不捕获"缺方法论"用户痛点 | P1 |
| 2 | P2 expert_reasoning_gaps 输出 schema 不完整 | P2 |
| 3 | P3 gap 类型 → CA 要素缺映射 | P3 |
| 4 | P4 Phase 段落 → 4 类内容缺映射 | P4 |
| 5 | P5 评分边界细则缺失 | P5 |

## Expert 正确做法

每个 gap 的 expert 正确做法（用于 P4 补内容）：

1. **P1 加"内容深度维度"**（区别于 Actionability，专评方法论/案例/判断标准）
2. **P2 expert_reasoning_gaps schema 标准化**（含 5 字段：trigger/failure/expert_action/missing_rule/evidence）
3. **P3 gap → CA 要素映射表**
4. **P4 Phase 段落 → 内容类型映射表**
5. **P5 评分边界细则表**

## 可追溯证据

- 主 agent 模拟过程，2026-06-18
- 每个 gap 来自具体 Phase 模拟的卡点
- 改动量：5 个 references 文件 + SKILL.md 多处
