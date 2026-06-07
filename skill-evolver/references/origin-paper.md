# Origin Paper: SkillEvolver

**Title**: SkillEvolver: Skill Learning as a Meta-Skill
**arXiv**: https://arxiv.org/abs/2605.10500
**Authors**: Genrui Zhang, Erle Zhu, Jinfeng Zhou, Caiyan Jia, Hongning Wang
**Date**: May 11, 2026

## Core Thesis

Agent skills are static artifacts — authored once and consumed unchanged. SkillEvolver proposes a lightweight meta-skill that iteratively authors, deploys, and refines domain-specific skills. The learning target is skill prose/code, not model weights.

## Key Concepts

### Meta-Skill Pattern
- SkillEvolver is itself a skill loaded through the same interface as domain skills
- It instructs the agent (SkillEvolver Agent) to author/refine another skill for a target task
- The Domain-Skill Agent is a separate CLI-agent that uses the candidate skill
- Learning signal comes from what the Domain-Skill Agent actually does or fails to do

### Strategy-Diversified Exploration (SDE)
- Before K parallel rollouts, the meta-skill writes a strategy set S={s_1,...,s_K}
- Each strategy specifies a distinct high-level plan (library choice, algorithm family, etc.)
- Unlike temperature sampling which changes wording, SDE covers decision axes
- K=4 throughout the paper

### Contrastive Skill Update
- Compare success trajectories (τ+) vs failure trajectories (τ-)
- Derive a targeted patch from the contrast
- Apply patch to current skill v_r → v_{r+1}

### Fresh-Agent Overfit Audit
- Independent audit in a completely new session/context
- Catches: information leakage, overfitting to training traces
- Catches: **silent-bypass mode** — skill appears valid in content but is never invoked at runtime

### Deployment-Grounded Learning
- Refine only AFTER deploying the candidate skill
- Learning signal from deployment failures, not exploratory traces alone
- This is the key distinction from trace-distillation methods

### Contamination Controls
- Layer 1: Train/test split (T_train / T_val)
- Layer 2: Workspace whitelist (audit agent can't see training traces)

## Results
- 56.8% accuracy on 83 SkillsBench tasks (vs 43.6% human-curated, 29.9% no-skill)
- GPU kernel speedup: 1.16 → 1.51 on KernelBench

## Our Implementation Mapping

| Paper Concept | Our Implementation | Gap |
|-------------|-------------------|-----|
| Meta-skill | skill-evolver SKILL.md | ✓ |
| Strategy-diversified exploration | K=6 parallel explorer agents with S1-S6 | ✓ |
| Contrastive update | Comparison learning in exploration phase | Partial — we score but don't explicitly contrast |
| Fresh-agent audit | Independent opus auditor agent | ✓ |
| Silent-bypass detection | Not implemented | **GAP** — we don't check if skill is actually invoked |
| Deployment-grounded learning | Trace collection from sessions | Partial — we collect traces but don't enforce deployment |
| T_train / T_val split | test-prompts.json | ✓ |
| Workspace isolation | Not implemented | **GAP** — auditor can see training context |

## Missing Implementations (Action Items)

1. **Silent-bypass detection**: Audit must check if skill instructions are actually followed, not just present
2. **Git repo detection**: git-setup must detect and target the skill's own repo, not CWD
3. **Phase gate enforcement**: User confirmation must be mandatory, not skippable
4. **Workspace isolation for audit**: Auditor should not see training traces
