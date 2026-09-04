---
name: skill-stats
description: 报告 skill 与 subagent 的使用统计（本地 usage 日志）。Use when 用户问「skill 统计」「skill 用量」「我用了哪些 skill」「哪个 skill 用得多」「最近 skill/subagent 活动」「skill stats」「which skills do I use」.
---

# skill-stats

报告 `.stats/usage.jsonl` 中的 skill / subagent 调用统计，数据由 PostToolUse:Skill 与 SubagentStop hooks 写入。

## 用法

```bash
bash /Users/ganjie/skills/.stats/stats.sh                       # 完整报告
bash /Users/ganjie/skills/.stats/stats.sh --skill coder         # 按名称过滤
bash /Users/ganjie/skills/.stats/stats.sh --since 2026-07-01    # 某日期之后
bash /Users/ganjie/skills/.stats/stats.sh --last 20             # 最近 N 条
bash /Users/ganjie/skills/.stats/stats.sh --raw                 # 原始 JSONL（管道用）
```

过滤器可组合：`--skill coder --since 2026-06-01 --last 30`。

## 报告内容

- 总条目数与日期范围
- Top 15 skill（已归一化命名空间前缀，如 superpowers:xxx → xxx）
- Subagent 按名称与 model 分布
- 最近 N 条（默认 5）

## 数据源

`/Users/ganjie/skills/.stats/usage.jsonl` — JSONL，由以下 hook 写入：

- `log-skill.sh` — PostToolUse hook，matcher `Skill`（2026-09-04 起：tokens 从 transcript usage 抽取，含 outcome / resp_bytes 字段）
- `log-subagent.sh` — SubagentStop hook

每条记录：`{ts, type, skill|subagent, duration_ms, session_id, tokens:{input,output}, outcome, resp_bytes}`。

日志为空 = 安装统计后没有 skill 被调用。jq 报错 = 日志可能损坏，用 `--raw` 检查并修剪坏行。

> token 账本 / 健康诊断 / 部署审计等维护工具在 `scripts/`（ledger.sh / deploy.sh），使用说明见仓库 README.md——不在本 skill 职责内。
