# Gap Diagnosis（4 维度诊断协议）

借鉴 ECC `skill-stocktake` 的 holistic AI judgment（**不是 numeric rubric 死算**）。

## 5 维度定义（v1.1 加 Content Depth）

> v1.0 是 4 维度。v1.1 加第 5 维度 Content Depth，捕获 Actionability 不能覆盖的"缺方法论 / 缺案例 / 缺判断标准"用户痛点。

### 维度 5: Content Depth（内容深度，v1.1 新增）

**问**：有真实案例 / 具体方法论 / 可操作判断标准吗？还是全是流程模板？

| 评分 | 标准 | 反例 |
|------|------|------|
| 5/5 | 含真实失败案例库 + 可证伪方法论 + 具体 do/don't | harness 的 6 架构模式 + SatangSlide 7 bug |
| 4/5 | 有方法论但案例不足 / 案例有但方法论模糊 | coder v3.0（流程清晰但缺真实 bug 库） |
| 3/5 | 流程清晰但全是抽象指导，无 expert reasoning | skill-search v4.0（流程合规但无深度） |
| 1/5 | 纯流程模板，零案例零方法论 | "1.理解 2.执行 3.验证" |

**检测方式**：随机抽 3 个 Phase 步骤，问"专家会怎么判断这步？SKILL.md 说了吗？"

**与其他维度区别**：
- Actionability: "能立即行动吗？"（命令级）
- Content Depth: "知道为什么这样行动吗？"（专家级）

例：coder v3.0 的"运行 lint"Actionability 5/5（命令具体）但 Content Depth 3/5（无"为什么这步是 lint 不是 type check"的 expert reasoning）。

---

## 4 维度定义（v1.0 原版，仍有效）

### 1. Actionability（可操作性）

**问**：用户读完能否立即行动？

| 评分 | 标准 | 反例 |
|------|------|------|
| 5/5 | 每条指令都有 code example / command / 具体步骤 | "对 Go 项目用 `golangci-lint run ./...` 检查" |
| 3/5 | 多数指令可执行，少数需 agent 自行发挥 | "执行语言验证链"（不写具体命令） |
| 1/5 | 全是抽象指导 | "重视代码质量"、"按需优化" |

**检测方式**：随机抽 5 条指令，问"我能 1 分钟内执行吗？"

### 2. Scope fit（范围契合）

**问**：name / trigger / content 三者对齐吗？

| 评分 | 标准 | 反例 |
|------|------|------|
| 5/5 | name 描述能力，trigger 精准命中场景，content 兑现 trigger 承诺 | "coder" + "写代码/实现" + 多语言编码流程 |
| 3/5 | name OK 但 trigger 太宽 / 太窄 / content 部分偏题 | trigger 含 "做" 但 content 不覆盖所有"做"场景 |
| 1/5 | 三者严重不一致 | name "skill-validator" 但 content 含部署流程 |

**检测方式**：用 3 个真实场景测 description 命中率（应该 2 个以上触发）。

### 3. Uniqueness（独特性）

**问**：能否被 MEMORY.md / CLAUDE.md / 其他 skill 替代？

| 评分 | 标准 | 反例 |
|------|------|------|
| 5/5 | 提供独有价值，无替代 | "gf gen ctrl 自动生成协议"（独有） |
| 3/5 | 部分内容可被替代 | "使用 git commit"（CLAUDE.md 也有） |
| 1/5 | 几乎全部可替代 | "写代码要简洁"（coding-rules R2 也有） |

**检测方式**：grep MEMORY.md / CLAUDE.md / 其他 skill，看是否重复。

### 4. Currency（时效性）

**问**：技术参考是否过期？

| 评分 | 标准 | 反例 |
|------|------|------|
| 5/5 | 所有工具/命令/API 在当前环境可用（WebSearch 验证） | "用 ruff 0.5+ 的 check 命令" |
| 3/5 | 多数可用，少数可能过期 | "用 flake8"（项目可能已迁移到 ruff） |
| 1/5 | 关键工具已废弃 | "用 setup.py"（Python 现代项目用 pyproject.toml） |

**检测方式**：WebSearch 查 SKILL.md 提到的所有工具/命令的当前状态。

## 诊断报告模板

```markdown
## P1 缺口诊断

### 评分汇总

| 维度 | 评分 | 关键证据 | 深化方向 |
|------|------|---------|---------|
| Actionability | X/5 | {SKILL.md 行号 + 引用} | {补 code example / command} |
| Scope fit | X/5 | {行号 + 引用} | {改 trigger / 删 content} |
| Uniqueness | X/5 | {行号 + 引用} | {删重复 / 加独有} |
| Currency | X/5 | {行号 + WebSearch 验证} | {更新工具/命令} |

### 综合诊断

- **总分**：X/20
- **优先深化方向**（基于最低维度）：
  1. {P2-P4 重点方向 1}
  2. {方向 2}

### Currency 验证记录

- `{tool}` 当前版本：{version}，SKILL.md 用法：{still valid / outdated}
- `{api}` 当前状态：{active / deprecated}

### 下一步建议

{P2 反推通道的重点任务设计}
```

## 与 ECC 的差异

- ECC 用 4 维度做 **Keep/Improve/Update/Retire/Merge** verdict
- 我们用 4 维度做**深化方向排序**（不淘汰 skill，只深化）

## 红线（必须触发 P2 反推）

如果以下任一命中，P2 必须跑：

- Actionability ≤ 2
- Currency ≤ 2（有过期技术）
- 任何维度评分理由含"无证据" / "无引用"
