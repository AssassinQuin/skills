# Context7 Integration (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: on-demand
- **核心**: context7 集成
- **执行**: 第三方库 API 查询

## 内容

- `SKILL.md` (~600 tokens)

## 核心原则

resolve-library-id / query-docs

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/context7-integration/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
