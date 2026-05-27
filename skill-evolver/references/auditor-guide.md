# 独立审计详细指南 — Phase 4

Phase 4 审计时读取本文件。

---

## 审计执行要求

**必须用全新上下文子 agent（model=opus）**。只给子 agent：
- 原始 SKILL.md
- 补丁后的 SKILL.md
- 本文件

**不给**：Phase 1-3 的分析结果、进化过程记录、信号数据、测试 prompt。

---

## 逐项检查方法

### 1. Framing（问题定义）
- 读 SKILL.md 前 3 段
- 检查：是否清楚说明解决什么问题、为谁、什么场景用
- FAIL：开头直接跳到步骤，没有问题定义

### 2. Literals（字面量正确性）
- 提取所有文件路径、命令、URL、参数名
- 检查：路径存在？命令合法？参数名与实际一致？
- FAIL：路径指向不存在的文件、命令拼写错误

### 3. Script bloat（脚本膨胀）
- 列出所有引用的 scripts/ 文件
- 检查：每个 script 是否在流程中被实际调用？有无重复功能？
- FAIL：引用了未使用的 script，或新引入了不必要的 script

### 4. Untraceable imperative（模糊指令）
- 搜索泛化动词：处理、优化、分析、生成、检查、调整、确保
- 检查：每个泛化动词后是否有具体操作步骤或参数
- FAIL："处理一下边界情况"（没有具体方法）

### 5. Shape-bake（过度硬化）
- 检查输出格式要求
- 检查：是否在不需要固定格式的地方硬编码了格式？
- FAIL：所有场景都要求 JSON，但有些场景用户需要 Markdown

### 6. Coverage（场景覆盖）
- 对比 frontmatter description 声明的功能
- 检查：每个声明功能是否都有对应流程步骤
- FAIL：description 说"支持批量处理"但流程只有单文件

### 7. X-ref（交叉引用）
- 收集所有 `[text](path)` 引用
- 检查：文件是否存在？路径正确？
- FAIL：引用 `references/advanced.md` 但文件不存在

### 8. Under-abstraction（重复逻辑）
- 寻找相同或非常相似的步骤/指令出现 2+ 次
- 检查：是否可以提取为变量或共用段落
- FAIL：3 个步骤都写了"如果失败则回滚 git"

### 9. Silent-bypass（静默跳过）
- 模拟执行每个步骤
- 检查：是否有步骤可在不报错的情况下被跳过
- FAIL："如果找不到配置文件就跳过"，但后续步骤依赖配置

### 10. Overfit（过拟合检查，来自论文）

这是防止"补丁只对测试 prompt 有效"的关键检查。

**检查方法**：
1. 用一个**未在进化过程中使用过**的新 prompt 测试补丁后的 skill
2. 对比：补丁后的 skill 在新 prompt 上的表现是否也优于补丁前？
3. 检查补丁内容是否只针对特定 prompt 的措辞做了特殊处理

**FAIL 信号**：
- 补丁后的 skill 对测试 prompt 表现好，但换一个类似 prompt 就不 work
- 补丁中出现了对特定 prompt 关键词的硬匹配（如"当用户说 XXX 时..."）
- 补丁只在某个狭窄场景生效，但 description 声明了更广的范围

**通过标准**：补丁在至少 1 个未见过的新 prompt 上也表现出改善。

---

## 审计报告格式

```markdown
## Audit Report: {skill-name} Round {N}

| # | Check | Result | Note |
|---|-------|--------|------|
| 1 | Framing | PASS | - |
| 2 | Literals | FAIL | 路径 `scripts/xxx.py` 不存在 |
| ... | ... | ... | ... |
| 10 | Overfit | PASS | 新prompt测试通过 |

**Summary**: X/10 PASS, Y FAIL
**Verdict**: PASS / NEEDS-FIX / REJECT
```

保存到 `.evolve/audit-reports/{skill}-R{round}.md`
