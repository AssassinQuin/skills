# Phase 3 Design Options (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: Phase 3
- **核心**: 设计方案 + test-plan
- **执行**: N oracle 并发

## 内容

- `SKILL.md` (~1200 tokens)

## 核心原则

alternatives + deep module + test-plan（vertical cycle）

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/phase-3-design-options/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
