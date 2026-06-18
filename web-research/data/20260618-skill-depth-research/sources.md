# 信息源 + 知识空白

## 调研执行统计

| 维度 | 执行情况 |
|------|---------|
| 子 agent 数 | 3 spawn（论文 + 开源 skill + 方法论灵感） |
| 成功 agent | 2（论文 + 方法论灵感） |
| 中断 agent | 1（开源 skill 因 API 529） |
| 主 agent 补救 | github 搜索 + zread 深读 4 个候选 |
| 总 tool_uses | ~25 |
| 预算超支 | 否（30 内） |

## 论文 agent 输出（7 篇）

按可借鉴度排序：
1. ⭐⭐⭐ Codified Human Expertise (arXiv:2601.15153)
2. ⭐⭐⭐ Agent-as-a-Judge (arXiv:2508.02994)
3. ⭐⭐⭐ Agent Skills 综述 (arXiv:2602.12430)
4. ⭐⭐ Voyager (arXiv:2305.16291)
5. ⭐⭐ Reflexion (arXiv:2303.11366)
6. ⭐ SAGE (arXiv:2512.17102)
7. ⭐ SkillsBench (arXiv:2602.12670)

## 方法论 agent 输出（3 方法 + 3 灵感）

方法论：
1. ⭐⭐⭐ Cognitive Apprenticeship（Model/Coach/Scaffold/Fade）
2. ⭐⭐ Prompt Distillation（teacher LLM + contrastive loss）
3. ⭐⭐⭐ Anthropic 反推法（evaluation-first）

灵感：
1. ⭐⭐⭐ Skill 路由没有算法（纯 description 语义匹配）
2. ⭐⭐ 结构化 prompt 在反直觉指令上更强
3. ⭐⭐⭐ Anthropic 反 monolithic + Always hand-edit

## 开源 skill 主 agent 补救输出（4 个）

| 仓库 | Stars | 深度证据 | 借鉴点 |
|------|-------|---------|--------|
| multica-ai/andrej-karpathy-skills | 177k | 80 行单文件，4 原则专家语言 | micro-skill 极致案例 |
| affaan-m/ECC | 217k | 198 个 micro-skill 目录 | skill 库架构 |
| ECC/rules-distill | - | 三阶段 + 6 verdicts + 3 层过滤 | cross-skill principles 提取 |
| ECC/skill-stocktake | - | 4 维 holistic 判断 + 5 verdicts | skill 库审计 |

## 知识空白（未覆盖方向）

| 方向 | 原因 | 建议 |
|------|------|------|
| Distilling Step-by-Step / PaD 论文 | "knowledge distillation into prompt" query 因 API 529 失败 | 后续手工 arxiv 检索 |
| 更多 ECC 内部 skill 深读（continuous-learning-v2 / prompt-optimizer） | 预算限制 | 后续按需深读 |
| Meta Llama skill library | 搜索结果未命中 | 后续直接搜 meta.ai |
| 国内 skill 库（除 huashu-nuwa） | 搜索未覆盖 | 后续知乎/V2EX 单独搜 |
| Anthropic 32 页 skill guide 原文 | 仅找到 Reddit 讨论未拿到原文 | 后续 platform.claude.com 直接读 |

## 工具降级记录

- 论文 agent: SearXNG 失效（返回 arxiv 首页）→ 降级 WebSearch
- 开源 skill agent: API 529 中断（19 tool_uses 后）→ 主 agent github search 补救
- 方法论灵感 agent: SearXNG 完全失效 → 降级 web-search-prime 成功

## 验证完整性

- 所有 URL 真实可达（论文 arxiv / github / anthropic 官方）
- 无 AI 编造内容
- 关键引文均标注来源
- 知识空白显式标注（不掩盖）
