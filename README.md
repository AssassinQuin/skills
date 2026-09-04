# skills — 全局 skill 仓库维护手册

> 本仓库是全局 skill 的**唯一实体源**。维护规则、判据、工具说明集中在本 README。
> 最近全量维护：2026-09-04（skill-stats 管理化改造 + 项目 skill 摘链 + MCP 清理 + 外部 skill 更新）。

## 架构

```
/Users/ganjie/skills/          ← 唯一实体源（本 repo，git 管理）
~/.claude/skills              → symlink 指向本 repo（部署入口）
项目 skill（story 系列等）      ← 留在项目 repo（books_creater），不链接到全局（2026-09-04 摘链 14 个）
```

- 全局 skill 统一在本仓库实体维护，各处以软链接消费
- 项目 skill 留在项目 repo，不进全局（`bash scripts/deploy.sh` 可审计拓扑）

## 红线：外部 skill 不做本地修改

外部克隆 skill 保持上游原样——不瘦身、不拆渐进披露、不改 frontmatter。本地修改会破坏与上游同步的能力（2026-09-04 教训：对 nuwa 的拆分在更新上游时全部作废）。

- 更新方法：`git clone --depth 1 <上游>` → 整目录替换（`rm -rf .git` 防嵌套）→ 保留运行产出（如 cangjie 的 `books/`）
- 它们的超 5K 等问题归上游，本仓库只记录不修改
- 只有自建 skill 才做 description 重写 / 瘦身 / 拆分

### 外部 skill 来源表

| 本地目录 | 上游 | 当前版本 | 更新日 |
|---|---|---|---|
| huashu-nuwa | alchaincyf/nuwa-skill | 2026-08-25 commit | 2026-09-04 |
| cangjie-skill | kangarooking/cangjie-skill | v2.5.0（Capability Bundle） | 2026-09-04 |

## 工具箱（scripts/）

| 脚本 | 作用 |
|---|---|
| `ledger.sh [--json]` | token 账本 + 健康诊断：僵尸 / 触发失败嫌疑 / 超5K / description 违规 |
| `deploy.sh` | 部署审计：symlink 拓扑、断链、哑目录、双实体漂移 |
| `setup-agents.sh` | agents 目录初始化（SessionStart hook 调用） |
| `search-mcp-benchmark.sh` | 搜索 MCP 基准测试 |

使用统计（skill-stats skill 职责）：`bash .stats/stats.sh`，数据由 hooks 写入 `.stats/usage.jsonl`。

## 判据速查（来源：reports/research/skill-improve/ 2026-09-04 调研）

- 官方硬限制仅两个：description ≤1,024 字符、name ≤64 字符；SKILL.md <5K tokens 是建议值非硬限
- 僵尸判定必须含年龄线：>60 天龄且 0 使用（≤60 天的 0 使用是 NEW_UNVERIFIED，不杀）
- token 优化优先级（反直觉）：MCP server schema > 全局 CLAUDE.md > 僵尸 skill 的 description 行 > SKILL.md body（body 仅触发时付费）
- 触发失败嫌疑：31–60 天龄 0 使用 → 查 description 触发词是否覆盖用户实际说法
- description 是路由层：压缩空间 ~48%，缺失/漂移 = 触发失效（SkillReducer 实证 26.4% 缺失）

## 数据流（.stats/）

```
PostToolUse:Skill → log-skill.sh → usage.jsonl（2026-09-04 起：tokens 从 transcript usage 抽取 + outcome/resp_bytes）
SubagentStop    → log-subagent.sh → usage.jsonl（type=subagent）
```

## 相关文件

- MCP server 清单（13 个，脱敏）：`reports/mcp-inventory-2026-09-04.json`
- 调研依据：`reports/research/skill-improve/`、`reports/research/claude-skill-eco/`、`reports/research/skill-evolve/`
- 执行记录：`reports/2026-09-04-p0-skill-improvement-execution.md`
