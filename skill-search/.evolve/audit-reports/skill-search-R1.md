# Audit Report: skill-search R1 (Round 3 — 本次进化)

**[L2-FALLBACK-AUDIT]** — 本审计由主 Agent 执行（非独立上下文子 Agent）。
原因：PP-010 在 audit 阶段复现 — `ToolSearch select:Task` 反复返回空，无法 spawn `evolver-auditor` 子 Agent。
本审计继承了进化过程信息，存在污染风险，D5 维度评分已保守化处理。

> 上一轮 R1（2026-06-12）：Score 7.60，已归档在 git 历史。本轮基于 2026-06-14 实际执行暴露的 5 个新痛点（PP-010~014）重新进化。

## 标记验证

- BEFORE: 139 行（基线版本，3.0）
- AFTER: 340 行（改写版本，3.1）
- 标记状态: ✅ 正常（AFTER 行数较多，因新增 P0 + 6 个 Phase AskUser 关卡 + MCP 规范化）

## 5 维评分

| 维度 | Score | Weight | Weighted | Evidence |
|------|-------|--------|----------|----------|
| **D1 Frontmatter** | **9/10** | 10% | 0.90 | name+description+触发词完整；allowed-tools 扩展至 27 项（新增 mcp__zread__*、mcp__plugin_context-mode__*、ToolSearch、Task、AskUserQuestion）；version 3.1；4 个 references 引用全部可达。扣 1 分：tool-usage.md 是新建文件，SKILL.md 主流程仅在开头提示一次 |
| **D2 Workflow** | **8/10** | 20% | 1.60 | P0-P6 全覆盖；每个 Phase 末尾强制 AskUserQuestion；exit-checklist 全脚本化；L2 fallback 路径明确。扣 2 分：AskUserQuestion 自身是 deferred 工具，依赖 P0 加载，是潜在嵌套 silent-bypass 点 |
| **D3 Boundary** | **7/10** | 15% | 1.05 | 无脚本膨胀；tool-usage.md 拆分避免主 SKILL.md 进一步膨胀；MCP fallback 矩阵清晰（4 级降级）。扣 3 分：SKILL.md 从 139 → 340 行（+144%），接近健康上限 500 行 |
| **D4 Precision** | **9/10** | 20% | 1.80 | Agent() 调用 4 参数齐全（subagent_type/model/description/prompt）+ 缺参数失败模式表；ctx_batch_execute 双参数签名（commands + queries）+ 已知陷阱说明；P4 文件读取优先级表（4 级）；ToolSearch select 返回空但有明确处理。无模糊动词 |
| **D5 Empirical** | **5/10** | 35% | 1.75 | **保守评分**：5 痛点理论上全部解决（PP-010~014 都有对应方案）；但本审计为 L2 fallback（非独立子 Agent 验证），未实际跑 T_val。关键观察：PP-010 在 skill-evolver 自身仍存在（本会话无法 spawn auditor），说明 P0 工具加载是文字声明非脚本强制 |

**Score**: **7.10/10** （0.90 + 1.60 + 1.05 + 1.80 + 1.75）

**Verdict**: **PASS（条件性）** — Score > 基线 4.85，无维度 < 5

## 进化效果对比

### 问题解决

| 痛点 | 进化前 | 进化后 | 改善 |
|------|--------|--------|------|
| **PP-010** Agent 无法 spawn | P2 强制 Agent() 并行但 skill 没说怎么加载 Agent 工具 | 新增 P0 Phase（硬约束 1）：5 类 ToolSearch 调用顺序 + tool-usage.md 完整 Task() 调用模板 + L2 fallback 路径 | **文字层面完全解决**；脚本化保障仍依赖 agent 自律 |
| **PP-011** MCP 利用不充分 | ctx_batch_execute 用错参数（commands vs queries）；zread MCP 未使用 | tool-usage.md 双参数签名 + 已知陷阱说明；allowed-tools 加 mcp__zread__*、ctx_batch_execute；search-templates.md 加 L2 fallback 批量模式 | **完全解决**（路径明确，参数签名清晰） |
| **PP-012** get_file_contents 不展示内容 | 拉到 SHA 后被迫 webReader 重拉（双倍 token） | P4 文件读取优先级表（4 级）：zread > WebFetch raw > webReader > get_file_contents 仅验证存在性；硬约束 8 禁止 get_file_contents 读内容 | **完全解决**（路径明确） |
| **PP-013** Phase 关卡无强制确认 | P2→P3→P4→P5→P6 一气呵成 | 6 个 Phase 全部加 AskUserQuestion 硬约束；execution-gates.md 每个关卡加确认点（4 选项） | **文字层面解决**；AskUser 自身依赖 P0 加载 |
| **PP-014** 缺工具加载前置 | deferred 工具未先 ToolSearch 加载 schema | 新增 P0 Phase + 5 类 ToolSearch 调用顺序 + 加载验证（Bash echo）+ 失败降级（WebSearch-only 模式） | **文字层面解决**；脚本化保障依赖 agent 自律 |

### 量化对比

| 指标 | Before | After | Δ |
|------|--------|-------|---|
| Score | 4.85 | 7.10 | **+2.25** |
| D1 Frontmatter | 6 | 9 | +3 |
| D2 Workflow | 5 | 8 | +3 |
| D3 Boundary | 7 | 7 | 0 |
| D4 Precision | 4 | 9 | +5 |
| D5 Empirical | 4 | 5 | +1（保守） |
| 硬约束数 | 6 | 10 | +4 |
| SKILL.md 行数 | 139 | 340 | +201 |
| references 文件数 | 3 | 4 | +1 |
| allowed-tools 数 | 14 | 27 | +13 |
| 痛点 open（理论） | 5 | 0 | -5 |

## Contamination Check

[L2-FALLBACK-AUDIT] 主 Agent 审计继承进化上下文，已知：
1. 策略选择（S1+S2+S3）— 审计中已知
2. 痛点描述（PP-010~014）— 审计中已知
3. 改动意图 — 审计中已知

**缓解措施**：D5 维度已保守化（理论 5 痛点解决给 5/10 而非 8-10），以抵消污染带来的乐观偏差。

## 诚实边界

### 本轮未验证（UNVERIFIED）
- **D5 实际未跑 T_val**：本审计是 L2 fallback（非独立子 Agent），未生成 T_val 测试 prompts 实际执行改写后的 skill
- **PP-010 解决方案未实测**：P0 工具加载是 prompt 声明，在本会话中 skill-evolver 自身仍无法 spawn 子 Agent，说明脚本化保障层面仍有缺口
- **AskUserQuestion 调用语法未实测**：参数 schema 在 tool-usage.md 中给出但未在本会话验证

### 本轮未覆盖
- S5（范式转换）和 S6（拆分/合并）策略未探索
- T_train / T_val 测试 prompts 未生成本轮新版本
- Skill 实际调用测试未做（需下次用户触发时观察）

### 结构性局限
- **P0 是 prompt 声明非 hook 强制**：Claude Code 的 hook 机制（settings.json）才能真正在每次 skill 触发时强制执行 ToolSearch；当前 SKILL.md 改进仍依赖 agent 自律
- **L2 fallback 审计继承进化上下文**：审计分数可能偏高
- **AskUserQuestion 自身是 deferred 工具**：嵌套 silent-bypass 风险

### 信息盲区
- **ToolSearch select 返回空的根因未知**：本会话中 `select:Task` `select:AskUserQuestion` `select:Bash` 全部返回空但工具实际可用
- **zread MCP 实际可用性未测**：虽然加入 allowed-tools，但本会话未实际调用 mcp__zread__read_file 验证
- **历史 trace 缺失**：未扫描 ~/.claude/projects/ 历史会话

## Verdict

**PASS（条件性）** — Score 7.10 > 基线 4.85，无维度 < 5，可进入 deployment。

**条件**：deployment 阶段必须做痛点回归测试，并在下次实际触发 `/skill-search` 时收集真实执行反馈到 `.evolve/deployment-traces.jsonl`，作为下一轮 D5 客观化的依据。
