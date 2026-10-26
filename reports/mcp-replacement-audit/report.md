# 已有 Skills + MCP 的上位替代 / 垂直替代 / 优化审计

**日期**：2026-10-23
**对象**：本机 `~/.agents/skills` 下 98 个已安装 skill + 当前会话在用 MCP
**模式**：Requested deep / Effective deep+solo

---

## 一、总判断（先说结论）

**你的问题不是"缺更好的 skill"，而是"装太多、复制太重、该是数据的被做成了 skill"。**

三层结构性问题，替代只是其中一层：

| 层 | 问题 | 证据 |
|---|---|---|
| **数量层** | 98 个 skill 已远超社区实测的 ~30 个性能退化阈值；每个 description 常驻 ~100 tokens，每轮 API 都付费 | [S6][S7][S8] |
| **架构层** | 该是"知识数据"的（Naval 系 19 个、perspective 系 15 个）被做成了独立 skill；该是"工具链"的（小说系 19 个）只是提示词方法论，缺确定性检查 | 本地盘点 + [S2] |
| **替代层** | 小说系有明确上位替代（story-skills）；memory MCP 有升级候选（Mem0）；其余大多保留 | [S2][S11][S12] |

社区同行的实践已经给出同样答案：**"装了 50 多个，实际每天在用的不超过 5 个，开始清库存"**[S1]、**"用了三个月，删掉 80%"**[S5]。98 个 → 目标 30 个以内是第一优先级，比找任何新替代都重要。

---

## 二、Skill 逐类审计（98 个 → 4 类）

### 2.1 小说写作系（19 个）→ **明确的上位替代：story-skills**

**现状**：novel-skeleton 12 个 + plot-thickens 7 个，全部是 5-13K 的方法论文档（维兰德三幕、人物引擎、冲突设计、悬念系统等），顶层和 `cangjie-skill/books/` 双份安装。

**上位替代**：[danjdewhurst/story-skills](https://github.com/danjdewhurst/story-skills)（341★，2026-10-20 仍活跃，24 个 skill，MIT）
- **架构代差**：你的 19 个 = "提示词方法论"；story-skills = "项目格式契约 + 确定性检查器 + CI"
- **Continuity Engine**：`story` CLI 把 story bible 当可校验合同——死掉的角色再出场、payoff 早于 setup、状态过期，都像类型错误一样被抓住 [S2]
- **evals 回归测试**：`evals/` 目录用种子 brief 和已知陷阱回归测试写作技能——你的 19 个 skill 零 eval [S2]
- **GitHub Actions**：PR 打破连续性会 fail check；可定时起草下一章开 PR [S2]
- **输出链**：EPUB / DOCX / Shunn manuscript / 印刷内页 / HTML 审阅稿 / 剧本 / Twine / ink，全部从同一项目构建 [S2]
- **Codex 插件分发**：`codex plugin marketplace add danjdewhurst/story-skills` [S2]
- **多语言**：含中文竖排、RTL 支持 [S2]

**技能映射**（你的 → story-skills）：
| 你的 skill | story-skills 对应 |
|---|---|
| premise-sentence | premise-workshop |
| character-engine / character-interview | character-management |
| structure-three-act / scene-map | plot-structure |
| setting-worldbuild | worldbuilding |
| theme-discovery | theme-craft |
| context-macro-edit | revision-continuity |
| condense-outline / reverse-outline | editorial-review / line-editing |
| novel-outline-pipeline | story-init + discovery-drafting |

**垂直替代参考**：[PhosAQy/novel-skills](https://github.com/PhosAQy/novel-skills)（16★，2026-01 后停更）——中文网文流水线：卷规划→章节生成→OOC/Lore/逻辑/风格/重复 5 维质量评分→记忆管理 [S3]。**不建议直接依赖**（停更 10 个月、单作者、16★），但其 5 维评分表对中文网文场景有借鉴价值。

**建议行动**：
1. 安装 story-skills 作为架构层（项目格式 + continuity check + CI）
2. 你的 19 个 skill **不是删除，是降维合并**：中文写作方法论保留为 story 项目内参考文件；19 个独立 skill 收敛为 1 个 `cn-fiction-craft` 路由 skill
3. 借鉴 novel-skills 的 5 维评分标准做中文网文垂直化

### 2.2 Naval / 心智模型系（~19 个 × 最多 3 份复制）→ **不是替代，是形态错误：该是知识库**

**现状**：`cangjie-skill/books/naval-almanack-skill/`（19 个）+ `benchmarks/naval/prototypes/`（2 份打包）+ `dist/naval-almanack-pack/` + `dist/naval-almanack-single/` —— 同一内容最多 **3-4 份安装副本**。

**判断**：这批本质是**知识而非程序**。Naval 的决策启发式、幸福框架、peer-selection 原则是"查询时阅读的参考资料"，不是需要独立路由入口的技能。做成 19 个独立 skill 的代价：
- 19 条 description 常驻 ≈ 2,000-4,000 tokens 纯路由开销 [S8]
- 与其他高频技能争夺触发注意力（30+ 个 skill 后触发准确率下降）[S6]

**建议**：19 → 1。保留一个 `naval-almanack` 路由 skill（现有 single 版 7.2K 已接近正确形态），其余内容移为 `references/*.md` 按需加载；删除 dist/benchmarks 重复副本。

### 2.3 人物 perspective 系（15 个，24-54K）→ **瘦身，不是替代**

**现状**：huashu-nuwa 产出的 15 个人物视角 skill 全部 24-54K（Karpathy 31.6K、孙宇晨 31.7K、huashu-nuwa 本体 38.2K），远超官方建议的 <5K token [S18]。

**问题**：SkillReducer 对 55,315 个 skill 的实证：body 压缩 39% 后功能质量**反升 2.8%**（less-is-more）[S18]。60%+ 的 body 内容不可行动，纯粹是 context 干扰。

**建议**：每个 perspective skill 拆三层——
1. SKILL.md <5K：触发条件 + 5 个核心心智模型索引 + 指向 reference
2. `references/{person}-heuristics.md`：8 条决策启发式全文
3. `references/{person}-voice.md`：表达 DNA 与句式库
触发频率低的（MrBeast、x-mastery-mentor 等营销类）可进一步合并为一个 `perspective-advisor` + 人物数据文件。

### 2.4 工具系（8 个）→ 分级处理

| skill | 判断 | 依据 |
|---|---|---|
| **deep-research**（12K） | **保留，吸收外部架构** | GPT Researcher（29K★）是独立框架非 skill 替代；但其 planner/executor 分离、引用强制、多源交叉值得吸收 [S9][S10]。LangChain deepagents 同理 [S9]。你的 skill 价值在于"在当前 agent 内编排"，这是外部框架做不到的 |
| **global-search / zhihu-search** | **降级为 fallback** | 当前 websearch_cn MCP 已覆盖两者大部分场景（知乎 site: 搜索可用 websearch 完成）；两个 CLI skill 保留作为 MCP 失败时的降级链（你的 deep-research 已经这么用它们） |
| **skill-stats** | 保留 | 本地 usage 日志独有，无外部替代 |
| **find-better-path** | 保留 | 触发式决策 skill，轻量（4K） |
| **portfolio-rebalance** | 保留但低频 | 垂直场景，无外部上位替代证据 |
| **cangjie-skill / huashu-nuwa** | 保留但瘦身 | 拆书/造人两个元技能有价值；huashu-nuwa 38K 需按 2.3 方式瘦身 |

---

## 三、MCP 层审计（第二问）

| 在用 MCP | 判断 | 替代/升级候选 |
|---|---|---|
| **memory** | 保留，评估升级 | **Mem0 MCP**：LoCoMo 92.5 / LongMemEval 94.4，2026-10 仍活跃 [S11]。memory MCP 生态已膨胀到 21 框架 × 20 向量库 [S12][S13]。注意：Mem0 OpenMemory 已转 hosted server（非本地 Docker）[S13]，隐私/成本需实测。当前 memory MCP 能满足则不必急换 |
| **context7** | **保留** | 54K★、upstash 官方活跃、版本化文档是核心差异点；对比文存在但无全面上位替代 [S14] |
| **websearch_cn / web_search_prime** | 保留，质量可升 | **Tavily / Exa / Firecrawl** 是质量升级候选：Firecrawl 2026-07 search 升级自报 94.7% SimpleQA 且成本更低 [S15][S16]。但 websearch_cn 的中文引擎（百度/搜狗/CSDN）覆盖是国内场景独有价值，Tavily 系不可替代中文 lane |
| **playwright** | **保留** | 官方生态标准，无上位替代证据 |
| **codebase-memory** | **保留** | 10.5K★、C 写知识图谱、158 语言；旧调研结论：适合 macOS + Python/Go，Windows 二等公民 [S19] |
| **context_mode** | 保留 | 旧调研：headroom（44.8K★）是代理层替代候选，但有破坏 prefix cache 的自伤 bug [S19] |
| **node_repl / cua / artifact_session** | 保留 | 宿主内置，无外部替代概念 |

**MCP 层结论**：没有"全套换血"的必要。唯一值得试点的升级是 **memory → Mem0**（有 benchmark 优势）和**搜索质量层加一个 Tavily/Exa**（中文 lane 保留 websearch_cn）。

---

## 四、优化路线图（优先级排序）

| # | 行动 | 效果 | 工作量 |
|---|---|---|---|
| **P0** | 删除 dist/benchmarks 重复副本，98 → ~40 | 消除 3-4 份重复安装，立即减常驻 token | 1 小时 |
| **P1** | 安装 story-skills；小说 19 个 → 1 个 `cn-fiction-craft` 路由 + 方法论外置 | 架构升级 + 减 18 条路由 | 半天 |
| **P2** | Naval 19 → 1（single 版为底，references 外置） | 减 18 条路由 | 半天 |
| **P3** | perspective 15 个瘦身：每个 <5K router + references/ | 总体积 −60% 以上（SkillReducer 实证可行）[S18] | 1-2 天 |
| **P4** | 用 skill-stats 采集 30 天真实触发数据，再砍一轮长尾 | 数据驱动清库存（社区经验：50→5）[S1] | 30 天 |
| **P5** | memory MCP 试点 Mem0（并行跑 2 周对比召回） | 可选升级 | 2 周 |
| **P6** | deep-research 吸收 GPT Researcher 的引用强制+多源计数 | 质量提升 | 半天 |

P0-P3 完成后 skill 数量约 25-30，正好落在社区建议区间 [S6][S7]。

---

## 五、最强反驳（contrarian pass）

1. **"30 个阈值"非官方数据**：agentengineermaster / bswen 均为第三方博客实测，Anthropic 官方未发布 skill 数量-performance 基准；description token 成本方向正确，但阈值数字可能因模型版本而异。**缓解**：以官方硬限（description ≤1,024 字符）为准绳，数量阈值作参考。
2. **story-skills 规模风险**：341★、单作者主导，与 183K★ 的官方仓库相比是长尾项目；其方法论以英文出版流程为主，中文网文长篇场景未验证。**缓解**：作为架构层（格式+检查器）采用而非照搬 24 个 skill；中文方法论保留自有内容。
3. **Mem0 benchmark 自报嫌疑**：92.5/94.4 来自 Mem0 官方博客，存在既当运动员又当裁判的问题；第三方对比中各家争议仍在 [S12][S13]。**缓解**：并行试点而非直接迁移。
4. **GPT Researcher 专属批评未发现**：搜索未找到针对性翻车证据，但泛深研 agent 的引用可靠性风险（幻觉引用）已有学术记录；深研结论仍需人工复核。

## 六、未解问题

1. story-skills 在中文长篇网文场景未实测——建议用一个 10 章试写项目验证（可放 `mcp-replacement-audit/inbox/`）
2. 用户 30 天真实 skill 触发频率未采集——P4 执行后可复查
3. Mem0 hosted server 的数据隐私与成本未实测——P5 并行期出结论

## Meta

- Requested Mode: deep；Effective Mode: deep+solo（spawn 环境不可用，主会话串行扮演搜索员/核实员）
- lane 健康：cn ✓（websearch_cn）/ glb ✓（websearch_cn bing+ddg）/ prime 部分（2 次空结果，已用 glb 兜底）/ github ✓（gh API 升级后成功 4 查）/ zhihu 未启用（无需）/ human ✓（旧报告+记忆复用）
- 查询统计：fresh 9 次 / reused 3 条（两份旧报告 + 一条 2026-06 记忆）
- 降级记录：prime 第 1 次返回空（计 1 次）；gh 首次被沙箱拦截后按规则升级成功

---

## 七、追加验证：story-skills 中文实测（2026-10-23，用户批准后执行）

用 `/tmp/story-skill-trial/guixu-zhiqiu` 构造了包含两个故意陷阱的中文短篇（林晚秋第2章死亡→第4章再出场；承诺第3章 setup→第2章 payoff 顺序反转），跑 `story check` 实测：

### 结果：两个陷阱全部命中，中文正文零干扰

```
error: chapters/chapter-04.md lists lin-wanqiu, who died in chapter-02;
       move posthumous appearances to mentions
error: continuity/promises/the-tide-table.md pays off in chapter-02
       before it is planted in chapter-03
```

### 中文适配明细

| 项目 | 结果 |
|---|---|
| 连续性契约（deaths/promises/cast） | ✅ 完全语言无关，frontmatter 引用即可，正文可全中文 |
| CJK 字数统计 | ✅ 按字符逐字计数（declared 48 vs 实数 55 被正确标记 stale），行为符合中文习惯 |
| 引用完整性 | ✅ 缺 location/arc 文件同样被抓（13 errors 全部有理有据） |
| init 纯中文标题 | ⚠️ 不能自动推导目录名，需显式 `--dir ascii-name`（小摩擦） |
| 错误消息 | ⚠️ 英文输出（可接受） |

### 验证结论

报告 §2.1 的建议从"纸面推断"升级为"实测通过"：**story-skills 的连续性编译器对中文小说完全可用**。唯一适配动作是项目目录用拼音/英文 ID、`title` 字段保留中文。§六 未解问题第 1 条（中文场景未实测）至此关闭。
