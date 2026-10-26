---
name: cangjie-skill
description: Distill a book, long-video transcript, podcast, course, or interview into a coherent set of executable skills. Use when the user asks to "拆书" / "蒸馏一本书" / "把 XX 书做成 skill" / "把这个视频/播客/课程蒸馏成 skill" / "turn a book or video into skills" — i.e. wants the frameworks, principles, and methodologies in long-form content extracted into atomic, reusable Codex skills that an agent can invoke in real-world situations. NOT for simple summarization, book reviews, or role-playing as the author (that is huashu-nuwa's job).
metadata:
  cangjie.version: "2.5.0"
  deployment: wrapper
---

# cangjie-skill deployment wrapper

This global entry is a routing wrapper only. The upstream remains unmodified at:

`/Users/ganjie/skill-vendors/cangjie-skill/`

When this skill is invoked:

1. Read `/Users/ganjie/skill-vendors/cangjie-skill/SKILL.md` and follow it as the authoritative methodology.
2. Resolve every methodology, extractor, script, document, benchmark, and output path relative to `/Users/ganjie/skill-vendors/cangjie-skill/`, not to this wrapper directory.
3. Do not recursively expose the vendor directory as global skills; install or copy a selected capability into this repository only after the user confirms it is needed.
4. Keep the vendor checkout unmodified. Updates should replace the vendor directory, then refresh this wrapper if upstream frontmatter or entry path changes.
