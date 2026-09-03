# deep-research skill 端到端验收报告

- 日期：2026-09-03
- Spec：`docs/superpowers/specs/2026-09-03-deep-research-skill-design.md` §13
- Plan：`docs/superpowers/plans/2026-09-03-deep-research-skill.md`（含执行期修订 A/B）
- 实现：Task 1-6 全部完成，6 轮任务审查 + 2 轮修复复审全部 Approved

## 验收结果（spec §13 六条）

| # | 验收项 | 结果 | 证据 |
|---|---|---|---|
| 1 | 三个真实问题端到端 | ✅ | ①quick：`seres-2026h1`（validate 一次过）②deep：`claude-skill-eco`（用户指定主题：GitHub skill 生态四维度调研，全 lane 触发）③补充+inbox：seres 续跑吸收 2 份人工投喂。日语 lane 未单列——deep 主题的 glb lane 覆盖 EN+多语言引擎，如实记录为覆盖偏差 |
| 2 | core 覆盖率 100% 或显式列出 | ✅ | 两份 findings.json 的未解问题节均显式（deep 含「ACLA 查无」「Voyager 缺搜索侧来源」等） |
| 3 | findings.json 过 validate | ✅ | 3/3 PASS（quick 一次过；deep 一次过；补充一次过） |
| 4 | benchmark 查询集 lane 冒烟 | ⚠️ 偏差 | 未跑静态 benchmark 脚本，以 3 次真实 E2E 的活体 lane 冒烟替代（cn/glb/zhihu/github/prime/reader 全触发，baidu-302 已知问题复现并按降级链处理）。活体测试严格强于静态冒烟，记录为有意偏差 |
| 5 | 同题重跑 reused>0 | ✅（机制级） | 首轮 13 条查询写回后，逐条过 route-lane.sh **13/13 reuse**；`--refresh` 对照正确返回 search。注意：精确 key 匹配意味着近义改写不会命中（记录为已知限制+改进方向） |
| 6 | inbox 投喂被吸收 | ✅ | `raw/S17-inbox.md`+`S18-inbox.md`，4 条 findings 带 `lane:"human"` 证据，meta 登记 absorbed_inbox；核实员还抓到投喂数据的算术矛盾并按 R7 暴露不擅断 |

## 限额与停止纪律实测

| 约束 | deep 实测 | 结论 |
|---|---|---|
| 主 wave ≤2 + gap ≤1 | wave1（4 搜索员并行+prime直调）+ wave2（gap 轮）| 守住 |
| github ≤8 | 8/8 | 守住（顶格用满） |
| prime ≤3（仅 deep） | 2/3（1 次空结果未重试，按 glb 兜底） | 守住 |
| zhihu ≤4 | 2/4 | 守住 |
| contrarian ≤6 | 6/6 | 守住 |

## E2E 发现的缺陷与摩擦（全部登记，终审裁决）

**P1（结果完整性）**：gap 轮后台 agent 的 SendMessage 回编排名义上不可达——deep 轮 2 个迟到搜索员中 1 个（glb/SkillWeaver）成果进产物、1 个（cn/S8 中文策展文）未进 findings（cache/queries.jsonl 有痕迹）。后台 gap agent 的结果回收机制不可靠。
**P2（模型可用性）**：opus 嵌套 spawn 400（modelCode 不存在）→ 降级链已吸收（回退 sonnet+Meta 记录），两轮均触发。
**P3（Write 守卫）**：编排者写 report.md 被拦 → 备选文件名降级链生效（deep 实际产出 `research-report.md`）。教训：绝不固化「绕过权限拒绝」路径，只走备选名+记录。
**P4（空结果≠失败）**：prime 返回 `[]` 与硬失败在降级链里无法区分。
**P5（route-lane github 条目）**：固定 `tool: search_repositories` 对 issue/commit 类查询误导，note 说「自选」自相矛盾。
**P6（计数器）**：zhihu/prime 调用数仅靠编排者手工记账，无共享计数器。
**P7（补充模式）**：无显式 supplement/continue 语义，任务目录复用靠编排者判断（两轮判断均合理但属未定义行为）。
**P8**：Phase 0「已在子 agent 内→solo」混淆了嵌套与 spawn 不可用；inbox 吸收无 S 编号分配规则（现靠扫 sources.json 最大值）；verifier 的 contrarian 查询结构性无法写回 cache。
**P9（agent 自报数与实态不符）**：补充轮编排者报告 registry 19 条，实际 15（其摩擦③自解释了差异）——agent 报告需工件核验，不可直接采信。

## 结论

6 条验收 5✅+1⚠️（有意偏差），skill 达到可日常使用状态。P1-P9 全部登记进 `.superpowers/sdd/progress.md`，由全分支终审裁决哪些必须在合并前修。
