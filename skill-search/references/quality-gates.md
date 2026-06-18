# 四维质量门（Quality Gates）

借鉴 vercel-labs/skills `find-skills` Step 4（原文加粗：**Do not recommend a skill based solely on search results**）。

## 核心原则

**单源不可推荐**：候选必须通过至少 2 个质量门才能进入 P4 深读。仅通过 1 个的进入"待观察"，全不通过的拒绝。

## 四维硬阈值表

| 维度 | 推荐阈值 (✓) | 警告阈值 (⚠) | 拒绝阈值 (✗) | 数据源 |
|---|---|---|---|---|
| **Install count** | ≥1K | 100-999 | <100（新仓库 < 6 个月豁免） | skills.sh / skillsmp.com / plugin marketplace |
| **Source reputation** | 官方源（anthropics/vercel-labs/microsoft/知名组织） | 个人作者但活跃 | 匿名/不可追溯/无 README | GitHub owner type + README 完整度 |
| **GitHub stars** | ≥100 | 10-99 | <10（新仓库 < 6 个月豁免） | `mcp__github__search_repositories` |
| **维护活跃度** | 6 个月内有 commit + 有 release | 6-12 个月无 commit | >12 个月僵尸 | `mcp__github__list_commits` + `list_releases` |

## 评分聚合

每个候选在 P3 阶段输出一个 4 位 signature：

```
signature = "✓✓⚠✗"  # install=✓ source=✓ stars=⚠ activity=✗
gate_status = "通过" if signature.count("✓") >= 2 else "待观察/拒绝"
```

## 新仓库豁免（避免马太效应）

skills.sh 单用 install count 导致 vercel-labs/agent-skills 永久霸榜（**Trap1**）。本框架对新仓库（created_at < 6 个月）豁免 install/stars 阈值，但**强制**：
- Source reputation 必须 ✓ 或 ⚠（拒绝匿名）
- 维护活跃度必须 ✓（最近 30 天内有 commit）

## 数据采集协议（强制使用 git mcp）

P3 阶段对每个候选执行：

```
mcp__github__search_repositories(query="repo:{owner}/{name}")  # stars/forks/created_at/updated_at
mcp__github__list_commits(owner, repo, perPage=5)              # 最近 commit 时间 + message 质量
mcp__github__list_releases(owner, repo, perPage=3)             # 最新 release 时间 + 版本管理
mcp__github__list_tags(owner, repo, perPage=5)                 # 版本 tag 数量
```

**禁止**用 `get_file_contents` 拿这些数据（GitHub MCP 在 Claude Code 中只返回 SHA）。

## "为什么推荐这个"字段（可审计，避免 Trap2）

P6 报告每个候选必须含：

```markdown
### 推荐理由（可审计）
- 命中质量门：✓ install(2.3K) / ✓ source(anthropics) / ⚠ stars(87) / ✓ activity(最近 commit 2026-06-15)
- 命中 trigger：用户输入"找 X skill" → match description 关键词 "X"
- 排除项：未命中第 5 个候选因为 activity ✗（>12 个月僵尸）
```

无此字段的候选不可进入最终推荐列表。

## 与 evaluation-rubric.md 的关系

四维质量门 = **P3 粗筛的硬门槛**（gate，二值通过/拒绝）。
D1-D8 评分 = **P4 深读的启发式信号**（score，1-5 分）。

两者用途不同：质量门用于过滤（不通过的进不了 P4），D1-D8 用于排序（通过的横向对比）。
