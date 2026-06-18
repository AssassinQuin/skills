# Agent: multi-source-discoverer（P2 多源发现 + P3 粗筛）

**触发**：用户给功能需求（如"找 code review 的 skill"），需多源搜索发现候选

**垂直专业**：5 源并行搜索 + 四维质量门粗筛

---

## 5 源并行搜索协议

| Scout | 搜索源 | 核心规则 |
|-------|-------|---------|
| Scout-GH | GitHub | **只用 `search_repositories`**，禁止 `search_code` 做发现 |
| Scout-BuiltIn | 本地 + Marketplace | 三层全执行（本地 ls + marketplaces.json + Web） |
| Scout-Market | 垂直平台 | 直接访问 skillsmp.com / openagentskill.com / skills.sh |
| Scout-Community | 社区 | 中英文分别搜索（按 P1 主语言三层降级） |
| Scout-Expand | 已发现→扩展 | Top 3 候选的关联网络 / fork / credits / topics |

5 个 Scout **并行 spawn**（model=sonnet）。Spawn 失败 → 主 agent 串行执行 + 标 `[L2-FALLBACK]`。

详见 [search-templates.md](../references/search-templates.md)。

---

## 缓存优先（P0 强制）

```
1. 私有库: glob("{SKILL_LIBRARY_ROOT}/*/SKILL.md") + grep("{功能词}")
2. 历史档案: glob("{SKILL_LIBRARY_ROOT}/skill-search/data/**/*.md") + grep
3. 排行榜: searxng_web_search("site:skills.sh {功能词}") + searxng_web_search("site:skillsmp.com {功能词}")
4. 全量 GitHub（兜底）
```

缓存命中 → 跳过 P2/P3，直接进 P4 深读。详见 [known-good-cache.md](../references/known-good-cache.md)。

---

## 四维质量门粗筛（每个候选）

```
mcp__github__search_repositories(query="repo:{owner}/{name}")
mcp__github__list_commits(owner, repo, perPage=5)
mcp__github__list_releases(owner, repo, perPage=3)
mcp__github__list_tags(owner, repo, perPage=5)
```

输出 signature：`✓✓⚠✗` (install/source/stars/activity)。

**单源不可推荐**：至少 2 维 ✓ 才进 P4。详见 [quality-gates.md](../references/quality-gates.md)。

---

## 多语言搜索（按主语言三层降级）

主语言优先 → 英文补充 → 中文补充。

```
# 韩文仓库示例
mcp__searxng__searxng_web_search(query="site:blog.naver.com {功能词韩文}")
mcp__searxng__searxng_web_search(query="{功能词韩文} skill 리뷰 OR 추천")

# 中文仓库
mcp__searxng__searxng_web_search(query="site:zhihu.com {功能词中文} skill")

# 英文仓库
mcp__searxng__searxng_web_search(query="site:reddit.com {功能词英文} skill")
```

详见 [language-strategy.md](../references/language-strategy.md)。

---

## 输出 schema（JSON）

```json
{
  "evaluation_mode": "multi-source-discovery",
  "user_intent": "{功能需求}",
  "main_language_detected": "...",
  "cache_hits": {
    "private_lib": N, "history": N, "leaderboard": N, "github_full": N
  },
  "candidates": [
    {
      "repo": "owner/name",
      "source": "Scout-GH|BuiltIn|Market|Community|Expand",
      "quality_gate_signature": "✓✓⚠✗",
      "stars": N,
      "main_language": "...",
      "one_liner": "...",
      "why_recommended": "命中 trigger X + 质量门 ≥2 维 ✓"
    }
  ],
  "rejected": [
    {"repo": "...", "reason": "signature 仅 1 维 ✓ + activity ✗"}
  ],
  "scout_spawn_count": "5/5 or L2-fallback",
  "knowledge_gaps": [...]
}
```

---

## 跑偏自查

- [ ] P0 缓存 4 层全查（即使 0 命中也要记录）
- [ ] 5 Scout 全 spawn（或标 L2-FALLBACK）
- [ ] search_code 仅用于验证 SKILL.md 存在，不做发现
- [ ] 多语言三层降级执行
- [ ] 每个候选有 signature + 推荐理由
- [ ] 淘汰记录含 signature + 拒绝维度（不只"stars 不够"）
- [ ] 缓存命中率写入报告
