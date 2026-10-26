# skills — 全局 skill 仓库维护手册

> 本仓库是全局自建/已启用 skill 的**实体源**。维护规则、判据、工具说明集中在本 README。
> 最近专项维护：2026-10-26（vendor 迁移收口、MCP manifest 单源化、CC Switch 收缩为 provider/proxy/usage 控制面）。

## 架构

```
/Users/ganjie/skills/          ← 全局启用 skill 实体源（本 repo，git 管理）
~/.claude/skills              → symlink adapter
~/.codex/skills               → symlink adapter
~/.agents/skills              → Trae/通用 adapter
/Users/ganjie/skill-vendors/  ← 外部上游完整源码（不进入全局递归扫描）
config/mcp/inventory.json     ← 可迁移 MCP 的唯一设计清单（脱敏）
~/.cc-switch/                 ← provider/proxy/usage 控制面；MCP 同步已冻结
项目 skill（story 系列等）      ← 留在项目 repo，不链接到全局
```

- 全局启用 skill 统一在本仓库实体维护，各处以软链接消费
- 外部上游完整仓库只放在 `skill-vendors/`，避免其嵌套 `SKILL.md` 被全局路由层扫描；需要入口时在本 repo 放最小 wrapper
- 项目 skill 留在项目 repo，不进全局（`bash scripts/deploy.sh` 可审计拓扑）

## 红线：外部 skill 不做本地修改

外部克隆 skill 保持上游原样——不瘦身、不拆渐进披露、不改 frontmatter。本地修改会破坏与上游同步的能力（2026-09-04 教训：对 nuwa 的拆分在更新上游时全部作废）。

- 更新方法：在 `/Users/ganjie/skill-vendors/<name>` 用 `git clone --depth 1 <上游>` → 整目录替换（移除嵌套 `.git`，保留运行产出）
- 它们的超 5K 等问题归上游，本仓库只记录不修改；启用入口只允许 wrapper 指向 vendor 绝对路径
- 只有自建 skill / wrapper 才做 description 重写 / 瘦身 / 拆分
- 禁止把 vendor 完整目录复制回本 repo；那会让 74+ 个嵌套 manifest 重新进入全局路由层

### 外部 skill 来源表

| 本地目录 | 上游 | 当前版本 | 更新日 |
|---|---|---|---|
| `/Users/ganjie/skill-vendors/huashu-nuwa` | alchaincyf/nuwa-skill | 2026-08-25 commit | 2026-10-23 摘出扫描根，暂不启用 |
| `/Users/ganjie/skill-vendors/cangjie-skill` | kangarooking/cangjie-skill | v2.5.0（Capability Bundle） | 2026-10-23 摘出扫描根；本 repo 仅保留 wrapper |

## 工具箱（scripts/）

| 脚本 | 作用 |
|---|---|
| `ledger.sh [--json]` | token 账本 + 健康诊断：僵尸 / 触发失败嫌疑 / 超5K / description 违规 |
| `deploy.sh` | 部署审计：Claude/Codex/agents symlink、断链、哑目录、双实体漂移 |
| `sync_mcp.py --check` | 比较 MCP manifest 与 Claude/Codex/Trae live adapter；`--apply` 原子更新且保留未管理项 |
| `audit-agent-stack.sh` | Git、skills、MCP、secret、CC Switch 边界和备份新鲜度统一门禁 |
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

## MCP / Provider 边界

- Provider、本地代理和用量继续由 CC Switch 管理；不要手改它管理的 provider 字段。
- 可迁移 MCP 只改 `config/mcp/inventory.json`，凭证引用保存在 `~/.config/agent-stack/mcp-secrets.json`（0600，不入 Git）。
- Codex 宿主专属 `node_repl` 是未管理项；generator 更新时不删除未管理 server。
- CC Switch 中 MCP 同步开关已全部关闭，避免同名字段覆盖 manifest 生成的 adapter。
- 日常门禁：

```bash
python scripts/sync_mcp.py --check
bash scripts/deploy.sh
bash scripts/audit-agent-stack.sh
```

## 相关文件

- MCP server 设计清单（脱敏）：`config/mcp/inventory.json`；历史审计：`reports/mcp-inventory-2026-10-23.json`
- 外部上游摘出记录：`docs/skill-vendors.json`、`reports/2026-10-23-skills-mcp-optimization-audit.md`
- 多 Agent 管理模型：`docs/agent-skill-mcp-management.md`
- 调研依据：`reports/research/skill-improve/`、`reports/research/claude-skill-eco/`、`reports/research/skill-evolve/`
- 执行记录：`reports/2026-09-04-p0-skill-improvement-execution.md`、`reports/2026-10-26-vendor-migration-reconciliation.md`
- cc-switch 治理调研：`reports/research/cc-switch-management-audit/report.md`
