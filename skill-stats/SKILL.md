---
name: skill-stats
description: >
  Analyze skill usage statistics from .stats/usage.jsonl. Shows usage ranking, time trends,
  zero-use candidates for deletion, and optimization recommendations. Use when user says
  "skill stats", "skill统计", "skill使用情况", "哪些skill没人用", "/skill-stats", or wants
  to audit skill quality and usage patterns.
---

# Skill Stats — 使用统计与质量分析

分析 `.stats/usage.jsonl` 日志，生成 skill/subagent 使用统计报告。

## 数据格式

`usage.jsonl` 每行一个 JSON 事件，`type` 字段区分：

- `"skill"` — Skill 工具调用（PostToolUse hook）
- `"subagent"` — Subagent 调用（SubagentStop hook）

新格式字段：`ts, type, skill/subagent, model?, duration_ms?, session_id?, tokens?{input, output}`
旧格式（兼容）：`ts, skill`（缺少 type 字段视为 skill）

## 执行流程

### 1. 读取数据

读取 `/Users/ganjie/skills/.stats/usage.jsonl`。若文件不存在或为空，报告"无数据，需先使用一段时间积累日志"。

### 2. 统计分析

用代码（非手动）计算以下指标：

**Skill 使用排行**（type=skill 或旧格式）：
- 统计每个 skill 的总调用次数
- 按次数降序排列
- 标注 zero-use skill（日志中从未出现的 skill）

**Subagent 使用排行**（type=subagent）：
- 每个 subagent 的调用次数、总 token 消耗（如有）、平均耗时（如有）
- 按调用次数降序

**时间趋势**：
- 最近 7 天 / 30 天 / 总计 调用次数
- 活跃（7天内有调用）vs 闲置

**Token 成本分析**（仅新格式有 tokens 字段时）：
- 每个 skill/subagent 的总 input + output token
- TOP 5 token 消耗者
- 估算成本（按 sonnet $3/opus $15 per MTok input 估算）

**Darwin 交叉**（若 `darwin-skill/results.tsv` 存在）：
- 高使用+低分 → 优化优先级最高
- 零使用 → 删除候选

**分类统计**：
- 原创技能 vs mattpocock skills 各自使用率
- Hidden vs visible skills 使用率

### 3. 生成报告

输出格式：

```
## Skill Stats Report（统计周期：YYYY-MM-DD ~ YYYY-MM-DD）

### Skill 使用排行 TOP 10
| # | Skill | 调用次数 | 7天 | 30天 | 建议 |
|---|-------|---------|-----|------|------|

### Subagent 使用排行
| # | Subagent | 调用次数 | 总 tokens | 平均耗时ms | 建议 |
|---|----------|---------|----------|-----------|------|

### Token 消耗 TOP 5
| # | Skill/Subagent | Input Tok | Output Tok | 估算成本 |
...

### 闲置 Skills（30天未使用）
| Skill | 上次使用 | 建议 |
...

### 零使用 Skills（从未被调用）
| Skill | 类型 | 建议 |
...

### 分类概览
| 分类 | 数量 | 使用率 |
...

### 优化建议
- 🔴 优化: [skill]（高频低质）
- 🟡 观察: [skill]（中频但近期下降）
- 🟢 健康: [skill]（高频高质）
- ⚪ 删除候选: [skill]（零使用）
```

### 4. 补充操作

用户可以追加指令：
- "删除零使用的" → 列出零使用 skill 确认后删除
- "优化 xxx" → 调用 darwin-skill 对目标 skill 评分优化
- "导出" → 将报告保存到 `.stats/report-YYYY-MM-DD.md`

## 获取完整 skill 列表

```bash
ls -d /Users/ganjie/skills/*/SKILL.md | sed 's|.*/\([^/]*\)/SKILL.md|\1|' | sort
```
