# Expert Role Audit（多专家角色评审）

借鉴 Agent-as-a-Judge（arXiv:2508.02994）。让 agent 扮演多个 domain expert 角色，注入多样化专业判断。

---

## 为什么需要多角色

skill-evolver 单 auditor 只看结构合规（防过拟合），不看内容深度。

skill-deepener 的 P5 需要**内容深度评审**，单角色不够，需要多专家视角。

---

## 三角色定义

### 角色 1：方法论严谨者（Methodology Rigor）

**专业视角**：方法是否经得起推敲？是否有可证伪的判断标准？

**评估清单**：
- [ ] 是否有具体方法论（不是空泛指导）？
- [ ] 方法论是否可证伪（"do X" 能被验证，"重视 X" 不能）？
- [ ] 步骤之间是否有逻辑依赖（不是随机列表）？
- [ ] 是否有反例 / 边界场景处理？
- [ ] 是否经得起"为什么"追问（5 why 不破）？

**评分标准**：
- 5/5：方法论清晰可证伪 + 反例齐全 + 5 why 不破
- 3/5：有方法但部分模糊 / 反例不足
- 1/5：全是抽象指导，无可证伪标准

### 角色 2：案例真实者（Case Authenticity）

**专业视角**：案例是真的吗？能复现吗？包含失败模式吗？

**评估清单**：
- [ ] 案例是否来自真实执行（非编造）？
- [ ] 是否有具体触发条件（不是"如果用户问 X"）？
- [ ] 是否包含失败模式（不只是 happy path）？
- [ ] 失败案例的 expert 正确做法是否具体？
- [ ] 案例是否有时间戳 / 来源（可追溯）？

**评分标准**：
- 5/5：案例全真实可追溯 + 失败模式齐全 + 来源标注
- 3/5：案例真实但 happy path 偏多
- 1/5：案例编造 / 无失败模式 / 无来源

### 角色 3：领域准确者（Domain Accuracy）

**专业视角**：领域术语准吗？符合 expert 共识吗？

**评估清单**：
- [ ] 领域术语使用准确（不是泛化误用）？
- [ ] 是否符合该领域 expert 共识？
- [ ] 是否有该领域最新发展（非过期）？
- [ ] 边界情况是否符合领域惯例？
- [ ] 是否有领域 expert 误判的常见陷阱？

**评分标准**：
- 5/5：术语精准 + 符合 expert 共识 + 含领域陷阱
- 3/5：术语基本对但部分过期
- 1/5：术语误用 / 不符合 expert 共识

---

## Spawn 协议

### 每个 auditor 独立 spawn

**禁止**共享 context 或合并 prompt。每个角色独立 fresh context。

```
Agent(
  description="{role} audit",
  subagent_type="evolver-auditor",
  model="opus",
  prompt="{role-specific 评估 prompt + 目标 skill 路径}"
)
```

### Prompt 模板

```markdown
你是 {role}（{角色定义}），独立评审 {target_skill} 深化后的内容。

## 输入
- 目标 skill: {path}
- 深化前快照: {path}/.deepen/{date}/BEFORE-SKILL.md
- 深化后: {path}/SKILL.md

## 你的角色视角
{角色定义 + 评估清单}

## 输出（严格 JSON）

{
  "role": "{role}",
  "score": 1-5,
  "verdict": "accept | revise | reject",
  "evidence": [
    "具体证据 1（行号 + 引用）",
    "具体证据 2",
    ...
  ],
  "improvements": [
    "改进建议 1（surgical）",
    ...
  ]
}
```

---

## 综合 verdict

3 角色独立评分后，主 agent 综合：

```markdown
## P5 多专家评审

### 方法论严谨者：{score} {verdict}
- 证据：{top 2}
- 改进：{top 2}

### 案例真实者：{score} {verdict}
- 证据：{top 2}
- 改进：{top 2}

### 领域准确者：{score} {verdict}
- 证据：{top 2}
- 改进：{top 2}

### 综合 verdict 决策表

| 任一角色 reject | reject → 回 P4 重写 |
| 任一角色 ≤ 2 | revise → P4 局部修改 |
| 全部 ≥ 3 + 总分 ≥ 12 | accept → 进 P6 |
| 全部 ≥ 4 | 强 accept → 进 P6 + 标 ⭐ 高质量 |
```

---

## 与 skill-evolver audit 的差异

| 维度 | skill-evolver audit | skill-deepener P5 |
|------|---------------------|-------------------|
| 目标 | 防过拟合（结构合规） | 评内容深度 |
| 检查 | 9-check + Check 10 | 三角色 + 4 维度评分 |
| auditor | 单 auditor (opus) | 3 auditor (opus each, 独立 context) |
| 输入 | candidate + BEFORE | candidate + BEFORE + P2 失败案例 |
| 输出 | binary gate + violations | 3 维度评分 + 综合 verdict |
| 失败处理 | reject → targeted patch | reject → 回 P4 重写 |

---

## 反例（必须避免）

### 反例 1：3 角色共享 context
```
# 错误做法
Agent(
  prompt="你是方法论严谨者+案例真实者+领域准确者..."
)
```
**问题**：单 context 会自我一致，失去多视角价值。

### 反例 2：角色定义模糊
```
# 错误做法
角色：你是审计员
```
**问题**：没有领域专业视角，等于单 auditor。

### 反例 3：评分无证据
```
# 错误做法
{"score": 3, "verdict": "revise", "evidence": ["不够好"]}
```
**问题**：无法定位具体改进点。

---

## 配置参数

| 参数 | 默认 | 说明 |
|------|------|------|
| 并行/串行 | 并行 | 3 个 spawn 同 tool_calls |
| 超时 | 各 5 分钟 | 单 auditor 超时不影响其他 |
| 失败处理 | 某角色 fail → 标 N/A 不阻塞 | 其他 2 角色仍可综合 |
