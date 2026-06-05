# Vibe-Noveling + Novel Writer Workflow 深度分析

> 调研日期: 2026-05-31 | 来源: GitHub README完整内容 + 仓库结构分析

---

## 一、Vibe-Noveling（TulanCN）— S级仓库分析

**仓库**: `TulanCN/vibe-noveling` | Stars: 未获取（搜索受限） | 许可: MIT
**定位**: 完整中文网络小说创作工作流，基于Claude Code自定义Skill + Agent体系。**针对GLM-5/GLM-5.1深度定制优化。**

### 1.1 架构概览

```
13个技能(Skills) + 4个内置子Agent + 知识图谱(JSON) + 文件系统存储
```

**关键设计决策**：
- 文件驱动（memory/目录），非数据库驱动
- 针对GLM模型优化（注意：需关闭思考模式）
- 男频网文默认风格基线（主角装逼兑现优先）

### 1.2 技能体系（13个）

| 技能 | 触发词 | 核心功能 | books_creater对应 |
|------|--------|---------|------------------|
| `/novel-init` | 初始化 | 创建项目骨架（memory/chapters/CLAUDE.md） | novel-setup |
| `/novel-discuss` | 讨论 | 苏格拉底式对话+事件画布+剧情链产出 | novel-plan(部分) |
| `/booming` | 太平了 | 10套高烈度剧情爆破方案 | ❌ 无对应 |
| `/fuck-it` | 单章加戏 | 同终点15种加戏方向+3套强化方案 | ❌ 无对应 |
| `/novel-bookplan` | 全书大纲 | Save the Cat 15节拍全书/分卷规划 | novel-plan |
| `/novel-write` | 写章节 | 事件卡→强制反思→写作→后处理 | novel-write |
| `/novel-revise` | 返修 | 标记式返修（加粗/删除线/斜体）+3种SSoT候选 | novel-fix |
| `/novel-sync` | 同步 | 更新知识图谱+past.md+future/ | writing_finish |
| `/novel-knowledge` | （内部） | 知识图谱搜索/创建/更新 | MCP工具集 |
| `/novel-obsidian` | Obsidian | 同步到Obsidian vault可视化 | ❌ 无对应 |
| `/novel-name` | 命名 | 8类命名生成器（Python脚本） | lorecraft+abilitycraft |
| `/novel-snapshot` | 快照 | 版本备份与回滚 | git |
| `/novel-progress` | 进度 | HTML字数统计饼图 | ❌ 无对应 |

### 1.3 内置子Agent（4个）

| Agent | 用途 | books_creater对应 |
|-------|------|------------------|
| `context-collector` | 为novel-write收集并缓存章节上下文 | get_chapter_context(MCP) |
| `consistency-guard` | 一致性检查 | validate_chapter(MCP) |
| `writer-zhouzi` | 会说话的肘子风格底稿（快节奏战斗+临场决断） | ❌ 无对应（我们用author-voice引擎） |
| `writer-dazhongma` | 大仲马风格高光稿（精密布局+戏剧交锋） | ❌ 无对应 |

💡**独特点**：两个writer subagent是不同写作风格的"底稿生成器"，一个负责快节奏战斗（肘子风），一个负责精密戏剧（大仲马风）。这是"多Agent多视角"的实际应用。

### 1.4 核心工作流（6阶段）

```
init → discuss(设定/事件画布/剧情链) → bookplan(可选) → write → revise → sync
```

**关键设计**：
- 剧情链在`novel-discuss`中确认后**不再额外确认**，直接进入正文
- `novel-write`从事件卡读剧情链→**强制反思**（四维定调+预判翻车点+核心瞬间+禁用句式）→写作→后处理
- 后处理：一致性校验 → AI味检测(10项) → 独立润色
- 返修是**标记式**：用户在正文中标记（加粗=扩写/删除线=简写/斜体=润色），为每个标记生成3种SSoT候选

### 1.5 知识图谱

- JSON文件驱动（`memory/_graph.json` + `_index.json`）
- 实体分类：characters/locations/factions/items/concepts
- 过去剧情：`memory/past.md`
- 未来规划：`memory/future/`（全书锚点/主线线程/分卷蓝图/事件规划）

### 1.6 Save the Cat 15节拍

内置Blake Snyder的15节拍故事结构：
- 全书层：15节拍锚定全书节奏
- 分卷层：每卷的职责段、卷内位置、关键状态变化
- 单章层：由事件讨论产出，不预设章节数

### 1.7 优缺点分析

**优点** ✅：

| 维度 | 说明 |
|------|------|
| **GLM深度优化** | 针对我们实际使用的模型定制，实用价值高 |
| **booming/fuck-it** | 创意爆破+加戏模式，解决"剧情太平"痛点，我们没有 |
| **标记式返修** | 加粗/删除线/斜体+3种候选，比我们的review→fix更轻量直接 |
| **强制反思** | 四维定调→预判翻车→核心瞬间→禁用句式，从源头防AI腔 |
| **双writer Agent** | 肘子风+大仲马风，多风格底稿可借鉴 |
| **关闭思考模式** | 针对GLM的关键配置——过度思考会丧失创造性 |
| **完整设计文档** | `docs/plans/`记录每个设计决策的演进过程 |

**缺点** ❌：

| 维度 | 说明 |
|------|------|
| **文件驱动** | JSON知识图谱 vs 我们的libsql DB，缺乏结构化查询能力 |
| **男频默认** | "装逼兑现优先"的默认基线与我们的群像/暗线设计冲突 |
| **无伏笔系统** | 没有伏笔埋设/回收追踪，我们有完整的foreshadow系统 |
| **无角色蒸馏** | 没有7层角色蒸馏追踪，人物一致性靠memory文件 |
| **无世界览权威源** | 设定散落在entity文件中，缺乏我们的world_query分层加载 |
| **无写作引擎系统** | 没有scene-composition/dialogue/action等引擎文件 |
| **单卷规划** | 无百万字马拉松的卷级+跨卷规划体系 |
| **无MCP** | 所有数据操作通过文件读写，无MCP工具层 |

---

## 二、Novel Writer Workflow Guide（wordflowlab）

**仓库**: `wordflowlab/novel-writer-skills` | 许可: MIT
**定位**: 七步方法论的Claude Code专用实现，带Agent Skills自动激活+插件系统。

### 2.1 七步方法论

| 步骤 | 命令 | 功能 | 输出 |
|------|------|------|------|
| 1 | `/constitution` | 创建创作宪法 | `.specify/memory/constitution.md` |
| 2 | `/specify` | 定义故事规格 | `stories/[name]/specification.md` |
| 3 | `/clarify` | 澄清模糊点（5个问题） | 更新specification.md |
| 4 | `/plan` | 制定创作计划 | `stories/[name]/creative-plan.md` |
| 5 | `/tasks` | 分解任务清单 | `stories/[name]/tasks.md` |
| 6 | `/write` | 执行章节写作 | `stories/[name]/content/chapter-XX.md` |
| 7 | `/analyze` | 质量验证分析 | 分析报告（框架/内容双模式） |

### 2.2 Agent Skills（自动激活）

| 类别 | 自动触发条件 | 内容 |
|------|------------|------|
| 类型知识库 | 提及特定类型时 | 言情/悬疑/奇幻惯例 |
| 写作技巧 | 写作过程中 | 对话/场景/角色弧线 |
| 一致性检查 | 后台持续监控 | 角色/世界观/时间线 |
| 工作流引导 | 偏离方法论时 | 引导回到七步流程 |

### 2.3 追踪系统

| 命令 | 功能 |
|------|------|
| `/track-init` | 初始化追踪 |
| `/track` | 综合追踪更新 |
| `/plot-check` | 情节一致性检查 |
| `/timeline` | 时间线管理 |
| `/relations` | 角色关系追踪 |
| `/world-check` | 世界观验证 |

### 2.4 插件系统

- `authentic-voice`：真实人声写作插件
- npm安装方式：`npm install -g novel-writer-skills`
- CLI工具：`novelwrite init/upgrade/check/plugin:add/plugin:remove`

### 2.5 优缺点分析

**优点** ✅：

| 维度 | 说明 |
|------|------|
| **七步方法论清晰** | 从宪法→规格→澄清→计划→任务→写作→分析，每步有明确输入输出 |
| **Agent Skills自动激活** | 类型知识库/写作技巧/一致性检查自动触发，无需手动 |
| **插件系统** | 可扩展架构（authentic-voice等） |
| **npm安装** | 标准化安装流程，比手动复制更规范 |
| **追踪系统** | plot/timeline/relations/world四个维度追踪 |
| **CLI独立使用** | 不依赖Claude Code也能工作 |

**缺点** ❌：

| 维度 | 说明 |
|------|------|
| **通用型设计** | 面向英文小说为主，中文网文适配不足 |
| **无子Agent** | 没有内置sub-agent，全部靠skill+slash command |
| **文件存储** | JSON追踪数据，无DB，缺乏结构化查询 |
| **无伏笔/蒸馏** | 与vibe-noveling一样，缺少伏笔管理和角色蒸馏 |
| **单本设计** | 无百万字多卷规划能力 |
| **无写作引擎** | 靠Agent Skills知识库替代，缺乏分层引擎系统 |
| **规格: 未标明stars** | 社区验证不足 |

---

## 三、与books_creater的架构对比

| 维度 | books_creater | vibe-noveling | novel-writer-skills |
|------|--------------|---------------|-------------------|
| **存储** | libsql DB(MCP) | JSON文件 | JSON/MD文件 |
| **数据操作** | 56个MCP工具 | 文件读写 | 文件读写+CLI脚本 |
| **技能数** | 6个核心skill | 13个skill | 7个命令+Agent Skills |
| **子Agent** | 自定义(.claude/agents/) | 4个内置(writer×2+guard+collector) | 无内置 |
| **伏笔系统** | ✅ 完整(埋设/回收/密度控制) | ❌ | ❌ |
| **角色蒸馏** | ✅ 7层(决策/认知/关系/声音/能力/弧线/快照) | ❌ | ❌ |
| **写作引擎** | ✅ 20+引擎文件(场景/对话/动作/战斗/反AI...) | ❌ 靠skill内嵌 | ❌ 靠Agent Skills知识库 |
| **AI味检测** | ✅ validate_chapter+writing_rules表 | ✅ 10项检测清单 | ⚠️ analyze命令 |
| **世界览权威源** | ✅ DB+分层加载(smart/volume/targeted) | ⚠️ JSON图谱 | ⚠️ JSON追踪 |
| **百万字规划** | ✅ 卷级+跨卷+暗线+配角轮换 | ⚠️ Save the Cat分卷 | ❌ 单本设计 |
| **返修模式** | review→fix两步 | 标记式一步(加粗/删除线/斜体) | ❌ analyze后手动 |
| **创意工具** | lorecraft术语+abilitycraft能力 | booming爆破+fuck-it加戏 | ❌ |
| **GLM优化** | ⚠️ 部分适配 | ✅ 深度定制 | ❌ |
| **模型选择** | R5.1分层(haiku/sonnet/opus) | ❌ 单模型 | ❌ 单模型 |
| **术语系统** | ✅ term-map+文化根脉映射 | ❌ | ❌ |

---

## 四、可借鉴的点

### 从vibe-noveling借鉴

| 优先级 | 功能 | 理由 | 实施难度 |
|--------|------|------|---------|
| **P0** | 关闭思考模式配置 | 针对GLM的关键优化，我们的项目也跑GLM | 低（CLAUDE.md加一句） |
| **P1** | booming剧情爆破 | 解决"剧情太平"痛点，我们没有这个能力 | 中（新建skill或引擎） |
| **P1** | 标记式返修 | 比review→fix更轻量直接，用户体验更好 | 中（改造novel-fix） |
| **P1** | 强制反思（四维定调+预判翻车+核心瞬间+禁用句式） | 写作前的结构化反思，我们只在validate阶段检查 | 低（加入novel-write流程） |
| **P2** | 双writer Agent（多风格底稿） | 可扩展为多作者声音底稿 | 高 |
| **P2** | fuck-it加戏模式 | 与booming互补，不改终点只加过程 | 中 |
| **P3** | 15种单章加戏方向 | fuck-it的内置参考库 | 低（写参考文件） |

### 从novel-writer-skills借鉴

| 优先级 | 功能 | 理由 | 实施难度 |
|--------|------|------|---------|
| **P1** | 创作宪法（constitution） | 全局约束层，我们的writing_spec部分覆盖 | 低（已有world_upsert category=writing_spec） |
| **P2** | Agent Skills自动激活 | 根据上下文自动加载类型知识库，我们的skill需手动触发 | 高 |
| **P3** | npm安装/CLI工具 | 标准化安装，我们目前手动配置 | 高 |

### 不需要借鉴的

- 文件驱动存储（我们的DB方案更优）
- 男频默认基线（我们做群像/暗线）
- JSON知识图谱（我们的MCP+DB更强大）
- 单本书设计（我们面向百万字马拉松）

---

## 五、总结判断

### vibe-noveling：**值得深入研究，部分功能可移植**

**核心价值**：它是目前发现的**唯一针对GLM模型深度优化的**中文网文写作插件。关闭思考模式、强制反思、针对GLM的prompt调整等，对我们的项目有直接参考价值。

**最佳借鉴**：booming剧情爆破 + 标记式返修 + 关闭思考模式配置 + 强制反思流程。

**不推荐全面采用的原因**：文件驱动架构、缺少伏笔/蒸馏/引擎系统、男频默认基线与我们不匹配。我们的DB+MCP架构在数据管理维度远超。

### novel-writer-skills：**参考价值有限**

七步方法论有启发性（特别是constitution+clarify的前期约束），但面向英文通用小说，中文网文适配不足。追踪系统（plot/timeline/relations/world）的设计思路可参考，但实现方式（JSON文件）不如我们的DB方案。

**结论**：两个插件都不能替代我们的系统。vibe-noveling有几个值得"拿来"的创意功能（booming/标记返修/强制反思/GLM优化），可以作为引擎文件或skill参考引入。novel-writer-skills的七步方法论和自动激活思路可参考。
