# Phase 0.6 Bug Diagnosis (Module)

独立 module of coder skill v7.0+。

## 用途

- **Phase**: Phase 0.6
- **核心**: bug 诊断子流程
- **执行**: 6 步 diagnose 循环（来自 mattpocock diagnose）

## 内容

- `SKILL.md` (~2000 tokens)
- `scripts/build-feedback-loop.py`

## 核心原则

feedback loop → reproduce → 3-5 ranked falsifiable hypotheses → fix

## 加载策略

按 SKILL.md frontmatter 的 `load_priority` 加载（always/high/on-demand）。

## 独立使用

可单独加载此 module，不需整 coder 包：

```bash
cat modules/phase-0.6-bug-diagnosis/SKILL.md  # 直接读
```

## 上游 / 下游

见 SKILL.md 末尾"引用"段。
