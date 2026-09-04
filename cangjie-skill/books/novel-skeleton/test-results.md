# 压力测试结果 — 《小说的骨架：好提纲成就好故事》

> 阶段 4 产出。测试方法：**独立 sub-agent 盲测**（看不到预期答案，只做"该激活哪个 skill"的判断题）。

## 测试方式

- 一次性盲测 16 个 skill 的**触发精度**，重点覆盖**跨 skill 混淆**（同书 16 个 skill 互相抢调用，是部署后最常见的故障）。
- 盲测 agent 只拿到 16 个 skill 的 name + 一句话描述 + 18 条用户 prompt，输出"该激活哪个 skill 或 none"。
- 18 条 prompt 覆盖：should-trigger（各 skill 的典型正面场景）、跨 skill 混淆（故意用相近措辞诱导选错）、诱饵（与写作无关）。

## 结果：18/18 通过（100%）

| # | prompt | 预期 | 盲测 | 结果 |
|---|---|---|---|---|
| 1 | 帮我写一句前提句概括我的故事 | premise-sentence | premise-sentence | ✓ |
| 2 | 帮我把发散出来的点子压缩成一句话 | premise-sentence | premise-sentence | ✓ |
| 3 | 帮我头脑风暴几个可能的方向 | what-if-brainstorm | what-if-brainstorm | ✓ |
| 4 | 我知道结局但中间卡住了 | reverse-outline | reverse-outline | ✓ |
| 5 | 帮我盘点已知场景 | scene-map | scene-map | ✓ |
| 6 | 帮我采访反派角色 | character-interview | character-interview | ✓ |
| 7 | 我的人物到底想要什么 | character-engine | character-engine | ✓ |
| 8 | 场景太平淡怎么加冲突 | conflict-engine | conflict-engine | ✓ |
| 9 | 帮我挖主角的过去 | backstory-iceberg | backstory-iceberg | ✓ |
| 10 | 帮我搭三幕结构 | structure-three-act | structure-three-act | ✓ |
| 11 | 这个场景该用谁的视角 | pov-selection | pov-selection | ✓ |
| 12 | 一堆零散场景帮我整理 | scene-map | scene-map | ✓ |
| 13 | **只帮我写个前提句就够了** | premise-sentence（非流水线） | premise-sentence | ✓ |
| 14 | 纠结要不要写提纲怕束缚 | outline-mindset | outline-mindset | ✓ |
| 15 | 有素材帮我整理成完整提纲 | novel-outline-pipeline | novel-outline-pipeline | ✓ |
| 16 | 帮我写第一章正文 | none | none | ✓ |
| 17 | 帮我查 API 参数 | none | none | ✓ |
| 18 | 故事中间拖沓怎么搭结构 | structure-three-act | structure-three-act | ✓ |

## 关键结论

- **跨 skill 混淆全部通过**：最危险的 #13（"只写前提句"）正确路由到 `premise-sentence` 而非 `novel-outline-pipeline`；#4（已知结局卡住）正确路由到 `reverse-outline` 而非 `scene-map`。
- **诱饵容错为 0**：#16（写正文）、#17（查 API）都被正确判为 none，没有误激活。
- **结论**：16 个 skill 的 `description`（A2 触发场景）边界清晰，无互相抢调用问题。

## 说明

- 本次为**合并盲测**（18 prompt 覆盖整包 skill 的触发精度），重点验证了 cangjie-skill 的"硬性要求"——跨 skill 混淆。
- 每个 skill 的 `test-prompts.json`（darwin 兼容，含 3 should_trigger + 2 诱饵 + 1 edge）已就绪，可交由 darwin-skill 做**逐条 ratcheting 自动进化**（会跑 per-case 测试并记录各自通过率）。
