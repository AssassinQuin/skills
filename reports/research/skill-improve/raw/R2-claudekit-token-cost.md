# What Do Claude Code Skills Actually Cost in Tokens? We Measured the Full ClaudeKit Catalog
- url: https://theclaudekit.com/blog/claude-code-skills-token-cost-measured
- fetched: 2026-09-04

- published: 2026-03-02
- author: madni (article:author)
- site: ClaudeKit

---

A typical Claude Code skill costs **600 to 1,500 tokens** when its body is loaded into context. A small fraction of tool-heavy skills reach 3,000 to 4,000 tokens. We measured the entire ClaudeKit v2 catalog — **82,197 tokens across 5 kits, 101 commands, 19 skills, and 13 read-only agents** — and the per-kit ledger is below. The spread between a lean skill and a bloated one is roughly 7x, and almost nobody publishes the figures.

## Why does token cost per skill matter?

Context is the scarcest resource in an agent run. Every skill Claude Code loads into context is space it cannot spend on your actual problem. Yet most skill authors ship without a token count. Most users have no idea what they are paying per skill. And the consequences compound: a session that opens with 40 installed skills, three MCP servers, and a sprawling `CLAUDE.md` can burn 30,000+ tokens before you type a single word.

The token cost of a skill is not "small" or "large" — it is a specific number you can measure. Running `ck tokens <kit>` on any ClaudeKit kit prints a ledger down to the individual skill. This post is the worked version of that ledger, with commentary on what the distribution tells you and what to do about it.

## How did we measure the token counts?

Token counts depend on the tokenizer. We do not have access to Anthropic's exact production tokenizer, so we are explicit about method and label everything as an estimate.

We counted with a **tiktoken-compatible byte-pair counter** run over the raw text of each published skill file. Where we fell back on estimation (for third-party repos we read but did not clone), we use the widely accepted **~4 characters per token** approximation and say so. The two methods agree within ~10% on English-plus-code Markdown, which is what skill bodies are.

For each skill in the ClaudeKit v2 catalog, we:

1. Took the full skill body — frontmatter, prose, code fences, examples — as the unit, because that is what Claude Code reads when a skill activates.
2. Ran the counter over the raw bytes.
3. Recorded the result alongside the skill's kit, category, and whether it bundles reference files.
4. Summed per-kit and cross-kit totals.

```
# Print the full token ledger for a kit
ck tokens engineer

# Recount all installed kits
ck tokens --all --format csv > token-ledger.csv
# Each row: kit, skill/command/agent, tokens, category
```

The `ck tokens` command ships with **claudekits v0.1.3** (npm). It re-runs the count at install time so the ledger reflects whatever actually landed in `~/.claude`. Run `ck doctor` if numbers look wrong after an update.

## What is the full ClaudeKit v2 token ledger?

Complete cross-kit breakdown measured on the v2 catalog as shipped June 2026.

| Kit | Commands | Skills | Agents | Total tokens | Avg tokens/command |
| --- | --- | --- | --- | --- | --- |
| EngineerKit `/eng` | 25 | 4 | 4 | 20,413 | ~817 |
| MarketingKit `/mkt` | 20 | 3 | 2 | 16,714 | ~836 |
| SEOKit `/seo` | 19 | 4 | 2 | 16,004 | ~842 |
| EcomKit `/ecom` | 20 | 3 | 2 | 16,464 | ~823 |
| VideoKit `/video` | 17 | 5 | 3 | 12,602 | ~741 |
| **Totals** | **101** | **19** | **13** | **82,197** | **~814** |

EngineerKit is the heaviest kit at 20,413 tokens because its commands embed deep procedural knowledge — `/eng debug` alone encodes a root-cause-first methodology with a structured evidence chain. VideoKit is the leanest at 12,602 tokens; its commands tend to be operation-specific (caption, clone, social) with less inline prose.

The cross-kit average lands at **814 tokens per command**, which is close to our earlier estimate of 840 when we counted a wider corpus including third-party repos. The median is lower — closer to 720 — because a few long commands pull the mean up.

## What does the token distribution actually look like?

Looking at all 101 commands across the five kits, the distribution sorts into five bands:

| Band | Token range | Share of commands | Typical example |
| --- | --- | --- | --- |
| Lean | under 500 | ~18% | single-purpose formatters, schema generators |
| Typical | 500–900 | ~41% | most analysis and content commands |
| Substantial | 900–1,400 | ~29% | full audits, brief writers, multi-step workflows |
| Heavy | 1,400–2,200 | ~10% | orchestration commands embedding long procedures |
| Tool-heavy | 2,200–3,500 | ~2% | commands wrapping large API surfaces or render pipelines |

The lightest command in the catalog is a breadcrumb schema generator at **390 tokens**. The heaviest is the `/video clone` command at roughly **3,100 tokens** — it needs to encode Remotion component architecture, style-matching methodology, and a verification loop in a single coherent body.

Three kit flagship commands measured:

- `/eng debug` — ~1,200 tokens (root-cause-first protocol with five evidence gates)
- `/seo quick-wins` — ~980 tokens (positions 8–20 sweep plus low-CTR filter logic)
- `/mkt humanize` — ~760 tokens (14 AI-tell detection and rewrite rules)

## How do always-loaded tokens differ from on-demand tokens?

This is the part most people get wrong, and it is the most important distinction in practical token management.

The cost model has three layers:

1. **Always-on: skill/command name and description lines.** These sit in the system prompt so the model knows what exists. Typically 15–40 tokens per item. For a kit with 25 commands, this is roughly 500–1,000 tokens total — always present, regardless of what you actually run.
2. **On-demand: the skill or command body.** This is the 600–1,500 token number. It loads only when you invoke the skill or command. In a normal session you might invoke 1–3 commands, so the practical always-on overhead from the kit is modest.
3. **On-demand: bundled reference files.** Some commands reference external templates or spec files. These load only when the command explicitly reads them, which may never happen in a given run.

A kit with 25 installed commands is not paying 25 × 814 = ~20k tokens at rest. It is paying roughly 25 × 30 tokens for the always-on description lines (~750 tokens) plus the body of whatever commands actually fire.

**The cost that actually bites is not command bodies — it is everything else.** A single rich MCP server's tool schema can exceed 10,000 tokens and loads every session. A bloated global `CLAUDE.md` can quietly hit several thousand tokens. Every installed skill description line you never use is a 25-to-40 token leak per item.

Honest priority order for trimming context:

1. Unused MCP servers with fat tool schemas (often 5k–15k tokens each, always on)
2. A sprawling global `CLAUDE.md` with stale rules
3. Dozens of installed-but-unused skill description lines
4. Individual command bodies — which only cost you when they fire

Most people start at item 4 and ignore item 1. That is backwards.

## How do ClaudeKit v2 kits compare to installing commands individually?

Installing ClaudeKit via `ck install <kit>` versus building your own slash command library from scratch raises a fair question: does a curated kit spend tokens more efficiently than a hand-rolled setup?

Three factors make kit-packaged commands leaner in practice:

**1. Progressive disclosure architecture.** ClaudeKit commands keep the skill body lean and push long reference procedures into files that load only when the command explicitly needs them. A hand-written command often dumps everything inline because there is no build step enforcing discipline.

**2. Shared skills.** The 19 skills in v2 are loaded by multiple commands across the same kit. A skill body loaded once supports many commands without N-fold duplication. Installing the same capability as standalone commands means re-encoding shared knowledge in every command file.

**3. Measured accountability.** Because `ck tokens` reports the ledger at install time, every token in the catalog has been reviewed. Commands that grew too heavy were trimmed before shipping. Without a measure-at-pack-time step, nobody trims.

That said, curated kits are not always leaner than a minimal hand-rolled setup. If you genuinely only need two or three commands, you can write them at 200–400 tokens each and beat any kit's per-command average. The kits earn their weight for teams running 10+ commands regularly, where the shared-skill and progressive-disclosure savings compound.

If you want to actually measure — not estimate — your current Claude Code token footprint, here is the process:

1. **Run `ck tokens --all`** if you have ClaudeKit installed. This prints a per-kit, per-item ledger for everything in `~/.claude/claudekit/`.
2. **Audit your MCP servers.** For each server in `.mcp.json`, look up (or measure) the tool schema size. Servers with 20+ tools often exceed 8,000 tokens.
3. **Measure your `CLAUDE.md` files.** Run `wc -c ~/.claude/CLAUDE.md` and divide by 4 for a rough token estimate. Anything over 4,000 characters (1,000 tokens) is worth reviewing.
4. **Check global vs local installs.** `ck install --local` scopes a kit to the current project's `.claude/` folder instead of `~/.claude`. Local installs do not load in sessions outside that project, so they cannot leak into unrelated work.
5. **Re-run after changes.** `ck doctor` will flag mismatches between your entitlement and what is installed, and `ck tokens` will recount the current state.

For a deeper walkthrough of context management, the token budget spiral playbook covers progressive disclosure patterns and how to structure `CLAUDE.md` to avoid runaway token growth. The skills guide for 2026 explains how auto-loading knowledge differs from slash commands and when each makes sense.

## Does the token cost change between kit versions?

Yes, and we publish the delta. When a command is updated — either trimmed for efficiency or expanded to handle new cases — the `ck tokens` output changes at the next install or `ck update`. The version history in `/changelog` records notable size changes for major commands.

In the v1-to-v2 migration (shipped June 2026), we made structural changes that affected token counts significantly:

- Removed the reviewer/quality-gate agent layer. In v1 architecture, commands ended by invoking a blocking reviewer agent. That agent's definition added 800–1,400 tokens per kit run and introduced latency without improving output quality. In v2, **commands end with EVIDENCE** — a report, a diff, a verified file — not a reviewer gate. This alone shaved roughly 8,000 tokens from a typical multi-step session.
- Merged FounderKit and SalesKit into other kits or removed them entirely. The five v2 kits are EngineerKit, MarketingKit, VideoKit, SEOKit, and EcomKit. The old `/marketing`, `/founder`, and `/sales` namespaces are gone; the v2 namespaces are `/eng`, `/mkt`, `/video`, `/seo`, and `/ecom`.
- Replaced orchestrator agents with read-only specialist agents. The 13 agents in v2 are reviewers, auditors, and researchers that read and report — they do not spawn subagents or block command completion. This caps agent overhead at a fixed definition size rather than an unbounded execution tree.

## FAQ

### How many tokens does a Claude Code skill use on average?

The ClaudeKit v2 catalog averages **814 tokens per command** across 101 commands, with a median closer to 720 tokens. A lean single-purpose command can be under 500 tokens; a complex orchestration command like `/video clone` runs around 3,100 tokens. The skill name and description that are always loaded add only 15–40 tokens each on top of that.

### Does installing a ClaudeKit kit cost tokens even if I never run a command?

Yes, but only a little. Installed commands contribute their name and one-line description to the system prompt — roughly 25–40 tokens per command, always loaded. For a 25-command kit that is around 750 tokens at rest. The command body, the 600–1,500 token bulk, loads only when you actually invoke the command.

### What costs more tokens: skills or MCP servers?

MCP servers usually cost more per item. A single rich MCP server tool schema can exceed 10,000 tokens and is loaded every session regardless of whether you use it. An individual skill body is typically under 1,500 tokens and loads only on demand. If you are trimming context, audit your MCP servers before your skills.

### How do I measure the token footprint of my current Claude Code setup?

Install the `claudekits` CLI (v0.1.3 on npm), then run `ck tokens --all` to get a per-item ledger of every ClaudeKit command and skill in `~/.claude`. For non-ClaudeKit context (MCP servers, `CLAUDE.md` files), measure the raw file size and apply the ~4 characters per token approximation, or use a tiktoken-compatible counter for more precision.

### Why did ClaudeKit remove the reviewer gate in v2?

The v1 blocking reviewer agent added 800–1,400 tokens per run and introduced latency without measurably improving output quality. In v2, commands end with **EVIDENCE** — a diff, a structured report, a verified output file — rather than routing through a reviewer agent that would re-evaluate and potentially block completion. The result is lower token spend and faster command completion with equivalent accountability.

### How does `ck tokens` work and when should I re-run it?

`ck tokens <kit>` reads the installed skill and command files in `~/.claude/claudekit/<kit>/` and runs a tiktoken-compatible byte-pair count over each. The output is a ledger with per-item token counts and a kit total. Re-run it after `ck update`, after editing any command files manually, or after switching between `--local` and global installs to confirm what is actually in scope.

---

If the token numbers above made you want to actually run the commands rather than just audit them, the EngineerKit is the best starting point for developers — 25 commands, 4 agents, and a daily-eight workflow (`/eng catchup`, `plan`, `tdd`, `debug`, `verify`, `review`, `commit`, `handoff`) that covers the full development loop. Single kit at $14.99/month, or get all five for $49.99/month All-Access. Token ledger prints on every install so you always know what you are loading.
