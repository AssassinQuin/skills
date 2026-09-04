# P0 skill 进化执行报告（一次执行）

> 日期：2026-09-04 ｜ 依据：reports/research/skill-improve/ 调研 + 2026-09-04 会话授权「一次执行」
> 范围：P0 三项（token 账本 / description 与超重修复 / 僵尸清理）+ MCP 常驻层审计

## 执行结果总览

| 动作 | 结果 | 状态 |
|---|---|---|
| 1. token 账本 | 固化为 `scripts/token-ledger.sh`（可重跑，--json 支持） | ✅ |
| 2. 僵尸清理 | **归档 0 个**——13 个候选全部不满足 60 天线（见下） | ✅（诚实空转） |
| 3. 超重修复 | huashu-nuwa 9,326t → **4,796t**（-49%），渐进披露改造 | ✅ |
| 4. description | 24/24 合规（无缺失、无 >1024 字符），无需重写 | ✅ 零动作 |
| 5. MCP 常驻层 | 16 → **13 server**（删 context-mode 试用残留 / zhihu / zhihu-hot / zai-coding-plugins 悬空 marketplace），deep-research 路由已同步 | ✅ 已执行 |

## 1. token 账本（2026-09-04 快照）

```
合计 24 skill：body 按需 ≈38,328t；description 常驻 ≈1,400t
僵尸(>60天龄且0用/超60天未用): 0
新建待验证(≤60天龄0用): 13
超5K建议值: 0；description 违规: 0
```

重跑方式：`bash scripts/token-ledger.sh [--json]`

## 2. 僵尸判定修正（重要）

初判 13 个「僵尸」被**年龄线否决**：
- 12 个 novel 系列工序 skill：**9 天龄**（2026-08-26 建，维兰德流水线刚搭建），0 使用是「未走到该工序」不是死项目 → NEW_UNVERIFIED
- portfolio-rebalance：53 天龄（未过线），且 auto-memory 记录用户每月实际在用（usage 记录缺口，推测 log-skill.sh hook 未覆盖其调用路径）

**结论：无可归档。** 60 天线纪律避免了误杀刚建的流水线。待 2026-10-25 前后重跑账本，届时 novel 系列过 60 天线仍 0 用的工序再议归档。

## 3. huashu-nuwa 渐进披露改造（唯一超 5K 项）

37,304B（≈9,326t）→ 19,184B（≈4,796t），**-49%**，低于官方 5K 建议值：

| 文件 | 内容 | 加载时机 |
|---|---|---|
| SKILL.md（瘦身后） | 入口分流/Phase 0 路由/回答工作流/品味守则 + 指针 | 触发即载 |
| references/phase1-swarm-collection.md（11.5KB） | Agent Swarm 采集模板/分工/去重纪律 + Phase 1.5 Review 清单 | 执行 Phase 1 时读 |
| references/phase2-3-synthesis-build.md（5.5KB） | Synthesis 提炼/确认检查点/SKILL.md 生成规范 | 执行 Phase 2-3 时读 |
| references/special-cases.md（2.7KB） | 活人vs历史人物/中西/冷门/蒸馏自己 5 个分支 | 遇对应场景时读 |

每个切割点留了「执行本 Phase 前必须先完整读取 references/xxx.md」的强制指针。原 references/ 目录 4 个既有文件未动。结构校验通过（frontmatter/回答工作流/更新已有Skill/最后 均在）。

## 4. MCP 常驻层审计（最大 token 大头，未动配置）

按 ClaudeKit 实测口径（每 server schema 5k–15k tokens 常驻），15 个 server ≈ **75k–225k tokens 常驻**——超过全部 skill body（38k）总和数倍。识别的重叠组：

| 组 | server | 观察 |
|---|---|---|
| 图像分析 ×2 | 4_5v_mcp、zai-mcp-server | 功能高度重叠（后者 8 个视觉工具） |
| 网页读取 ×3 | web-reader、searxng(web_url_read)、context-mode(ctx_fetch_and_index) | 三套抓取 |
| 知乎 ×3 | zhihu、zhihu-hot、zhihu-global | 可合并为一个 |
| context-mode ×2 | context-mode（独立）、plugin_context-mode_context-mode（插件） | **同一套工具注册两次**，工具清单直接翻倍 |

**建议**（需用户确认后改 ~/.claude.json，本轮不动全局配置）：优先去重 context-mode 双注册与知乎三连，预期省 20k–60k tokens/会话常驻——这是比 skill 瘦身大一个数量级的收益。

### 执行记录（2026-09-04 用户授权后）

| 动作 | 命令 | 结果 |
|---|---|---|
| ① 删 context-mode 试用残留 | `claude mcp remove context-mode` | ✅（plugin 完整版保留，hooks 绑 homebrew 版不受影响） |
| ② 删 zhihu-hot | `claude mcp remove zhihu-hot` | ✅（用户首次粘贴被终端转义序列吞掉，编排者补删） |
| ③ 删悬空 marketplace | `claude plugin marketplace remove zai-coding-plugins` | ✅ 连带消除 4_5v_mcp 与 web_reader 下划线版双注册 |
| ④ 删 zhihu（二选一留 global） | `claude mcp remove zhihu` | ✅ |

依赖同步（deep-research skill，repo 与 ~/.claude/skills 同存储改一处即生效）：
- `scripts/route-lane.sh:32`：zhihu lane 首选工具 `mcp__zhihu__zhihu_search` → `mcp__zhihu-global__global_search`（count 5），fallback 改 websearch-cn
- `SKILL.md` 搜索员工具表：zhihu 搜索员工具列删去 zhihu_search
- 验证：未缓存探针查询的路由输出 `tool=mcp__zhihu-global__global_search` ✓；缓存命中路径不受影响 ✓

最终清单（13 个，全部 Connected）：plugin:context-mode / websearch-global / context7 / github / web-reader / web-search-prime / searxng / zread / codebase-memory-mcp / zhihu-global / zai-mcp-server / websearch-cn / memory。MCP 变更自下个会话起在工具清单中生效。

## 遗留

- usage 记录缺口：portfolio-rebalance 在用但 0 记录 → 下一步给 log-skill.sh 补覆盖或检查 hook 绑定
- novel 系列 12 个工序 2026-10-25 后复评
- description 层面：数量合规，但「路由有效性」（触发词是否真的命中用户说法）无评测集——属 P1 skill-evolve 范畴
