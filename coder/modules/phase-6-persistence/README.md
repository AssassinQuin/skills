# Phase 6 Persistence (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: Phase 6
- **核心**: 持久化 + delivery-checklist + handoff
- **执行**: orchestrator + AskUserQuestion 验收

## 内容

- `SKILL.md` (~1000 tokens)
- `scripts/gen-delivery-checklist.py`
- `assets/delivery-checklist-template.md`
- `assets/archive-template.md`

## 核心原则

12-Factor XI logs + handoff 视角

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/phase-6-persistence/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
