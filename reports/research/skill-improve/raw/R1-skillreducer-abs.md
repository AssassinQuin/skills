# [2603.29919] SkillReducer: Optimizing LLM Agent Skills for Token Efficiency
- url: https://arxiv.org/abs/2603.29919
- fetched: 2026-09-04

- Authors: Yudong Gao, Zongjie Li, Yuanyuan Yuan, Zimo Ji, Pingchuan Ma, Shuai Wang
- Subjects: Software Engineering (cs.SE)
- Submitted: v1 on 31 Mar 2026; v2 (current) on 24 Jun 2026
- DOI: https://doi.org/10.48550/arXiv.2603.29919
- PDF: https://arxiv.org/pdf/2603.29919

## Abstract

LLM-based coding agents rely on \emph{skills}, pre-packaged instruction sets that extend agent capabilities, yet every token of skill content injected into the context window incurs both monetary cost and attention dilution. To understand the severity of this problem, we conduct a large-scale empirical study of 55,315 publicly available skills and find systemic inefficiencies: 26.4% lack routing descriptions entirely, over 60% of body content is non-actionable, and reference files can inject tens of thousands of tokens per invocation. Motivated by these findings, we present \textsc{SkillReducer}, a two-stage optimization framework. Stage 1 optimizes the routing layer by compressing verbose descriptions and generating missing ones via adversarial delta debugging. Stage 2 restructures skill bodies through taxonomy-driven classification and progressive disclosure, separating actionable core rules from supplementary content loaded on demand, validated by faithfulness checks and a self-correcting feedback loop. Evaluated on 600 skills and the SkillsBench benchmark, \textsc{SkillReducer} achieves 48% description compression and 39% body compression while improving functional quality by 2.8%, revealing a \emph{less-is-more} effect where removing non-essential content reduces distraction in the context window. These benefits transfer across five models from four families with a mean retention of 0.965, and generalize to an independent agent framework.

## Submission history

- From: Zongjie Li
- [v1] Tue, 31 Mar 2026 15:57:53 UTC (997 KB)
- [v2] Wed, 24 Jun 2026 01:45:48 UTC (997 KB)

---
以下为页面原始抓取内容（webReader 正文，含 arXiv 页面导航样板的原文，供溯源核对）：

[2603.29919] SkillReducer: Optimizing LLM Agent Skills for Token Efficiency

Skip to main content

arXiv is now an independent nonprofit!
Learn more

Search / Submit / Donate / Log in

# Computer Science > Software Engineering

__arXiv:2603.29919__ (cs)

Submitted on 31 Mar 2026 (v1), last revised 24 Jun 2026 (this version, v2)

Title: SkillReducer: Optimizing LLM Agent Skills for Token Efficiency

Authors: Yudong Gao, Zongjie Li, Yuanyuan Yuan, Zimo Ji, Pingchuan Ma, Shuai Wang

(摘要正文见上方 Abstract 节，与页面 citation_abstract/og:description 一致)

| Subjects: | Software Engineering (cs.SE) |
| Cite as: | arXiv:2603.29919 [cs.SE] |
|  | (or arXiv:2603.29919v2 [cs.SE] for this version) |

Full-text links: View PDF / HTML (experimental) / TeX Source

Current browse context: cs.SE

References & Citations: NASA ADS, Google Scholar, Semantic Scholar
Bibliographic tools: BibSonomy, Reddit, Bibliographic Explorer, Connected Papers, Litmaps, scite.ai
Code & Data links: alphaXiv, CatalyzeX Code Finder, DagsHub, GotitPub, Huggingface, ScienceCast, Replicate, Spaces, TXYZ.AI
Recommenders: Influence Flower, CORE Recommender
