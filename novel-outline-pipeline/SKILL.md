---
name: novel-outline-pipeline
description: |
  总编排：把用户零散的人物经历、场景、点子，按维兰德的方法串成一条完整流水线，最终输出一份完整小说提纲。
  何时调用: 用户说"帮我写提纲""整理我的素材成提纲""我有些点子/人物/场景，帮我变成大纲"，或想从零开始搭一本小说的提纲。
  关键 trigger: "帮我写提纲""整理素材成提纲""把点子变成大纲""写大纲""outline my story""help me outline"。
  何时不调用: 用户只要某一道工序（如"只帮我做前提句""只帮我想冲突"）——直接调对应子 skill，不必跑全流程；或用户要的是正文写作而非提纲。
source_book: 《小说的骨架：好提纲成就好故事》 凯蒂·维兰德 (K.M. Weiland)
source_chapter: 全书（第一至十一章的完整流程）
tags: [pipeline, orchestrator, outlining, workflow, meta]
related_skills:
  - slug: outline-mindset
    relation: depends-on
  - slug: what-if-brainstorm
    relation: depends-on
  - slug: premise-sentence
    relation: depends-on
  - slug: scene-map
    relation: depends-on
  - slug: character-engine
    relation: depends-on
  - slug: conflict-engine
    relation: depends-on
  - slug: theme-discovery
    relation: depends-on
  - slug: inciting-event
    relation: depends-on
  - slug: backstory-iceberg
    relation: depends-on
  - slug: character-interview
    relation: depends-on
  - slug: setting-worldbuild
    relation: depends-on
  - slug: pov-selection
    relation: depends-on
  - slug: structure-three-act
    relation: depends-on
  - slug: reverse-outline
    relation: depends-on
  - slug: condense-outline
    relation: depends-on
---

# 小说提纲流水线（零散素材 → 完整提纲）

## R — 原文 (Reading)

> "我们从前提开始，逐步搭建出你小说的提纲，勾勒出你小说的轮廓……写提纲，我们除了关注小说布局外，还要关注讲故事的技巧。"
>
> — 凯蒂·维兰德，序

---

## I — 这套流程在做什么 (Interpretation)

这是本书蒸馏出的**总编排层**：把 15 道原子工序（每个都是一个独立 skill）串成一条流水线，输入是用户随手给的碎片——人物经历、场景、点子，输出是一份**完整小说提纲**。

流水线按维兰德自己的方法排序，共 8 个阶段，每阶段产出可确认的中间产物：

| 阶段 | 调用的子 skill | 产出 |
|---|---|---|
| 0 摆正心态 | `outline-mindset` | 用户认同"提纲是指南非铁律" |
| 1 定义小说 | `what-if-brainstorm` → `premise-sentence` | 一句前提句 |
| 2 盘点场景 | `scene-map` | 场景清单 + 漏洞标记 |
| 3 核心元素 | `character-engine` + `conflict-engine` + `theme-discovery` | 动机/冲突/主题 |
| 4 人物深挖 | `inciting-event` + `backstory-iceberg` + `character-interview` | 人物档案 + 激发事件 |
| 5 背景世界 | `setting-worldbuild` | 背景四问 + 世界观 |
| 6 搭结构 | `pov-selection` + `structure-three-act` + `reverse-outline` | 三幕结构 + 视角 |
| 7 精简成稿 | `condense-outline` | 可用的精简版提纲 |

关键原则：**每阶段结束后停下来，把中间产物给用户看、让用户确认或修正**，不要一口气跑到最后——这既是维兰德"提纲是活的、随时调整"的立场，也符合"你给素材、我帮你整理"的协作方式。

---

## A1 — 书中的应用 (Past Application)

### 案例: 维兰德自己的完整流程
- **问题**: 从模糊设想到能直接写初稿，怎么走？
- **方法论的使用**: 以《守望黎明》为例——先"如果"问句，再前提句，再场景示意图，再动机/冲突/主题，再幕后故事/人物采访，再背景，再扩展版提纲，最后精简版提纲。
- **结论**: 每一步都聚焦一件小事，层层搭建。
- **结果**: 从零散想法到一份能直接指导写作的路线图。

---

## A2 — 触发场景 (Future Trigger) ★

### 用户会在什么情境下需要这个 skill?

1. 用户手里有零散素材（人物经历、几个场景、几个点子），想整理成一份完整提纲。
2. 用户是新手，不知道提纲是什么、从哪下手，需要被一步步带着走。
3. 用户想开一本新书，但只有模糊想法。
4. 用户已经写了一部分，想回头补一份系统的提纲。

### 语言信号

- "帮我写提纲""整理这些素材成提纲""把点子变成大纲"
- "我有几个人物/场景/点子，帮我串起来"
- "不知道提纲怎么写""从零开始写大纲"
- "help me outline my story""turn my ideas into an outline"

### 与相邻 skill 的区分（初稿）

- 与 15 个原子 skill 的区别: 本 skill 是**入口**，负责判断"该跑全流程还是只跑某一步"，并把各阶段串起来；具体每道工序交给对应子 skill。
- 与 `outline-mindset` 的区别: 本 skill 组织执行，mindset 只解决"认知/心态"。

---

## E — 可执行步骤 (Execution)

**第一步：收集素材**
- 问用户：你有哪些人物经历、场景、点子？（哪怕是碎片、关键词都行）
- 完成标准: 素材清单落成文字，用户已把脑子里有的都倒出来。

**第二步：跑 8 个阶段，每阶段给中间产物**
- 阶段 0 摆正心态 → 阶段 1 前提句 → 阶段 2 场景 → 阶段 3 核心元素 → 阶段 4 人物 → 阶段 5 背景 → 阶段 6 结构 → 阶段 7 精简成稿。
- 每个阶段调用对应子 skill（见上表），完成后**暂停**，把产物给用户确认。
- 判停条件: 用户在某阶段说"够了/只想要这些"→ 停在该阶段，不硬跑后续。

**第三步：组装完整提纲**
- 把 8 个阶段的产物整合成一份结构化的完整提纲文档（前提句 + 场景 + 人物 + 冲突/主题 + 激发事件 + 背景 + 三幕 + 精简路线图）。
- 完成标准: 用户拿到一份能直接指导写初稿的提纲，且中途每个决策都经过用户确认。

---

## B — 边界 (Boundary) ★

### 不要在以下情况使用此 skill

- 用户只要某一道工序（只写前提句/只想冲突）——直接调对应子 skill，别跑全流程。
- 用户要写的是**正文/初稿**而非提纲——本流水线的终点是提纲，不是成稿。
- 用户是斯蒂芬·金式的即兴创作者、明确不要提纲——尊重，不强跑（见 outline-mindset 的边界）。

### 作者在书中警告的失败模式

- **把提纲当铁律跑到底**：流水线是指南不是流水账，任何阶段冒出更好的想法，都要允许回头调整。
- **一口气跑完不给用户看**：提纲必须让用户参与确认，否则"整理素材"就变成了"替用户做主"。

### 作者的盲点 / 时代局限

- 本流水线是西方"单主人公 + 三幕结构"的传统范式；用于**网文**（超长篇、多线、爽感驱动）时，需把"全书提纲"降级为"单卷/单条主线的提纲"，并让各子 skill 的 B 段"文学性 vs 网文"张力由用户/现有网文 skill 承接。

### 容易混淆的邻近方法论

- 与"直接写正文"的区分: 本流水线只做提纲；写正文是 story-long-write 等网文写作 skill 的职责。

---

## 相关 skills

- **depends-on** 全部 15 个原子 skill — 本 skill 是总编排，按阶段调用它们（见 I 段的流水线表）。
- **contrasts-with** 无（本 skill 与原子 skill 是"编排 vs 工序"的关系，非并列可选）。

---

## 审计信息

- **验证通过**: 编排层（非独立方法论单元，由 15 个原子 skill 组合而成）
- **测试通过率**: 待阶段 4
- **蒸馏时间**: 2026-08-26
