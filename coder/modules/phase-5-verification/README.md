# Phase 5 Verification (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: Phase 5
- **核心**: 验证
- **执行**: 3 reviewer 并发（correctness/project/security）+ test-runner

## 内容

- `SKILL.md` (~1200 tokens)

## 核心原则

OWASP Top 10 + Test Pyramid

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/phase-5-verification/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
