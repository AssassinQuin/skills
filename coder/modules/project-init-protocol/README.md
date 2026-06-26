# Project Init Protocol (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: init
- **核心**: 项目初始化协议
- **执行**: 三层架构（coder/.claude/memory）

## 内容

- `SKILL.md` (~2500 tokens)
- `assets/go-coder-template.md`
- `assets/project-reviewer-template.md`
- `assets/claude-md-template.md`
- `assets/delivery-template.md`
- `assets/python-coder-template.md`

## 核心原则

12-Factor I + V + oh-story-claude intelligent merge

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/project-init-protocol/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
