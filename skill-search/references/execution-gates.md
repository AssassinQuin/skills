# 执行门控

每个 Phase 的 exit-checklist。**全部打勾才能进入下一阶段**，任何一项未通过就停在当前阶段补完。

每个 Phase 末尾必须调用 `AskUserQuestion` 强制确认。未收到确认禁止进入下一 Phase。

## P0 Exit Checklist（工具加载）

```
□ ToolSearch select:Agent,Bash,WebFetch,AskUserQuestion 已执行
□ ToolSearch select:mcp__github__* 已执行
□ ToolSearch select:mcp__web-search-prime__*,mcp__web-reader__webReader,WebSearch 已执行
□ ToolSearch select:mcp__zread__* 已执行
□ ToolSearch select:mcp__plugin_context-mode_context-mode__ctx_batch_execute,ctx_search 已执行
□ Bash 验证：echo "tools loaded" 可执行
□ AskUserQuestion 确认进入 P1
```

**降级**：加载失败 → 标注 `[TOOL-LOAD-FAIL]`，降级到 WebSearch-only 模式。

## P1 Exit Checklist（需求解析）

```
□ 四组搜索词已生成（中英双语）
   - 功能词 / 同义词 / 上下游词 / 生态词
□ AskUserQuestion 确认搜索词范围
   - 选项 A：使用当前搜索词进入 P2
   - 选项 B：用户补充/调整搜索词
   - 选项 C：限定技术栈/平台
```

## P2 Exit Checklist（多源搜索）

```
□ Scout-GH: search_repositories 返回 >= 5 个候选
   → 不足：用同义词/上下游词扩展搜索词重试
□ Scout-BuiltIn 第一层：~/.claude/skills/ 已扫描（用 ctx_batch_execute）
□ Scout-BuiltIn 第二层：marketplaces.json 已读取，registry 已遍历
   → 无市场源：跳过但记录"未注册商城"
□ Scout-BuiltIn 第三层：Web 搜索已执行
□ Scout-Market：至少 2 个垂直平台已搜索
□ Scout-Community：英文和中文信息源分别搜索，分开记录
□ Scout-Expand：Top 3 候选的关联网络已追踪
□ 总候选数 >= 10
   → 不足：回到 Scout-GH 用关联词组扩展
□ 子 Agent 实际 spawn 数已记录（如 5/5 或 L2 fallback, 0 spawn）
□ AskUserQuestion 确认候选池（选项：继续 P3 / 补充搜索词 / 跳过某 Scout）
```

## P3 Exit Checklist（粗筛）

```
□ 每个候选的 stars/issues/forks 已获取
□ 有 SKILL.md 的候选 >= 5 个
□ 淘汰记录已生成（每个一行原因）
□ AskUserQuestion 确认 Top 5 进入深读
```

## P4 Exit Checklist（深读）

```
□ P2 未使用 search_code 做发现（若使用了，丢弃结果重搜）
□ 每个候选先 mcp__zread__get_repo_structure 检查目录（不做根目录假设）
□ 多 Skill 仓库已识别（SKILL.md 在 skills/ 子目录）
□ SKILL.md + README.md 已用 mcp__zread__read_file 或 WebFetch raw URL 读取
   → 禁止用 mcp__github__get_file_contents 读内容（只返回 SHA）
□ examples/ 或 test-prompts.json 已检查（没有则标记"缺失"）
□ 每个候选已按 evaluation-rubric.md 打分（8 维 40 分制）
□ AskUserQuestion 确认深读报告
```

## P5 Exit Checklist（社区口碑）

```
□ Top 3-5 候选的 GitHub Issues 已读取
□ 英文社区反馈已搜索（Reddit/HN/Medium/Dev.to）
□ 中文社区反馈已搜索（知乎/V2EX/掘金/CSDN）
□ 每条反馈标注来源 + 日期
□ 中英文反馈差异已标注
□ AskUserQuestion 确认口碑采集完成
```

## P6 Exit Checklist（综合报告）

```
□ 报告包含需求摘要
□ 每个候选有：来源/Stars/定位/优缺点/Issue/社区反馈(分中英文)/安装建议/适合谁
□ 淘汰记录在附录
□ 搜索覆盖统计（GitHub/Marketplace/内置/英文社区/中文社区）
□ 搜索查询记录（中文/英文分开）
□ 执行透明度声明：
   - 子 Agent spawn 数（如 5/5 或 L2 fallback, 0 spawn）
   - MCP 工具调用统计（search_repositories: X 次, zread: Y 次 等）
   - Fallback 触发记录（哪些工具降级到了什么）
□ AskUserQuestion 确认最终报告
```

## 多 Skill 仓库处理

部分仓库（如 `sanyuan-skills`、`alirezarezvani/claude-skills`）是 Skill 合集，SKILL.md 不在根目录。

处理步骤：
1. `mcp__zread__get_repo_structure` 查看目录树
2. 根目录无 SKILL.md → 检查 `skills/` 子目录
3. 找到匹配用户需求的子 Skill → 用 `mcp__zread__read_file` 读取其 SKILL.md
4. 在报告中注明"来自合集 {仓库名} 的 {子 Skill 名}"
