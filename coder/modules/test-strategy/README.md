# Test Strategy (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: Phase 3
- **核心**: 测试策略
- **执行**: test-strategist (sonnet)

## 内容

- `SKILL.md` (~1500 tokens)
- `assets/test-plan-template.md`

## 核心原则

高危代码 7 类 + property test + Test Pyramid

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/test-strategy/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
