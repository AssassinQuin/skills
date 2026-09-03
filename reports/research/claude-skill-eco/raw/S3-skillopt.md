# SkillOpt: Executive Strategy for Self-Evolving Agent Skills
- url: https://arxiv.org/abs/2605.23904
- fetched: 2026-09-03

Authors: Yifan Yang, Ziyang Gong, Weiquan Huang, Qihao Yang, Ziwei Zhou, Zisu Huang, Yan Li, Xuemei Gao, Qi Dai, Bei Liu, Kai Qiu, Yuqing Yang, Dongdong Chen, Xue Yang, Chong Luo

(View PDF | HTML (experimental) | Code: https://aka.ms/skillopt)

## Abstract

Agent skills today are hand-crafted, generated one-shot, or evolved through loosely controlled self-revision, none of which behaves like a deep-learning optimizer for the skill, and none of which reliably improves over its starting point under feedback. We argue the skill should instead be trained as the external state of a frozen agent, with the same discipline that makes weight-space optimization reproducible. SkillOpt is, to our knowledge, the first systematic controllable text-space optimizer for agent skills: a separate optimizer model turns scored rollouts into bounded add/delete/replace edits on a single skill document, and an edit is accepted only when it strictly improves a held-out validation score. A textual learning-rate budget, rejected-edit buffer, and epoch-wise slow/meta update make skill training stable while adding zero inference-time model calls at deployment. Across six benchmarks, seven target models, and three execution harnesses (direct chat, Codex, Claude Code), SkillOpt is best or tied on all 52 evaluated (model, benchmark, harness) cells and beats every per-cell competitor among human, one-shot LLM, Trace2Skill, TextGrad, GEPA, and EvoSkill skills. On GPT-5.5 it lifts the average no-skill accuracy by +23.5 points in direct chat, by +24.8 inside the Codex agentic loop, and by +19.1 inside Claude Code. Transfer experiments further show that optimized skill artifacts retain value when moved across model scales, between Codex and Claude Code execution environments, and to a nearby math benchmark without further optimization.

## Submission history

From: Yifan Yang [view email]

- [v1] Fri, 22 May 2026 17:59:50 UTC (329 KB)
- [v2] Mon, 25 May 2026 17:58:16 UTC (329 KB)

## Metadata (arXiv citation fields)

- citation_arxiv_id: 2605.23904
- citation_date: 2026/05/22
- citation_online_date: 2026/05/25
- citation_pdf_url: https://arxiv.org/pdf/2605.23904
- citation_author: Yang, Yifan; Gong, Ziyang; Huang, Weiquan; Yang, Qihao; Zhou, Ziwei; Huang, Zisu; Li, Yan; Gao, Xuemei; Dai, Qi; Liu, Bei; Qiu, Kai; Yang, Yuqing; Chen, Dongdong; Yang, Xue; Luo, Chong
