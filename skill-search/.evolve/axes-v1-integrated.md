# Phase 1 Axes v1.integrated — 整合 researcher 借鉴发现

## 借鉴发现 → 新增 Axis

| 新 Axis | 借鉴源 | 优先级 |
|---|---|---|
| Axis 11: 本地高质量 skill 缓存（Leaderboard 优先 → 全量兜底） | vercel find-skills P1 | P1 |
| Axis 12: 显式四维质量门硬阈值（install/source/stars/activity），单源不可推荐 | vercel find-skills P2 | P0 |
| Axis 13: 触发词矩阵扩展（6 类显式+隐式） | vercel find-skills P4 | P2 |
| Axis 14: 评分谦逊化 — 不假装绝对评分，输出"候选+来源+数据"（弱化分数，强化可审计） | SkillsMP P5 + coding-rules R12 | P1 |

## 对已有 Axis 的修正

### Axis 1 (Rubric) — 修正
**原计划**：严格用 D1-D8 40 分制
**修正后**（注入 Axis 14）：保留 D1-D8 作为**信号之一**，但报告核心改为"候选清单 + 每条来源链接 + install/stars/维护时间 + 命中的 trigger/质量门"，分数降为辅助参考。理由：SkillsMP 明确放弃自动评分，vercel find-skills 也是"四维质量门"而非综合分数。

### Axis 2 (主语言优先) — 增强（注入 P3）
**原计划**：P1 检测主语言 → P2/P5 按主语言调整
**增强后**：主语言 + 任务域 + agent 平台 三维过滤。韩文仓库 → Naver/Tistory/Namuwiki；日文 → Qiita/Zenn；中文 → 知乎/V2EX/掘金；英文 → Reddit/HN/Medium。中文 trigger 与英文 trigger 等价（不歧视）。

### Axis 7 (git mcp) — 增强（注入 P2 维护活跃度）
**新增**：`list_releases` + `list_commits` 不只是"用不用"，而是作为四维质量门中"维护活跃度"的**强制证据**。最近 commit > 6 个月 → 警告标记。

### Axis 5 (raw/) — 扩展
**原计划**：保存子 agent 原始输出
**扩展后**：保存所有 MCP 调用的原始返回（包括 list_issues、search_repositories 等），命名 `raw/mcp-{tool}-{timestamp}.json`，便于事后审计。

---

## 最终 14 个 Axes（按优先级）

### P0 必修（合规性 + 核心方法论）

| Axis | 描述 | 补丁目标 |
|---|---|---|
| **3** | references/ 强制深读至少 2 个（被 SKILL.md 反复引用的优先） | execution-gates.md P4 Exit |
| **5** | raw/ 强制保存所有 MCP 调用原始返回（扩展） | execution-gates.md P6 Exit |
| **12** | 显式四维质量门硬阈值（install/source/stars/activity），单源不可推荐 | 新增 references/quality-gates.md |
| **14** | 评分谦逊化 — D1-D8 作为信号之一，核心输出"候选+来源+数据" | SKILL.md P4/P6 + evaluation-rubric.md |

### P1 应修（用户明确方向 + 借鉴精华）

| Axis | 描述 | 补丁目标 |
|---|---|---|
| **2** | 主语言优先 + 三维过滤（语言/任务域/平台） | 新增 references/language-strategy.md |
| **4** | examples/test-prompts 必检查 | execution-gates.md P4 Exit |
| **6** | MCP 调用统计进透明度声明 | execution-gates.md P6 Exit |
| **7** | git mcp 加 list_releases + list_commits + list_tags + search_code | search-templates.md Scout-GH |
| **8** | searxng mcp 主力化（替代部分 agent spawn） | search-templates.md Scout-Community |
| **10** | 单仓库评估正式分支 E1 | SKILL.md + execution-gates.md |
| **11** | 本地高质量 skill 缓存（Leaderboard 优先） | 新增 references/known-good-cache.md |

### P2 优化

| Axis | 描述 | 补丁目标 |
|---|---|---|
| **9** | token 节省（长文档 ctx_index + ctx_search） | search-templates.md |
| **13** | 触发词矩阵扩展为 6 类（显式+隐式能力缺口） | SKILL.md description |

---

## Patch 计划（surgical，不重写）

### 改动文件

| 文件 | 改动类型 | 内容 |
|---|---|---|
| `SKILL.md` | Edit（多处 surgical） | 加 E1 模式 / 主语言检测 / 四维质量门指针 / MCP 统计 |
| `references/execution-gates.md` | Edit（多处 surgical） | 加 P4 references/examples 检查 / P6 raw+MCP 统计 / 新增 E1 Exit |
| `references/search-templates.md` | Edit（多处 surgical） | 加 git mcp 4 调用 / searxng 主力化 / token 策略 |
| `references/evaluation-rubric.md` | Edit | 加"评分谦逊化"声明，D1-D8 降为信号之一 |
| `references/quality-gates.md` | **新增** | 四维质量门硬阈值表 |
| `references/language-strategy.md` | **新增** | 主语言检测 + 三维过滤 + 各语言社区源 |
| `references/known-good-cache.md` | **新增** | 本地高质量 skill 缓存清单 |

### 验证

用 revfactory/harness 这次的场景重跑（Before 已存 `.evolve/snapshots/`），对比：
- 评分是否合规（D1-D8 + 谦逊化声明）
- references/ 是否深读至少 2 个
- raw/ 是否保存
- MCP 调用统计是否完整
- 主语言策略是否生效（韩文 → Naver/Tistory）
- 四维质量门是否落地

---

## Phase 1 → Phase 3 Patch 决策

按 skill-evolver Algorithm 1，r=1 是 surgical patch。本次 patch 涉及 4 个文件 edit + 3 个文件新增，**改动量适中**，不算 rewrite（核心流程 P1→P6 不变，只是补强）。

按 SKILL.md 要求 AskUserQuestion 等用户确认再进入 Phase 3。
