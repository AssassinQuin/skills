# GitHub Claude/AI-agent skill 仓库生态与 skill 可进化性 调研报告

## 摘要

- **生态规模**：GitHub 上 `claude skills` 相关仓库（stars>100）达 **7,301 个**[S1]。头部仓库 star 量级 17万-28万（2026-09-03 GitHub API 直查：obra/superpowers **280,991**、affaan-m/ECC 246,583、mattpocock/skills 245,733、anthropics/skills **173,344**、ultraworkers/claw-code 195,165）[S1][S47]；注意 star 数存在公开"注水 10-25%"争议[S49]。
- **可进化性设计已收敛为一套公开方法论**：Anthropic 官方确立**渐进披露三层**（metadata→SKILL.md→bundled files）+ description 写"what+when" + 「Does this paragraph justify its token cost?」逐段成本检验 + "Start with evaluation" 评测先行[S9][S10]；Agent Skills 已于 **2025-12-18 成为开放标准**[S9]。
- **自进化机制真实存在且已成谱系**：论文线 SkillWeaver（2025-04，探索+API 合成）[S48] → EvoSkills/SkillFoundry（2026-04，共进化验证/异构资源挖掘）[S17][S18] → **SkillOpt**（Microsoft，2026-05：冻结模型+优化器模型，rollout→reflect→有界编辑→held-out 验证门，编辑预算=文本学习率）[S44][S45]；工程线 GEPA 已进 DSPy 官方 API[S27][S28]，Nous Research hermes-agent-self-evolution 用 DSPy+遗传算法自动进化 skills[S30]。学界自认：**loosely controlled self-revision 不可靠进化**[S51][S44]。
- **多语言采用**：中文已进入"写自定义 skill"实操层但**无 GitHub 原生中文合集仓库**[S31][S34][S47]；日语有 Qiita 系统教程系列[S24]；知乎批评"Skills 只是换皮 AGENTS.md"[S38][S50]。
- **对本仓库的落点**：38 个本地 skill 中 24 个零使用、15/38 有 version 字段、0 个有评测集；外部 superpowers:* 占本仓库全部 skill 调用的 44%。进化建议见专节（流程/命令/token 三方向 + 门控自进化机制）。

## 发现

### sq1 仓库指标：头部 skill 仓库 star/fork/issue（core, github）

GitHub search API（`claude skills agent skills stars:>100`，total 7,301，2026-09-03）：

| 仓库 | Stars | Forks | Created | 定位 |
|---|---|---|---|---|
| obra/superpowers | 280,991* | 25,179 | 2025-10-09 | 最大社区 skill 库（TDD/debugging/brainstorming 工作流） |
| affaan-m/ECC | 246,583 | 37,172 | 2026-01-18 | skills+instincts+memory 性能优化 harness |
| mattpocock/skills | 245,733* | 20,878 | 2026-02-03 | "Skills for Real Engineers" |
| ultraworkers/claw-code | 195,165 | 108,753 | 2026-03-31 | Rust，宣称 no human intervention |
| **anthropics/skills**（官方） | **173,344*** | 20,581 | 2025-09-22 | 官方示范库（open_issues_count 1,207 含 PR；issue 总数 390[S5]） |
| multica-ai/andrej-karpathy-skills | 209,759 | 21,336 | 2026-01-27 | 单文件 CLAUDE.md 风格 |

\* 核实员 2026-09-03 二次 API 直查复核值（与搜索员 280,983/173,337 等 ±10 漂移一致）[S1]。第三方旁证：公众号 star 表格（2026-08-21）anthropics/skills 169,874 / superpowers 273,037，与 API 值随时间吻合[S47]。**冲突**：Firecrawl 文章称 superpowers 40.9k[S12]，经核实员直查判定为失效/过时数据，不可引用；Instagram 帖（2026-06-20）称流行榜单 star 普遍注水 10-25%、给 superpowers"真实值"213k[S49]——与今日 API 280,991 矛盾（或为 6 月后增长），star 争议留痕。官方仓库 issue 三大痛点：Windows 兼容（trigger-eval harness 崩坏、并行 worker 把触发率压到 1/N）、内容陈旧（mcp-builder 默认模型停在 claude-3-7）、触发词/描述精度（doc-coauthoring 单轮环境 15/15 零产出）[S5]。

### sq2 流行度与更新频率：谁活跃、谁停滞（core, github）

- **anthropics/skills**：2026-08-17~09-01 五次 commit（claude-api skill 更新至 Fable 5.1、Files/Skills API 转 GA、新增 discernment-nudge），日增 issue 2-4 个，单月约 45 条外部 PR[S2][S54]——高频活跃。
- **obra/superpowers**：v6.2.0（07-23，skills compression sweep）→ v6.3.0（08-12），约 3 周一个 minor release；commit 带 `Co-Authored-By: Claude Opus 4.8`（AI 协作自举开发）[S3]。
- **affaan-m/ECC**：每日多次 commit（重度 CI 维护）[S7]；mattpocock/skills 08-21~08-24[S6]；claw-code 最近 commit 08-16（13 个并行 explore agents 生成 AGENTS.md 知识库）[S8]。
- **停滞面**：7,301 个仓库的长尾无活跃度数据，但 trending-claude-skills 之类 15 分钟刷新榜单的存在说明生态分化剧烈[S16]；LinkedIn 2026-05 评测称"只有少数 skill 持续交付真实价值"[S14]。

### sq3 skill 编写方法论（core, glb）

官方一手（Anthropic 自述，无第三方独立复核——机构口径单源）：
- **渐进披露三层**：启动只预载 name+description（每 skill 约 100 token）→ 触发时才读全文 SKILL.md（一般 <5K token）→ bundled reference 文件按需读；脚本代码不进 context、只有执行结果进 context[S9][S38]。
- **description 决定触发**：必须同时写"what it does + when to use it"，Claude 据此在 100+ skills 中选择[S10]。
- **token 纪律**：每段自问「Does this paragraph justify its token cost?」；官方范例 50 token 精炼版 vs 150 token 冗长版[S10]。
- **自由度分级**：高自由度（纯指引）/中（带参伪代码）/低（固定脚本），按任务"脆弱性与可变性"匹配[S10]。
- **评测先行**："Start with evaluation"——先在代表任务上跑 agent 找能力缺口，再增量建 skill[S9]。
- **确定性代码优于 token 生成**：排序用代码比用 token 生成便宜且确定；PDF skill 预写脚本无需把脚本或 PDF 载入 context[S9]。
- 命名：建议 gerund 动名词形式；skill 名禁含 claude/anthropic 保留字、描述上限 1024 字符（官方仓库 commit 披露）[S2]。

### sq4 论文：agent 技能学习/技能库（core, glb）

谱系（均 arXiv 单源，无独立二手佐证——置信 medium）：
- **SkillWeaver**（arXiv 2504.07079，2025-04）：web agent 通过探索自主发现+honing skills、API 合成实现自改进[S48]。
- **EvoSkills**（arXiv 2604.01687，2026-04-02）：自主生成 skill + **共进化验证**；明确指出现有面向 tool 的自进化方法不能直接用于 skill[S17]。
- **SkillFoundry**（arXiv 2604.03964，2026-04-05）：从异构科学资源自动挖掘构建自进化 skill library，提升基准与领域任务[S18]。
- **RL for Self-Improving Agent with Skill Library**（arXiv 2512.17102，2025-12）：批评现有 skill library 依赖 LLM 自评、缺验证[S21]。
- **SkillOpt**（arXiv 2605.23904，Microsoft，v1 2026-05-22）：见 sq7。自称 52/52 cells 胜 no-skill/human-skill/TextGrad/GEPA——**论文自报，3 个多月无独立全量复现**（aipractitioner 明确声明"not a full replication"）[S44][S51]。
- 综述线：Gao et al.《A Survey of Self-Evolving Agents》what/when/how 框架（被引 255）；Fang et al. 2025 统一反馈环；taxonomy 博客把自进化分三档（见 sq7）[S41][S46]。Voyager（2023 概念源头）未直接命中一手来源（见未解问题）。

### sq5 中文社区采用度（core, cn）

- **已进入实操层**：公众号《ClaudeCode2026 终极使用指南》演示 `.claude/skills/techdebt/SKILL.md` 完整自定义写法（2026-09-02）[S31]；CSDN 全流程教程（安装→接 DeepSeek/智谱→Skills→自写 skill→排错），国产模型混搭成常态[S32][S34]；支付宝员工"保姆级教程"给出 scripts+references 标准结构[S40]。
- **注意力信号**：OpenClaw 退潮后中文圈"集体转头研究 Claude Code、Codex、Skills 和 Harness"（2026-08-29）[S33]。
- **合集缺位**：**未发现 GitHub 原生中文合集仓库**；中文世界靠公众号文章转述 star 表格[S47]，唯一例外是 CSDN 付费下载包"A股投资实践 skills 统一集合"（非 GitHub 原生、疑似转载形态）[S52]。中文引擎对新主题召回弱（sogou 反爬 + 新旧混杂）[S36][S37]。
- 中文自进化论述已有体系化文章：CSDN"自我批评→经验学习→技能库构建"四层闭环（执行/批评/学习/技能层），点名 Hermes/EvolveR/SkillAxe/Arbor、技能版本管理、**人工审批关卡**[S35]（单源，疑似 AI 洗稿风险，未核实框架真实性）。

### sq6 知乎观点与争议（background, zhihu）

- 逆向分析：Skill 不是可执行代码，是注入上下文的特化 prompt 模板；最普遍批评 **"Skills are just AGENTS.md in disguise"**（Simon Willison 正面评价但承认批评有理）[S38]——此批评获 HN 第三方 eval 佐证（《AGENTS.md outperforms skills in our agent evals》）[S50]。
- 场景争议：**探索型工作流（算法研究）大概率鸡肋，规范型业务开发实打实有价值**[S38]。
- 独特视角（单源 low，未经证实）：Skills 不是技术创新而是**经济生存策略**——固定容量租约下需降低单位 token 消耗 20-30%，是"虚拟扩容"；Skills 解决"上下文何时加载"，MCP 解决"有没有上下文"[S39]。

### sq7 自进化机制：从使用统计/评测反馈自动改进（core, glb+github）

- **三档 taxonomy**（lsl.zone 单源博客）：artifact 迭代优化 / harness 自改进（prompt+memory 层、tools+skills 层——**agent 修改自己的组件**）/ model learning（self-play、TTT 等名目）[S46]。
- **SkillOpt 机制**（微软，2 独立域证实）：冻结目标模型 + 优化器模型；在打分批次上 rollout → 反思成败 minibatch → 有界 add/delete/replace 编辑（**编辑预算=文本学习率**，防止有用规则被大改覆盖）→ **held-out validation gate**（验证集不涨分不收）；**被拒编辑成为负反馈**（buffered）避免重复有害方向；rejected edits + meta skill 提供长周期反馈不膨胀部署[S44][S45]。这正是"基于评测反馈自动改进 skill"的完整闭环形状。
- **工程可用件**：GEPA（reflective prompt evolution，2025）已进 DSPy 官方 optimizer API；gepa-ai/gepa 用评测指标+训练数据自动改 prompt/代码/agent 架构，Pareto 感知选择[S27][S28][S29]；Nous Research hermes-agent-self-evolution（2026-06，单源媒体）：DSPy+遗传算法自动进化 agent 的 skills/prompts/工具代码[S30]。
- **仓库侧**：volcengine/OpenViking（35,253 stars）"Self-evolving Context Database——统一 Agent Memory/Knowledge RAG/Skills"；CowAgent 46,769 stars"self-evolves with memory"；claw-code 宣称 no human intervention 开发[S4][S1]。
- **反例与边界**：SkillOpt 论文摘要自认领域缺陷"loosely controlled self-revision…none of which reliably improves over its starting point"[S51]；斯坦福 CS329A 核心论点"**可靠反馈才是闭环能否跑起来的关键**、执行力越强验证越重要"[S42]；官方仓库 issue #1718 显示评测 harness 本身会坏（单轮环境 15/15 零产出）[S5]。产业案例（Tax AI 6 周准确率翻三倍、MOSS 源码级自改 0.25→0.61）为媒体转述未核实[S43]。

### sq8 日语社区采用度（background, glb）

- Qiita 系统教程系列已出现：《Claude Skills 完全ガイド①》2026-08-11 且持续更新[S24]；YouTube"24 個の具体的な活用事例"（2026-03-27，1K views）[S22]；note.com"全部試してみた"[S26]；tsukatte-ai.com 2026 年版指南（Excel/PPT/Notion 实务场景）[S25]。整体热度为**教程导入期**（各项孤证，Zenn 未命中），明显小于中英社区。

### sq9 本仓库现状（core, local）

`.stats/usage.jsonl`（223 条，2026-05-27~09-03）：外部 superpowers:* 占 **98/223=44%**（brainstorming 40、systematic-debugging 21、writing-plans 12）；自研检索/基础设施 25（deep-research 6、global-search 6）、写作类 23（story-long-write 9）、投研类仅 7 且自 2026-07-21 停用。38 个本地 skill 中 **24 个零使用**（story-audit/review/deslop/import、9 个写作工序件、portfolio-rebalance 等）；frontmatter 规范率低：仅 15/38 有 version、16/38 有「何时不调用」；**无任何 eval/测试目录**。历史包袱：曾有 skill-evolver skill（8 次调用后已被删除）。

## 对本仓库 skills 的进化建议

> 依据：官方方法论（sq3）+ 自进化谱系（sq7）+ 本仓库使用数据（sq9）。按 流程/命令/token 三方向 + 自进化机制决策给出，全部可直接执行。

### 流程方向（准确性）

1. **评测先行（官方 "Start with evaluation" 的本地化）**：为高频 7 skill（deep-research、story-long-write、global-search、skill-stats、portfolio-rebalance、huashu-nuwa、cangjie-skill）各建 5-10 例最小评测集（输入→期望产物特征清单），放 `skills/<name>/eval/cases.json`；`.stats/log-skill.sh` 增加 `outcome` 字段（success/fail/human-fixed），让 usage.jsonl 从"计数器"升级为"反馈环数据"。
2. **长尾治理=触发准确率治理**：官方明确 description 是 Claude 在 100+ skills 中选择的唯一依据[S10]——24 个零使用 skill 的描述仍在稀释触发匹配。把零使用件移入 `archive/`（保留 git 历史）或并入 `novel-outline-pipeline` 路由层做二级分发；同步对官方保留字规则做一致性检查（skill 名禁含 claude/anthropic、描述 ≤1024 字符）[S2]。
3. **frontmatter lint 挂钩**：写 `scripts/lint-skills.sh` 校验三段必备（version / 关键 trigger / 何时不调用），git pre-commit 或 hook 强制——当前合规率 15/38、16/38，一次性补齐后防回退。

### 命令方向（可靠性）

4. **确定性逻辑下沉为脚本**（官方 PDF skill 模式："跑脚本，不把脚本载入 context"[S9]）：把写作工序里的确定性判断脚本化——inciting-event 的"门测试"判定、pov-selection 三问打分、三幕节拍位置检查（0.25/0.5/0.75 校验）、condense-outline 字数配额计算；投研类的仓位回撤公式、久期分档规则做成查表脚本。R5 原则已在 deep-research 落地（route-lane.sh/validate-findings.sh 是正确示范），向 story/投研系列复制该模式。
5. **每个 skill 配一个 validate 脚本**：deep-research 已有 validate-findings.sh；story 系列补轻量校验（validate-outline：主线因果链完整性/伏笔登记表非空；validate-character：动机→愿望→目标三级链非空）。产出不过校验=显性失败（R12），这是 skill 可靠性的最低保障，也是自进化的"门"。
6. **多环境验证**：官方 issue 区头号痛点是 trigger-eval harness 在 Windows/并行环境失真（触发率被压到 1/N）[S5]——本仓库 skill 若分发他人，评测脚本必须固定单进程+记录环境指纹，避免"评测通过=只在作者机器通过"。

### token 方向（消耗）

7. **渐进披露改造**：按官方三层模型审计超重 SKILL.md（deep-research 180 行、story-long-write 系列、huashu-nuwa），把方法论长文、示例库移到 `references/*.md`，SKILL.md 只留 frontmatter 描述 + 目录式正文；目标单 SKILL.md 正文 <5K token[S9][S38][S10]。
8. **逐段成本检验进 lint**：lint-skills.sh 加一条启发式——指令段落若超过官方"坏例子"的 ~150 token 量级即告警，用「Does this paragraph justify its token cost?」复核[S10]；确定性运算一律指向脚本（方向 4）而非 prompt 内规则展开，直接省 token。
9. **zombie skill 清零也是 token 优化**：24 个零使用 skill 的 metadata 每次会话都占启动预算（官方口径每 skill ~100 token[S38]），归档即省。

### 是否引入自进化机制：**引入，但必须门控（SkillOpt 形状），禁止无验证自改**

10. **采纳 SkillOpt 闭环的本地最小版**：`使用统计（skill-stats + outcome 字段）→ 月度进化批次生成候选修改（描述优化/触发词/瘦身/脚本化）→ 过 eval 评测集（held-out gate：指标不涨不收）→ 人工审批关卡（CSDN 闭环文章同款原则[S35]）→ 合入；被拒修改记入负反馈清单防重复（SkillOpt buffered rejected edits[S45]）`。编辑要有界（一次批次 ≤3 个 skill、每 skill ≤5 处编辑）——"编辑预算=文本学习率"[S44]。
11. **历史教训显式化**：本仓库删掉的 skill-evolver 正是无门控自改的尝试（8 次使用后废弃）；学界自认 loosely controlled self-revision 不可靠[S51]、官方 harness 自己都会坏[S5]——所以 gate 必须与生产同环境、保留人工关卡。不自进化模型权重，只自进化"harness 层"（描述/结构/脚本），与 taxonomy 的 harness self-improvement 档位对齐[S46]。
12. **机会项**：中文世界无 GitHub 原生 Skills 合集仓库（sq5），若本仓库未来开源，写作类 skill 垂直合集（网文工序化）是空位。

## 最强反驳

最强反驳针对整个选题的效用前提：**skill 生态的效用与数据都未经中立验证**。(1) HN 第三方评测帖直接声称《AGENTS.md outperforms skills in our agent evals》[S50]，与知乎"换皮 AGENTS.md"批评互证[S38]；(2) 头部仓库 star 数被公开指控注水 10-25%（Instagram 帖称 superpowers"真实值"213k，2026-06-20）[S49]——虽与今日 API 值矛盾，但 Firecrawl 40.9k 的失效已证明二手 star 数据不可轻信；(3) SkillOpt 的 52/52 SOTA 为论文自报，3 个多月无独立全量复现[S51]；(4) 领域自认 loosely controlled self-revision 无一可靠超越起点[S44]——即"skill 自进化"目前只有带验证门的版本被证明可行，无门控自改有反例支持。未发现针对"官方渐进披露三层机制描述"本身的反驳（V3/V4 逐字核实通过）。

## 未解问题

- Voyager（2023，skill library 概念源头）未取得一手来源命中（q19 被 SkillWeaver 占位）——sq4 的谱系起点依赖二手转述。
- obra/superpowers star 的公开争议（213k 注水指控 vs API 280,991）无法在本轮内裁定；watchers 精确数、issue 按赞排序 Top 榜未取得（GitHub search API 不返回，调用已到 8 次上限）。
- "Skills 降低单位 token 消耗 20-30%"为知乎单源[S39]，未找到独立证实或证伪；cn lane 的 sogou 反爬使公众号生态定量规模（教程总量）无法估计。
- 中文 CSDN"统一集合仓库"为付费下载包，其内容与来源合法性未核实[S52]；Hermes/EvolveR/SkillAxe/Arbor 等中文文章点名框架未做原文核实[S35]。
- Tax AI/MOSS 产业自进化案例为媒体转述，原始论文未核[S43]。

## 引用

见 `sources.json`（S1-S54）。核心：S1 github search API（2026-09-03）；S2 anthropics/skills commits；S3 obra/superpowers commits；S5 anthropics/skills issues；S9 Anthropic engineering blog（2025-10-16，开放标准 2025-12-18）；S10 Skill authoring best practices；S17 EvoSkills；S18 SkillFoundry；S24 Qiita 完全ガイド；S31/S33/S47 公众号三源；S35 CSDN 自进化闭环；S38-S43 知乎六源；S44/S45 SkillOpt（arXiv+官方页）；S46 taxonomy；S48 SkillWeaver；S49-S51 核实员 contrarian 新源。

## Meta

- Requested Mode: deep / Effective Mode: deep（主 wave 2/2：wave1=cn+glb+zhihu+github 四通道并行；wave2=gap 轮 2 查询 + 读取员 5 URL；无第 3 wave）
- lane 健康：github ok（8/8 次用满）；glb ok（5+1 查询）；cn 降级（sogou 反爬吃掉 wave1 两条查询，fallback 引擎+gap 轮恢复）；zhihu ok（2/4）；prime 1/2 空结果（p1 返回 []，已由 glb q6/q7 覆盖，未再重试）；human inbox 空
- 限额核对：prime 2/3、zhihu 2/4、github 8/8、主 wave 2/2 + gap 1/1、核实员 contrarian 6/6
- 模型降级：无（核实员 opus spawn 成功，未触发 400 回退）
- reused/fresh：reused 0 / fresh 28（其中 prime p1 空结果 1 条、baidu 302 失败 1 条）
- 降级记录：Write 首选名 report.md 被守卫拦截 → 按 SKILL 降级链改用 research-report.md（meta.json report_file 字段已记）；auto-memory 写回不可用（编排者无 auto-memory 工具）→ 以本报告 + INDEX.md 行替代
- 任务目录：reports/research/claude-skill-eco
