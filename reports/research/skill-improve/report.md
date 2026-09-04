# skill 进化完善方法论调研报告

> 日期：2026-09-04 ｜ 模式：deep → deep ｜ 查询：复用 8 / 新搜 22（含核实员 contrarian 6 次）
> 主题：如何帮助/驱动 skill 进化——流程/使用/命令更准确、token 更低、自我进化机制；GitHub 指标、多语言、论文、流行度与更新频率四维度。

## 摘要

skill 进化已有可量化的工程方法论：**token 层**——典型 skill body 加载 600–1,500 tokens，SkillReducer 对 55,315 个 skill 的实证发现 26.4% 缺 routing description、>60% body 内容不可行动，其两阶段压缩（description −48%、body −39%）反而让功能质量 **+2.8%**（less-is-more 效应）[S19]；**触发层**——官方硬限制只有 description ≤1,024 字符 / name ≤64 字符，<5K token 是建议值非硬上限 [S56][S57]，description 质量直接决定触发准确率；**进化层**——门控自进化（SkillOpt 的配对 A/B evalkit + McNemar 显著性检验 [S13]）是活跃方向，无门控自改（hermes）已被社区证伪。生态侧：标准 90 天内从 8k→17k indexed skills [S33]、~40 平台兼容 [S34]，但市场规模存在 **五口径冲突**（59,826 / 85k / 52,652 / 66.9 万 / 80 万级），且 65% 的 ClawHub 包从未被安装 [S26]——热度 ≠ 使用。多语言：中/日/法/西语社区均已有实操层内容，中文侧「skill 自进化」仍是空白（负结果）[S27]。

## 发现

### 一、GitHub 热度与活跃度（Q1）

**合集层头部集中、克隆泛滥**（2026-09-04 API 直查）：
- ComposioHQ/awesome-claude-skills **74,425★**/8,554 forks/1,396 open issues，创建 2025-10-17，最后 push 2026-08-10（git 停约 3.5 周）[S1]
- hesreallyhim/awesome-claude-code **53,467★**，最后 push 2026-09-04（当天仍活跃）[S2]；VoltAgent/awesome-agent-skills **33,715★**，宣称收录 1,000+ 跨 CLI skills，push 2026-09-02 [S3]
- 同名克隆效应：三个 "awesome-claude-skills"（ComposioHQ 74k / travisvn 14,955★ 停滞 4 个月 / BehiSecc 10,094★）描述几乎相同，均创建于 2025-10-16~17 两天内 [S1][S4][S5]——热点出现 48 小时内即被克隆
- **marketplace 仓库形态远弱于合集形态**：最大的 davepoon/buildwithclaude 仅 3,409★（push 2026-09-03 活跃）[S10]，netresearch/claude-code-marketplace 55★（挂 agentskills.io 开放标准）[S11]、artemnovichkov/skills 36★（skills.sh）[S12]，其余全部 ≤55★
- 昨日复用数据（claude-skill-eco 报告，2026-09-03 API）：obra/superpowers 280,991★、anthropics/skills 173,344★、alirezarezvani/claude-skills 25,445★，star 数存在 10–25% 注水争议 [本地P1]

**自进化/优化项目更新频率**（list_commits，2026-09-04）：
- **microsoft/SkillOpt：活跃**。2026-08-26 ×1 + 08-29 ×4 批量合并；#242 引入「paired A/B evalkit with McNemar and bootstrap CIs」——固定任务清单、配对二值结果 McNemar 检验、成功率差值 bootstrap CI、多种子方差带；评测目标覆盖 codex/claude/cursor/copilot 四种 CLI；PR 编号已到 249–261 区间，PR 流量可观 [S13]
- **ace-agent/ace：季度脉冲**。2026-02-18 → 03-12 → 05-19 → 08-24（#39 并行化 ComBEE 提案 + LLM reducer，距检索日 11 天）[S14]
- **NousResearch/hermes-agent-self-evolution：静默 2.5 个月**（最后 commit 2026-06-17），2026-03-09 曾由 hermes-agent-evolution 改名（旧名 404）。自报 Phase 1：DSPy+GEPA 把 arxiv skill 从 0.408 → 0.569（+39.5%）——自报 PDF，非独立验证；且昨日报告核实其 issue #172 存在「evolved 与 baseline 0 行 diff 却报 +30.7%」的评测完整性问题 [S15][本地P2]

**结论**：看更新频率比看 star 更能识别真项目——SkillOpt（微软、月级活跃、统计严谨化方向）> ace（季度脉冲但仍在动）> hermes（疑似弃坑）。合集仓库 star 集中但 git 活跃度分化严重，awesome 类仓库本身会腐烂（travisvn 版已停 4 个月）。

### 二、skill 质量改进方法论与 token 优化（Q2）

**成本结构实测**（ClaudeKit v2 全目录，tiktoken 兼容计数器，2026-03-02 发布/2026-06 v2 复测）[S16]：
- 典型 skill body 加载 **600–1,500 tokens**，工具密集型 3,000–4,000；全目录 5 kits/101 commands/19 skills/13 agents 合计 **82,197 tokens**
- 命令级分布：Lean <500（18%）/ Typical 500–900（41%）/ Substantial 900–1,400（29%）/ Heavy 1,400–2,200（10%）/ Tool-heavy 2,200–3,500（2%）；均值 814、中位 ~720；最轻 390（breadcrumb schema 生成器）、最重 ~3,100（/video clone）
- **三层成本模型**：① always-on = 名称+description 行（15–40 tokens/条，25 条命令 ≈ 500–1,000 tokens 常驻）；② on-demand = body（600–1,500，仅调用时加载）；③ on-demand = reference 文件（可能永不加载）
- **审计优先级（反直觉排序）**：真正吃 context 的是 1) 未用的 MCP server tool schema（5k–15k/个，常驻）2) 膨胀的全局 CLAUDE.md（数千 tokens）3) 几十条装而不用的 description 行 4) command body（只在触发时付费）——「多数人从第 4 项开始优化，而该从第 1 项开始」[S16]

**官方规范边界**（对抗核实后修正）[S56][S57]：
- **硬限制**仅两个：description ≤1,024 字符、name ≤64 字符（platform.claude.com 官方 best practices）
- 「SKILL.md <5,000 tokens」是 **建议值**（recommended），非硬上限；besthub 等二手源称「official 5K limit」属拔高 [S21][S57]
- 渐进披露三级：Discovery（metadata 进系统提示）→ Activation（body 按需加载）→ Execution（references/脚本按需）[S35]

**SkillReducer——迄今最大规模 skill 优化实证**（arXiv 2603.29919，v1 2026-03-31 / v2 2026-06-24，cs.SE）[S19]：
- 55,315 个公开 skill 实证：**26.4% 完全缺 routing description**、**>60% body 内容不可行动**（non-actionable）、reference 文件单次调用可注入数万 tokens
- 两阶段框架：Stage 1 优化路由层（压缩冗长 description + 用 adversarial delta debugging 生成缺失的）；Stage 2 用 taxonomy 分类 + 渐进披露重构 body（核心规则 vs 按需补充内容），带 faithfulness 校验与自纠错回路
- 效果：**description 压缩 48%、body 压缩 39%，功能质量反升 2.8%**（less-is-more：删非必需内容减少 context 干扰）；跨 4 家族 5 模型 retention 均值 0.965，迁移到独立 agent framework 有效；600 skills + SkillsBench 验证

**社区工具**：claude-token-estimator skill（v1.6.0，定价数据 2026-02-20）做逐 skill 计数 [S17]；ClaudeKit 的 `ck tokens` 在安装时重跑账目，使「每个 token 都被审过」成为发布纪律 [S16]。

**中文社区方法论**（知乎时间线 2026-03 → 07 → 08）[S30][S31][S32]：
- 四步框架（2026-08-30，8 个月 30+ skill 实践）：任务识别 → 方法抽象 → 规则迭代 → 能力沉淀；**skill 化判据 =「同一件事对 AI 重复交代过三遍以上」**；任务识别三条件（高频 + 有方法论 + 交付标准化）缺一不做；规则迭代靠真实 badcase 驱动；效率对比：第一个 skill 写 2 天，框架熟练后升级只要 0.5 小时 [S30]
- 新手坑（2026-07-08）：**「让 AI 自己写第一个 skill 是第一大坑——AI 学会了一切，只剩自己依旧愚蠢」**；必须人先亲手写第一遍以获得评估 skill 好坏的能力，再让 AI 辅助 [S31]；转述官方建议：SKILL.md ≤500 行、附加资源放子文档引用、用官方 skill-creator 创建/测试/评估（此「500 行」为转述，未见官方原文链接，存疑标注）[S31]
- Anthropic 内部经验转述（2026-03-18）：内部数百 skill 活跃使用；最好的 skill 清晰归属单一类别，跨类别 skill 令人困惑；**验证类 skill 价值极高，「值得让一位工程师花一周打磨」**（录制测试视频、每步强制编程断言）[S32]
- CSDN 侧（2026）：skill 被定义为「token 高效利用」机制，Claude Code/Cursor/Trae/OpenCode 均原生支持导入，含中文优化要点 [S27]

### 三、相关论文全景（Q3）

| 论文 | 核心贡献 | 与 skill 进化的关系 |
|---|---|---|
| **SkillReducer**（arXiv 2603.29919，2026-03/06）[S19] | 55,315 skills 实证 + 两阶段压缩框架 | **最直接**：description −48%/body −39% 且质量 +2.8%，证明「less-is-more」 |
| **SkillOpt**（arXiv 2605.23904 + microsoft/SkillOpt 仓库）[本地P2][S13] | 自进化 skill：证据采集→判断→有界编辑→held-out gate；52/52 SOTA 为自报 | 门控自进化参考实现；仓库 2026-08 仍在加统计严谨性（McNemar） |
| **ACE**（arXiv 2510.04618 + ace-agent/ace）[本地P2][S14] | delta 增量更新 playbook 防 context collapse | 增量维护而非重写；issue #11 揭示 >100K token playbook 膨胀风险 |
| **ACON**（arXiv 2510.00615，ICML 2026，Microsoft，v3 2026-06-01）[S22] | Agent Context Optimization：最优压缩长程 observations/history | 峰值 token 降 **26–54%** 且成功率提升，小模型最高 +46%；基准 AppWorld/OfficeBench——注意与 skill 压缩是**不同机制**，数字不可混用 |
| **ClawHub Security Signals**（arXiv 2606.01494，2026-06）[S55] | 67,453 个 skill 版本的安全数据集 | 独立佐证 ClawHub 规模量级与安全面 |
| 昨日已核（本地P2） | GEPA（进化式 prompt 优化，已进 DSPy）、SkillWeaver/ACLA/Voyager（skill acquisition 谱系）、hermes（DSPy+GEPA 自报 +39.5%） | 见 reports/research/skill-evolve/ |

**方法论收敛判断**（本报告 + 两份本地前序报告交叉）：有效进化的公共形状 = **量化基线 → 有界编辑 → 统计显著性 gate → 人工审批 → 负反馈回收**；每一步的失败案例都已出现（无 gate→hermes；无量化→「AI 自己写第一版」；无负反馈→重复提案）。

### 四、自进化机制与失败模式（Q4）

**活跃且严谨化的路线**：SkillOpt 2026-08-29 的 #242 把评测仪器统一为「固定任务清单 + 配对二值结果 + McNemar 检验 + bootstrap CI + 多种子方差带」[S13]——即进化收益必须过统计显著性，这是对「自报提升」风气的直接回应。其配置默认 learning_rate=4（编辑预算的学术版本）、use_gate=true [本地P2]。

**失败模式清单**（跨昨日报告 + 今日核实）：
1. **无门控自改**：hermes 静默 2.5 月，issue #172（0 行 diff 报 +30.7%）、#169/#171/#175（校验器恒挂、dspy API 漂移静默回退）[S15][本地P2]
2. **评测 harness 本身会坏**：anthropics/skills #1706——并行 trigger-eval worker 共享 commands 目录导致触发率坍缩 ~1/N（10w→6%）[本地P2]
3. **skill 膨胀**：ACE issue #11 playbook >100K tokens；SkillReducer 实证 >60% body 不可行动 [本地P2][S19]
4. **安全攻击面**：Zenity Black Hat USA 2026-08-06——typosquat 克隆热门 skill 后延迟注入恶意代码，一个恶意 skill 家族经 skills.sh 累计 **>170 万次安装**（aggregate installs，非独立用户数）[S43][S49][S51]；OpenClaw 官方 2026-02 口径 341 个恶意 ClawHub skill [S52]；1/27–29 单窗口 28 个、1/31–2/2 再 386 个恶意 skill [S53]；CVE-2026-1847（热门 skill DataBridge 沙箱绕过）[S54]；Snyk ToxicSkills：3,984 skills 扫描 13.4% critical、76 恶意 payload [本地P1]
5. **自动进化的审计灾难**：hermes 仓库曾积累 38.7k issues（昨日核实）[本地P2]

**中文社区空白**：截至 2026-09，CSDN/掘金/linuxdo 可搜范围内**没有任何 skill 自进化/评测体系的中文实践文章**——「skill 自我改进」讨论全部在英文侧 [S27][S29]（负结果，本身是采用阶段信号）。

### 五、多语言用户使用（Q5）

| 语言 | 状态 | 证据 |
|---|---|---|
| 日语 | 教程导入期（昨日判定，今日复用确认） | Qiita/Zenn 使い方/活用事例教程 [本地P1] |
| 中文 | **实操层最厚**：四步框架本土方法论 + 官方经验转述 + 新手坑帖，时间线 2026-03→08 持续演进；但无 GitHub 原生中文合集（昨日判定）、无自进化内容（今日负结果） | [S30][S31][S32][S27] |
| 法语 | 完整指南存在：Chipie Studio 2026-07-02 发布，覆盖 SKILL.md 格式/渐进披露/双安装路径/5 个 freelance 用例/法语资源索引（厂商博客带 CTA，存在性证据成立、中立性打折） | [S38] |
| 西班牙语 | 组织化社区：claude.rich（官方认证 Claude Community Ambassador，面向墨西哥/拉美，meetups+教学）；GitHub 西语合集 abracu/Claude-Skills | [S39][S40] |
| 官方 | claude.com/community 作为多语言社区枢纽 | [S41] |

**本地化惯例要点**：中文侧已出现「触发语法 + 中文优化」写法讨论 [S27]；但**未找到任何语言的量化对比**（如双语 description 对触发准确率的影响）——多语言优化目前全是定性实践，无基准数据（未解问题#2）。

### 六、流行趋势、市场规模与更新频率（Q6）

**标准增长**（Agent Skills 2025-12 开放标准化后）[S33][S34][S36]：
- 索引量：Week 1（12/19–25）~8,000 skills → Week 2（12/26–31）~17,000 → 2026-01-09 更多（原文截断）[S33]
- ~40 兼容平台、数百万已发布 skills（9 个月内跨厂商标准，OpenAI/Google DeepMind 等采纳）[S34][S36]；规格库在 github.com/agentskills/ [S37]
- ⚠️ 全部为二手博客源，无官方审计数字（核实员判定）

**市场规模——五口径冲突**（引用任何数字必须带口径+日期）：
| 口径 | 数字 | 来源/时点 |
|---|---|---|
| skills.sh registry + GitHub 合计 | **59,826** skills / 152M 安装 | Skillselion，2026-08-21 [S45] |
| ClawHub 全库 | **52,652** skills | Trent AI，2026-06-09 [S26] |
| 中文转述 | **85,000+** | 头条（无时点）[S47] |
| skills.sh 列表 | **~669,670** | Ry Walker Research（口径不明）[S46] |
| SkillsMP 索引 | **80 万级别** | 微信公众号，2026-08-28 [S48] |
- skills.sh 由 Vercel 2026-01-20 发布（「AI agent skills 的 npm」），上线 4 天 >110,000 次安装、覆盖 17 个 coding agent [S44]
- **安装 ≠ 使用**：Vercel Labs 观点——装几十上百个 skill 的用户「每天真正在用的不到 5%」[S48]

**ClawHub 解剖**（Trent AI 全量分析，2026-06-09；竞品博客带 CTA，细分百分比为单源，方向获多源佐证）[S26]：
- 全库 ≤99 天、中位包龄 26 天；中位包大小 5.2KB（98% <100KB）——「供应链一半是纯文本」
- **65% 包从未被安装、80% 零 star**、install/download 转化率 0.73%、中位下载 171 次
- 发布者幂律：18,358 maintainers，中位发布 1 个；top1（gora050）1,941 包占全库 3.7%，top3 近 8%；38 个 >100 包的账号发布量 > 底部 65%（11,989 个单包作者）合计
- 安全：45%（23,952）包在 SKILL.md 引用至少 1 个外部凭证（最多 13 个）；20,974 包 VirusTotal 标记 suspicious（**suspicious≠malicious**，脚本类误报率高）；**全部 52,652 包无一声明 license**；迭代与使用零相关（downloads↔versions r=0.04）
- 现象级样本：`self-improving-agent` 单包 384,735 下载/3,156★/6,126 安装——「自我进化」是市场需求最热的题材之一

**增长质量判断**：数量暴涨 + 使用稀薄 + 发布高度集中 + 安全欠账 = 典型注意力经济早期形态；对 skill 进化者的启示是**别把 registry 数字当采用率**，也别把「没有 star/安装」直接判死（star 与质量在该生态相关性弱）。

### 七、综合：本仓库可执行的 skill 进化清单

（吸收本地 P1/P2 两份前序报告裁决 + 本轮新证据）

**A. token 优化（新证据强化了既有结论）**
1. 先建**逐 skill token 账本**（`ck tokens` 模式：tiktoken 兼容计数、安装/审计时重跑）[S16]——SkillReducer 实证 26.4% 缺 description、>60% body 冗余，本仓库大概率同构
2. 优化顺序按三层成本模型排：先砍常驻层（未用 MCP schema、CLAUDE.md、僵尸 skill 的 description 行），再瘦身 body——不是反过来 [S16]
3. body 瘦身可激进：SkillReducer 的 −39% body 压缩伴随质量 +2.8%，「删内容减少 distraction」有实证 [S19]；官方建议 <5K token/文件 [S57]
4. description 是路由层不是描述层：48% 压缩空间 + 缺失即触发失效 [S19]，重写优先级最高（本地 P2 裁决一致）

**B. 准确性/触发**
5. 高频 skill 建 5–10 例触发评测集，A/B 用配对检验（McNemar 方向，SkillOpt #242）[S13]；警惕并行评测共享目录的坍缩 bug（anthropics/skills #1706）[本地P2]
6. 触发词双语（中文用户 + 英文 trigger 词并列），中文侧已有此惯例讨论 [S27]

**C. 进化机制**
7. 门控自进化骨架维持本地 P2 裁决（改5砍1补3 后值得建）；编辑预算默认值可锚定 SkillOpt learning_rate=4 [本地P2]
8. 借鉴 SkillReducer Stage 1 的「adversarial delta debugging 生成缺失 description」——本仓库 24/38 僵尸 + 描述漂移场景直接适用 [S19]
9. 人写第一版、AI 做迭代（知乎共识 + hermes 反例交叉验证）[S31][S15]

**D. 安全卫生**
10. 外部 skill 引入前跑 ToxicSkills 式扫描；license 缺失是全生态默认态，内部使用可容忍、对外发布需自声明 [S26][本地P1]

## 最强反驳

（contrarian pass，核实员 6 次定向搜索，攻击证据最少的核心结论）

1. **「渐进披露降 API 成本 40–60%」站不住**：该数字 chudi.dev 单源；同类主张谱系从 98%（chrisduffy [S58]、developersdigest [S59]）到 40–60% 到 ACON 论文的 26–54% [S22]，跨度 >2 倍且无第二来源支撑中段值；ACON 压缩的是 observations/history（机制不同），存在数字张冠李戴风险。**处置：本报告已把该数字降级为「区间性定性表述」，改引 ACON 26–54% 并注明机制差异。**
2. **市场规模数字比表面更不可信**：核实新增第五口径（SkillsMP 80 万级 [S48]），五口径互相否证且很可能各量不同对象（列表数/索引数/安装数/时点）——任何单一值都不可直接引用。
3. **Trent.ai ClawHub 数据利益相关**：文末有自家产品 CTA；但方向获 4+ 独立源佐证（CVE-2026-1847 [S54]、OpenClaw 月报 341 恶意 [S52]、arXiv 2606.01494 的 67,453 版本量级吻合 [S55]）；「20,974 suspicious」需保留 suspicious≠malicious 限定，65% 零安装等细分百分比仍属孤证。
4. **「<5K 上限」归因错位**：官方硬限制是 description ≤1,024 字符 [S56]；<5K 是 spec 建议值 [S57]，besthub 的「official limit」说法是二手拔高 [S21]。
5. **Zenity 1.7M 修正**：官方口径是「一个恶意 skill 家族累计 >170 万次安装（aggregate installs）」，**非独立用户数**——多源确认（Business Wire 通稿 [S49][S50]、TNW [S51]），事件本身反而被加强。
6. **未发现**：对 GitHub star 数（一手 API）、SkillReducer 论文数字（abstract 原文核对）、SkillOpt/ace/hermes 活跃度（一手 commits）、中文社区方法论帖的反驳证据均未发现。

## 未解问题

1. **[Q5 部分未答]** 多语言优化的量化效果：双语 description / 非英语触发词对触发准确率的影响无任何语言的基准数据——现有证据全是定性存在性证明。原因：该课题尚无公开评测。
2. **[Q6 口径]** skills.sh/生态规模的官方（Vercel/Anthropic）口径数字不存在，五口径无法仲裁。原因：官方未发布审计数据；如需精确值可放入本任务 inbox 投喂。
3. **[Q2 转述存疑]** 知乎帖转述的「官方建议 500 行内」未找到官方原文出处（官方可查的是 <5K tokens 建议 [S57]），二者可能是同一建议的不同表述，无法确认。
4. **[Q1 覆盖限]** 部分中腰部合集仓库（BehiSecc/heilcheng/wesammustafa/bergside 等）pushed_at 未取得（API minimal output 限制），活跃度判断仅覆盖头部。

## 引用

S1: ComposioHQ/awesome-claude-skills — https://github.com/ComposioHQ/awesome-claude-skills — github — 2026-09-04 数据
S2: hesreallyhim/awesome-claude-code — https://github.com/hesreallyhim/awesome-claude-code — github — 2026-09-04 数据
S3: VoltAgent/awesome-agent-skills — https://github.com/VoltAgent/awesome-agent-skills — github — 2026-09-04 数据
S4: travisvn/awesome-claude-skills — https://github.com/travisvn/awesome-claude-skills — github — 2026-09-04 数据
S5: BehiSecc/awesome-claude-skills — https://github.com/BehiSecc/awesome-claude-skills — github — 2026-09-04 数据
S6: heilcheng/awesome-agent-skills — https://github.com/heilcheng/awesome-agent-skills — github — 2026-09-04 数据
S8: bergside/awesome-design-skills — https://github.com/bergside/awesome-design-skills — github — 2026-09-04 数据
S10: davepoon/buildwithclaude — https://github.com/davepoon/buildwithclaude — github — 2026-09-04 数据
S11: netresearch/claude-code-marketplace — https://github.com/netresearch/claude-code-marketplace — github — 2026-09-04 数据
S12: artemnovichkov/skills — https://github.com/artemnovichkov/skills — github — 2026-09-04 数据
S13: microsoft/SkillOpt commits（#242 A/B evalkit McNemar） — https://github.com/microsoft/SkillOpt — github — 2026-08-29
S14: ace-agent/ace commits（#39 parallelize ComBEE） — https://github.com/ace-agent/ace — github — 2026-08-24
S15: NousResearch/hermes-agent-self-evolution commits — https://github.com/NousResearch/hermes-agent-self-evolution — github — 2026-06-17
S16: What Do Claude Code Skills Actually Cost in Tokens? We Measured the Full ClaudeKit Catalog — https://theclaudekit.com/blog/claude-code-skills-token-cost-measured — glb — 2026-03-02（v2 复测 2026-06）
S17: ADIGHB/claude-token-estimator — https://github.com/ADIGHB/claude-token-estimator — glb — 2026-02-20
S18: Reduce Claude Token Usage 60%: Progressive Disclosure — https://chudi.dev/blog/reduce-ai-token-usage-progressive-disclosure — glb — n.d.（单源，已降级引用）
S19: SkillReducer: Optimizing LLM Agent Skills for Token Efficiency（arXiv 2603.29919 v2） — https://arxiv.org/abs/2603.29919 — glb — 2026-06-24
S21: Why Anthropic Caps SKILL.md at Under 5K Tokens（二手拔高，已修正） — https://www.besthub.dev/articles/why-anthropic-caps-skill-md-at-under-5k-tokens-and-how-to-structure-yours-9310df28cb04 — glb — n.d.
S22: ACON: Optimizing Context Compression for Long-horizon LLM Agents（arXiv 2510.00615） — https://arxiv.org/abs/2510.00615 — glb — v3 2026-06-01
S26: ClawHub By the Numbers: What 52,652 Skills Reveal — https://trent.ai/blog/clawhub-by-the-numbers/ — glb — 2026-06-09
S27: 一分钟搞明白Skill — https://blog.csdn.net/hq354974212/article/details/161169672 — cn — n.d.
S29: Claude Code Skills 推荐：2026年最值得安装的10个AI技能 — https://juejin.cn/post/7637367613895393295 — cn — 2026
S30: Claude Code skill 方法论：四步框架 — https://zhuanlan.zhihu.com/p/2077335900044915391 — zhihu — 2026-08-30
S31: 【Claude Code新手思维】小白教程，Skill才是关键 — https://zhuanlan.zhihu.com/p/2058275010524059575 — zhihu — 2026-07-08
S32: 构建 Claude Code 的经验：Anthropic 如何运用 Skills 技能（转述） — https://zhuanlan.zhihu.com/p/2017597470947967164 — zhihu — 2026-03-18
S33: How Agent Skills Became AI's Most Important Standard in 90 Days — https://ai.gopubby.com/how-agent-skills-became-ais-most-important-standard-in-90-days-a66b6369b1b7 — prime — 2026-01
S34: The Agent Skills Ecosystem in 2026 — https://agentman.ai/blog/agent-skills-ecosystem-report-2026 — prime — 2026
S35: Agent Skills Overview — https://agentskills.io/home — prime/glb — current
S36: What Is Agent Skills as an Open Standard — https://www.mindstudio.ai/blog/agent-skills-open-standard-claude-openai-google — prime — 2026
S37: Agent Skills: The Open Standard（inference.sh） — https://inference.sh/blog/skills/agent-skills-overview — prime — 2026
S38: Skills Claude en français : le guide complet 2026 — https://www.chipiestudio.com/fr/blog/skills-claude-francais — glb — 2026-07-02
S39: claude.rich · Claude Community Ambassador（西语） — https://claude.rich/es — glb — n.d.
S40: abracu/Claude-Skills（西语合集） — https://github.com/abracu/Claude-Skills — glb — n.d.
S41: Community | Claude by Anthropic — https://claude.com/community — glb — n.d.
S43: Zenity 恶意 skill 报道（anomity 转述） — https://anomity.ai/blog/zenity-malicious-agent-skills-credential-theft/ — glb — 2026-08
S44: I analysed the top 10 skills on Vercel's new AI agent registry — https://blog.devgenius.io/i-analysed-the-top-10-skills-on-vercels-new-ai-agent-registry-480c69e9d481 — glb — 2026-01
S45: The State of AI Agent Skills 2026 — https://skillselion.com/state-of-ai-agent-skills-2026 — glb — 2026-08-21
S46: skills.sh | Ry Walker Research — https://rywalker.com/research/skills-sh — glb — n.d.
S47: 2026年最火爆的AI Agent Skills榜单（头条） — https://www.toutiao.com/article/7619600379650802185/ — glb — n.d.
S48: Skill太多不会选?find-skills帮你找到最合适的那个（含 SkillsMP 80 万级 + <5% 日用） — http://mp.weixin.qq.com/s?src=11&timestamp=1788496495 — cn — 2026-08-28
S49: Zenity Labs Uncovers 1.7 Million-Install Malicious Skills Campaign（Business Wire 通稿/tmcnet） — https://www.tmcnet.com/usubmit/2026/08/06/10426627.htm — glb — 2026-08-06
S50: 同通稿 Morningstar 版 — https://www.morningstar.com/news/business-wire/20260806707467/ — glb — 2026-08-06
S51: Malicious AI skills hit 1.7 million installs（TNW） — https://thenextweb.com/news/zenity-malicious-ai-skills-1-7m-installs-supply-chain-credential-theft — glb — 2026-08
S52: OpenClaw Security Report: February 2026（341 恶意 ClawHub skills） — https://insiderllm.com/guides/openclaw-security-report-february-2026/ — glb — 2026-02
S53: ClawHub Skills Are a Security Minefield — https://openclawpulse.com/clawhub-skills-security-warning/ — glb — n.d.
S54: ClawHub Security Advisory（CVE-2026-1847） — https://openclaws.io/blog/clawhub-security-advisory — glb — 2026-02
S55: ClawHub Security Signals 数据集（arXiv 2606.01494，67,453 版本） — https://arxiv.org/abs/2606.01494 — glb — 2026-06
S56: Skill authoring best practices — Claude Platform Docs（官方硬限制） — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices — glb — current
S57: Skills Format Specification（<5,000 tokens recommended） — https://williamzujkowski.github.io/standards/guides/SKILL_FORMAT_SPEC/ — glb — n.d.
S58: Claude Skills: The 98% Token Savings Architecture — https://chrisduffyigniteai.substack.com/p/claude-skills-the-98-token-savings — glb — n.d.
S59: Progressive Disclosure: How Claude Code Cut Token Usage by 98% — https://www.developersdigest.tech/blog/progressive-disclosure-claude-code — glb — n.d.
本地P1: claude-skill-eco 报告（2026-09-03） — reports/research/claude-skill-eco/ — human — 复用缓存查询 6 组
本地P2: skill-evolve 报告（2026-09-03） — reports/research/skill-evolve/ — human — 本地引用

## Meta

- lane 健康：github:ok（5 次调用，含 2 仓库搜索 + 3 list_commits）/ glb:降级（startpage 全程故障「Failed to extract token」，全部结果来自 duckduckgo；brave 2 次 429）/ cn:降级（搜狗两次反爬拦截，结果来自 csdn+juejin fallback；linuxdo 零返回）/ zhihu:ok（1 次命中）/ prime:ok（1 次直调）
- 降级记录：无 model 回退（搜索员 sonnet / 读取员 haiku / 核实员 opus 全部按规格执行）；glb/cn 引擎层降级见上
- 查询计数：queries.jsonl 共 30 行 = 复用 8（wave 0）+ 新搜 22（wave1 16 + wave2 2 + verifier 6）
- 任务目录：reports/research/skill-improve/
- 报告文件：report.md（Write 一次成功，无备选文件名启用）
