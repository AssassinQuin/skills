---
name: skill-evolver
description: >
  部署驱动的 Skill 自进化框架。从真实使用数据中识别失败模式，用 K=6 多策略并行探索 +
  对比学习 + 10项独立审计驱动 skill 持续进化。强制流程执行，每步有用户确认关卡。
  Use when: "skill进化", "evolve skill", "自进化", "部署反馈优化", "skill自优化",
  "skill-evolver", "skill有使用问题", "优化失败的skill", "优化skill", "skill评分",
  "自动优化", "帮我改改skill", "skill怎么样", "提升skill质量", "skill review",
  "skill打分", "skill质量检查", "skill审计", "skill诊断", "skill改进", "skill不work",
  "skill不好用", "skill优化", "达尔文", "darwin", "auto optimize".
---

# Skill Evolver — 部署驱动的 Skill 自进化框架

> 一个 skill 驱动其他 skill 进化。进化信号来自真实部署中的成败轨迹，不靠猜测。
> 灵感来源：[SkillEvolver](https://arxiv.org/abs/2605.10500) + [darwin-skill](https://github.com/alchaincyf/darwin-skill)

---

## 子 Agent 模型分配

| 任务 | 模型 | 原因 |
|------|------|------|
| K=6 策略探索 | **sonnet** ×6 并行 | 快速并行 |
| 候选评分 + 测试 | **sonnet** | 快速迭代 |
| 独立审计（Phase 4） | **opus** | 仔细推理，质量优先 |
| 部署测试（Phase 5） | **sonnet** | 快速验证 |
| 自进化评估 | **opus** | 元认知，需深度分析 |

### 子 Agent 可靠性协议

子 agent 有两个高发故障模式：**工作目录错误**和**文件混淆**。所有子 agent prompt 必须遵守：

**1. 路径锚定**：prompt 中必须包含项目绝对路径，且第一步是验证：
```
你的工作目录是 {ABSOLUTE_PROJECT_PATH}
第一步：用 ls 确认关键文件存在，确认后再继续
```

**2. 审计文件标记**：Phase 4 审计 agent 的 prompt 必须用明确标记区分两个版本：
```
文件 A (BEFORE — 原始版本): {绝对路径}/SKILL.md.before
文件 B (AFTER — 改写版本): {绝对路径}/SKILL.md
先读文件 A，再读文件 B，对比时始终引用标记名
```
改写前先 `cp SKILL.md SKILL.md.before`，审计完成后删除 `.before` 文件。

**3. 测试 agent 守卫**：所有测试 agent（Phase 0 基线 + Phase 5 部署）的第一步必须是：
```bash
ls {预期文件} && echo "EXISTS" || echo "NOT FOUND"
```
如果返回 NOT FOUND，立即终止并报告路径问题，不要继续执行。

### 子 Agent 数据传输协议

子 agent 无法直接写文件（权限限制），且完整候选内容通过 Agent 响应传输会浪费大量 token。采用 **ctx_index → ctx_search** 中转：

```
写入侧（子 agent）：
  ctx_index(content=完整候选SKILL.md内容, source="{skill}-S{k}")
  响应只返回：{策略名, 总分, 关键改动≤3条, 改动段落数}

读取侧（主 agent）：
  ctx_search(queries=["完整内容"], source="{skill}-S{k}")
  → 获取完整候选 → 用于对比学习、评分、应用改写
```

**Token 节约估算**：每个候选 8-15KB，6 个共 48-90KB。用 ctx_index 中转后，Agent 响应仅 ~500 字 × 6 = 3KB，节省 90%+。

---

## 5 维评估 Rubric（总分100）

| # | 维度 | 权重 | 评分标准 |
|---|------|------|---------|
| 1 | **Frontmatter** | 10 | name规范、description含做什么+何时用+触发词、≤1024字符 |
| 2 | **工作流** | 20 | 步骤有序可执行、每步有输入/输出、覆盖声明场景 |
| 3 | **边界/安全** | 15 | 异常处理、fallback、Runtime中立、无硬编码 |
| 4 | **指令精度** | 20 | 无模糊动词、有参数/格式/示例、可直接执行 |
| 5 | **实测效果** | 35 | 2-3个典型prompt测试，输出质量对比baseline |

**评分规则**：
- 维度1-4：打1-10分（静态分析）
- 维度5：打1-10分（必须子agent测试，不可干跑替代）
- 总分 = Σ(维度分 × 权重) / 10，满分100
- 改进后总分必须 **严格高于** 改进前才可保留

---

## 流程总览（R=3 轮迭代）

```
Phase 0 初始化
  │
  ▼  ✓ 用户确认范围 + 基线评分
Phase 1 信号收集 → 理解差距
  │
  ▼  ✓ 用户确认候选 + 差距描述
Phase 2 K=6 多策略探索 → 对比学习 → 选最优
  │
  ▼  ✓ 用户确认策略选择
Phase 3 精准应用 + git commit
  │
  ▼  ✓ 用户确认改动内容
Phase 4 独立审计（opus，新上下文，10项检查）
  │
  ▼  ✓ 用户确认审计结果
Phase 5 部署验证 + 记录日志 + 更新指标
  │
  ▼  ✓ 用户确认部署结果
  │
  ├─ r < R → 以新版本为基线，回到 Phase 1
  └─ r = R → 进化完成，git merge 到 main
```

**刚性规则**：
- 每个 ✓ 是必经关卡，不可跳过
- 用户说"不好" → 回退到上一关卡重新执行
- 用户说"跳过" → 只能跳过本轮，不能跳过整个 Phase
- 任何 Phase 失败 → revert git，记录失败原因，继续下一个 skill

### Git 版本控制

`~/.claude/skills/` 是 git 仓库。每次进化操作都在 git 上可追溯。

**分支策略**：
```
main                        # 稳定版本
  └─ evolve/{skill}/YYYYMMDD  # 进化工作分支
```

**Phase 级 git 操作**：

| Phase | git 操作 | 目的 |
|-------|---------|------|
| Phase 0 | `git checkout -b evolve/{skill}/YYYYMMDD` | 创建工作分支 |
| Phase 3 | `git add {skill}/SKILL.md && git commit -m "evolve {skill}: {策略}-R{轮次}"` | 保存改写结果 |
| Phase 4 FAIL≥3 | `git revert HEAD` | 回滚到改写前 |
| Phase 5 退化 | `git revert HEAD` | 立即回滚 |
| Phase 5 通过 | 追加日志 + `git add {skill}/.evolve/ && git commit -m "log: {skill} R{轮次}"` | 记录指标 |
| 收工 | `git checkout main && git merge evolve/{skill}/YYYYMMDD` | 合并到主分支 |

**回滚命令**（任何阶段可用）：
```bash
# 查看进化历史
cd ~/.claude/skills && git log --oneline --grep="evolve codemap"

# 回滚到上一次进化前
cd ~/.claude/skills && git revert HEAD

# 回滚到指定版本
cd ~/.claude/skills && git log --oneline {skill}/SKILL.md
cd ~/.claude/skills && git checkout {commit-sha} -- {skill}/SKILL.md
```

### 进化日志与指标

**日志位置**：`{skill}/.evolve/evolution-log.jsonl`（每个 skill 独立）

**每轮追加一条 JSON 记录**：
```json
{
  "ts": "2026-05-27T04:00:00Z",
  "round": 1,
  "strategy": "S1+S2-merge",
  "skill": "codemap",
  "score_before": 63.5,
  "score_after": 80.5,
  "delta": 17,
  "audit_pass": 10,
  "audit_total": 10,
  "deploy_tests": [
    {"name": "T1", "before": 9, "after": 9, "valid": true},
    {"name": "T2", "before": 9, "after": 8, "valid": true}
  ],
  "deltas_fixed": ["Δ1-感知链", "Δ2-事实漂移"],
  "commit": "abc123"
}
```

**指标文件**：`{skill}/.evolve/metrics.json`（累积汇总）

Phase 5 结束后自动更新：
```bash
# 读取现有 metrics.json，追加本轮数据，写回
node -e "
  const fs = require('fs');
  const p = '{skill}/.evolve/metrics.json';
  const m = fs.existsSync(p) ? JSON.parse(fs.readFileSync(p)) : {};
  m.total_rounds = (m.total_rounds || 0) + 1;
  m.total_score_delta = (m.total_score_delta || 0) + {delta};
  m.avg_score_delta = Math.round(m.total_score_delta / m.total_rounds * 10) / 10;
  m.last_evolved = new Date().toISOString().split('T')[0];
  fs.writeFileSync(p, JSON.stringify(m, null, 2));
"
```

**关键指标**（Phase 0 时自动读取展示）：

| 指标 | 来源 | 用途 |
|------|------|------|
| `total_rounds` | metrics.json | 该 skill 被进化了几轮 |
| `avg_score_delta` | metrics.json | 平均每轮提升多少分 |
| `last_evolved` | metrics.json | 上次进化时间（太久→可能需要重评） |
| `audit_pass_rate` | metrics.json | 审计通过率（低→策略库可能有问题） |
| `strategy_hits` | metrics.json | 哪些策略对该 skill 有效（指导后续选型） |

### 关卡合并策略

6 个独立关卡会导致过多交互。合并规则：
- **关卡 0+1 合并**：基线评分 + 差距报告一起展示，一次确认
- **关卡 4+5 合并**：审计结果 + 部署验证结果一起展示，一次确认
- **关卡 2、3 不合并**：策略选择和改动确认是高风险决策点，必须独立确认
- 合并后实际交互：4 次（vs 原始 6 次），减少 ~33% 交互开销

---

## Phase 0: 初始化

```
1. 确认进化范围
   - 用户指定 → 直接使用
   - 用户未指定 → 扫描所有 skill 的 5 维评分，展示 TOP-10 低分列表

2. 读取历史指标（如有）
   - 读取 {skill}/.evolve/metrics.json
   - 展示：上次进化时间、总轮数、平均提升、策略命中历史
   - 如果 avg_score_delta < 5 或 total_rounds >= 5 → 提示"效率偏低，考虑 skill-creator 重写"

3. 创建 git 分支：evolve/{skill}/YYYYMMDD
   cd ~/.claude/skills && git checkout -b evolve/{skill}/YYYYMMDD

3. 基线评估
   - 按 5 维 rubric 完整评分（维度5 必须跑子agent测试）
   - 记录基线总分和各维度分

4. 设计测试集
   - 设计 3-5 个测试 prompt（覆盖 happy path + 复杂场景 + 已知失败场景）
   - 保存到 {skill}/test-prompts.json
```

### ✓ 关卡 0：用户确认

展示给用户并**等待确认**：
```
进化范围：[skill 列表]
基线评分：[每个 skill 的 5 维得分]
测试 prompt：[每个 skill 的测试集]
```

用户确认后才进入 Phase 1。

---

## Phase 1: 信号收集 + 差距理解

### 信号收集

按优先级依次尝试，取到数据就停：

| 优先级 | 信号源 | 读取方式 | 退化 |
|--------|--------|---------|------|
| 1 | `traces.jsonl` | 读目标 skill 目录下的部署轨迹 | 无 → 降级到 2 |
| 2 | `.stats/usage.jsonl` | skill-stats 格式的使用频率 | 无 → 降级到 3 |
| 3 | 基线评分 | Phase 0 的 5 维评分 | 始终可用 |

**无 traces 时的引导**：
> "当前无部署轨迹数据。建议：(1) 先使用 skill 一段时间积累数据 (2) 在每次使用后记录 traces.jsonl (3) 配置 PostToolUse hook 自动记录。本次将使用评分驱动。"

### 差距理解

对每个候选 skill，输出结构化差距报告：

```
## 差距报告：{skill-name}

### 擅长（从 success 归纳）
- ...

### 失败模式（从 fail/partial 归纳）
- 失败点1：...（出现 N 次）
- 失败点2：...（出现 M 次）

### 评分短板交叉验证
- 维度X得分Y → 与失败模式Z 相关

### 差距描述 Δ
- 该 skill 应能做到 [A] 但实际在 [B] 场景下失败
- 根因分析：[C]
```

### ✓ 关卡 1：用户确认

展示差距报告，用户确认 Δ 是否准确。用户可补充或修正差距描述。

---

## Phase 2: 多策略探索 + 对比学习

### K=6 策略矩阵

| 策略 | 决策轴 | 核心操作 | 详细指南 |
|------|--------|---------|---------|
| S1: 指令精化 | 指令粒度 | 模糊动词→精确操作序列+参数 | [S1](references/evolution-strategies.md#s1) |
| S2: 工作流重组 | 流程拓扑 | 步骤合并/拆分/重排 | [S2](references/evolution-strategies.md#s2) |
| S3: 边界增强 | 容错范围 | IF-ELSE/fallback/校验/兜底 | [S3](references/evolution-strategies.md#s3) |
| S4: 上下文优化 | 信息密度 | 拆分过密/补示例/调模板 | [S4](references/evolution-strategies.md#s4) |
| S5: 范式转换 | 组织范式 | 线性↔决策树↔状态机↔表格 | [S5](references/evolution-strategies.md#s5) |
| S6: 拆分/合并 | 边界重组 | 大skill拆分 / 相关skill合并 | [S6](references/evolution-strategies.md#s6) |

### 执行流程

```
Step 1: K=6 子 agent（model=sonnet）并行应用不同策略
        各自基于原始 SKILL.md + Δ 差距描述，完整改写目标段落
        → 用 ctx_index(content=完整候选, source="{skill}-S{k}") 存储
        → 响应只返回摘要（≤500字）：评分 + 关键改动 + 策略名
        ⚠️ 不用 Write/Edit 写文件（子 agent 无写入权限）
        ⚠️ 不在响应中返回完整候选内容（浪费 token）

Step 2: 主 agent 用 ctx_search(queries=["完整候选"], source="{skill}-S{k}")
        按需检索各候选 → 逐个评分 + 用 test-prompts.json 测试
        → 标记 τ+(success) 和 τ-(failure)
        ⚠️ 不要一次拉取所有 6 个候选到主 context，按需检索

Step 3: 对比学习（Δr 提取）
        a. 逐段 diff：每个候选 vs 原始（用 ctx_search 按 source 检索），标记差异段 {D1..Dn}
        b. 分类：Di 在成功版本 → +，在失败版本 → -，两者都有 → =
        c. 提取：Δr = {+段} \ {=段}（排除中性段）
        d. 排序：按出现在成功版本中的频率降序
        e. 输出：Δr 列表，标注每个差异段的置信度

Step 4: 选最优候选
        - 评分最高的候选 → 主推荐
        - Δr 置信度最高的策略 → 辅助参考
        - 两者不一致 → 同时展示，由用户选择
```

### ✓ 关卡 2：用户确认

展示给用户：
```
最优候选：S{k}（评分 {X}，原始 {Y}，Δ +{Z}）
对比分析：成功关键差异段 [列表]
策略命中：S{k} 在 K=6 中表现最佳
完整候选：[6个候选的评分排名]

其他候选摘要：
- S1: 评分XX（指令精化方向）
- S2: 评分XX（工作流重组方向）
...
```

用户确认使用哪个策略。用户可指定非最优的候选。

---

## Phase 3: 精准应用

**原则：准确完整地改写目标段落，不是打补丁。**

```
1. 基于 Phase 2 用户确认的策略，用 ctx_search 检索最优候选完整内容
   → 主 agent 直接应用改写到目标 SKILL.md（主 agent 有写权限）
   - 需要改的部分 → 完整重写（不是在原文上加 if-else 补丁）
   - 不涉及的段落 → 保持原样不动

2. 改写要求：
   - 改后的段落必须自成逻辑（不依赖上下文中的隐含假设）
   - 新增的边界条件必须给出具体操作（不是"适当处理"）
   - 改动后的整体结构必须连贯（不能出现断裂或矛盾）

3. git commit（message: "evolve {skill}: {策略}-R{轮次}-{改动摘要}"）
```

### ✓ 关卡 3：用户确认

展示完整 diff（不是摘要，是 git diff）：
```
改动范围：[涉及的段落/章节]
改动原因：[对应差距 Δ 的哪部分]
预期效果：[解决哪个失败模式]

--- git diff ---
[完整 diff 内容]

--- 评分预估 ---
改前总分：XX
预估改后：≥ XX+5（维度X提升）
```

用户逐段确认。不满意 → 指出具体段落，回到 Step 1 重写该段落。

---

## Phase 4: 独立审计

**强制要求**：全新上下文子 agent（model=opus），不继承任何进化过程信息。

给子 agent 的输入：
- **BEFORE**: 原始 SKILL.md 的副本（`cp SKILL.md SKILL.md.before`）
- **AFTER**: 改写后的 SKILL.md
- [auditor-guide.md](references/auditor-guide.md)
- 1 个**未在进化过程中使用过**的新测试 prompt

**prompt 中必须明确标注**：
```
文件 A (标记为 BEFORE): {绝对路径}/SKILL.md.before — 这是原始版本
文件 B (标记为 AFTER): {绝对路径}/SKILL.md — 这是改写后的版本
请先读 BEFORE，再读 AFTER，对比时始终引用标记名
```

**不给**：Δ 差距描述、Phase 2-3 的分析、测试 prompt 集、策略选择记录

**审计完成后**：`rm SKILL.md.before`

**不给**：Δ 差距描述、Phase 2-3 的分析、测试 prompt 集、策略选择记录

### 10 项审计清单

| # | 检查项 | 要点 | FAIL处理 |
|---|--------|------|---------|
| 1 | Framing | 问题/范围准确定义？ | 重写开头 |
| 2 | Literals | 路径/命令/参数字面正确？ | 修正 |
| 3 | Script bloat | 不必要的 scripts？ | 删除 |
| 4 | Untraceable imperative | 模糊指令→具体步骤？ | 补充 |
| 5 | Shape-bake | 格式过度硬化？ | 泛化 |
| 6 | Coverage | 声明场景都有流程？ | 补充 |
| 7 | X-ref | 引用路径可达？ | 修正 |
| 8 | Under-abstraction | 重复逻辑？ | 提取 |
| 9 | Silent-bypass | 关键步骤可被跳过？ | 加检查 |
| 10 | Overfit | 换新prompt测试，仍有效？ | 补充通用性 |

### ✓ 关卡 4：用户确认

展示审计报告：
```
审计结果：X/10 PASS，Y FAIL
通过项：[列表]
失败项 + 原因：[列表]

处理建议：
- FAIL ≤ 2：修复失败项 → 重审（只审失败项）
- FAIL ≥ 3：放弃本轮改动 → git revert → 回 Phase 2 换策略
```

用户确认处理方案。

---

## Phase 5: 部署验证

```
Step 1: 子 agent（model=sonnet）用 test-prompts.json 全部测试
        + traces.jsonl 中记录过的失败场景（如有）

Step 2: 验证三个维度
        a. 失败场景改善：之前 fail 的 prompt 现在 pass 了吗？
        b. 成功场景不退化：之前 pass 的 prompt 仍然 pass 吗？
        c. 新场景可用：审计中用的新 prompt 也通过吗？

Step 3: 记录日志 + 更新指标
        a. 追加一条 JSON 到 {skill}/.evolve/evolution-log.jsonl
        b. 更新 {skill}/.evolve/metrics.json（total_rounds, avg_score_delta, strategy_hits）
        c. git add + commit:
           cd ~/.claude/skills
           git add {skill}/.evolve/ {skill}/SKILL.md
           git commit -m "evolve {skill}: R{轮次} score {before}→{after}"
```

### ✓ 关卡 5：用户确认

```
部署验证结果：
- 测试 prompt 通过率：X/Y
- 失败场景改善：[具体 prompt 的 before/after]
- 退化检查：无退化 / [退化列表]

本轮总结：
- 策略：S{k}
- 评分：{before} → {after}（Δ +{N}）
- 审计：{X}/10 PASS
- 部署：{通过率}

操作：
- r < R：继续下一轮 / 暂停 / 收工
- r = R：合并到主分支 / 暂停 / 不合并
```

用户选择下一步。

---

## 进化效率度量

每次进化完成后，更新效率指标：

```
策略命中率 = 成功轮次 / 总轮次（跨所有 skill 累积）
平均提升 = Σ(delta_score) / 成功轮次
审计通过率 = 首审通过轮次 / 总轮次
部署通过率 = 首次部署通过轮次 / 总轮次
```

当策略命中率 < 30% 或平均提升 < 5 分时，在 Phase 0 提示用户"进化效率偏低，建议检查策略库或考虑 skill-creator 重写"。

---

## 异常处理

| 场景 | 处理 |
|------|------|
| 无 traces + 无 usage | 纯评分驱动，提示积累数据 |
| K=6 全部失败 | 转入 skill-creator 重写（传递 Δ + 失败模式 + 策略记录） |
| 审计子 agent 不可用 | **中止本轮**，不可跳过审计（非降级为自审） |
| 部署验证退化 | `cd ~/.claude/skills && git revert HEAD`，立即回滚 |
| Phase 4 FAIL≥3 | `cd ~/.claude/skills && git revert HEAD`，回 Phase 2 换策略 |
| 嵌套 git repo | 进入该目录执行 git 操作 |
| R 轮全未通过 | 展示所有记录 + metrics.json，用户决定重写或暂停 |
| 想恢复旧版本 | `cd ~/.claude/skills && git log --oneline {skill}/SKILL.md` 找到目标 commit → `git checkout {sha} -- {skill}/SKILL.md` |
| skill 目录无 .evolve | 自动创建 `.evolve/` + `evolution-log.jsonl` + `metrics.json` |

---

## 约束规则

1. **完整改写** — 需要改的段落完整重写，不打补丁
2. **不改核心功能** — 优化"怎么执行"，不改"做什么"
3. **独立审计** — Phase 4 必须新上下文 + opus，不可降级
4. **可回滚** — 所有改动在 git 上
5. **部署闭环** — 必须回测，不能只看评分
6. **策略多样性** — 必须跑满 K=6，不可减少
7. **关卡不可跳** — 每个用户确认关卡必须等待回复
8. **维度5 不可干跑** — 评分必须实测，不可模拟
9. **Runtime 中立** — 不引入 runtime 硬编码
10. **R 轮 ratchet** — 只保留有改进的版本
11. **模型匹配** — 探索用 sonnet，审计用 opus
12. **Token 节约** — 子 agent 用 ctx_index 存候选、ctx_search 取候选，不在响应中传输完整内容
13. **写入集中** — 所有文件写入由主 agent 执行，子 agent 不直接写文件（避免权限问题）
14. **路径锚定** — 子 agent prompt 必须包含绝对路径，且第一步 ls 验证
15. **审计隔离** — Phase 4 审计用 `.before` 副本 + BEFORE/AFTER 标记，防止文件混淆
16. **测试守卫** — 测试 agent 首步必须验证目标文件存在，不存在则立即终止

---

## 使用方式

```
"进化 brainstorm skill"      → Phase 0-5 完整流程（R=3）
"优化所有 skills"             → Phase 0 筛选 → 逐个进化
"brainstorm 输出太泛化"       → Phase 0-5，重点 S1+S3
"审计 brainstorm skill"       → 只执行 Phase 4
"查看进化历史"                → 读 evolution-log.jsonl
"评估 brainstorm 质量"        → 只执行 Phase 0
"重写 brainstorm skill"       → 跳过进化，直接 skill-creator
```

---

## 致谢

- **[SkillEvolver](https://arxiv.org/abs/2605.10500)** — 策略多样化探索、对比学习、独立审计、部署驱动精化、过拟合检查
- **[darwin-skill](https://github.com/alchaincyf/darwin-skill)** — 评估 rubric 思路、git ratchet 机制、Runtime 适配性审查
