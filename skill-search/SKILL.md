---
name: skill-search
version: "5.2"
description: >
  Skill 搜索与评估元 skill（编排 + 综合 + 路由）。按评估模式路由到 3 个垂直子 agent：
  single-repo-evaluator（E1 单仓库）/ multi-source-discoverer（多源发现 + 粗筛）/
  skill-class-evaluator（按 skill 类型差异化评估）。


  显式 trigger：找 skill、搜索 skill、skill 推荐、skill 选型、find skill、recommend skill、
  skill comparison、有什么好的 X skill、哪个 skill 好。
  隐式 trigger：how do I do X / is there a skill that can X / "扩展能力" / "wish I had
  help with X domain"。
  与 web-research 互不重叠（v5.2 显式）：本 skill 专注评估具体 skill 仓库（GitHub repo）；
  调研主题/技术/产品/政策用 web-research。
  DO：四维质量门 + D1-D8 启发式信号 + 主语言三层降级 + 评分谦逊化。
  DON'T：单一信息源 / 跳过本地优先 / 混淆 SEO 内容农场。
  Output: {skill_dir}/data/{date}-{slug}/
user-invocable: true
skill_type: research
allowed-tools:
  - mcp__github__search_repositories
  - mcp__github__search_code
  - mcp__github__get_file_contents
  - mcp__github__get_repo_structure
  - mcp__github__list_issues
  - mcp__github__list_commits
  - mcp__github__list_releases
  - mcp__github__list_tags
  - mcp__searxng__searxng_web_search
  - mcp__searxng__web_url_read
  - mcp__searxng__searxng_search_suggestions
  - mcp__web-search-prime__web_search_prime
  - mcp__web-reader__webReader
  - mcp__zread__get_repo_structure
  - mcp__zread__read_file
  - mcp__plugin_context-mode_context-mode__ctx_batch_execute
  - mcp__plugin_context-mode_context-mode__ctx_search
  - mcp__plugin_context-mode_context-mode__ctx_index
  - mcp__plugin_context-mode_context-mode__ctx_execute_file
  - Agent
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - WebSearch
  - WebFetch
---

# Skill Search — 搜索·筛选·评估·推荐元 skill

**架构**（v5.2 重构，类似 revfactory/harness + web-research v2.3 + coder v3.2）：本 skill 是**编排者**，按评估模式分发到垂直子 agent。

```
用户请求 → Phase 0 缓存查询
        → Phase 1 意图分类 + 路由
        → Phase 2 分发到垂直 agent
        → Phase 3 综合报告（评分谦逊化 + 双模式输出）
```

**MANDATORY**：每个发现必须可追溯真实来源（URL + 工具 + Query）。不假装绝对评分。

---

## 核心原则

1. **不假装绝对评分** — D1-D8 是启发式信号，不是绝对真理（详见 [evaluation-rubric.md](references/evaluation-rubric.md) 谦逊化声明）
2. **可追溯证据** — 候选 + 来源链接 + 四维质量门数据 + 命中 trigger
3. **本地优先** — P0 缓存查询（私有库 → 历史 → 排行榜 → 全量 GitHub）
4. **主语言优先** — P1 检测主语言 → P5 三层降级（主语言 → 英文 → 中文）
5. **不单一信息源** — 每条结论 ≥ 2 独立源 + 源质量 S/A/B/C/D 分级

---

## Phase 0: 缓存查询（强制 4 层）

```
1. 私有库: glob("{SKILL_LIBRARY_ROOT}/*/SKILL.md") + grep
2. 历史档案: glob("{SKILL_LIBRARY_ROOT}/skill-search/data/**/*.md") + grep
3. 排行榜: searxng_web_search("site:skills.sh ...") + searxng_web_search("site:skillsmp.com ...")
4. 全量 GitHub（兜底）
```

缓存命中 → 跳过 P1/P2，直接进 P3 综合。详见 [known-good-cache.md](references/known-good-cache.md)。

`SKILL_LIBRARY_ROOT` 默认 `~/.claude/skills`（用户私有库）。

---

## Phase 1: 意图分类 + 路由

按用户输入判定评估模式：

| 用户输入信号 | 路由到 |
|------------|--------|
| 具体 GitHub URL（如 `github.com/owner/repo`）或 `repo:owner/name` | → [`agents/single-repo-evaluator.md`](agents/single-repo-evaluator.md)（E1 模式）|
| 功能需求（"找 code review 的 skill"）需多源发现 | → [`agents/multi-source-discoverer.md`](agents/multi-source-discoverer.md) |
| 已知 skill 但需按类型差异化评估 | → [`agents/skill-class-evaluator.md`](agents/skill-class-evaluator.md) |
| 混合（多候选对比）| 多 agent 并行 + orchestrator 综合 |

**意图不清** → AskUserQuestion（≤ 2 次）：评估目的？输出形态（决策报告/知识地图）？范围限定？

---

## Phase 2: 分发到垂直 agent

按 Phase 1 路由 spawn 对应 agent（model=sonnet）。

**子 agent 契约**：
- 评估协议（步骤明确）
- 工具调用清单（含 git mcp 4 调用 + searxng + zread）
- 多语言搜索策略（按主语言三层降级）
- 多源验证标准（≥ 2 独立源 + 源质量分级）
- 输出 schema（JSON）
- 跑偏自查清单

**orchestrator（本 SKILL.md）只做**：路由 + 协调 + 综合。**不重复 agent 内部工作**。

---

## Phase 3: 综合报告（双模式 + 谦逊化）

### 3.0 输出模式选择（已在 Phase 1 澄清）

| 模式 | 内容 |
|------|------|
| **决策报告**（默认）| 推荐选项 + 理由 + 风险 + 证据等级 |
| **知识地图** | 背景 + 候选清单 + 主流方案 + 灵感 + 知识空白 |

### 3.1 综合报告结构

```markdown
## 评估报告

### 路由 agent（v5.2 新增）
- agents/{type}.md → 输出 schema：{摘要}

### 候选清单
- {候选名} | stars N | signature ✓✓⚠✗ | D1-D8 N/40 (grade)
  - 推荐理由（可审计）：命中 trigger X + 质量门 ≥2 维 ✓
  - 证据等级：多源验证 / 权威单源 / 矛盾源 / 知识空白
  - 来源链接：[URL]

### 💡 意外发现（按意外度 × 可验证性 × 行动启示度排序）

### 结论与建议（决策报告模式必含推荐 + 风险）

### 信息源列表（编号 + URL + 源质量 S/A/B/C/D）

### ⚠️ 局限性
- 知识空白 / 单源风险 / 矛盾未解 / 缓存命中率 / 预算超支影响
```

### 3.2 持久化（v5.1 强制结构）

```
{skill_dir}/data/{YYYYMMDD}-{slug}/
├── 评估报告.md
├── 候选-Top5.md
├── 淘汰记录.md
├── sources.md
└── raw/                         # 强制：所有 MCP 调用 + 子 Agent 原始输出
    ├── mcp-github-search-{ts}.json
    ├── mcp-github-list-issues-{ts}.json
    ├── mcp-github-list-commits-{ts}.json
    ├── mcp-zread-skill-md-{ts}.md
    └── scout-{role}-{lang}-{ts}.json
```

下次相似需求先 `glob("{skill_dir}/data/**/*.md")` + grep 查历史档案。

---

## 与其他 skill 的边界（v5.2 显式）

| 用户意图 | 用什么 |
|---------|-------|
| 评估具体 skill 仓库 | **skill-search**（本 skill）|
| 调研主题/技术/产品/政策 | web-research |
| 创建 skill | skill-creator |
| 进化 skill 结构 | skill-evolver |
| 深化 skill 内容 | skill-deepener |
| 蒸馏人物思维 | huashu-nuwa |

---

## 硬约束（v5.1 14 条 + v5.2 修订）

1. **exit-checklist 不可跳过** — 见 [execution-gates.md](references/execution-gates.md)
2. **`search_code` 禁用于 P2 发现** — 只用于验证 SKILL.md 存在
3. **垂直平台优先于 SearXNG** — skillsmp.com / openagentskill.com / skills.sh
4. **P4 必须先检查目录结构** — 不假设 SKILL.md 在根目录
5. **子 Agent 必须指定 model** — sonnet（搜索）/ opus（评估）
6. **P4 文件读取禁用 get_file_contents 读内容** — 用 zread_read_file 或 WebFetch raw URL
7. **本地保存强制 + raw/ 强制** — raw/ 含所有 MCP 调用原始返回
8. **四维质量门 + 单源不可推荐** — P3 输出 signature，至少 2 维 ✓
9. **主语言优先 + 中英补充** — 详见 [language-strategy.md](references/language-strategy.md)
10. **评分谦逊化** — D1-D8 是启发式信号，禁止作为唯一决策依据
11. **git mcp 充分利用** — search_repositories + list_commits + list_releases + list_tags
12. **searxng mcp 主力化** — Scout-Community 主力 searxng_web_search
13. **本地缓存优先** — P0 强制 4 层查询
14. **Token 预算** — 长文档（>300 行 / >2000 字）必须 ctx_index
15. **（v5.2 新增）路由分发** — 按评估模式路由到 agents/{type}.md，元 skill 不重复 agent 内部工作
16. **（v5.2 新增）与 web-research 边界** — 评估 skill 用本 skill，调研主题用 web-research

---

## 相关文件

- 垂直子 agent：[`agents/single-repo-evaluator.md`](agents/single-repo-evaluator.md) / [`agents/multi-source-discoverer.md`](agents/multi-source-discoverer.md) / [`agents/skill-class-evaluator.md`](agents/skill-class-evaluator.md)
- references（被 agents 引用）：
  - [`references/execution-gates.md`](references/execution-gates.md) — Phase exit-checklist
  - [`references/search-templates.md`](references/search-templates.md) — 搜索模板（5 Scout）
  - [`references/evaluation-rubric.md`](references/evaluation-rubric.md) — D1-D8 + 谦逊化
  - [`references/quality-gates.md`](references/quality-gates.md) — 四维质量门
  - [`references/language-strategy.md`](references/language-strategy.md) — 主语言三层降级
  - [`references/known-good-cache.md`](references/known-good-cache.md) — 缓存优先
