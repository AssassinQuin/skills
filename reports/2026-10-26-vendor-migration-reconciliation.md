# Vendor migration reconciliation — 2026-10-26

## Result

- Reconciled work-tree deletions before committing them.
- `cangjie-skill`: 442 deleted paths audited.
- All 442 paths have corresponding files under `/Users/ganjie/skill-vendors/cangjie-skill`.
- All 442 Git blobs at `HEAD` are byte-identical to the vendor copies (`git hash-object` equality).
- The active `cangjie-skill/SKILL.md` remains in this repository as the wrapper entry point; the full upstream checkout stays outside the skill scan root.
- `dockerfile/flaresolverr/docker-compose.yml` and `dockerfile/searxng-mcp/config/settings.yml` are intentionally not restored: the old local Docker files contain a local SearXNG secret and are obsolete in the current CLI-first search stack.

## Verification command shape

```bash
git diff --name-only --diff-filter=D
test "$(git diff --name-only --diff-filter=D -- cangjie-skill | wc -l | tr -d ' ')" = 0
```

The pre-commit audit compared:

```text
git rev-parse HEAD:<repo_path>
git hash-object /Users/ganjie/skill-vendors/<repo_path>
```

## Outcome

The work-tree no longer treats vendored upstream implementation files as active skill source. Future vendor updates replace `/Users/ganjie/skill-vendors/<name>` and refresh the wrapper only.
