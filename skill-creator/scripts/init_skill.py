#!/usr/bin/env python3
"""
Skill Initializer - Creates a new skill with standard directory structure

Usage:
    init_skill.py <skill-name> --path <path>

Examples:
    init_skill.py my-new-skill --path /Users/ganjie/skills
    init_skill.py my-api-helper --path /Users/ganjie/skills
"""

import sys
from pathlib import Path


SKILL_TEMPLATE = """---
name: {skill_name}
description: [TODO: What this skill does + when to use it. Include trigger scenarios.]
---

# {skill_title}

[TODO: Decision table or core workflow. See skill-creator/references/directory-guide.md for patterns.]
"""

README_TEMPLATE = """# {skill_title}

[TODO: 1-2 sentences describing what this skill does]

## Trigger

[TODO: Trigger words and phrases]

## Quick Start

```
/{skill_name} [example prompt 1]
/{skill_name} [example prompt 2]
```

## Workflow

[TODO: High-level steps]

## Directory Structure

```
SKILL.md                    # Core instructions
references/                 # Detailed guides
agents/
  claude-code.yaml          # Sub-agent config
```

## See Also

[TODO: Related skills]
"""

AGENT_TEMPLATE = """interface:
  display_name: "{skill_title}"
  short_description: "[TODO: One-line description]"
  trigger_words: ["{skill_name}"]
  default_prompt: "Use ${skill_name} to [TODO: action]."

agents: []

workflow: []
"""


def title_case_skill_name(skill_name):
    return ' '.join(word.capitalize() for word in skill_name.split('-'))


def init_skill(skill_name, path):
    skill_dir = Path(path).resolve() / skill_name

    if skill_dir.exists():
        print(f"Error: directory already exists: {skill_dir}")
        return None

    skill_title = title_case_skill_name(skill_name)

    try:
        skill_dir.mkdir(parents=True, exist_ok=False)
        print(f"Created: {skill_dir}")

        # SKILL.md
        (skill_dir / 'SKILL.md').write_text(
            SKILL_TEMPLATE.format(skill_name=skill_name, skill_title=skill_title))
        print("  SKILL.md")

        # README.md
        (skill_dir / 'README.md').write_text(
            README_TEMPLATE.format(skill_name=skill_name, skill_title=skill_title))
        print("  README.md")

        # agents/claude-code.yaml
        agents_dir = skill_dir / 'agents'
        agents_dir.mkdir()
        (agents_dir / 'claude-code.yaml').write_text(
            AGENT_TEMPLATE.format(skill_name=skill_name, skill_title=skill_title))
        print("  agents/claude-code.yaml")

        # references/ (empty)
        (skill_dir / 'references').mkdir()
        print("  references/")

        # scripts/ (empty, optional)
        (skill_dir / 'scripts').mkdir()
        print("  scripts/")

    except Exception as e:
        print(f"Error: {e}")
        return None

    print(f"\nSkill '{skill_name}' initialized at {skill_dir}")
    print("Next: edit SKILL.md and README.md, customize agents/ config")
    return skill_dir


def main():
    if len(sys.argv) < 4 or sys.argv[2] != '--path':
        print("Usage: init_skill.py <skill-name> --path <path>")
        sys.exit(1)

    skill_name = sys.argv[1]
    path = sys.argv[3]

    result = init_skill(skill_name, path)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
