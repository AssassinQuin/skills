# Anthropic Cybersecurity Skills 披露式流程分析 + coder 优化建议

**日期**：2026-06-25
**来源**：[mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills)（20.7k stars, 817 skills）
**目的**：分析其 progressive disclosure 架构，对照 coder v6.x 找优化重构点

---

## 1. Anthropic Cybersecurity Skills 的核心设计

### 1.1 Token 经济模型（**最大创新**）

| 操作 | Token 成本 |
|---|---|
| 扫描 1 个 skill frontmatter | ~30 tokens |
| 完整加载 1 个 skill | 500-2000 tokens |
| 扫描全部 817 skills | ~24k tokens（817 × 30） |
| 完整加载 top 3 match | 1500-6000 tokens |

**关键洞察**：817 个 skills 通过 progressive disclosure 实现"一次扫描全部 + 按需加载"。

### 1.2 Progressive Disclosure 4 步流程

```
1. Scan all frontmatters (~30 tokens each)
   → identify relevant by tags / description / domain matching

2. Load top N matches (500-2000 tokens each)
   → 完整加载 Workflow / Verification / References

3. Execute structured Workflow step-by-step
   → 按步骤执行

4. Validate using Verification section
   → 显式验证成功条件
```

### 1.3 Skill 标准结构（每个 skill 独立目录）

```
skills/{skill-name}/
├── SKILL.md              ← YAML frontmatter + Markdown body
├── references/
│   ├── standards.md      ← 框架映射
│   └── workflows.md      ← 深度技术参考
├── scripts/
│   └── process.py        ← 辅助脚本
└── assets/
    └── template.md       ← 模板 / checklist
```

### 1.4 YAML Frontmatter 字段（标准化 + 可发现性）

```yaml
name: performing-memory-forensics-with-volatility3  # kebab-case, 1-64 chars
description: >-                                      # keyword-rich for discovery
  Analyze memory dumps to extract running processes, network connections,
  injected code, and malware artifacts using the Volatility3 framework.
domain: cybersecurity
subdomain: digital-forensics
tags: [forensics, memory-analysis, volatility3, incident-response, dfir]
atlas_techniques: [AML.T0047]                        # 6 框架映射
d3fend_techniques: [D3-MA, D3-PSMD]
nist_ai_rmf: [MEASURE-2.6]
nist_csf: [DE.CM-01, RS.AN-03]
version: "1.2"
author: mukul975
license: Apache-2.0
```

### 1.5 6 框架映射（**一个 skill 6 个合规复选框**）

| 框架 | 用途 |
|---|---|
| MITRE ATT&CK | Adversary behaviors / TTPs |
| NIST CSF 2.0 | Organizational security posture |
| MITRE ATLAS | AI/ML adversarial threats |
| MITRE D3FEND | Defensive countermeasures |
| NIST AI RMF | AI risk management |
| MITRE F3 | Cyber-enabled financial fraud |

---

## 2. 对照 coder v6.x 的 5 个差距

### 差距 1：references 没有 token 经济模型

**当前**：SKILL.md §7 列了 20+ references，orchestrator 不知道加载成本。

**cybersec 做法**：每个 skill 标 ~30/500-2000 token。

**影响**：orchestrator 可能一次加载太多 references 爆 context，或漏加载关键 reference。

### 差距 2：references description 不 keyword-rich

**当前**：
```yaml
description: Phase 0 需求确认协议（v6.0 强化版）
```

**cybersec 做法**：description 含大量 discoverable keyword：
```yaml
description: Analyze memory dumps to extract running processes, network connections, injected code, and malware artifacts using the Volatility3 framework.
```

**影响**：orchestrator 检索时可能漏匹配（"我搜 phase 0 multi-turn askuserquestion spec" → 当前 description 不命中）。

### 差距 3：references 缺 Verification 段

**当前**：每个 Phase reference 描述"怎么执行"。

**cybersec 做法**：每个 skill 有 **Workflow + Verification**——后者显式列"如何确认成功"。

**影响**：orchestrator 不容易自动验证 Phase 完成度，依赖 hook 检查。

### 差距 4：references 不是 skill 形态（平铺）

**当前**：
```
coder/references/
├── phase-0-intent-capture.md
├── phase-0.5-reuse-analysis.md
├── ...
```

**cybersec 做法**：每个 reference 是独立 skill 目录（含 SKILL.md + scripts/ + assets/）：
```
skills/performing-memory-forensics/
├── SKILL.md
├── scripts/process.py
├── assets/template.md
└── references/standards.md
```

**影响**：coder 的 references 是文档，无 scripts/assets 配套（init-project.py / coder-state.py 等都集中在 `coder/scripts/`，不与 reference 绑定）。

### 差距 5：无框架映射

**当前**：coder 产出无显式映射到软件工程框架。

**cybersec 做法**：6 框架映射，"one skill 6 compliance checkboxes"。

**影响**：用户在合规 / best practice 审计时，需手动对照（如"这个 Phase 是否符合 SOLID？"）。

---

## 3. 优化建议（按优先级）

### 优化 A（v6.3 立即做）：references 加 Token 估算 + Load Priority ⭐⭐⭐

为每个 reference frontmatter 加：
```yaml
tokens_estimate: 1500           # 完整加载成本
load_priority: always|high|on-demand
load_when: "进入 Phase 0 时"
```

SKILL.md §7 加 "Token 预算表"：
```markdown
## references 加载决策（token 经济）

| Reference | Tokens | Priority | When |
|---|---|---|---|
| hard-constraints.md | ~1500 | **always** | 每次 |
| anti-patterns.md | ~2000 | **always** | 每次 |
| v6-execution-protocol.md | ~3000 | high | 第一次 |
| phase-N-*.md | ~1000 each | on-demand | 对应 Phase |

**总预算**：always (~3500) + 当前 Phase (~1500) ≤ 5000 tokens
```

### 优化 B（v6.3 立即做）：references 加 Verification 段 ⭐⭐⭐

每个 phase-N reference 加：
```markdown
## Verification（如何确认本 Phase 成功）

- [ ] spec.md 已生成
- [ ] state.json phases["Phase 0"] = completed
- [ ] user_signed_hash 已记录
- [ ] AskUserQuestion 用户点了"确认"

未达任一项 → 留在本 Phase，不允许进下一个。
```

### 优化 C（v6.3 立即做）：description 改 keyword-rich ⭐⭐

每个 reference 的 description 加 discoverable keyword：
```yaml
# 旧
description: Phase 0 需求确认协议（v6.0 强化版）

# 新
description: Phase 0 multi-turn AskUserQuestion spec.md user signature acceptance checklist phase selection budget v6.0 strengthened orchestrator intent capture
```

### 优化 D（v6.4 候选）：references 加框架映射 ⭐⭐

给 coder reference 加软件工程框架映射：
```yaml
frameworks:
  solid: [SRP, OCP]              # 本 Phase 验证 SOLID 哪几条
  twelve_factor: [III, IV]       # 本 Phase 验证 12-Factor 哪几条
  owasp_top_10: []               # 本 Phase 检查 OWASP（Phase 5 security-reviewer 才有）
  test_pyramid: [unit, property] # 本 Phase 测试金字塔层级
```

### 优化 E（v7.0 候选，大重构）：references → skill 形态 ⭐

把 `coder/references/*.md` 重构为 `coder/skills/{name}/SKILL.md`：
```
coder/skills/
├── phase-0-intent-capture/
│   ├── SKILL.md
│   ├── scripts/
│   │   └── gen-spec.py
│   └── assets/
│       └── spec-template.md
├── phase-0.6-bug-diagnosis/
│   ├── SKILL.md
│   └── scripts/
│       └── build-feedback-loop.py
```

**收益**：脚本与文档绑定 / 一个目录一个完整能力 / 可独立分发包

**代价**：所有 init / state / delivery 脚本重新组织 / 引用路径全改

---

## 4. v6.3 实现路线

### v6.3-1（task 56）：references 加 tokens_estimate + load_priority

修改 `coder/references/*.md` 的 frontmatter（21 个文件）：
```yaml
tokens_estimate: <数字>
load_priority: <always|high|on-demand>
load_when: "<何时加载>"
```

### v6.3-2（task 57）：references 加 Verification 段

修改 `coder/references/phase-*.md`（11 个 Phase reference）：
- 每个 Phase 末尾加 `## Verification` 段
- 列可观察的成功条件

### v6.3-3（task 58）：description 改 keyword-rich

修改 `coder/references/*.md` 的 description 字段：
- 加 discoverable keyword
- 保持中文描述（双语 keyword）

### v6.3-4（task 59）：SKILL.md §7 加 token 预算表

修改 `coder/SKILL.md` §7：
- 把 references 索引改成 Token 预算表
- 标 always / high / on-demand
- 总预算 ≤ 5000 tokens 承诺

### v6.3-5（task 60）：core references 加 frameworks 字段

`hard-constraints.md` / `test-strategy.md` / `phase-5-verification.md` 加框架映射。

---

## 5. 关键差异对照

| 维度 | Anthropic Cybersec | coder v6.x | v6.3 优化 |
|---|---|---|---|
| Token 经济 | 显式（30/500-2000） | 隐式 | ✅ tokens_estimate |
| Progressive disclosure | 4 步（scan/load/execute/verify） | 3 步（load/execute） | ✅ 加 Verification |
| Skill 形态 | 独立目录 + scripts/assets | 文档 + 集中 scripts/ | ⏳ v7.0 |
| Frontmatter keyword | keyword-rich | 简单描述 | ✅ 改 keyword-rich |
| 框架映射 | 6 框架 | 无 | ⏳ v6.4 |
| 一次扫描 | 817 skills × 30 tokens | 20 references × ~100 tokens | ✅ 总成本更低 |

---

## 6. 总结

**Anthropic Cybersecurity Skills 的核心启发**：**token 是显式资源**，每个 skill 必须声明成本，agent 按预算加载。

**coder v6.x 借鉴**：
1. **token 经济显式化**（v6.3 优化 A）：references 加 tokens_estimate
2. **Verification 段标准化**（v6.3 优化 B）：每个 Phase 加"如何确认成功"
3. **description keyword-rich**（v6.3 优化 C）：可发现性提升
4. **SKILL.md token 预算表**（v6.3 优化 D）：orchestrator 按表加载
5. **框架映射**（v6.4 优化 D）：软件工程框架对照
6. **skill 形态重构**（v7.0 优化 E）：长期演进

**核心原则**：从"文档驱动的 progressive disclosure"升级为"token 经济驱动的 progressive disclosure"。

---

## 引用

- [mukul975/Anthropic-Cybersecurity-Skills (GitHub)](https://github.com/mukul975/Anthropic-Cybersecurity-Skills)
- [Anthropic Cybersecurity Skills — AI Agents on GitHub](https://skillsllm.com/skill/anthropic-cybersecurity-skills)
- [agentskills.io standard](https://agentskills.io)
- [Privacy & Data Protection Skills (相关 repo)](https://github.com/mukul975/privacy-data-protection-skills)
