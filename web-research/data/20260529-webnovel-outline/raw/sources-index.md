# 降级日志

| 时间 | 能力 | 降级 | 原因 | 降级到 | 结果 |
|------|------|------|------|--------|------|
| 2026-05-29 | 提取 | ctx_fetch_and_index | 知乎 13个URL HTTP 403 | Agent WebSearch降级搜索 | ✅ Agent补搜知乎内容成功 |
| 2026-05-29 | 提取 | ctx_fetch_and_index | xs91.net DNS解析失败 | 跳过（非核心） | ⚠️ 1个URL跳过 |
| 2026-05-29 | 搜索 | searxng | 百万字节奏query返回大量无关结果 | Agent补充WebSearch | ✅ Agent补搜Stage32/NowNovel/RoyalRoad |

# 提取状态表

| URL | 状态 | 工具 | 主题 |
|-----|------|------|------|
| https://blog.csdn.net/2301_79545694/article/details/143214080 | ✅ 成功 | ctx_fetch_and_index | 方法论 |
| https://maliangwriter.com/blog/novel-outline-templates/ | ✅ 成功 | ctx_fetch_and_index | 模板 |
| https://news.chenggua.com/detail/33391.html | ✅ 成功 | ctx_fetch_and_index | 模板 |
| https://www.chinawriter.com.cn/n1/2022/1207/c404024-32582252.html | ✅ 成功 | ctx_fetch_and_index | 案例 |
| https://www.chinawriter.com.cn/n1/2024/1205/c404027-40375996.html | ✅ 成功 | ctx_fetch_and_index | 案例 |
| https://www.jianshu.com/p/7854d4eae629 | ✅ 成功 | ctx_fetch_and_index | 模板 |
| https://www.mx-xz.com/show_7434.html | ✅ 成功 | ctx_fetch_and_index | 方法论 |
| 知乎 13个URL | ❌ 403 | ctx_fetch_and_index → Agent WebSearch | 全部 |
| Agent补充URL (Stage32/Reedsy/RoyalRoad/Game Developer等) | ✅ 成功 | Agent WebSearch | 节奏/跨领域 |
