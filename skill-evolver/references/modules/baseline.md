# Module: Baseline（基线评估 + 差距理解）

合并原 Phase 0 + Phase 1。前置条件：无。预估 token：~8K。

## 关卡合并规则

与差距确认合并（关卡 baseline+gap）：
- 合并条件：首次进化 / 无 traces.jsonl / 用户选择快速模式
- 拆分条件：有 traces.jsonl 且用户要求逐步确认（拆为两次独立确认）

## 执行步骤

### Step 1: 确认进化范围

- 用户指定 → 直接使用
- 用户未指定 → 扫描所有 skill 的 5 维评分，展示 TOP-10 低分列表

### Step 2: 读取历史指标

读取 `{skill}/.evolve/metrics.json`，展示：
- 上次进化时间、总轮数、平均提升、策略命中历史
- 如果 `avg_score_delta < 5` 或 `total_rounds >= 5` → 提示"效率偏低，考虑 skill-creator 重写"
- 如果 `avg_token_efficiency < 0.4` → 提示"token 浪费严重，建议优化 prompt 精简度"
- 如果 `fallback_count >= 2` → 提示"ctx_index 稳定性问题"

### Step 3: 创建 git 分支（含并发冲突检测）

```bash
cd ~/.claude/skills
existing=$(git branch --list 'evolve/{skill}/*' | tr -d ' ')
IF -n "$existing"; THEN
  → 终止 baseline 模块
  → 记录日志：{"event":"conflict_detected","branch":"$existing","ts":"..."}
  → 输出："[CONFLICT] 检测到未完成的进化分支: $existing"
  → 输出："请先完成或删除该分支：git branch -D $existing"
ELSE
  git checkout -b evolve/{skill}/$(date +%Y%m%d)
FI
```

### Step 4: 基线评估

按 5 维 rubric 评分。维度 1-4 静态分析，维度 5 子 agent 实测。

**校准锚点（每个维度 3 档）**：

| 维度 | 优秀(8-10) | 合格(5-7) | 不合格(0-4) |
|------|-----------|----------|------------|
| D1 Frontmatter | name + description 50-100字 + 触发词 8-15个 + 版本号 + 适用模型 | name + description + 触发词，缺版本号 | 缺 name 或 description 或无触发词 |
| D2 工作流 | 步骤有前置条件 + checkpoint + fallback + token 预估 | 步骤清晰但缺 fallback 或 token 预估 | 步骤模糊或缺失关键阶段 |
| D3 边界/安全 | 有输入校验 + 输出兜底 + 错误恢复 + 并发保护 | 有部分校验但缺错误恢复 | 无边界处理 |
| D4 指令精度 | 每个动词可直接执行 + 有参数默认值 + 有示例 | 多数指令清晰但部分模糊 | 大量模糊动词 |
| D5 实测效果 | 测试通过率 ≥80% + 无退化 | 测试通过率 60-79% | 通过率 <60% |

### Step 5: 设计测试集

设计 3-5 个测试 prompt，保存到 `{skill}/.evolve/test-prompts.json`：
```json
[
  {"id": "T1", "type": "happy", "prompt": "...", "expect": "..."},
  {"id": "T2", "type": "complex", "prompt": "...", "expect": "..."},
  {"id": "T3", "type": "failure", "prompt": "...", "expect": "..."}
]
```

### Step 6: 初始化 .evolve 目录

```bash
mkdir -p {skill}/.evolve/audit-reports
touch {skill}/.evolve/evolution-log.jsonl
```

### Step 7: 差距分析

**信号收集**（按优先级取第一个有数据的）：

| 优先级 | 信号源 | 读取方式 |
|--------|--------|---------|
| 1 | `traces.jsonl` | `{skill}/.evolve/traces.jsonl` |
| 2 | `.stats/usage.jsonl` | skill-stats 格式 |
| 3 | 基线评分 | Step 4 的 5 维评分（始终可用） |

**差距报告格式**：
```markdown
## 差距报告：{skill-name}

### 擅长
- ...
### 失败模式
- 失败点1：...（出现 N 次）
### 评分短板交叉验证
- 维度X得分Y → 与失败模式Z 相关
### 差距描述 Δ
- 该 skill 应能做到 [A] 但实际在 [B] 场景下失败
- 根因分析：[C]
```

### Step 8: Checkpoint（CP-01）

```bash
cd ~/.claude/skills
git add {skill}/.evolve/test-prompts.json {skill}/.evolve/evolution-log.jsonl
git commit --allow-empty -m "evolve {skill}: baseline+gap-r{r}"
```

## 关卡：用户确认

展示基线评分 + 差距报告 + token 预算分配（总计 100K，baseline ~8K，剩余 ~92K）。

用户确认后进入 exploration 模块。
