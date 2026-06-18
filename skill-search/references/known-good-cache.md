# 本地高质量 Skill 缓存

借鉴 vercel-labs/skills `find-skills` P1（Leaderboard 优先 → CLI 兜底）。

避免每次都做昂贵的全量 GitHub 搜索；先查本地缓存命中即推荐。

## 缓存桶

| 桶 | 来源 | 数量 | 可信度 |
|---|---|---|---|
| **私有库** | `{SKILL_LIBRARY_ROOT}/` | TBD | 最高（用户自维护） |
| **历史评估** | `{SKILL_LIBRARY_ROOT}/skill-search/data/**/*.md` | 累积 | 高（已通过四维质量门） |
| **Anthropic 官方** | anthropics/skills | TBD | 最高（官方源） |
| **Vercel Labs** | vercel-labs/skills | TBD | 高（知名组织） |
| **Matt Pocock** | mattpocock/skills | 12 个 | 高（104k stars 作者） |
| **公共排行榜** | skills.sh / skillsmp.com | 35K+ | 中（混合质量） |

`SKILL_LIBRARY_ROOT` 默认 `~/.claude/skills`（见 SKILL.md 变量定义）。各桶数量为参考，实际以 glob 结果为准。

## 查询优先级（Leaderboard 优先 → 全量兜底）

```
1. 本地 glob + grep
   glob("{SKILL_LIBRARY_ROOT}/*/SKILL.md") + grep("{功能词}", ...)
   → 命中：直接进 P4 深读，跳过 P2/P3

2. skill-search/data/ 历史档案
   glob("{SKILL_LIBRARY_ROOT}/skill-search/data/**/*.md") + grep("{功能词}", ...)
   → 命中：用历史评分 + 标注"已评估 YYYY-MM-DD"

3. 排行榜检索
   mcp__searxng__searxng_web_search("site:skills.sh {功能词}")
   mcp__searxng__searxng_web_search("site:skillsmp.com {功能词}")
   → 命中：候选加入 P2 列表，仍需走四维质量门

4. 全量 GitHub 搜索（最后兜底）
   mcp__github__search_repositories(...)
```

## 缓存查询协议

每次 skill-search 触发，**强制执行缓存查询**（即使没命中也要记录）：

```python
# 伪代码
cache_query_log = {
    "private_lib": glob("{SKILL_LIBRARY_ROOT}/*/SKILL.md"),
    "history": glob("skill-search/data/**/*.md"),
    "leaderboard": searxng_search("site:skills.sh ..."),
    "github_full": None  # 仅在 1-3 都未命中时执行
}
# P6 报告标注每层命中数
```

## 缓存命中率统计

P6 透明度声明加入：

```
缓存命中：
- 私有库：0 命中 / 34 总
- 历史档案：0 命中 / X 总
- 排行榜：3 命中 / 10 候选
- 全量 GitHub：7 命中 / 15 候选（兜底）

Leaderboard 优先策略节省 ~40% GitHub API 调用
```

## 缓存维护

每次评估完一个新候选：
1. 自动加入 `skill-search/data/` 历史档案（已实现）
2. 若是高质量（四维质量门全 ✓），考虑加入私有库
3. 每月一次清理：>12 个月未访问的历史档案归档

## 与四维质量门的关系

缓存命中 ≠ 自动推荐。即使是私有库的 skill，也要走四维质量门验证（特别是维护活跃度）。
缓存的价值是**跳过 P2 发现 + P3 粗筛**，直接进 P4 深读。
