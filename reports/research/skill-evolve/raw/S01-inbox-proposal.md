# 提案输入材料（lane: human，inbox 转存）
- url: reports/research/skill-evolve-proposal-input.md
- fetched: 2026-09-03
# skill-evolve 提案（待验证的输入材料）

- 来源：claude-skill-eco deep 调研编排者的交叉分析产出（2026-09-03，B 部分）
- 性质：内部提案草稿，本文件作为 skill-evolve 深度调研的既有材料（等同 lane: human 的高优先输入）

## 提案要点

**定位**：审计并门控进化本仓库 skills——基于 .stats 使用数据 + 评测集，生成有界修改提案（描述/瘦身/归档/脚本化/评测），过 gate 后人工审批合入。

**四模式**：`audit`（只读报告：usage×frontmatter×体积矩阵）/ `evolve`（主流程）/ `harvest`（会话黄金路径收割，必须过 gate）/ `slim`（>5K token 的 SKILL.md 渐进披露改造）。

**evolve 管线**（批次硬限：≤3 skill、每 skill ≤5 处编辑——「编辑预算=文本学习率」）：
1. 收集：usage.jsonl（需先给 log-skill.sh 打 outcome 补丁：success/fail/human-fixed）+ lint 结果 + eval 基线
2. 判定=确定性评分脚本（僵尸=0 使用>60 天 / 超重 / 规范漂移 / 高频脆弱），模型只做分类与提案措辞
3. 提案仅五类有界编辑：描述重写（what+when ≤1024 字符）、瘦身、归档/并入、规则脚本化、补 eval 集
4. 双层 gate：可验证行为型 skill 跑 5-10 例 eval 新旧 A/B（单进程+环境指纹）；写作型跑结构 validator + 人工审；token 数必须不增
5. 审批：diff 以提案清单呈现，人工 yes/no
6. 应用后复验 + version +0.1 + 写 `.stats/evolution/log.jsonl`；被拒提案进 `rejected.jsonl` 永不重复提

**配套脚本**：`scripts/evolve-audit.sh`（只读矩阵）、`scripts/skill-lint.sh`（frontmatter 三段/保留字/1024/500 行/150 token 段落告警）、`eval/run-gate.sh`（新旧 A/B；gate 脚本人所有、运行中 agent 不可改）

**红线**：批次前 git 快照；只动 harness 层（描述/结构/脚本），永不动模型权重、不动 CLAUDE.md「怎么思考」段；外部 star/热度不作为输入。

## 提案声称的证据锚点（待本调研独立验证）

- 机制收敛：SkillOpt、ACE、alirezarezvani/claude-skills、skill-creator v2、ClawHub 五项目同构于「证据采集→判断→有界编辑→验证门→人工审批→应用复验→负反馈」
- skill-creator v2 三维度量化：触发准确率/输出质量/效率
- ACE 的 delta 增量更新防 context collapse
- hermes 反例：自动写 SKILL.md → 38.7k issues + 审计灾难
- SkillOpt 52/52 SOTA 为自报、3 个月无独立复现（contrarian 已发现）
- 本仓库实据：223 条 usage（superpowers 占 44%、24/38 僵尸、0 评测集）
- 官方 issue 证明评测 harness 本身会坏（并行触发率 1/N）
- 已删 skill-evolver 的无门控教训（本仓库历史）

## 本调研要回答的问题

1. 提案引用的机制是否属实、真的有效（逐项验证）
2. 同类工作有什么提案没覆盖的（最新进展、失败模式）
3. 关键参数依据：编辑预算（≤3 skill/≤5 编辑）、eval 5-10 例、僵尸 60 天线、token 不增
4. 风险与边界：自改 SKILL.md 的安全性、评估函数污染、gate 脚本「agent 碰不到」是否真能实现
5. 结论：提案的修正清单（改/砍/补）+ 是否值得建
