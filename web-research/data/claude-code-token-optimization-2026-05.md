# Claude Code Token 优化深度调研报告

> 调研日期: 2026-05-15
> 数据来源: GitHub Issues, 官方文档, 社区文章, GitHub 仓库, Reddit, 技术博客

---

## 一、问题本质：Token 去哪了？

多数人以为 token 消耗在代码生成上，实际上大头在别处：

| 消耗来源 | 占比估算 | 说明 |
|----------|---------|------|
| 命令输出 (git status, npm test, ls -la) | 30-50% | 每次命令 500-5000 token，会话累计 10k-250k token |
| CLAUDE.md + Memory + System Prompt | 10-20% | **每轮都加载**，5000 token 的 CLAUDE.md × 200 轮 = 1M token |
| MCP 工具定义 | 5-15% | 每个 MCP Server 的工具签名都在 context 里 |
| 历史对话 | 20-40% | 旧文件读入、错误尝试、不相关探索 |
| 模型 thinking token | 10-20% | Opus 默认 31,999 thinking token/请求 |

**核心原则：token 优化的本质是 context architecture，不是 prompt 技巧。**

---

## 二、官方内置方法（必做，零成本）

### 2.1 模型选择 (影响力: ★★★★★)

```json
// ~/.claude/settings.json
{
  "model": "sonnet",
  "env": {
    "MAX_THINKING_TOKENS": "10000",
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku"
  }
}
```

| 设置 | 默认值 | 推荐值 | 节省效果 |
|------|--------|--------|---------|
| `model` | opus | **sonnet** | ~60% 成本降低。Sonnet 能处理 80% 任务 |
| `MAX_THINKING_TOKENS` | 31,999 | **10,000** | ~70% 隐藏成本降低。简单任务可设 0 |
| `CLAUDE_CODE_SUBAGENT_MODEL` | 继承主模型 | **haiku** | Subagent 便宜 80% |

**实际数据** (来自 lmmartinb.com，2026年3月):
- 三天 Opus 占比: 80%, 84%, 85%
- Opus 比 Sonnet 贵 10-15 倍
- 切换到 Sonnet 为主后日花费从 $353 降到 ~$70

**切换策略**:
```
/model sonnet   # 日常默认
/model opus     # 架构设计、复杂调试
/model haiku    # 查找、格式化、模板
/effort low     # 简单任务降低 thinking 预算
```

### 2.2 CLAUDE.md 精简化 (影响力: ★★★★★)

**关键事实**: CLAUDE.md 在**每一轮**都完整加载到 context，从不 lazy-load，从不 evict。

5000 token 的 CLAUDE.md × 200 轮对话 = **1,000,000 token 纯开销**。

**规则**:
- 只放稳定指令: 测试命令、包管理器、格式化规则、架构约束
- 不放会议记录、设计历史、实现指南
- 目标是 500-1000 token 以内
- 像 lookup table，不像 brain dump

### 2.3 /compact 主动使用 (影响力: ★★★★)

**常见错误**: 等到 Claude 开始遗忘或 context 警告才 compact → 此时摘要质量已差。

**正确做法**: 在 session 还健康时主动 compact:
- 规划完成后
- Debug 完成后
- 切换关注点前
- 每 15-20 轮对话后

### 2.4 MCP Server 精简 (影响力: ★★★★)

官方建议: **每个项目不超过 10 个启用的 MCP Server**。

- 运行 `/mcp` 查看活跃 server 及其 context 成本
- 禁用不用的 MCP Server
- 能用 CLI 就不用 MCP (如 `gh` 替代 GitHub MCP, `aws` 替代 AWS MCP)
- `memory` MCP 默认配置但未被任何 skill/agent/hook 使用 → 考虑禁用

### 2.5 /context 诊断 (影响力: ★★★)

先诊断，再优化。`/context` 显示 context window 分布:
- System prompt 占比
- Tools 定义占比
- Messages 占比
- Memory/Skills 占比

`/cost` 查看当前 session 花费。

---

## 三、第三方插件/工具

### 3.1 RTK (Rust Token Killer) — 强烈推荐

| 属性 | 值 |
|------|---|
| GitHub | https://github.com/rtk-ai/rtk |
| Stars | 48,100 |
| Forks | 2,900 |
| 语言 | Rust (单二进制，零依赖) |
| 安装 | `brew install rtk && rtk init -g` |
| 原理 | PreToolUse hook 拦截 Bash 命令，压缩输出后再入 context |
| 成熟度 | 极高，944 commits，社区活跃 |

**实测数据** (136 条命令):
| 命令 | 无 RTK | 有 RTK | 减少 |
|------|--------|--------|------|
| git status | 805 bytes | 268 bytes | 67% |
| ls -la | ~900 bytes | ~400 bytes | 71% |
| npm run build (Astro) | 8,518 bytes | 221 bytes | **97%** |
| 全局 136 命令 | 714,900 tokens | 58,200 tokens | **91.9%** |

**四种压缩策略**: smart filtering, grouping, truncation, deduplication

**局限**: 只对 Bash 命令生效，Read/Grep/Glob 等内置工具不经过 hook。Windows 上 auto-rewrite hook 需要 Unix shell，会降级为 CLAUDE.md 注入模式。

**隐私**: 收集匿名统计数据 (salted device hash, 命令类型分布)，不收集源码/路径/参数。

### 3.2 context-mode — 强烈推荐 (本项目已安装)

| 属性 | 值 |
|------|---|
| GitHub | https://github.com/mksglu/context-mode |
| Stars | 14,700 |
| Forks | 1,000 |
| Commits | 1,572 |
| 安装 | `npm install -g context-mode` |
| 支持平台 | 15 个 (Claude Code, Gemini CLI, Cursor, Codex, VS Code, JetBrains...) |
| 原理 | MCP Server + Hooks，sandbox 工具输出，FTS5 索引检索 |

**Benchmark 数据**:
| 场景 | 原始大小 | Context Mode | 节省 |
|------|---------|-------------|------|
| Playwright snapshot | 56.2 KB | 299 B | 99% |
| GitHub Issues (20) | 58.9 KB | 1.1 KB | 98% |
| Access log (500 requests) | 45.1 KB | 155 B | 100% |
| Git log (153 commits) | 11.6 KB | 107 B | 99% |
| Test output (30 suites) | 6.0 KB | 337 B | 95% |
| Repo research (subagent) | 986 KB | 62 KB | 94% |

**全 session**: 315 KB 原始输出 → 5.4 KB，session 时间从 ~30 分钟延长到 ~3 小时。

**三大核心能力**:
1. **Context Saving** — sandbox 工具 (ctx_execute, ctx_batch_execute 等)，原始数据不入 context
2. **Session Continuity** — SQLite + FTS5 索引，compact 后通过 BM25 检索恢复上下文
3. **Think in Code** — 写代码处理数据，只 console.log 结果，一个脚本替代 10 次 tool call

**Hooks vs 纯指令文件**:
| 平台 | Hooks 模式 | 无 Hooks 模式 |
|------|-----------|-------------|
| Claude Code | **~98% saved** | ~60% saved |

**注意**: context-mode 不强制 brevity 风格，不修改模型输出行为，只管理 context 进出。

### 3.3 claude-context-optimizer — 可选

| 属性 | 值 |
|------|---|
| GitHub | https://github.com/egorfedorov/claude-context-optimizer |
| Stars | 49 |
| 安装 | `git clone` → plugin directory |
| 原理 | PostToolUse hook 追踪 token 使用，生成 heatmap/ROI 报告 |

**特色功能**:
- `/cco-anatomy` — 生成项目 compact map，读 1 个文件替代 20 个
- `/cco-claudemd` — 分析 CLAUDE.md 找出冗余、重复、过长代码块
- `/cco-budget` — 设置预算告警
- `Read Cache` — 阻止对同一文件同一范围的重复读取
- `ContextShield` — 自动在 session 启动时注入 token 优化规则
- MCP tool tracking (v3.6) — 追踪 `mcp__*` 工具的 token 消耗

**局限**: 社区较小 (49 stars)，token 估算用 ~4 tokens/line 启发式，非精确。

### 3.4 其他工具速览

| 工具 | Stars | 说明 |
|------|-------|------|
| claude-docu-optimizer | 14 | CLAUDE.md + docs/ 生态优化，语义同步 |
| claude-dcp | 9 | Dynamic Context Pruning, 从 OpenCode DCP 移植 |
| goodvibes-plugin | 6 | 75 个 token-efficient MCP 工具替代原生工具 |
| claude-context-doctor | 3 | TUI 诊断工具，检查 skills/plugins/MCP |
| project-scaffolder | 7 | 项目知识库生成 + Caveman token 优化 |

**结论**: 除了 RTK 和 context-mode 这两个被大规模验证的工具，其他插件社区太小，可靠性存疑。

---

## 四、社区验证的有效方法汇总

### 4.1 高影响力 (社区共识)

1. **默认用 Sonnet，Opus 只用于复杂推理** — 几乎所有文章的首要建议，60-85% 直接成本降低
2. **精简 CLAUDE.md** — 5000 token 文件 × 每轮加载 = 天文数字
3. **安装 RTK** — 91.9% 命令输出压缩，48k stars 验证
4. **安装 context-mode** — 98% tool output 压缩, 14.7k stars, 15 平台
5. **降低 MAX_THINKING_TOKENS** — 31,999 → 10,000，隐藏成本降 70%
6. **Subagent 用 Haiku** — 探索/读文件便宜 80%

### 4.2 中影响力

7. **主动 /compact** — 在 session 健康时 compact，而非等到爆
8. **MCP 精简** — 控制在 10 个以内
9. **用 Subagent 隔离大文件读取** — subagent 有独立 context window
10. **Playwright MCP → Playwright CLI** — 浏览器测试 ~75% token 减少 (114k → 27k/session)

### 4.3 低影响力但可叠加

11. **先用 /context 诊断再优化** — 找出真正的 token 消耗大户
12. **Specification 文件** — 让 agent 执行而非重新决策，降低无用探索
13. **用 offset/limit 读大文件** — 避免整文件进入 context
14. **减少 Agent 工具数** — 每个工具定义都有 context 开销
15. **定期 /clear** — 无关任务之间清空上下文

---

## 五、GitHub Issues 中反映的真实痛点

从 anthropics/claude-code issues 中提取:

1. **CLAUDE.md 膨胀** — 用户不知不觉塞入过多内容，导致每轮消耗剧增
2. **MCP Server 过多** — 每个 MCP tool 的 schema 定义占用固定 context 空间
3. **/compact 太晚** — 多数人等 context 爆了才 compact，摘要质量差
4. **Opus 默认模型** — 很多用户不知道可以切换模型，一直用最贵的
5. **Thinking token 不可见** — 用户看不到 thinking token 消耗，以为是"免费"的

---

## 六、针对本项目的具体建议

当前项目 (skills 库) 已安装 context-mode，实测有效。建议:

### 立即执行
```json
// ~/.claude/settings.json 或项目 .claude/settings.json
{
  "model": "sonnet",
  "env": {
    "MAX_THINKING_TOKENS": "10000",
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku"
  }
}
```

### 强烈建议
```bash
# 安装 RTK (命令输出压缩)
brew install rtk && rtk init -g

# 精简 CLAUDE.md — 当前可能过大
# 目标: 500-1000 tokens，只放稳定指令
```

### 可选
- 审计 MCP Server: `/mcp` 查看，禁用不用的
- 定期 `/context` 检查 context 分布
- 在每个任务断点 (规划完、debug 完) 主动 `/compact`

---

## 七、数据来源

1. [Claude Code 官方文档 - Context Window](https://code.claude.com/docs/en/context-window)
2. [Claude Code 官方文档 - Manage Costs](https://code.claude.com/docs/en/costs)
3. [RTK GitHub](https://github.com/rtk-ai/rtk) — 48.1k stars
4. [context-mode GitHub](https://github.com/mksglu/context-mode) — 14.7k stars
5. [everything-claude-code token-optimization.md](https://github.com/affaan-m/everything-claude-code) — 182k stars
6. [How I Cut Claude Code Token Usage by 80% - lmmartinb.com](https://lmmartinb.com/en/claude-code-token-optimization/) — 实测 $353→$70/天
7. [7 Practical Ways to Reduce Claude Code Token Usage - KDnuggets](https://www.kdnuggets.com/7-practical-ways-to-reduce-claude-code-token-usage)
8. [Claude Code Token Optimization — What Actually Works - Bartosz Gaca](https://bartoszgaca.pl/en/news/claude-code-token-optimization-caveman-2026-en/)
9. [10 Tips to Stop Burning Your Tokens in Claude Code - Medium](https://medium.com/@habib23me/10-tip-to-stop-burning-your-tokens-in-claude-code-4776d4ac8956)
10. [How to Optimize Token Usage in Claude Code: Comparison of 13 Tools - Medium](https://medium.com/data-science-collective/how-to-optimize-token-usage-in-claude-code-comparison-of-13-tools-6c1fb7cd1137)
11. [anthropics/claude-code GitHub Issues](https://github.com/anthropics/claude-code/issues)
12. [Claude Context: Reduce Token Usage with Milvus - Milvus Blog](https://milvus.io/blog/claude-context-reduce-claude-code-token-usage.md)
13. [Stop Hitting Claude Code Usage Limits - UX Planet](https://uxplanet.org/how-to-stop-hitting-your-claude-code-limits-1524b3cc79f9)
