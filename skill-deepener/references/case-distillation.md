# Case Distillation（失败案例沉淀方法论）

来源：Reflexion (arXiv:2303.11366) + ECC `rules-distill` + Anthropic evaluation-first。

把 Domain-Skill Agent 的真实失败轨迹沉淀为可复用 case library。

---

## 案例生命周期

```
P2 反推（真实执行）→ 案例萃取 → P4 沉淀 → references/case-library.md → P5 评审 → 持久化
```

---

## Step 1: 萃取（P2 输出）

每个失败案例必须含 5 字段：

```markdown
### 案例 {N}: {任务类型简述}

- **触发场景**：{什么时候会遇到}
  - 例：用户要求修一个 Go 项目中的 panic
  - 反例："修 bug"（太泛）

- **失败模式**：{agent 实际怎么错的}
  - 例：直接改了 panic 行，未发现根因是 nil map 初始化顺序
  - 反例："修复不彻底"（无具体行为）

- **Expert 正确做法**：{专家怎么做}
  - 例：先 `go test -run {panic 复现}` + 用 `delve` 跟踪调用栈 + 排查 init 顺序
  - 反例："找到根因"（无具体步骤）

- **对应规则**：{SKILL.md 哪条 do/don't 防这个}
  - 例：coder/SKILL.md L150 "Bug 修复 → 语义定位 → 修复 → 回归测试"
  - 反例："coder skill 会处理"（无引用）

- **可追溯证据**：{Domain-Skill Agent 轨迹行号 + 时间}
  - 例：trajectory.json L45-L62，2026-06-18 T3 跑 V1
  - 反例："实验观察"（无证据）
```

---

## Step 2: 沉淀（P4 写入）

案例库的 3 种格式（按 skill 类型选）：

### 格式 A：单文件 case-library.md（适合执行型 skill）

```
{target_skill}/references/case-library.md

# 失败案例库

## Go 项目

### Case 1: nil map panic
- 触发：{...}
- 失败：{...}
- Expert：{...}
- 规则：{...}
- 证据：{...}

## Python 项目
...
```

### 格式 B：嵌入 SKILL.md（适合 references < 3 个的小 skill）

在 SKILL.md 的对应 Phase 后加：

```markdown
### Step 3: 加载历史经验

> 💡 专家视角 + 失败案例：
>
> **案例**：某次任务 memory_search 返回 0 条经验，agent 未标注 "⚠️ 无历史经验"
> 提醒，用户首次踩坑。后续规范：0 条必须显式标注，提醒用户风险。
>
> **教训**：memory_search limit=5 是上限不是目标，0 条也要给信号。
```

### 格式 C：拆为多 reference（适合案例 > 10 个）

```
references/
├── cases-go.md
├── cases-python.md
├── cases-tooling.md
└── cases-general.md
```

---

## Step 3: 案例质量过滤（P5 评审标准）

不是所有失败都值得沉淀。3 层过滤：

### 层 1：可复现性

案例必须可在类似场景复现。**独特偶发**不入库。

```
# 通过：Go 项目 nil map panic（多个项目可能遇到）
# 拒绝：用户项目特定的 race condition（仅此一次）
```

### 层 2：教学价值

案例必须能教 agent 某个原则。**纯操作错误**不入库。

```
# 通过：agent 没问根因直接修 bug → 教"先 reproduce"
# 拒绝：agent typo 写错变量名 → 操作错误，不是方法论问题
```

### 层 3：通用性

案例必须能跨项目复用。**单项目特有配置**不入库。

```
# 通过：Edit 工具 Tab 缩进陷阱（所有 Go 项目都遇）
# 拒绝：用户公司内部 CI 配置错误
```

---

## Step 4: 与 ECC rules-distill 协同

案例沉淀后，**可被 skill-evolver 的 cross-skill principles 提取**复用。

```
案例库 (skill-deepener 产出)
  ↓
ECC rules-distill 风格提取
  ↓
rules/common/{topic}.md（跨 skill 共性）
```

例：
- coder/case-library.md 有 "Tab 缩进陷阱" 案例
- skill-search/case-library.md 有 "SearXNG 韩文盲区" 案例
- 共性："工具 fallback 必须显式标注" → rules/common/tool-fallback.md

---

## 反例（必须避免）

### 反例 1：编造案例

```
# 错误
"案例：agent 在某任务中失败了，原因是..."
```
**问题**：无证据。必须来自 P2 真实轨迹。

### 反例 2：案例过少 happy path

```
# 错误
案例 1: 用户问 X，agent 答 X，用户满意。
```
**问题**：教学价值低。失败模式才能教 agent。

### 反例 3：案例与规则脱节

```
# 错误
案例：agent 失败了。
规则：（SKILL.md 没有对应条目）
```
**问题**：案例必须能映射到具体规则。

---

## 持久化建议

- **单 skill 案例库** ≤ 30 个（超过拆 sub-file）
- **每条案例** ≤ 200 字（过长拆"完整版" + "TL;DR"）
- **每季度清理**：移除 > 1 年未触发的案例（Currency 维度）
- **Memory 同步**：高频案例同步到 memory（tag: `case-{skill-name}`）

---

## 与 memory_search 的关系

案例库 + memory 双层：

| 层 | 内容 | 触发 |
|---|------|------|
| references/case-library.md | 经过 P5 评审的高质量案例 | skill 加载时 |
| memory（tags: `case-*`） | 实时积累的临时案例 | task 开始时 memory_search |

定期：临时案例 → 评审 → 升级为 references 案例库。
