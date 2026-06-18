# Token 预算协议

PP-7 历史问题（理解阶段 Read 5 个完整文件 ~40KB 进 context）+ v8.1 Gate 4 共同驱动。

## 硬预算

| 维度 | 限额 |
|------|------|
| 单次任务主上下文 | ≤ 30k tokens |
| 单个长文件读取 | >300 行 / >2000 字 → 必须 ctx_index 转换 |
| 并行 Read 单步骤 | ≤ 3 个文件（避免 PP-7 重现） |
| 子 agent 独立 context | ≤ 30k tokens |

## 长文件决策门

```
Read 文件 > 300 行？
├── Yes → 是否含 CJK 字符（韩/日/中，token ×1.5-2 效率差）？
│         ├── Yes + 行数 > 150 → 强制 ctx_index 转换
│         └── No + 行数 > 300 → 强制 ctx_index 转换
└── No → 全文进主上下文 OK

ctx_index 转换协议：
  1. mcp__plugin_context-mode_context-mode__ctx_index(
       content="{文件内容}",
       source="{lang}-{filename}"
     )
  2. mcp__plugin_context-mode_context-mode__ctx_search(
       queries=["关键概念 1", "关键概念 2"]
     )
  3. 主上下文只接收 ctx_search 返回段
```

## 理解阶段 Read 策略（PP-7 防护）

| 文件类型 | 策略 |
|---------|------|
| 目标改动文件 | 全文 Read（必须看精确字节才能 Edit） |
| 依赖文件（imports） | 优先 grep + 行号定位，必要时 Read with offset/limit |
| 测试文件 | ctx_index + ctx_search 关键段 |
| 大型 references / 文档 | ctx_index + ctx_search |

**反例（PP-7）**：理解阶段并行 Read 5 个相关文件全文 ~40KB → 主上下文爆炸 → 后续推理质量下降。

**正确做法**：先 grep 定位关键行 → Read with offset/limit 取上下文 → ctx_index 留底以备复检。

## 验证

任务结束前自检：

```
主上下文 tokens 用了多少？
超过 30k → 标注 [⚠️ TOKEN 超预算]，记录到经验总结
下次任务启动时回顾：是否有可优化的 Read 调用？
```

## 与硬约束的关系

- SKILL.md 约束段已加 "Token 预算" 硬约束
- references/hard-constraints-check.md 含 token 预算检查项
- skill-evolver v8.1 Check 10 会验证此约束是否真执行
