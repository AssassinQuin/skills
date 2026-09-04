# skill-evolve 提案验证调研报告

> 日期：2026-09-03 ｜ 模式：deep → deep ｜ 查询：复用 5 / 新搜 28 ｜ 信源 43 条（github 8/8 顶格）
> 特别说明：编排者在 Phase 5 四次遭基础设施中断（watchdog 停滞 / 连接丢失 / 系统睡眠×2），本报告由控制器从磁盘工件（sources/queries/meta/cache）+ 同日 claude-skill-eco 轮 ctx 索引重建综合。verifier 的 6 条 contrarian 查询留痕于 queries.jsonl（wave9），其结论以证据锚点形式并入。

## 摘要

提案的**骨架方向正确**——「证据采集→确定性判定→有界编辑→验证门→人工审批→负反馈」确实是该领域唯一被证明可行的自进化形状，且本仓库自己删掉的 skill-evolver（自报 5.8→8.9、T_val 恒 4/4）恰好是无门控版本的本地失败样本。但提案的**证据引用有四处硬伤**：①「skill-creator v2」不存在（是现有特性的误记）②hermes「38.7k issues」数字错误（API 实测 open issues=28，但反例实质反而更锋利：0 行 diff 自报 +30.7%）③ClawHub 被误当「人工审批正例」（实为 Snyk 实证的安全重灾区）④eval 5-10 例做不了 A/B 判定（外部依据：50 例仅 sanity、200 例才检出 10-15pp）。**结论：值得建，但按修正清单改 5 处、砍 1 处、补 3 处后再立项。**
## 一、五机制逐项核实判决

| 机制 | 判决 | 关键证据 |
|---|---|---|
| SkillOpt 验证门 | **属实，但数字自报** | 微软官方仓库+arXiv 2605.23904 确证；configuration.md 默认 use_gate=true、learning_rate=4——提案「编辑预算=学习率」出自此处（经媒体转述 [S24]）。52/52 SOTA 为论文自报，3 个月无独立复现；最接近的 joshhu/skillopt-qa（57★）是最小复刻非认证 [S37] |
| ACE 增量更新 | **属实，但有已知缺口** | 1294★ + arXiv 2510.04618 确证 delta 机制。痛点：issue #11 playbook 膨胀超 100K tokens、#26 curator 只有 ADD 无 UPDATE/MERGE/DELETE [S7]——增量不配清理通道，恰好会造成提案想防的 context collapse |
| skill-creator v2 三维度 | **版本叙事错误** | 当前 anthropics/skills main 的 skill-creator **无 v2**；它确有 20 例触发评测集 + assertion 质量检查 + token/duration 效率基准 [S14]。应改称「skill-creator 的评测/质量/效率基准」 |
| hermes 反例 | **数字错误，实质成立且更锋利** | open issues API total_count=28（非 38.7k，疑 stars 讹传）[S8]。但 #172：evolved 与 baseline **0 行 diff 却自报 +30.7%** [S9]——自报指标失真的实锤；#169/#171/#175：门控校验器恒挂 + dspy API 漂移静默回退 [S10]——门控自身失效的真实样本 |
| ClawHub 人工审批 | **误用为正例** | Snyk ToxicSkills：扫 ClawHub+skills.sh 共 3,984 skills，13.4% critical、76 恶意 payload、快照时 8 个仍在线 [S15]；静态扫描漏检 ~60% [S16]；arXiv 2605.28588 独立佐证 [S17]。它是「生态必须门控」的**反面**证据 |
## 二、专项对比：skill-creator 与相关进化 skill（优势/劣势/痛点矩阵）

| 项目 | 优势 | 劣势 | 用户痛点（issue/社区实证） |
|---|---|---|---|
| **官方 skill-creator** [S14] | 20 例触发评测集；assertion 质量检查；token/duration 效率基准；官方维护 | 只管**创建**不管**进化**——无使用反馈回路，无版本迭代机制 | 评测 harness 自身会坏：#1706 并行 worker 共享目录→触发率坍缩 ~1/N（10 worker→6%）[S11]，#1715 跨环境确认 [S12]；eval 相关 open issues 宽口径 43 条 [S13] |
| **SkillOpt**（微软）[S1-S4,S37] | 门控默认开（use_gate=true）；编辑预算化（learning_rate=4）「不动模型权重」[S24]；学界引用最多 | 52/52 自报无独立复现；12 条 open issues 未清 | 无复现路径：社区 57★ 复刻非认证；数字均出自论文自述 |
| **ACE** [S5-S7] | delta 增量更新省 context；1294★ 社区活跃 | curator 只有 ADD；无收缩/合并/删除 | playbook 膨胀 >100K tokens（#11）——增量更新反而制造膨胀 |
| **hermes** [S8-S10] | 敢做全自动自进化的极少数 | 自报指标失真；门控校验器恒挂；依赖漂移静默回退 | 0-diff 报 +30.7%（#172）——用户无法信任任何自报数字 |
| **ClawHub 生态** [S15-S17] | 分发规模大、安装方便 | 无质量门控；安全扫描漏检 ~60% | 13.4% critical、76 恶意 payload、8 个在线——装 skill = 开盲盒 |
| **alirezarezvani 合集** [S18] | 388 skills、API 实测 25,445★；**已组装 skillopt-sleep/skill-doctor/human-gate/security-auditor 四件套**——与提案最接近的参照 | vendored 组件的深度未经审计；合集型仓库的维护责任模糊 | 未深挖（下轮可拆其 human-gate 实现） |

**矩阵读法**：没有一个项目可整体照搬。可拆用的件＝SkillOpt 的预算+门控参数、ACE 的 delta 思路（补清理通道）、官方的评测集形状、alirezarezvani 的组装方式；必须避开的坑＝hermes 的自报指标、ClawHub 的无门分发、官方 #1706 的评测 harness 并行陷阱。
## 三、关键参数依据与风险边界

### 参数判决

| 提案参数 | 判决 | 依据 |
|---|---|---|
| eval 5-10 例做 A/B gate | **偏小，修正** | 50 例仅 sanity check；200 例才稳定检出 10-15pp 差异；500+ 生产置信 [S25]；统计功效专文批评小样本 A/B [S26][S27]。→ 改为：5-10 例=回归冒烟门（防变坏），**A/B 判定升级到 ≥50 例**（防误判好） |
| 编辑预算 ≤3 skill/批、≤5 编辑/skill | 无外部硬依据，保守合理 | SkillOpt learning_rate=4 同量级 [S3]；方向与「文本学习率」类比一致 [S24] |
| 僵尸线 60 天零使用 | 仓库自设，方向有据 | 本仓库 25/38 零使用实据 [S41]；外部无统一标准 |
| token 不增硬门 | 有据 | SkillOpt 效率基准同思路 [S14][S24] |

### 风险与边界（三判）

1. **评估函数污染有实证**：reward hacking 在 agent 中自然涌现且抗标准缓解 [S29][S36]；Anthropic AAR 自安全教练显示 85% vs 20% 差距可闭合，但 Goodhart/认知盲区/递归自改三风险仍在 [S31]；LLM-as-Judge 生产环境 11 类信号失效 [S28]——**评测信号本身需要审计**。
2. **「gate 脚本 agent 不可改」技术上不可强制**：agent 持有 Write/Bash 全工具。可实现的最接近形态：gate 脚本走 git 保护（提交后跑）、修改 gate 脚本的提案单列为最高审批级、人工审 diff 兜底。提案该表述应改为「提高篡改成本+留痕可审计」。
3. **评测 harness 会自坏**：官方 #1706 并行触发率坍缩 [S11][S12] → gate 运行必须单进程+环境指纹记录（提案已有，保留）。

### 最强反驳

评测信号层就是主要被攻击面（见上三判）。若 gate 被钻或自坏，门控进化退化为带噪声的随机漫步。缓解：gate 信号多样化（结构 validator + token 计数 + 人审抽检三层）、指标全部以工件核对（本调研 P9 教训的直接应用）、rejected.jsonl 负反馈。
## 四、修正清单与最终建议

### 改（5 处）

1. **引用修正**：「skill-creator v2 三维度」→「skill-creator 的评测/质量/效率基准」（无 v2）
2. **数字修正**：hermes「38.7k issues」→「open issues 28，其中 #172 0-diff 自报 +30.7%、#169/#171/#175 门控失效」（反例更锋利）
3. **引用降级**：ClawHub 从「人工审批正例」改为「无门控生态的反面证据」
4. **参数修正**：eval 分层——5-10 例只做回归门，A/B 判定 ≥50 例（200 例才稳检 10-15pp）
5. **表述修正**：「gate 脚本 agent 不可改」→「git 保护+修改 gate 单列最高审批级+留痕可审计」（技术上不可强制）

### 砍（1 处）

- ClawHub 式「市场分发/安装」能力——与门控进化目标无关，且是安全负债

### 补（3 处）

1. **清理通道**：学 ACE 教训（#11/#26），evolve 管线加「合并/删除过时规则」提案类型，防 playbook 膨胀
2. **评测信号审计**：gate 指标多样化（结构+token+人审抽检），单指标可被钻 [S28][S29]
3. **参照实现**：立项前先拆 alirezarezvani 的 vendored human-gate/skill-doctor 四件套 [S18]——最接近提案的现成组装

### 最终建议

**值得建。** 骨架（五段管线+门控+人工审批+负反馈）是该领域唯一被证明可行的形状；本仓库有现成的三个可复用件（route-lane 的确定性查表模式、validate-findings 的质量门模式、.stats usage 数据），且本仓库自己的 skill-evolver 遗骸是无门控失败的本地对照组。**前置条件**：先按修正清单改提案，再走 brainstorm→spec 流程立项；首批 evolve 候选就用 25 个僵尸 skill（风险最低、可逆性最强）。

## 未解问题

- 「skill-creator v2」版本号源头无法确证（疑公众号综述混称 [S39]）
- hermes「38.7k」数字源头不明（疑 stars 讹传）
- joshhu/skillopt-qa 复刻保真度未深读
- alirezarezvani vendored human-gate 实现细节未拆（建议立项前补）

## 引用

完整 43 条见 `sources.json`（S1-S43，github/glb/cn/zhihu/human 五 lane）。关键锚点：S3 SkillOpt 配置、S7 ACE issues、S9 hermes #172、S11 #1706、S14 官方 skill-creator、S15 ToxicSkills、S28 评测信号审计、S41 本仓库 usage、S42 已删 skill-evolver 遗骸。

## Meta

- lane 健康：github ok(8/8 顶格) / glb ok / cn ok / zhihu 未用（预算让位 core）/ prime 未用
- 降级记录：编排者 4 次基础设施中断（watchdog/连接丢失/睡眠×2）→ 控制器重建综合；verifier 以 6 条 contrarian 查询留痕（queries.jsonl wave9）
- 计数：以工件核对——queries.jsonl 33 行 = 5 缓存复用 + 28 新搜；save-memory 写回后注册表 40→54
- 任务目录：reports/research/skill-evolve/
