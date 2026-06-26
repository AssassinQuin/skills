# Memory Tier Strategy (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: Phase 6
- **核心**: memory MCP 三级隔离
- **执行**: project/shared/global

## 内容

- `SKILL.md` (~1000 tokens)

## 核心原则

12-Factor IV backing services

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/memory-tier-strategy/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
