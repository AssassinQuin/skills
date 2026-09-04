# PIPELINE_STATE — 小说的骨架：好提纲成就好故事

> cangjie-skill 流水线状态 · 断点续跑用 · 每完成一个阶段更新

## 基本信息
- 书名：小说的骨架：好提纲成就好故事（[美]凯蒂·维兰德 / K.M. Weiland，邢玮 译）
- 原书：Outlining Your Novel (2011)，中译 2018 后浪
- 源文本：PDF 208 页，提取 90071 字（/tmp/novel_skeleton_full.txt）
- 处理时间：2026-08-26

## 阶段进度

- [x] **阶段 0 — 整书理解** → `BOOK_OVERVIEW.md` ✅
- [x] **阶段 1 — 5 个 extractor 并行提取** → `candidates/`（框架 32 + 原则 69 + 案例 49 + 反例 44 + 术语 18）
- [x] **阶段 1.5 — 三重验证筛选** → `verified.md`（15 单元）+ `rejected/REJECTED.md`
- [x] **阶段 2 — RIA++ 构造 skill** → 15 原子 SKILL.md + 1 编排 SKILL.md
- [x] **阶段 3 — Zettelkasten 链接** → `INDEX.md` + `GLOSSARY.md` + 各 skill related_skills
- [x] **阶段 4 — 压力测试** → 16 个 test-prompts.json + `test-results.md`（盲测 18/18 通过）
- [x] **阶段 5 — 交付** → `DIGEST.md` ✅ + 已安装到 `~/.claude/skills/`（16 个 skill 全量复制）

## 产出清单（16 个 skill）
- 总编排: novel-outline-pipeline
- 15 原子工序: outline-mindset, what-if-brainstorm, premise-sentence, scene-map, character-engine, conflict-engine, theme-discovery, inciting-event, backstory-iceberg, character-interview, setting-worldbuild, pov-selection, structure-three-act, reverse-outline, condense-outline

## 下一步
DIGEST.md 已产出。剩余：用户确认安装位置（项目级 `.claude/skills/` 推荐 / 用户级 `~/.claude/skills/` / 只留仓库），然后复制 skill 目录。

## 关键决策记录
- slug 用 `novel-skeleton`（沿用 plot-thickens 的英文 kebab-case 惯例）
- 源文本是中文译本（无英文原文），R 段引用中文译本 ≤150 字，I 段用自己的话重写、不照搬译者句式
