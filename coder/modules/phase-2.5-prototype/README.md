# Phase 2.5 Prototype (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: Phase 2.5
- **核心**: throwaway prototype
- **执行**: 验证 design 关键假设

## 内容

- `SKILL.md` (~1500 tokens)

## 核心原则

6 rules + tracer-bullet + fail-fast

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/phase-2.5-prototype/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
