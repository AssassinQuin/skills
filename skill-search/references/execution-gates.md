# 执行门控

每个 Phase 的 exit-checklist。**全部打勾才能进入下一阶段**，任何一项未通过就停在当前阶段补完。

## P0 Exit Checklist（本地缓存查询）

```
□ 私有库已查询：glob("{SKILL_LIBRARY_ROOT}/*/SKILL.md") + grep("{功能词}")
□ 历史档案已查询：glob("{SKILL_LIBRARY_ROOT}/skill-search/data/**/*.md") + grep("{功能词}")
□ 排行榜已查询：searxng_web_search("site:skills.sh {功能词}") + searxng_web_search("site:skillsmp.com {功能词}")
□ 缓存命中数已记录（即使 0 也要记录）
□ 若命中：跳过 P2/P3，直接进 P4 并标注"缓存来源：私有库/历史/排行榜"
```

`SKILL_LIBRARY_ROOT` 默认 `~/.claude/skills`（见 SKILL.md 变量定义）。

## P1 Exit Checklist（需求解析 + 主语言检测）

```
□ 四组搜索词已生成（中英双语）
   - 功能词 / 同义词 / 上下游词 / 生态词
□ 主语言已检测（用户给具体仓库时强制）
   - GitHub metadata language 字段
   - README 前 100 行字符分布
   - SKILL.md description 扫描
□ searxng_search_suggestions 已用于扩展同义词
□ 主语言标记已记录（en/zh/ko/ja/...）
```

## P2 Exit Checklist（多源搜索）

```
□ Scout-GH: search_repositories 返回 >= 5 个候选
   → 不足：用同义词/上下游词扩展搜索词重试
□ Scout-BuiltIn 第一层：~/.claude/skills/ 已扫描
□ Scout-BuiltIn 第二层：marketplaces.json 已读取（无市场源则跳过但记录"未注册商城"）
□ Scout-BuiltIn 第三层：Web 搜索已执行
□ Scout-Market：至少 2 个垂直平台已搜索
□ Scout-Community：**按主语言三层降级执行**（主语言源 → 英文 → 中文），分开记录
□ Scout-Expand：Top 3 候选的关联网络已追踪
□ 总候选数 >= 10
   → 不足：回到 Scout-GH 用关联词组扩展
□ 子 Agent 实际 spawn 数已记录（如 5/5 或 L2 fallback 0 spawn）
□ P2 全程未使用 search_code 做发现
```

## P3 Exit Checklist（四维质量门）

```
□ 每个候选执行 4 个 git mcp 调用：
   - mcp__github__search_repositories (stars/created_at)
   - mcp__github__list_commits (最近 commit 时间)
   - mcp__github__list_releases (最新 release)
   - mcp__github__list_tags (版本管理)
□ Install count 数据已采集（skills.sh / skillsmp.com / plugin marketplace）
□ 每个候选输出 4 位 signature：✓✓⚠✗
□ **维护活跃度子维度（v5.1）已检查**：commit 节奏 + 版本管理（release/tag）双重判断，纯 main 分支开发降级为 ⚠
□ 通过质量门（≥2 维 ✓）的候选 >= 5 个
□ 淘汰记录已生成（每个含 signature + 拒绝维度，不只是"stars 不够"）
□ "为什么推荐这个"字段已起草（命中 trigger + 命中质量门）
```

## P4 Exit Checklist（深读）

```
□ P2/P3 未使用 search_code 做发现（只在 P4 验证 SKILL.md 存在用）
□ 每个候选先 mcp__zread__get_repo_structure 检查目录（不做根目录假设）
□ 多 Skill 仓库已识别（SKILL.md 在 skills/ 子目录）
□ SKILL.md + README.md 已用 mcp__zread__read_file 读取（不用 get_file_contents 读内容）
□ **references/ 至少深读 2 个文件**（被 SKILL.md 反复引用的优先）— 不允许只读目录列表
□ examples/ 或 test-prompts.json 已检查（没有则明确标记"缺失"，不算通过不算失败）
□ 长文档 token 策略已执行：
   - SKILL.md > 300 行 → ctx_index + ctx_search
   - Issue body > 2000 字 → ctx_execute_file 过滤
□ **长文件决策门（v5.1）已执行**：
   - zread_read_file 后立即检查返回行数
   - 行数 > 300（韩/日 > 150）→ 强制 ctx_index 转换
   - 决策门执行记录已写入 P6 透明度声明
□ 每个候选已按 evaluation-rubric.md D1-D8 打分（8 维 40 分制，作为启发式信号）
□ **评分谦逊化声明已附加**（D1-D8 非绝对真理，仅启发式参考）
```

## P5 Exit Checklist（社区口碑 — 主语言三层降级）

```
□ Top 3-5 候选的 GitHub Issues 已读取（含 closed issues，看维护者响应速度）
□ **主语言源已搜索**（韩文 → Naver/Tistory；日文 → Qiita/Zenn；中文 → 知乎/V2EX；英文 → Reddit/HN）
□ **SearXNG 盲区降级链（v5.1）已执行**：searxng 返回 0 结果时，按降级链 web-search-prime → 通用 searxng → WebFetch 验证至少 2 个方案
□ 英文源已补充搜索（Reddit/HN/Medium/Dev.to）
□ 中文源已补充搜索（知乎/V2EX/掘金/CSDN）
□ 每条反馈标注：来源语言 + 平台 + 日期 + 一句话观点
□ **主语言 vs 英文 vs 中文 三层差异已标注**（如"主语言热门但国际冷门"）
□ 主力工具是 searxng_web_search（不是 spawn agent），深读才 spawn
```

## P6 Exit Checklist（综合报告 + 本地保存）

```
□ 报告包含需求摘要 + 主语言标记
□ 每个候选有：定位 / 四维 signature / 推荐理由（可审计）/ 优缺点（附证据链接）/ 典型 Issue /
  社区反馈（按主语言/英文/中文三层分）/ 安装建议 / 适合谁 / D1-D8 启发式信号
□ 评分谦逊化：D1-D8 标注为"启发式信号"，未作为唯一决策依据
□ 淘汰记录在附录（含 signature + 拒绝维度）
□ 搜索覆盖统计（GitHub ×N / Marketplace / 主语言源 / 英文源 / 中文源）
□ **缓存命中统计**（私有库 X / 历史档案 X / 排行榜 X / 全量 GitHub X）
□ **MCP 调用统计**（github ×N / searxng ×N / zread ×N / Agent ×N）
□ **token 消耗估算**（主上下文 + 子 agent 独立 context）
□ 搜索查询记录（按语言分开：主语言 / 英文 / 中文）
□ 执行透明度声明（spawn 数 + L2 fallback 标注）
□ 本地保存完成，结构：
   {skill_dir}/data/{YYYYMMDD}-{slug}/
   ├── 评估报告.md
   ├── 候选-Top5.md
   ├── 淘汰记录.md
   ├── sources.md
   └── raw/  ⚠️ 强制：所有 MCP 调用 + 子 Agent 原始输出
       ├── mcp-github-search-{ts}.json
       ├── mcp-github-list-issues-{ts}.json
       ├── mcp-github-list-commits-{ts}.json
       ├── mcp-zread-skill-md-{ts}.md
       └── scout-{role}-{lang}-{ts}.json
```

## E1 Exit Checklist（单仓库深度评估模式）

触发：用户给具体 GitHub URL 或 `repo:owner/name`。

```
□ P0 已执行（命中即用历史档案，跳过 P2/P3）
□ P1 主语言检测已完成（决定 P5 三层降级）
□ P3 四维质量门 signature 已输出（作为健康检查，不过滤）
□ P4 完整深读（SKILL.md + README + references ≥2 + examples 检查）
□ P5 主语言 + 英文 + 中文三层社区源（不可省任何一层）
□ P6 全套保存（含 raw/ + MCP 统计 + 缓存命中）
□ 报告标题明确标注"评估模式 E1：单仓库深度评估"
□ 报告说明哪些 Phase 被省略及理由
```

## 多 Skill 仓库处理

部分仓库（如 `sanyuan-skills`、`alirezarezvani/claude-skills`）是 Skill 合集，SKILL.md 不在根目录。

处理步骤：
1. `mcp__zread__get_repo_structure` 查看目录树
2. 根目录无 SKILL.md → 检查 `skills/` 子目录
3. 找到匹配用户需求的子 Skill → 用 `mcp__zread__read_file` 读取其 SKILL.md
4. 在报告中注明"来自合集 {仓库名} 的 {子 Skill 名}"
