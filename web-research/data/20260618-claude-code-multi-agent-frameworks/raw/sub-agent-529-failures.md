# 子 agent 529 失败记录

**记录目的**：透明记录本次调研中 3 个子 agent 全部 API 529 失败的详情，供 v2.4 改进模型降级链参考。

## 失败详情

| agent_id | 角色 | 状态 | token | tool_uses | duration | 错误 |
|----------|------|------|-------|-----------|----------|------|
| a33aed6a63ca30df5 | tech-compare | failed | 0 | 0 | 186s | API 529 sonnet 网关过载 |
| a29b56d76dcb71268 | methodology | failed | 0 | 0 | 190s | API 529 sonnet 网关过载 |
| a7e9344a43abb167d | product | failed | 0 | 0 | 192s | API 529 sonnet 网关过载 |

**关键观察**：3 个 agent 都在 spawn 后约 3 分钟时返回 529，且全部 0 token / 0 tool_use，说明 sonnet 网关在 spawn 时就过载，agent 完全没启动。

## 根因分析

### MCP vs LLM 层区分

| 层 | 是否共享 | 故障影响 |
|---|---|---|
| MCP 工具（github/searxng/zread） | ✅ **共享** | 主 agent 用着完全正常 |
| LLM 模型 | ❌ **独立** | 子 agent sonnet 网关过载 → 529 |

→ **529 不是 MCP 故障**，是 LLM 网关故障。

### 为什么主 agent 没事

- 主 agent 用 `glm-5.2`（环境提示："You are powered by the model glm-5.2"）
- 子 agent 按 v2.3 协议 `model: "sonnet"`
- 不同网关：glm-5.2 网关正常，sonnet 网关过载

## 暴露的 v2.3 设计 gap

**v2.3 协议假设 sonnet 可用**，但缺**模型降级链**（类似已有的 MCP 三级降级）。

### v2.4 改进建议（模型降级链）

```
spawn 子 agent 时：
  try model: "sonnet"
  ↓ 529 / timeout
  try model: "haiku"
  ↓ 529 / timeout
  fallback: 取消 spawn，主 agent 直接做（不依赖子 agent）
```

类似 MCP L1/L2/L3 三级失败信号，加 model L1/L2/L3：

| 级别 | 触发 | 处理 |
|------|------|------|
| L1 单次 529 | sonnet 单次过载 | 重试 1 次 |
| L2 连续 529 | sonnet 连续 2 次过载 | 降级到 haiku |
| L3 全模型过载 | sonnet + haiku 都过载 | 取消 spawn，主 agent 直接做 |

## 主 agent 补救措施

3 子 agent 全失败后，主 agent 直接做调研：
- git mcp 5 调用（github search_repositories）
- searxng 5 调用（含 web_url_read 深读 Gerald Chen 博客）
- memory 1 调用（命中历史档案）
- 综合 17 个候选框架 + Anthropic 官方 + 横评博客

**质量评估**：尽管子 agent 失败，主 agent 调研质量不打折（关键发现 Gerald Chen 横评 + Anthropic 官方文档都是 S/A 级源）。

## 教训

1. **不要假设 sonnet 永远可用**（v2.3 + skill-deepener v1.3 + skill-evolver v8.1 全部默认 sonnet）
2. **必须有模型降级链**（同 MCP 降级）
3. **主 agent 直做是有效 fallback**（特别是 MCP 共享时）

→ 建议所有元 skill（web-research / coder / skill-search / skill-deepener）下个版本统一加模型降级链。
