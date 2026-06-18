# Phase 1 Axes — v0 → v1 改进点

基于上次执行复盘 + 用户 3 个方向。

## 上次执行 FM 映射

| FM | 上次违反 | 对应 Axis |
|---|---|---|
| FM-RUBRIC | 用 10 分制而非 D1-D8 40 分制 | Axis 1 |
| FM-UNVERIFIED | references/ 6 文件零读取但给 9.0 | Axis 3 |
| FM-RAW-LOSS | raw/ 未保存子 agent 原始输出 | Axis 5 |
| FM-SKIP-CHECK | examples/ 未检查、MCP 调用统计未记 | Axis 4 + 6 |
| FM-CONTEXT-LEAK | Issue #8 + 韩文 SKILL.md 全文进上下文 | Axis 9 |
| FM-MODE-MISSING | "单仓库评估"未正式定义 | Axis 10 |

## 用户 3 个方向映射

| 用户方向 | 对应 Axis |
|---|---|
| 1. 借鉴其他 skill 搜索/分析 skill | 待 researcher 返回 → 注入 Axis 1/4 |
| 2. 优先用 git mcp / searxng mcp | Axis 7 + 8 |
| 3. 主语言优先 + 中英补充 | Axis 2 |

---

## Axis 清单（10 个）

### Axis 1: Rubric 严格化（FM-RUBRIC，P0）
- **现状**：evaluation-rubric.md 已定义 D1-D8 40 分制，但 SKILL.md 流程未强制使用
- **目标**：P4 Exit 增加"按 evaluation-rubric.md D1-D8 40 分制打分"，禁止自定义分制
- **补丁位置**：execution-gates.md P4 Exit + SKILL.md P4 段落

### Axis 2: 主语言优先搜索（用户方向 3，P1）
- **现状**：默认中英双语并行，未检测仓库主语言
- **目标**：P1 增加"主语言检测"（GitHub repo metadata `language` 字段 + README 前几行扫描）；P2/P5 按主语言调整搜索词优先级
- **示例**：韩文仓库 → 先 Naver Blog / Tistory / Namuwiki，再英文 Reddit/HN，最后中文知乎/V2EX
- **补丁位置**：SKILL.md P1 + 新增 `references/language-strategy.md`

### Axis 3: references/ 强制深读（FM-UNVERIFIED，P0）
- **现状**：只读 SKILL.md + README.md
- **目标**：P4 Exit 增加"至少深读 2 个 reference 文件（被 SKILL.md 反复引用的优先）"
- **补丁位置**：execution-gates.md P4 Exit + SKILL.md P4 段落

### Axis 4: examples/test-prompts 检查（FM-SKIP-CHECK，P1）
- **现状**：未检查
- **目标**：P4 Exit 增加"检查 examples/ 或 test-prompts.json，不存在则明确标记'缺失'"
- **补丁位置**：execution-gates.md P4 Exit + SKILL.md P4 段落

### Axis 5: raw/ 强制保存（FM-RAW-LOSS，P0）
- **现状**：未保存子 agent 原始输出
- **目标**：每个子 agent 输出原样存 `raw/scout-{role}-{lang}-{timestamp}.json`
- **补丁位置**：execution-gates.md P6 Exit + SKILL.md P6 段落

### Axis 6: MCP 调用统计（FM-SKIP-CHECK，P1）
- **现状**：只标 spawn 数
- **目标**：透明度声明列出所有 MCP 调用次数（github ×N / zread ×N / searxng ×N / Agent ×N）
- **补丁位置**：execution-gates.md P6 Exit + SKILL.md P6 段落

### Axis 7: git mcp 充分利用（用户方向 2，P1）
- **现状**：仅用 search_repositories + list_issues
- **目标**：加 4 个调用
  - `list_releases` — 看最新 release 判断维护活跃度
  - `list_commits` — 看最近 commit 判断僵尸仓库（>6 个月未更新警告）
  - `list_tags` — 看版本管理质量
  - `search_code` — P4 验证 SKILL.md 实际存在（不依赖目录结构假设）
- **补丁位置**：search-templates.md Scout-GH + P4 检查项

### Axis 8: searxng mcp 充分利用（用户方向 2，P1）
- **现状**：基本未用，主靠 spawn agent（重）
- **目标**：
  - Scout-Community 主力用 `searxng_web_search`（轻量，直接进主上下文可控）
  - 只在需要 `web_url_read` 深读时才 spawn agent
  - 加 `searxng_search_suggestions` 做关键词扩展（P1 阶段）
- **补丁位置**：search-templates.md Scout-Community + SKILL.md P5 段落

### Axis 9: token 节省（FM-CONTEXT-LEAK，P2）
- **现状**：长文档全文进上下文（Issue body + SKILL.md 韩文）
- **目标**：长 SKILL.md (>300 行) / 长 Issue body (>2000 字) 用 `ctx_index` + `ctx_search` 取关键段
- **补丁位置**：硬约束新增 + search-templates.md token 策略

### Axis 10: 单仓库评估正式分支（FM-MODE-MISSING，P1）
- **现状**：无正式定义
- **目标**：新增"评估模式 E1: 单仓库深度评估"
  - 触发条件：用户明确给 GitHub URL 或 `repo:owner/name`
  - 可省 Phase：P2 多源发现 / P3 粗筛（因为候选只有 1 个）
  - 不可省：P4 完整深读 + P5 双源社区 + P6 全套保存
  - exit-checklist 独立
- **补丁位置**：SKILL.md 新增段落 + execution-gates.md 新增 E1 Exit

---

## 优先级分组（待 researcher 返回后整合）

**P0 必修**（合规性）：Axis 1, 3, 5
**P1 应修**（用户明确方向）：Axis 2, 4, 6, 7, 8, 10
**P2 优化**（token 效率）：Axis 9
