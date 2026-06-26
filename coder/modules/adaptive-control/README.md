# Adaptive Control (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: drift 触发
- **核心**: drift 自适应
- **执行**: drift ≥ 0.4 时 oracle 重新分解

## 内容

- `SKILL.md` (~1000 tokens)

## 核心原则

control theory + drift correction

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/adaptive-control/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
