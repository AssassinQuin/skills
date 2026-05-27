---
name: codemap
description: Generate hierarchical codemaps for repositories with incremental git-aware updates. Triggers on "run codemap", "map this repo", "generate codemap", or any explicit request to document/map the codebase structure. Only runs when explicitly requested.
---

# Codemap Skill

Generate and maintain hierarchical codemaps with **incremental updates** — only touch folders that actually changed.

## When to Use

- User explicitly asks to map/document a codebase
- "Run codemap", "map this repo", "generate codemap"

## Script Invocation

The script location varies by installation. Use this resolution sequence:

```bash
SCRIPT="${HOME}/.claude/skills/codemap/scripts/codemap.mjs"
[ ! -f "$SCRIPT" ] && SCRIPT="${HOME}/.config/opencode/skills/codemap/scripts/codemap.mjs"
```

If neither path exists, locate it: `find ~ -name "codemap.mjs" -type f 2>/dev/null | head -1`

All commands below use `$SCRIPT` as the resolved path.

## Workflow

### Step 0: Perception Injection (ALWAYS FIRST)

**Before generating any codemap content, ensure future sessions can discover it.**

1. Check if CLAUDE.md (or AGENTS.md) already references codemap:

```bash
grep -n -i 'codemap\|Repository Map' CLAUDE.md 2>/dev/null
```

2. If no reference found, append to CLAUDE.md (preferred, loaded every session):

```markdown
## Repository Map

A hierarchical codemap exists in this project:
- Root map: `codemap.md` in project root
- Folder maps: `codemap.md` in each source directory

Read `codemap.md` before working on any task to understand architecture and data flow.
For deep work on a specific folder, also read that folder's `codemap.md`.
```

3. If no CLAUDE.md exists, create one with only this block.

4. **Verify** the injection by re-running grep.

### Step 1: Detect State and Classify Run

```bash
cat .slim/codemap.json 2>/dev/null | head -5
```

- **No state** → Full Init (Step 2)
- **State exists** → Incremental Update (Step 3)

### Step 2: Full Init (first run only)

#### 2a. Detect project type

Read the repository root and match against this table:

| Project type | Detection signal | --include | --exclude (mandatory) |
|---|---|---|---|
| Go | `go.mod` exists | `**/*.go`, `go.mod` | `**/*_test.go`, `vendor/**` |
| TypeScript/JS | `tsconfig.json` or `package.json` | `src/**/*.ts`, `src/**/*.tsx`, `package.json` | `**/*.test.*`, `**/*.spec.*`, `node_modules/**`, `dist/**` |
| Python | `pyproject.toml` or `setup.py` | `**/*.py`, `pyproject.toml` | `**/test_*.py`, `**/*_test.py`, `tests/**`, `__pycache__/**`, `.venv/**`, `venv/**`, `*.egg-info/**` |
| Rust | `Cargo.toml` exists | `src/**/*.rs`, `Cargo.toml` | `target/**`, `tests/**` |
| Multi-language | Multiple signals | Union of applicable includes | Union of applicable excludes |

Always add: `.git/**`, `docs/**`, patterns from `.gitignore`.

#### 2b. Run init

```bash
node "$SCRIPT" init --root ./ \
  --include "<pattern1>" --include "<pattern2>" \
  --exclude "<exclude1>" --exclude "<exclude2>"
```

#### 2c. Generate codemap content for each folder

For each folder that received an empty `codemap.md`:

1. Read all source files in the folder
2. Classify the folder by **role** (see Content Tiering below)
3. Apply the corresponding template
4. Write the codemap.md

**Parallelism**: When 3+ folders exist, spawn agents in parallel batches of 3. Use the Agent Prompt Template below.

#### 2d. Generate root codemap

1. Read all sub-folder `codemap.md` files
2. Write root `codemap.md` using the Root template (see Content Tiering)

#### 2e. Save state

```bash
node "$SCRIPT" update --root ./
```

### Step 3: Incremental Update (state exists)

**This is the critical step for token efficiency.**

```bash
node "$SCRIPT" changes --root ./ --json
```

Parse the JSON output:

```jsonc
{
  "has_changes": true,
  "method": "git",
  "dirty_folders": ["src/utils"]  // ONLY these need updates
}
```

#### Decision tree:

| `has_changes` | `dirty_folders` | Action | Token cost |
|---|---|---|---|
| `false` | — | **Stop.** | ~0 |
| `true` | `[]` | Run `update` only. | ~0 |
| `true` | `["src/utils"]` | Update that folder only. | Low |
| `true` | 3+ folders | Update those folders only. | Medium |

**Key rule: Only process folders in `dirty_folders`. Ignore all others.**

### Step 4: Update Only Dirty Folders

For each folder in `dirty_folders`:

1. Read the changed source files (from `added` + `modified` arrays)
2. Read the existing `codemap.md`
3. Reconcile: remove deleted files, add new files, update modified descriptions
4. Apply the appropriate tier template
5. Write the updated `codemap.md`

**Spawn one agent per dirty folder when 2+ exist.** Use parallel spawning.

### Step 5: Update Root Codemap (conditional)

Only update if `dirty_folders` is non-empty AND at least one is not root.

1. Read changed sub-folder `codemap.md` files
2. Update the root atlas with current structure

### Step 6: Validate (MANDATORY)

After all codemaps are written/updated, run these checks:

1. **Existence check** — every folder in state has a codemap.md:
```bash
node -e "
  const s = JSON.parse(require('fs').readFileSync('.slim/codemap.json','utf8'));
  const missing = Object.keys(s.file_hashes || {}).filter(f => {
    const p = f === '.' ? 'codemap.md' : f + '/codemap.md';
    return !require('fs').existsSync(p);
  });
  console.log(missing.length ? 'MISSING: ' + missing.join(', ') : 'All codemaps present.');
"
```

2. **Cross-reference check** — file paths mentioned in codemap exist on disk:
```bash
grep -oP '`[^`]+\.(go|ts|py|rs)`' codemap.md | tr -d '`' | while read f; do [ ! -f "$f" ] && echo "MISSING: $f"; done
```

3. **Freshness spot-check** — pick 2-3 dirty folders, verify codemap matches actual files.

4. **Fix or flag** — if any check fails, fix the codemap. Do NOT save state until all checks pass.

**Scope**: Full validation on init. Dirty-folders-only on incremental updates.

### Step 7: Save State

**Always run after validation passes:**

```bash
node "$SCRIPT" update --root ./
```

## Content Tiering

Not all directories need the same depth. Classify by **role** (primary) and **size** (secondary):

### Root Codemap (always exhaustive)

Use the Root template. Must include: Project Responsibility, System Entry Points, full Directory Map table, Request Lifecycle (if applicable).

### Sub-directory Classification

| Tier | Criteria | Template | Example directories |
|------|----------|----------|-------------------|
| **Tier 1: Core** | Business logic, entry points, middleware, routing | Full (4 sections) | `cmd/`, `logic/`, `controller/`, `internal/` |
| **Tier 2: Support** | Utilities, types, constants, generated code | Compact (2 sections) | `utility/`, `consts/`, `model/`, `dao/internal/` |
| **Tier 3: Leaf** | Single-purpose, trivial wrappers, <3 files | Minimal (1-2 lines) | `version/`, `packed/`, `api/inside/v1/` |

**Classification heuristics:**
- Directories containing files the user will likely edit → Tier 1
- Directories the user reads for context but rarely edits → Tier 2
- Directories the user never opens directly → Tier 3
- When uncertain → Tier 2 (safe default)

### Templates

**Tier 1 (Full):**

```markdown
# {folder}/

## Responsibility
{One sentence with standard term: Service Layer, DAO, Middleware, Controller, etc.}

## Design
{Key patterns, abstractions, architectural decisions.}

## Flow
{Numbered steps with actual function/module names.}

## Integration
- **Depends on**: {modules with file paths}
- **Consumed by**: {modules with file paths}
```

**Tier 2 (Compact):**

```markdown
# {folder}/

## Responsibility
{One sentence.}

## Integration
- In: {upstream} | Out: {downstream}
```

**Tier 3 (Minimal):**

```markdown
# {folder}/
{One sentence summary.}
```

### Estimated token savings

| Project | Before (all Tier 1) | After (tiered) | Savings |
|---------|--------------------|-----------------|---------|
| jyteam (42 dirs) | ~24,500 tokens | ~10,000 tokens | ~60% |

## Agent Prompt Template

When spawning agents for parallel folder processing, use this prompt:

```
You are updating the codemap for folder `{FOLDER}`.

INSTRUCTIONS:
1. Read these source files: {FILES}
2. Read existing codemap.md at `{FOLDER}/codemap.md` if present
3. Classify folder tier:
   - Tier 1 (Core): business logic, routing, middleware → Full template
   - Tier 2 (Support): utilities, types, generated code → Compact template
   - Tier 3 (Leaf): trivial, <3 files → Minimal template
4. Write codemap.md using the chosen template
5. Verify every file path you referenced exists on disk

RULES:
- Reference actual function/type names, not vague descriptions
- Preserve existing structure when updating
- Exclude test files, build artifacts, docs
- Output under 1500 words for Tier 1, 200 words for Tier 2, 50 words for Tier 3
```

## Detection Strategies

1. **Git fast-path** (O(changed)): `git diff <old-head>..HEAD` for changed files. Extremely fast.
2. **Hash fallback** (O(all)): Walk all tracked files, compare MD5. Used when git is unavailable.

## Token Budget Guidance

| Scenario | Estimated tokens |
|---|---|
| No changes (git fast-path) | ~200 |
| 1-2 dirty folders (Tier 2-3) | ~1,000-3,000 |
| 1-2 dirty folders (Tier 1) | ~2,000-5,000 |
| Full init (tiered) | ~5,000-30,000 |
| Full init (all Tier 1 — rare) | ~10,000-50,000 |

## Script Fallback

If `$SCRIPT` is not found:

1. Locate: `find ~ -name "codemap.mjs" -type f 2>/dev/null | head -1`
2. If found, substitute the path
3. If not found, use manual mode:
   - Dirty detection: `git diff --name-only HEAD~10`
   - File selection: `find . -name "*.go" -not -path "*/vendor/*"` (adapt extension)
   - Create minimal `.slim/codemap.json` manually if needed
