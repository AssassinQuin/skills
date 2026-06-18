# coder v3.0 Axes — 综合 19 历史 PP + v8.1 协议适配

## 来源映射

| Axis | 来源 |
|------|------|
| 1 Skill 类型显式标注 | v8.1 Gate 1 (Phase 1 Step 2b 强制) |
| 2 Token 预算硬约束 | v8.1 Gate 4 + PP-7 (历史: Read 5 文件 ~40KB 进 context) |
| 3 硬约束自验证清单 | v8.1 Check 10 (硬约束自验证) + PP-9 + PP-19 |
| 4 references 加载证据 | PP-9 (声明加载但未实际加载) |
| 5 工具链探测持久化 | PP-22 (无框架工具链探测 → 已加，但未持久化) |
| 6 新语言扩展 checklist | PP-15 (通用骨架与语言细节耦合) |
| 7 审查门控自动化 | PP-19 (后置审查无强制 → 已加门控，但触发条件模糊) |
| 8 memory tag 标准化 | PP-20 (memory_search tags 不匹配) |

## 详细 Axes

### Axis 1: Skill 类型显式标注（P0）
- **现状**：frontmatter 无 `skill_type` 字段
- **目标**：加 `skill_type: execution` 让 skill-evolver Phase 1 自动识别
- **patch 位置**：coder/SKILL.md frontmatter

### Axis 2: Token 预算硬约束（P0）
- **现状**：PP-7 已部分解决（"Read 5 文件"），但无量化预算
- **目标**：单次任务主上下文 ≤ 30k tokens；长文件（>300 行）强制 ctx_index
- **patch 位置**：coder/SKILL.md 约束段 + 新增 references/token-budget.md

### Axis 3: 硬约束自验证清单（P0）
- **现状**：5+ 个"强制，不可跳过"硬约束（上下文加载/经验总结/审查门控/工具链探测）
- **目标**：每次任务结束前，输出"硬约束执行检查清单"（每条 ✓/✗ + evidence）
- **patch 位置**：coder/SKILL.md 汇报段 + 新增 references/hard-constraints-check.md

### Axis 4: references 加载证据（P1）
- **现状**：加载表声明，但执行时可能跳过（PP-9）
- **目标**：每次加载 reference 后输出"📂 已加载: [文件列表]"作为执行证据
- **patch 位置**：coder/SKILL.md 上下文加载段 + core-protocols.md

### Axis 5: 工具链探测结果持久化（P1）
- **现状**：探测到自动生成目录后，约束"禁止手动编辑"，但探测结果未存
- **目标**：探测完成后 `memory_store(content="环境: {工具} 关键命令: {命令}", tags="coding-{lang}-toolchain")`
- **patch 位置**：coder/SKILL.md 理解段 Step 4

### Axis 6: 新语言扩展 checklist（P2）
- **现状**：SKILL.md "新增语言扩展" 段仅 1 行
- **目标**：加最小集合 checklist（tooling + editing-rules + verification-loop + conventions）
- **patch 位置**：coder/SKILL.md "新增语言扩展"段

### Axis 7: 审查门控自动化（P1）
- **现状**：Layer 1 自审 + Layer 2 深度审计，但触发条件含糊（"完整路径自动触发"）
- **目标**：复杂度 ≥ 标准 → 强制 Layer 1；复杂度 = 复杂 → 强制 Layer 2
- **patch 位置**：coder/SKILL.md 审查门控段

### Axis 8: memory tag 标准化（P1）
- **现状**：core-protocols.md 用 `{language} coding gotcha`，未明确 tag 命名
- **目标**：定义标准 tag：`coding-{lang}-gotcha` / `coding-{lang}-convention` / `coding-{lang}-toolchain`
- **patch 位置**：core-protocols.md 经验持久化段

## Phase 3 Patch 策略

surgical patch（不重写）：
- SKILL.md 多处 Edit（frontmatter + 上下文加载 + 理解 Step 4 + 审查门控 + 汇报 + 约束）
- core-protocols.md Edit（references 加载证据 + memory tag 标准化）
- 新增 references/token-budget.md
- 新增 references/hard-constraints-check.md
