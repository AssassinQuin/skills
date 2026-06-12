# Prose Craft

Writing quality engine. Three-layer voice system: document type → discourse community → styleguide. Calibrates tone, rhythm, and precision using classic writing references.

## Trigger

写文章、prose、写作、改写、润色、文案、writing、edit prose、voice

## Quick Start

```
/prose-craft 帮我写一篇关于 AI Agent 架构的技术博客
/prose-craft 润色这段项目介绍，目标读者是投资人
/prose-craft 用 On Writing Well 的风格改写这段
```

## Workflow

1. **Layer 1: Document Type** — What does this document do? (inform, persuade, instruct, entertain)
2. **Layer 2: Discourse Community** — Who is the audience? What do they already know?
3. **Layer 3: Conventions** — What styleguide fits? Auto-select or let user choose.
4. **Voice Calibration** — Set voice statement based on the three layers.
5. **Draft & Polish** — Write with calibrated voice, then tighten.

## Built-in Styleguides

| Styleguide | Best For | Reference |
|-----------|----------|-----------|
| Elements of Style | Precision, brevity | Strunk & White |
| On Writing Well | Non-fiction clarity | Zinsser |
| Dreyer's English | Copy editing precision | Dreyer |
| Microstyle | Micro-copy, headlines | Johnson |
| Lessons in Clarity & Grace | Academic/professional | Williams & Bizup |

## Directory Structure

```
SKILL.md                    # Core instructions
references/
  elements-of-style.md      # Strunk & White summary
  on-writing-well.md        # Zinsser summary
  dreyers-english.md        # Dreyer summary
  microstyle.md             # Johnson summary
  lessons-in-clarity-and-grace.md  # Williams & Bizup summary
```

## See Also

- doc-coauthoring — Structured document co-authoring workflow
- storytelling — Narrative and story structure
- humanizer — Humanize AI-generated text
