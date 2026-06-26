# Coder-Reuse

**Phase 0.5 复用 + 替代分析**。3 路并发（explorer 项目内扫描 + researcher 外部调研 + oracle 决策），输出 reuse-report.md。

## Trigger

- 进入 coder 流水线 Phase 0.5（spec.md 已生成）
- 用户问 "有没有现成的 X" / "能不能复用 Y"
- 新功能可能已有类似实现

## Quick Start

```
/coder-reuse 我要加 PDF 导出，看有没有现成方案
```

## Workflow

1. explorer(haiku) 扫描项目内已有相似实现
2. researcher(sonnet) 查外部库/方案
3. oracle(opus) 综合决策：复用 / 引新 / 自写
4. 输出 reuse-report.md
5. 用户选定 reuse decision

## Directory Structure

```
SKILL.md / assets/reuse-report-template.md / scripts/{explorer-runner,researcher-runner} / README.md
```

## Output Format

```
reuse-report.md（3 路并发输出合并 + 决策表 + 用户选定方案）
```

## See Also

coder-spec (Phase 0) / coder-debug (Phase 0.6) / coder-metadata (Phase 1) / coder (主 router)
