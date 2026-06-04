## R1 — 2026-06-04
- **策略**：S4（上下文优化）+ S3（边界增强）+ S1（指令精化）
- **为什么改**：SKILL.md 混入了 Go 经验知识（gopls 策略、tab 陷阱、验证循环），应该拆到 references/；委托接口缺少注入参数；缺少边界处理
- **改了什么**：
  1. Go 经验知识拆到 4 个 references 文件（gopls-strategy/editing-traps/verification-loop/go-conventions）
  2. 委托协议升级为 Pre/Inject/Post 三步注入表，每个委托目标有具体 gopls 命令和参数模板
  3. 新增 DO NOT trigger 区 + 前置条件检查（go.mod + gopls 可用性）
- **痛点解决**：PP-1→resolved, PP-2→resolved, PP-3→resolved
- **结果**：评分 5.5 → 7.9（Δ +2.4），T_train 4/4 Pass，T_val 3/3 Pass（100%）
- **遗留**：4 条 WARN（allowed-tools 字段、Phase 2 停止条件、触发词扩展、占位符推导）
