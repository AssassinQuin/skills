# Baseline Score: coder v5.0 vs v3.2

**日期**: 2026-06-22
**评估方法**: STRUCTURAL_SCORE(结构 + spec 合规分析)
**非**: EMPIRICAL_SCORE(真实 Domain-Skill Agent 执行 — 需要 Phase 2-4)
**评估者**: skill-evolver v8.0 Phase 1 Initialize
**honesty gate**: 符合 v8.1(模型可基于结构打分,但必须标记为 STRUCTURAL)

---

## Rubric(5 维度,对应用户 5 个评估重点)

| 维度 | 评估重点 |
|---|---|
| D1 | Anthropic skill 规范合规(progressive disclosure) |
| D2 | Router 形态清晰可执行 |
| D3 | 并行 subagents 设计(Phase 1/3/5)|
| D4 | memory MCP 替代语言 references |
| D5 | 整体可执行性 + 完整度 |

每维 0-10 分。

---

## 详细评分

### D1: Anthropic 规范合规度

**v5.0 = 9.0 / 10**
- ✅ SKILL.md 203 行(≤500 硬性,接近 ≤200 理想)
- ✅ frontmatter v2 规范(只 name + description + metadata)
- ✅ §7 references 索引表显式
- ✅ §9 加载规则(progressive disclosure 显式)
- ✅ 14 references 按 phase 按需加载
- ⚠️ 203 行略超 200 目标(可接受,接近理想)

**v3.2 = 6.0 / 10**
- ⚠️ SKILL.md 246 行(超 200)
- ⚠️ frontmatter 含 `allowed-tools`(v1 规范,已废弃)
- ⚠️ references 加载规则分散在各 Phase(无统一索引)
- ⚠️ 没有 progressive disclosure 显式分层
- ✅ 但整体可读

**Δ = +3.0**

---

### D2: Router 形态清晰度

**v5.0 = 8.5 / 10**
- ✅ §2 7 Phase 路由表(执行者/输入/输出/下一 Phase)
- ✅ §3 语言路由细则(Go/Python/TS/Rust)
- ✅ §8 降级策略表(6 场景)
- ✅ §9 新语言扩展协议(4 步)
- ⚠️ 缺每 Phase 的执行 checklist(在 references 里,需要加载)

**v3.2 = 7.0 / 10**
- ✅ Phase 1-4 流程清楚
- ⚠️ 没有"路由表"概念,是线性流水线
- ⚠️ 退出条件分散
- ⚠️ 没有显式降级策略表

**Δ = +1.5**

---

### D3: 并行 subagents 设计

**v5.0 = 8.0 / 10**
- ✅ Phase 1: 3 路并发(explorer + get_architecture + researcher)
- ✅ Phase 3: N oracle 并发(2-4,决策表 + 命名约定 A/B/C/D)
- ✅ Phase 5: 3 reviewer 并发(正确性/S.U.P.E.R/安全)
- ✅ 互不可见设计(借鉴 brainstorm-collider)
- ✅ 失败处理(50% 重试,全失败降级)
- ⚠️ 并发 prompt 模板是 skeleton(step 2 待扩充)
- ⚠️ 未实战验证 oracle 输出 schema 一致性

**v3.2 = 4.0 / 10**
- ❌ 零并发
- ✅ spawn go-coder / python-coder(单一)
- ❌ Phase 3 无 parallel exploration
- ❌ Phase 5 无 reviewer 并发

**Δ = +4.0**(最大差距)

---

### D4: memory MCP 替代语言 references

**v5.0 = 8.5 / 10**
- ✅ tag 规范清晰(8 个 tag,4 tier 分配)
- ✅ 写入权限分层(子 agent 项目级;共享/全局级 🔒 用户确认)
- ✅ seed 策略(Q7:模型告知 + 用户确认,3 选项)
- ✅ 降级策略(Q9:不回退,裸跑 + ⚠️)
- ✅ 检索策略(memory_search 注入子 agent prompt)
- ⚠️ seed-memory.py 未实现(step 3.5)
- ⚠️ 首次使用体验依赖用户确认(可能影响 adoption)

**v3.2 = 5.0 / 10**
- ❌ 没有 memory tier 概念(只有项目级)
- ⚠️ 经验总结 tag(coding-{lang}-gotcha 等)是项目级
- ⚠️ 语言知识在文件里,不可累积
- ✅ 但 v3.2 production 可用(不依赖 memory MCP)

**Δ = +3.5**

---

### D5: 整体可执行性 + 完整度

**v5.0 = 6.5 / 10**(关键短板)
- ✅ SKILL.md router 形态可立即被 AI 加载
- ✅ 14 references 骨架就位(skeleton)
- ✅ 5 个 agent allowed-tools 扩展完成
- ✅ 失败模式覆盖(§8 降级 + R12)
- ⚠️ **references 是骨架,实战内容待 step 2 补**
- ⚠️ **seed-memory.py 未实现,memory 链路不通**
- ⚠️ **没经过真实任务测试**
- ⚠️ 子 agent prompt 模板未实战

**v3.2 = 8.5 / 10**(production 优势)
- ✅ 已生产可用
- ✅ references 内容完整(非骨架)
- ✅ 实战验证过(round 1-9 audit pass 10/10)
- ⚠️ 没并发
- ⚠️ 没 memory-first

**Δ = -2.0**(v5.0 唯一劣处)

---

## 总分对比

| 维度 | v5.0 | v3.2 | Δ | 评价 |
|---|---|---|---|---|
| D1 Anthropic 规范 | 9.0 | 6.0 | **+3.0** | v5.0 大幅领先 |
| D2 Router 清晰度 | 8.5 | 7.0 | **+1.5** | v5.0 略优 |
| D3 并行设计 | 8.0 | 4.0 | **+4.0** | v5.0 大幅领先(最大差距) |
| D4 memory-first | 8.5 | 5.0 | **+3.5** | v5.0 大幅领先 |
| D5 可执行性 | 6.5 | 8.5 | **-2.0** | v3.2 反超(v5.0 未实战) |
| **加权平均** | **8.1** | **6.1** | **+2.0** | **v5.0 净进步** |

---

## 核心结论

### v5.0 是净进步(+2.0),但有 1 个关键短板

**进步面(D1/D2/D3/D4)**:
- 架构升级显著(平均 +3.0)
- 符合 Anthropic 最新规范
- 并行 + memory-first 是质变

**短板(D5)**:
- references 是 skeleton,实战内容待补
- memory seed 脚本未实现,链路不通
- **未经过真实任务验证**

### 这是典型的"架构升级 vs 实战验证" tradeoff

- v5.0 = 设计先进的 skeleton
- v3.2 = production-ready 但架构老

---

## 推荐路径

| 阶段 | 主版本 | 理由 |
|---|---|---|
| 短期(1-2 周) | **v3.2 仍 production** | 覆盖现有任务,无回归风险 |
| 中期(2-4 周) | **v5.0 step 2-3.5 完成** | references 扩充 + seed-memory.py + 并发实战 |
| 长期(1 个月后) | **v5.0 取代 v3.2** | 用 v5.0 跑 3-5 个真实任务验证 |

---

## 风险

1. **references skeleton 太薄**:子 agent 实际跑可能"卡壳"(无具体 prompt 模板)
2. **seed 脚本未实现**:首次使用体验差(memory 空 → 用户必须确认 seed)
3. **parallel 未实战**:oracle/reviewer 输出 schema 可能不一致,合并失败
4. **全局 agent 工具扩展**:explorer/oracle/reviewer 加工具影响 programmer/darwin-skill/code-review 等其他 skill(无害但需观察)

---

## Limitation 声明(per v8.1 honesty gate)

- ✅ 本评分是 **STRUCTURAL_SCORE**(基于 SKILL.md 结构 + spec 合规 + references 骨架)
- ❌ 本评分**不是 EMPIRICAL_SCORE**(未跑 Domain-Skill Agent 真实任务)
- ⚠️ 真实评分需要 Phase 2-4 完整 Algorithm 1(R=2, K=4, V=5),约 1-2 周
- ⚠️ 本评分可用于**架构决策参考**,不能用于"v5.0 一定比 v3.2 好"的承诺
- ⚠️ D5 评分尤其需要真实执行才能确认(v3.2 经验丰富,v5.0 是未知)

---

## CP-01 检查点(Phase 1 Initialize 完成)

| 项目 | 状态 |
|---|---|
| `.evolve/` 工作目录 | ✅ 创建(snapshots/strategies/traces/logs) |
| T_train / T_val 拆分 | ✅ 5 T_train + 2 T_val(类型不重叠) |
| Skill 类型检测 | ✅ 执行型(binary reward) |
| axes.json | ✅ 6 个决策轴 + 4 个 training constants |
| BEFORE snapshot | ✅ coder-v5.0-BEFORE.md + coder-v3.2-BASELINE.md |
| 基线评分 | ✅ STRUCTURAL_SCORE(v5.0=8.1, v3.2=6.1) |
| Limitation 声明 | ✅ STRUCTURAL 非 EMPIRICAL |

**本轮局限**:
- 只评 STRUCTURAL,未跑真实任务(EMPIRICAL)
- 5 个 T_train 任务覆盖度可能不足(未含 deploy / migration 等大场景)
- v3.2 baseline 引用历史 audit pass 数据,可能过时

**等待用户决策**:
- 进入 Phase 2(真进化,需要 spawn Domain-Skill Agent 跑 T_train)
- 或停在 Phase 1(评估已完成,不做进化)
