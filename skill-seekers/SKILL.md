---
name: skill-seekers
description: Use when converting documentation websites, GitHub repositories, or PDFs into Claude AI skills. Triggers: "create skill from docs", "scrape documentation", "generate skill from GitHub", "PDF to skill", "build Claude skill".
---

# Skill Seekers

Convert documentation websites, GitHub repositories, and PDFs into Claude AI skills automatically.

## When to Use

- User wants to create a skill from documentation website
- User wants to generate skill from GitHub repository
- User wants to convert PDF into skill
- User mentions "skill", "Claude skill", "documentation to skill"
- User wants unified multi-source skill (docs + GitHub)

## Installation Check

```bash
skill-seekers --version
```

If not installed:
```bash
pip install skill-seekers
```

## Core Commands

### 1. Scrape Documentation Website

```bash
# Using config file
skill-seekers scrape --config configs/react.json

# Quick mode (no config)
skill-seekers scrape --url https://react.dev --name react --description "React UI framework"

# With async mode (3x faster)
skill-seekers scrape --config configs/godot.json --async --workers 8

# Estimate pages first
skill-seekers estimate configs/react.json
```

### 2. Scrape GitHub Repository

```bash
# Basic scraping
skill-seekers github --repo facebook/react --name react

# With authentication (higher rate limits)
export GITHUB_TOKEN=ghp_your_token
skill-seekers github --repo django/django --name django

# Include issues and changelog
skill-seekers github --repo owner/repo \
  --include-issues \
  --max-issues 100 \
  --include-changelog \
  --include-releases
```

### 3. Extract from PDF

```bash
# Basic extraction
skill-seekers pdf --pdf docs/manual.pdf --name myskill

# With parallel processing
skill-seekers pdf --pdf docs/manual.pdf --name myskill --parallel --workers 8

# Scanned PDFs (requires: pip install pytesseract)
skill-seekers pdf --pdf scanned.pdf --name myskill --ocr

# Password-protected
skill-seekers pdf --pdf encrypted.pdf --name myskill --password mypassword
```

### 4. Unified Multi-Source (docs + GitHub)

```bash
# Use unified config
skill-seekers unified --config configs/react_unified.json

# Creates skill with conflict detection between docs and code
```

Unified config structure:
```json
{
  "name": "myframework",
  "description": "Complete framework knowledge from docs + code",
  "merge_mode": "rule-based",
  "sources": [
    {
      "type": "documentation",
      "base_url": "https://docs.myframework.com/",
      "extract_api": true,
      "max_pages": 200
    },
    {
      "type": "github",
      "repo": "owner/myframework",
      "include_code": true,
      "code_analysis_depth": "surface"
    }
  ]
}
```

### 5. AI-Powered Enhancement

```bash
# Local enhancement (no API key, uses Claude Code)
skill-seekers enhance output/react/

# During scraping
skill-seekers scrape --config configs/react.json --enhance-local
```

### 6. Package and Upload

```bash
# Package skill
skill-seekers package output/react/

# Creates output/react.zip

# Auto-upload (requires API key)
export ANTHROPIC_API_KEY=sk-ant-...
skill-seekers package output/react/ --upload

# Or upload existing zip
skill-seekers upload output/react.zip
```

### 7. One-Command Install

```bash
# Complete workflow: fetch → scrape → enhance → package → upload
skill-seekers install --url https://react.dev --name react
```

## Available Presets

| Config | Framework |
|--------|-----------|
| `configs/godot.json` | Godot Engine |
| `configs/react.json` | React |
| `configs/vue.json` | Vue.js |
| `configs/django.json` | Django |
| `configs/fastapi.json` | FastAPI |

## Creating Custom Config

```bash
# Interactive mode
skill-seekers scrape --interactive

# Or create config file
```

Config structure:
```json
{
  "name": "myframework",
  "description": "When to use this skill",
  "base_url": "https://docs.myframework.com/",
  "selectors": {
    "main_content": "article",
    "title": "h1",
    "code_blocks": "pre code"
  },
  "url_patterns": {
    "include": ["/docs", "/guide"],
    "exclude": ["/blog", "/about"]
  },
  "categories": {
    "getting_started": ["intro", "quickstart"],
    "api": ["api", "reference"]
  },
  "rate_limit": 0.5,
  "max_pages": 500
}
```

## Output Structure

```
output/
├── myskill_data/        # Scraped raw data
│   ├── pages/           # JSON files
│   └── summary.json
└── myskill/             # The skill
    ├── SKILL.md         # Main skill file
    ├── references/      # Categorized docs
    ├── scripts/
    └── assets/
```

## Large Documentation (10K+ pages)

```bash
# Split into sub-skills
skill-seekers estimate configs/godot.json

# Auto-split strategy
# - router: hub + specialized sub-skills (recommended)
# - category: split by doc categories
# - size: split every N pages

# Use checkpoint/resume for long scrapes
skill-seekers scrape --config configs/large.json --resume
```

## Performance Tips

1. **Use async mode**: `--async --workers 8` for 3x speed
2. **Estimate first**: `skill-seekers estimate` to know page count
3. **Reuse data**: `--skip-scrape` to rebuild without rescraping
4. **Checkpoint**: Auto-saves every 1000 pages, resume with `--resume`

## Common Workflows

### Quick Skill from Docs
```bash
skill-seekers scrape --url https://docs.example.com --name example
skill-seekers enhance output/example/
skill-seekers package output/example/
```

### GitHub Repo to Skill
```bash
skill-seekers github --repo owner/repo --name myskill
skill-seekers package output/myskill/
```

### Full Production Skill
```bash
skill-seekers unified --config configs/myframework_unified.json
skill-seekers enhance output/myframework/
skill-seekers package output/myframework/ --upload
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No content extracted | Check `main_content` selector |
| Categories wrong | Edit config `categories` section |
| Rate limited | Increase `rate_limit` value |
| Large docs timeout | Use `--async` and `--workers` |

## Reference

- GitHub: https://github.com/yusufkaraaslan/Skill_Seekers
- PyPI: https://pypi.org/project/skill-seekers/
