# Phase 1 Super Check (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: Phase 1
- **核心**: S.U.P.E.R 评分
- **执行**: 简化/未用/性能/错误/重复 5 维

## 内容

- `SKILL.md` (~800 tokens)

## 核心原则

S.U.P.E.R = SOLID 的可观察版

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/phase-1-super-check/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
