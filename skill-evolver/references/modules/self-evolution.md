# Module: Self-Evolution（模式 D 适配）

skill-evolver 自我进化时的流程适配。解决循环依赖：SKILL.md 既是进化目标，又是流程定义。

## 适配点

| 阶段 | 普通模式 A | 自我进化模式 D | 原因 |
|------|-----------|--------------|------|
| baseline | 读 SKILL.md 评分 | **同** | SKILL.md 未改，正常读 |
| exploration | 子 agent 读 SKILL.md 生成候选 | **副本隔离** | 子 agent 读 .before 副本，不改正在进化的文件 |
| application | 主 agent 改写 SKILL.md | **扩展范围** | 改 SKILL.md + references/ |
| audit | opus 读新版 + .before | **同** | 已 commit，正常对比 |
| deployment | T_val 测试 | **meta 测试** | 测试用例适配 meta-skill |
| T_train/T_val | 测试 skill 处理用户意图 | **测试流程可执行性** | 验证"按流程走能否产生好结果" |

## 副本隔离（exploration 阶段）

```bash
# baseline 结束后、exploration 开始前
cp skill-evolver/SKILL.md skill-evolver/SKILL.md.snapshot
# 子 agent prompt 中将 {skill_path}/SKILL.md 替换为 snapshot 路径
# exploration 结束后删除
rm skill-evolver/SKILL.md.snapshot
```

子 agent prompt 额外注入：
```
注意：此 skill 是进化框架本身。改写时：
- 保留模块化的渐进披露架构（references/modules/）
- 策略可影响 SKILL.md 和 references/ 下的所有文件
- 不要破坏流程骨架（baseline→exploration→application→audit→deployment）
```

## Meta 测试设计

T_train/T_val 的测试 prompt 不测"skill 回答用户问题"，而是测"流程可执行性"：

```json
{
  "T_train": [
    {"id": "T1", "type": "流程完整性", "prompt": "进化 neat-freak skill", "expect": "走完整 baseline→exploration→application→audit→deployment 流程"},
    {"id": "T2", "type": "模式路由", "prompt": "审计 neat-freak", "expect": "走模式 B（快速审计），不触发完整流程"},
    {"id": "T3", "type": "回滚处理", "prompt": "审计 FAIL≥3 的场景", "expect": "git reset HEAD~1 回到 CP-02"}
  ],
  "T_val": [
    {"id": "V1", "type": "边界场景", "prompt": "进化 skill-evolver（自我进化）", "expect": "走模式 D，使用副本隔离"},
    {"id": "V2", "type": "边界场景", "prompt": "优化所有 skills（批量模式）", "expect": "走模式 E，baseline 筛选后逐个进化"}
  ],
  "source": "meta-designed"
}
```

## Application 扩展

模式 D 的 application 步骤额外包含：
```bash
# 除了 git add SKILL.md，还包括修改过的 references/ 文件
git add skill-evolver/SKILL.md skill-evolver/references/
git commit -m "evolve skill-evolver: apply-r{r}-{策略}"
```

## 不适配的部分

以下阶段与普通模式 A 完全相同，无需特殊处理：
- baseline（评分 rubric 通用）
- audit（opus 独立审计，读已 commit 文件）
- deployment（T_val 验证泛化能力）
- git 分支策略、日志格式、约束规则
