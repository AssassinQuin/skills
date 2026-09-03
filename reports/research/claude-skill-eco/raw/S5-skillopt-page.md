# Executive Strategy for Self-Evolving Agent Skills (SkillOpt project page)
- url: https://microsoft.github.io/SkillOpt/
- fetched: 2026-09-03

Project webpage for SkillOpt, a text-space optimizer that trains reusable natural-language skills for frozen language agents.

## Project Video

SkillOpt in motion. A short visual overview of how SkillOpt treats natural-language skills as trainable artifacts: roll out, reflect, edit, validate, and export.

(Promotional video for the SkillOpt project page. The static paper teaser is shown below for high-resolution inspection.)

## Paper Teaser

The core loop at a glance. The teaser summarizes the SkillOpt training loop: rollout evidence, optimizer-side reflection, bounded skill edits, validation gating, and the exported reusable skill.

(Figure: SkillOpt teaser figure showing the target model, optimizer model, bounded edits, validation gate, and exported best skill — https://microsoft.github.io/skillopt-assets/teaser-1.png)

### A skill is external state for an agent.

Instead of fine-tuning a model or hand-maintaining prompts, SkillOpt runs the frozen agent on scored batches, asks an optimizer model to propose structured edits, and accepts a candidate only when validation performance improves.

Key elements: Frozen target model | Optimizer model | Add / delete / replace edits | Held-out gate

1. __Rollout__ — The target model executes tasks with the current skill and records scored trajectories.
2. __Reflect__ — The optimizer analyzes success and failure minibatches to find reusable procedures.
3. __Edit__ — Candidate add, delete, and replace operations are merged and ranked under a budget.
4. __Gate__ — The candidate skill is kept only if it improves held-out selection performance.

### Evidence

Rollout batches capture messages, tool calls, verifier feedback, task metadata, and final scores.

### Minibatches

Failures and successes are reflected separately so edits correct recurring errors while preserving working behavior.

### Bounded Edits

An edit budget functions as a textual learning rate, preventing useful rules from being overwritten by broad rewrites.

### Memory

Rejected edits, slow update, and optimizer-side meta skill provide longer-horizon feedback without bloating deployment.

(Figure: SkillOpt pipeline showing rollout, reflection, bounded edits, validation gate, slow update, and meta skill — https://microsoft.github.io/skillopt-assets/pipeline-1.png)

## Method comparison

SkillOpt clears the strongest baseline on every benchmark.

| Component | Setting | SearchQA | Spreadsheet | LiveMath |
| --- | --- | --- | --- | --- |
| Learning rate | lr=4 default | __87.1__ | __77.5__ | __61.3__ |
| Learning rate | without lr | 84.6 | 75.7 | 57.3 |
| Rejected buffer | with buffer | __87.1__ | __77.5__ | __61.3__ |
| Rejected buffer | without buffer | 85.5 | 72.9 | 58.9 |
| Update memory | meta skill + slow update | __87.1__ | __77.5__ | __61.3__ |
| Update memory | without both | 86.3 | 55.0 | 59.7 |

### What the ablations say

__Bounded__ — Textual learning rates prevent destructive rewrites while keeping enough plasticity to learn new procedures.

__Gated__ — Held-out selection turns reflection into propose-and-test optimization rather than unconditional self-editing.

__Buffered__ — Rejected edits become negative feedback, helping the optimizer avoid repeating harmful directions.

(Figure: Epoch checkpoint trends for SpreadsheetBench, SearchQA, and LiveMath — https://microsoft.github.io/skillopt-assets/epoch-trends-1.png)

Epoch checkpoint trends from the paper. Selection-best checkpoints are compared with train rollout score and unseen test performance. Accepted edits become the current skill only after held-out selection improves. Step 3 is rescued by a slow update; Step 4 trains higher but fails selection.

## Highlights

- Cross-model __+15.2__ — GPT-5.4 LiveMath skill transferred to GPT-5.4-nano on LiveMathBench.
- Cross-harness __+31.8__ — Codex-trained SpreadsheetBench skill transferred into Claude Code.
- Self-optimizer __+10.4__ — GPT-5.4-nano used as its own optimizer improved SpreadsheetBench over baseline.
- Deployment __1 file__ — The target model consumes only the final skill, not optimizer memory.

A stronger optimizer model gives the largest gains, but the loop is not merely distillation from a stronger model. Even matched target-as-optimizer settings can discover useful edits when the update is constrained, buffered, and validated.

## BibTeX

```bibtex
@article{yang2026skillopt,
  title={Skillopt: Executive strategy for self-evolving agent skills},
  author={Yang, Yifan and Gong, Ziyang and Huang, Weiquan and Yang, Qihao and Zhou, Ziwei and Huang, Zisu and Li, Yan and Gao, Xuemei and Dai, Qi and Liu, Bei and others},
  journal={arXiv preprint arXiv:2605.23904},
  year={2026}
}
```
