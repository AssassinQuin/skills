# Phase 0.5 Reuse Analysis (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: Phase 0.5
- **核心**: 复用 + 替代分析
- **执行**: explorer + researcher + oracle 并发

## 内容

- `SKILL.md` (~1200 tokens)
- `assets/reuse-report-template.md`

## 核心原则

[[DRY]] 复用优于自造；oracle 评估 alternatives

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/phase-0.5-reuse-analysis/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
