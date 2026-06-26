# Anti Patterns (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: (always)
- **核心**: Anti-pattern 案例库
- **执行**: 历次执行偏离（AP-1 ~ AP-10）

## 内容

- `SKILL.md` (~2000 tokens)

## 核心原则

反例对照 SOLID / R1-R12 硬约束

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/anti-patterns/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
