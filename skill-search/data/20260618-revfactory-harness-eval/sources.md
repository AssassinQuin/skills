# 搜索与执行记录 — revfactory/harness 评估

## 评估模式
**单仓库深度评估**（用户指定 URL，跳过 P2 多源搜索 + P3 粗筛）

## 数据采集记录

### Phase A: 仓库元数据（GitHub API）
- 查询：`mcp__github__search_repositories(query="repo:revfactory/harness")`
- 结果：1 命中，stars 7056 / forks 969 / open_issues 20 / created 2026-03-26
- 主语言：HTML（因 index.html landing page）
- 默认分支：main
- License：Apache 2.0

### Phase B: 目录结构（zread）
- 调用：`mcp__zread__get_repo_structure(repo_name="revfactory/harness")`
- 关键发现：**多 Skill 仓库**结构
  - `skills/harness/SKILL.md`（不在根目录）
  - `skills/harness/references/`（6 个文件）
  - `_workspace/`（4 个 audit/launch/scout/strategist 样例）
  - `docs/quickstart.md` + `docs/experimental-dependency.md`

### Phase C: Issues（GitHub API）
- Open issues（实际 issue 数 3，issues_count 20 包含 PR）：
  - #29 feat: per-task model tiering（反对强制 opus）
  - #28 feat: 更广泛的语言支持
  - #26 feat: Mermaid 架构图导出
- Closed issues（共 7 条，重点）：
  - #20 bug: marketplace 安装失败
  - #18 question: model tiering 策略（韩文）
  - #8 proposal: 韩国 persona 数据集扩展
  - #7 feat: owner.email 缺失
  - #4 bug: orchestrator rerun 路径漏洞
  - #3 question: Gemini 适配性
  - #2 通知：被 Awesome Claude Code 收录

### Phase D: 核心文件深读（zread）
读取文件：
- `skills/harness/SKILL.md`（~580 行，韩文为主 + 部分英文术语）
- `README.md`（英文，三语链接）
- `skills/harness/references/` 目录（6 文件：agent-design-patterns / orchestrator-template / team-examples / skill-writing-guide / skill-testing-guide / qa-agent-guide）

### Phase E: 社区口碑（并行子 Agent）

**子 Agent 1: 英文社区**（sonnet, general-purpose）
- 搜索范围：Reddit / HN / Medium / Dev.to / X / YouTube
- 关键查询：
  - `revfactory harness site:reddit.com`
  - `"revfactory/harness"` site:news.ycombinator.com
  - HN Algolia 全文 + comment 搜索
- 结果：**0 条独立英文评测**
- 被动收录 5 条（DEV.to 教程 / Medium 标题党 / Trending 榜 / 2 个 Awesome 列表）

**子 Agent 2: 中文社区**（sonnet, general-purpose）
- 搜索范围：知乎 / V2EX / 掘金 / CSDN / 微博 / 即刻 / 小红书 / B 站
- 关键查询：
  - `revfactory harness site:zhihu.com`
  - `revfactory harness site:v2ex.com`
  - `"build a harness for this project"` 中文
- 结果：**0 条中文讨论**
- 名字冲突：中文 "harness" 内容 99% 指 OpenAI 的 Harness Engineering 范式（无关）

## 评分依据（evaluation-rubric）

| 维度 | 分数 | 主要证据 |
|---|---|---|
| 内容深度 | 9.0 | SKILL.md 580 行 + 6 references + 7-Phase 闭环 + QA agent 独立 guide |
| 触发器质量 | 6.5 | description 韩文，英文触发词仅在 README，命中率打折 |
| 文档完整度 | 9.0 | 三语 README + use cases + A/B 数据 + coexistence 矩阵 + FAQ |
| 社区活跃度 | 7.0 | 7k stars 但 0 独立评测；issue 回复周期 1-2 周 |
| 维护性 | 6.0 | 单作者（Hwang, M.），3 个月 7 closed / 3 open |
| 可移植性 | 4.5 | 实验 Agent Teams + 强制 opus + 韩文 SKILL + Claude Code 原生 |
| 实际效果 | 7.5 | 作者自测 +60%（n=15）；harness-100 生产样例 |
| 创新性 | 8.5 | L3 Meta-Factory 子层定位清晰，6 架构模式系统化 |

## 与用户已有 skills 的能力对比

| 能力 | 用户已有 | harness 提供 | 重叠度 |
|---|---|---|---|
| 单 skill 创建 | skill-creator | Phase 4 skill 生成 | 高 |
| 人物视角 skill | huashu-nuwa | 无（不做人设） | 低 |
| skill 优化 | darwin-skill / skill-evolver | 无 | 无 |
| 执行期管理 | planning-with-files | _workspace/ + Phase 0 上下文确认 | 中 |
| agent 团队设计 | 无（依赖全局 agents/） | 6 架构模式 + orchestrator | **用户缺口** |
| QA agent 模式 | code-review / fin-code-review | incremental + 边界交叉 | 中 |

**结论**：harness 在"**agent 团队架构设计**"维度填补用户空白，但其强制 opus + 韩文 + 实验 Teams 的代价不值得全量引入。

## 关键文件路径（备查）
- SKILL.md：https://github.com/revfactory/harness/blob/main/skills/harness/SKILL.md
- agent-design-patterns：https://github.com/revfactory/harness/blob/main/skills/harness/references/agent-design-patterns.md
- orchestrator-template：https://github.com/revfactory/harness/blob/main/skills/harness/references/orchestrator-template.md
- harness-100（生产样例）：https://github.com/revfactory/harness-100
- A/B 实验仓库：https://github.com/revfactory/claude-code-harness
