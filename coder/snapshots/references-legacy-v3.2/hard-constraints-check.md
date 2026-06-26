# 硬约束执行检查清单

v8.1 Check 10（硬约束自验证）适配。每个 coder 任务结束前必须输出此清单。

## 6 项检查

| # | 硬约束 | ✓ 标准 | ✗ 信号 |
|---|--------|--------|--------|
| 1 | **上下文加载** | 加载了表声明的全部 references（按项目类型） + 输出 `📂 已加载: [列表]` | 加载声明但无 `📂` 输出；汇报缺 "references 引用点" 字段 |
| 2 | **工具链探测** | 扫描 Makefile/Taskfile/justfile/package.json + 标记自动生成目录 + memory_store 持久化 | 探测声明但未扫描；探测到生成目录但未 memory_store |
| 3 | **验证链执行** | lint → type → test 全链走完 + 区分预存失败 | 只跑 test 不跑 lint；预存失败当成新引入失败处理 |
| 4 | **审查门控触发** | 复杂度=标准 → Layer 1 + 语义覆盖复核；复杂度=复杂 → Layer 2 强制 | 标准路径跳过自审；复杂路径不触发 Layer 2 |
| 5 | **经验总结** | 含失败/中断场景触发 + 输出 "本次无新经验" 或具体经验 + 标准 tag | 任务失败回滚时跳过经验总结；tag 命名不一致（如 `coder-Python`） |
| 6 | **Token 预算** | 主上下文 ≤ 30k + 长文件 ctx_index | 主上下文 >30k 无标注；长文件全文 Read |

## 输出格式（嵌入汇报）

```markdown
## 硬约束执行检查（v3.0）
- [✓] 1. 上下文加载：已加载 5 个 references（go-tooling / go-editing-traps / go-verification-loop / go-conventions / core-protocols）
- [✓] 2. 工具链探测：扫描到 Makefile + gf gen ctrl，自动生成目录：service/ + dao/，已 memory_store tag=coding-go-toolchain
- [✓] 3. 验证链执行：golangci-lint ✓ + go vet ✓ + go test ✓（预存 1 个失败已标注）
- [✓] 4. 审查门控触发：复杂度=复杂（含 auth）→ Layer 1 + Layer 2 强制
- [✓] 5. 经验总结：本次 1 条新经验（踩坑: tab 缩进导致 Edit 失败），tag=coding-go-gotcha
- [✓] 6. Token 预算：主上下文 ~22k（< 30k ✓）
```

## ✗ 处理

任一项 ✗ 必须在汇报末尾标注 `[⚠️ 硬约束未达标: #{N}]` 并说明原因。**禁止假装 ✓**（违反 skill-evolver v8.1 价值锚定："诚实的 UNVERIFIED 比虚假的 ✓ 更有价值"）。

## 与 skill-evolver Check 10 的关系

skill-evolver v8.1 audit Check 10 检查"硬约束自验证"。coder 通过此清单为 skill-evolver 提供 traces 证据，避免 Check 10 命中。
