# Superpowers插件深度调研：优缺点、局限性与替代方案

> 调研日期: 2026-05-31 | 来源: 4篇评测文章 + 10条Reddit帖子 + GitHub Issues(146个) + 5个竞品方案

**仓库数据**: obra/superpowers — Stars 213K / Forks 19K / Issues 146 / PRs 145
**竞品**: affaan-m/ECC — Stars 189K / Skills 156 / Agents 38 / Commands 72 (v1.10.0)

## 一、Superpowers是什么

**仓库**: `obra/superpowers`（作者Jesse Vincent）| Stars: 150K+ | Forks: 15.7K
**本质**: Claude Code的**工作流纪律插件**，不是模型编排工具。通过7阶段流水线（头脑风暴→Spec→Plan→TDD→Sub-agent开发→代码审查→分支完成）强制执行结构化开发流程。

## 二、核心能力评估

### 能做的 ✅

| 能力 | 效果 | 数据来源 |
|------|------|---------|
| 强制TDD工作流 | 87%测试覆盖率（Builder.io案例） | ✅ 实测 |
| 防止方向性错误 | 规划阶段捕获架构决策问题 | ✅ Builder.io |
| 大型任务token优化 | 复杂任务40-60%节约 | ✅ MindStudio |
| 支持多平台 | Claude Code/Cursor/Gemini CLI/Codex/OpenCode | ✅ 官方 |
| 长时间自主会话 | 2小时无偏离是常态 | ✅ Builder.io |

### 不能做的 ❌

| 局限 | 影响 | 证据 |
|------|------|------|
| **不支持multi-model routing** | 所有sub-agent用同一模型 | ✅ 3个独立来源确认 |
| 小任务token反而增加 | 规划开销10-30%超过执行成本 | ✅ Reddit多帖+MindStudio |
| 无法处理环境调试 | macOS/Linux差异、Docker网络问题 | ✅ Builder.io |
| 规划继承spec错误 | 垃圾进垃圾出 | ✅ Builder.io |
| 与其他插件不自动协作 | 需手动配置CLAUDE.md | ✅ OpenSpec+Superpowers报告 |

## 三、用户真实评价（Reddit）

### 负面评价（高频）

| 帖子 | 核心观点 |
|------|---------|
| "superpowers plugin is absolute garbage" | 写plan → 执行很差 → 得到barely works的代码。内置plan mode对小任务更好 |
| "Anyone else not a fan" | 紧凑的CLAUDE.md + 显式约束 > 大多数插件。加入Superpowers后Claude反而限制自己 |
| "Has anyone actually benchmarked" | 实验Superpowers和GSD后，发现结果反而**更差** |
| "Superpowers suddenly changed behaviour" | 行为不稳定，同样prompt不同结果 |
| "$100 plan lasts less than 30 min" | Superpowers加剧token消耗问题 |

### 正面评价

| 帖子 | 核心观点 |
|------|---------|
| "actually delivers" | 对大型多文件项目效果显著 |
| Builder.io深度测评 | Ding项目（Go语言）"比任何agent构建的都干净" |
| Medium 150K stars | 45-60分钟构建Notion克隆，87%覆盖率，零手动代码 |

### 双峰分布

```
复杂任务（>5文件）：  40-60% token节约 ✅
简单任务（<3文件）：  10-30% token增加 ❌
紧急hotfix：         规划阶段太慢 ❌
环境调试：           完全不在workflow内 ❌
```

## 四、对model路由问题的直接回答

**Superpowers完全不解决model路由问题。** 它的"多代理"是功能分工（基础设施/UI/业务逻辑/测试），不是模型分层（haiku/sonnet/opus）。

所有sub-agent默认使用同一Claude模型，无法指定不同模型。插件层面没有model选择的DSL或配置项。

## 五、更好的替代方案

### 5.1 MindStudio Smart Orchestrator（最接近需求）

**方案**: Opus做编排器 + Haiku/DeepSeek做执行者

| 维度 | 说明 |
|------|------|
| model路由 | ✅ 显式SDK控制，Task级别指定不同模型 |
| token优化 | 理论80-90% token转移到廉价模型，5-10x成本降低 |
| 架构 | Orchestrator(Opus)→规划/审查/决策；Workers(Haiku)→执行 |
| 局限 | 需要MindStudio SDK，不是纯Claude Code方案 |
| 来源 | [MindStudio博客](https://www.mindstudio.ai/blog/smart-orchestrator-cheaper-sub-agent-models-claude-code/) |

**与我们R5.1的对比**：架构完全一致。Opus=opus, Haiku=haiku, Sonnet=sonnet。但MindStudio需要外部SDK。

### 5.2 自定义 `.claude/agents/` 文件（当前最佳实操方案）

**方案**: 在项目或用户级agents目录创建带model锁定frontmatter的subagent定义

```yaml
# .claude/agents/researcher.md
---
model: haiku
tools: [Read, Grep, Glob, WebSearch]
---
你是快速搜索agent，只负责定位代码和文件...
```

| 维度 | 说明 |
|------|------|
| model路由 | ✅ frontmatter中锁定model |
| 可行性 | 立即可用，无需外部依赖 |
| 局限 | 每个agent需单独定义文件；无法在运行时动态切换model |
| 证据 | Anthropic官方文档确认frontmatter model字段正常工作 |

### 5.3 Claude Code Agent Teams（内置实验功能）

**启用**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

| 维度 | 说明 |
|------|------|
| model路由 | ❌ 未提及per-agent model选择 |
| token优化 | ❌ 反而增加成本（独立实例） |
| 适用 | 95%日常任务不需要，仅大型项目 |
| 来源 | [Shipyard博客](https://shipyard.build/blog/claude-code-multi-agent/) |

### 5.4 claude-team-orchestration（zircote）

**仓库**: `zircote/claude-team-orchestration`

| 维度 | 说明 |
|------|------|
| 编排模式 | 7种（并行专家/管道/群集/研究+实现/计划审批/重构/RLM） |
| model路由 | 中等支持，可选不同plugin agents但model控制不明确 |
| 特色 | RLM模式处理超大文件（突破context限制） |
| 来源 | [GitHub](https://github.com/zircote/claude-team-orchestration) |

### 5.5 Agent Runway

**定位**: 阻止sub-agent制造技术债务的插件
**局限**: 专注于质量管控，不涉及model路由

## 六、方案对比总结

| 方案 | model路由 | token优化 | 实施成本 | 适合books_creater |
|------|----------|----------|---------|------------------|
| **Superpowers** | ❌ | 小任务反增 | 低（插件安装） | ❌ 不解决核心问题 |
| **MindStudio** | ✅ 强 | ✅ 5-10x | 中（需SDK） | ⚠️ 架构契合但需迁移 |
| **自定义agents/** | ✅ | ✅ 显式分层 | 低（30min/个） | ✅ **最佳实操方案** |
| **Agent Teams** | ❌ | ❌ 反增 | 低（环境变量） | ❌ 过度 |
| **team-orchestration** | ⚠️ | 中 | 中 | ⚠️ 可参考模式 |
| **Agent Runway** | ❌ | — | 低 | ❌ 不相关 |

## 七、结论与建议

**对books_creater项目**：

1. **不推荐引入Superpowers**。它解决的是"AI写代码不靠谱"的纪律问题，不是我们面临的"sub-agent model参数被剥离"的技术问题。

2. **当前最佳路径仍然是自定义 `.claude/agents/`**。这是唯一立即可用、无需外部依赖、且能锁定model的方案。MindStudio的架构验证了我们R5.1的haiku/sonnet/opus分层是正确的。

3. **长期观察Agent Teams**。Claude Code内置的多Agent功能在进化中，未来可能原生支持per-agent model选择。

4. **竞品值得参考的模式**：
   - claude-team-orchestration的7种编排模式（特别是RLM超大文件处理）
   - MindStudio的Opus编排+Haiku执行的两层架构验证

## 八、GitHub Issues深度分析

### Superpowers高频Issue（146个中抽样）

| Issue | 标题 | 类型 | 严重度 |
|-------|------|------|--------|
| #1648 (2026-05-29) | Consumes too much tokens while planning | bug | 🔴 高 |
| #743 (2026-03-15) | Slowness in responses since using the skill | bug | 🔴 高 |
| #385 | SessionStart hook matcher包含'compact'导致无限循环 | bug | 🔴 严重 |
| #1042 | writing-plans连续Write工具调用失败 | bug | 🟡 中 |
| #1100 | brainstorming输出折叠为"Worked for..." | bug | 🟡 中 |
| #1642 (2026-05-28) | Multi-agent parallel code review + adaptive batched questioning | 增强 | — |
| #234 | install失败(getaddrinfo thread failed) | 安装 | 🟡 中 |

**Issue #1642特别值得关注**：社区提议"6个并行Sonnet agent审查 + Haiku评分(≥80分才展示)"，说明社区已意识到model分层的重要性。但这个Issue是功能请求，尚未实现。

### ECC高频Issue（v1.10.0发布混乱）

| 问题 | 说明 |
|------|------|
| npm未发布 | GitHub v1.10.0已创建但npm停在1.9.0 |
| 插件名称变更 | ecc@ecc → everything-claude-code，导致用户混淆 |
| Token消耗 | 用户报告安装后token消耗明显加快 |
| 快速修复 | 2周内10+ PR合并（#1439/#1445/#1446/#1449等） |
| Hook兼容性 | Claude Code v2.1.x hook schema break需修复 |

### 维护态度对比

| 项目 | 风格 | 响应速度 |
|------|------|---------|
| Superpowers (Jesse Vincent) | 谨慎，要求repro case，拒绝AI slop gate | 中等 |
| ECC (Affaan Mustafa) | 激进迭代，大量PR快速合并 | 快但发布流程有瑕疵 |

### Issue趋势（2026年3-5月）

- Superpowers：Token/性能问题占比最高（约40%），社区活跃但功能增强讨论多于bug修复
- ECC：v1.10.0发布期间暴露大量安装问题，快速修复中
- 两个项目都面临用户质疑token消耗，均无完美解决方案

## 九、最终判断

### Superpowers对books_creater的价值：**不推荐**

| 判断维度 | 评分 | 理由 |
|---------|------|------|
| 解决model路由 | 0/10 | 完全不支持，不解决核心问题 |
| Token效率 | 3/10 | 复杂任务节约但小任务反增，且我们的skill系统已有自己的context管理 |
| 工作流纪律 | 7/10 | 7阶段流水线有借鉴价值，但我们已有6个skill + 编排器 |
| 安装稳定性 | 4/10 | 安装问题频发，hook无限循环风险 |
| 维护质量 | 6/10 | 谨慎但响应中等 |

### 推荐路径不变：自定义 `.claude/agents/` 文件

Superpowers/ECC/Agent Teams都不能解决我们的核心问题（Agent工具model参数被schema剥离）。**唯一立即可用的方案仍然是在`.claude/agents/`目录创建带frontmatter model锁定的自定义subagent定义文件**。
