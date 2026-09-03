# Skill authoring best practices
- url: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- fetched: 2026-09-03

Learn how to write effective Skills that Claude can discover and use successfully.

Good Skills are concise, well-structured, and tested with real usage. This guide provides practical authoring decisions to help you write Skills that Claude can discover and use effectively.

For conceptual background on how Skills work, see the Skills overview.

## Core principles

### Concise is key

The context window is a public good. Your Skill shares the context window with everything else Claude needs to know, including:

- The system prompt
- Conversation history
- Other Skills' metadata
- Your actual request

Not every token in your Skill has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Claude reads SKILL.md only when the Skill becomes relevant, and reads additional files only as needed. However, being concise in SKILL.md still matters: once Claude loads it, every token competes with conversation history and other context.

__Default assumption:__ Claude is already very smart

Only add context Claude doesn't already have. Challenge each piece of information:

- "Does Claude really need this explanation?"
- "Can I assume Claude knows this?"
- "Does this paragraph justify its token cost?"

__Good example: Concise__ (approximately 50 tokens):

__Bad example: Too verbose__ (approximately 150 tokens):

The concise version assumes Claude already has information about PDFs and how libraries work.

### Set appropriate degrees of freedom

Match the level of specificity to the task's fragility and variability.

__High freedom__ (text-based instructions):

Use when:

- Multiple approaches are valid
- Decisions depend on context
- Heuristics guide the approach

Example:

__Medium freedom__ (pseudocode or scripts with parameters):

Use when:

- A preferred pattern exists
- Some variation is acceptable
- Configuration affects behavior

Example:

__Low freedom__ (specific scripts, few or no parameters):

Use when:

- Operations are fragile and error-prone
- Consistency is critical
- A specific sequence must be followed

Example:

__Analogy:__ Think of Claude as a robot exploring a path:

- __Narrow bridge with cliffs on both sides:__ There's only one safe way forward. Provide specific guardrails and exact instructions (low freedom). Example: database migrations that must run in exact sequence.
- __Open field with no hazards:__ Many paths lead to success. Give general direction and trust Claude to find the best route (high freedom). Example: code reviews where context determines the best approach.

### Test with all models you plan to use

Skills act as additions to models, so effectiveness depends on the underlying model. Test your Skill with all the models you plan to use it with.

__Testing considerations by model:__

- __Claude Haiku__ (fast, economical): Does the Skill provide enough guidance?
- __Claude Sonnet__ (balanced): Is the Skill clear and efficient?
- __Claude Opus__ (powerful reasoning): Does the Skill avoid over-explaining?

What works perfectly for Opus might need more detail for Haiku. If you plan to use your Skill across multiple models, aim for instructions that work well with all of them.

## Skill structure

### Naming conventions

Use consistent naming patterns to make Skills easier to reference and discuss. Consider using __gerund form__ (verb + -ing) for Skill names, as this clearly describes the activity or capability the Skill provides.

Remember that the `name` field must use lowercase letters, numbers, and hyphens only.

__Good naming examples (gerund form):__

- `processing-pdfs`
- `analyzing-spreadsheets`
- `managing-databases`
- `testing-code`
- `writing-documentation`

__Acceptable alternatives:__

- Noun phrases: `pdf-processing`, `spreadsheet-analysis`
- Action-oriented: `process-pdfs`, `analyze-spreadsheets`

__Avoid:__

- Vague names: `helper`, `utils`, `tools`
- Overly generic: `documents`, `data`, `files`
- Reserved words: `anthropic-helper`, `claude-tools`
- Inconsistent patterns within your skill collection

Consistent naming makes it easier to:

- Reference Skills in documentation and conversations
- Understand what a Skill does at a glance
- Organize and search through multiple Skills
- Maintain a professional, cohesive skill library

### Writing effective descriptions

The `description` field enables Skill discovery and should include both what the Skill does and when to use it.

__Be specific and include key terms__. Include both what the Skill does and specific triggers/contexts for when to use it.

Each Skill has exactly one description field. The description is critical for skill selection: Claude uses it to choose the right Skill from potentially 100+ available Skills. Your description must provide enough detail for Claude to know when to select this Skill, while the rest of SKILL.md provides the implementation details.

Effective examples:

__PDF Processing skill:__

__Excel Analysis skill:__

__Git Commit Helper skill:__

Avoid vague descriptions like these:

### Progressive disclosure patterns

SKILL.md serves as an overview that points Claude to detailed materials as needed, like a table of contents in an onboarding guide. For an explanation of how progressive disclosure works, see How Skills work in the overview.

__Practical guidance:__

- Keep SKILL.md body under 500 lines for optimal performance
- Split content into separate files when approaching this limit
- Use the following patterns to organize instructions, code, and resources effectively

#### Visual overview: From simple to complex

A basic Skill starts with just a SKILL.md file containing metadata and instructions:

As your Skill grows, you can bundle additional content that Claude loads only when needed:

The complete Skill directory structure might look like this:

- `pdf/`
  - `SKILL.md`: Main instructions (loaded when triggered)
  - `FORMS.md`: Form-filling guide (loaded as needed)
  - `reference.md`: API reference (loaded as needed)
  - `examples.md`: Usage examples (loaded as needed)
  - `scripts/`
    - `analyze_form.py`: Utility script (executed, not loaded)
    - `fill_form.py`: Form filling script
    - `validate.py`: Validation script

#### Pattern 1: High-level guide with references

Claude loads FORMS.md, REFERENCE.md, or EXAMPLES.md only when needed.

#### Pattern 2: Domain-specific organization

For Skills with multiple domains, organize content by domain to avoid loading irrelevant context. When a user asks about sales metrics, Claude only needs to read sales-related schemas, not finance or marketing data. This keeps token usage low and context focused.

- `bigquery-skill/`
  - `SKILL.md` (overview and navigation)
  - `reference/`
    - `finance.md` (revenue, billing metrics)
    - `sales.md` (opportunities, pipeline)
    - `product.md` (API usage, features)
    - `marketing.md` (campaigns, attribution)

#### Pattern 3: Conditional details

Show basic content, link to advanced content:

Claude reads REDLINING.md or OOXML.md only when the user needs those features.

### Avoid deeply nested references

Claude may partially read files when they're referenced from other referenced files. When encountering nested references, Claude might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information.

__Keep references one level deep from SKILL.md__. All reference files should link directly from SKILL.md to ensure Claude reads complete files when needed.

__Bad example: Too deep__:

__Good example: One level deep__:

### Structure longer reference files with table of contents

For reference files longer than 100 lines, include a table of contents at the top. This ensures Claude can see the full scope of available information even when previewing with partial reads.

__Example:__

Claude can then read the complete file or jump to specific sections as needed.

For details on how this filesystem-based architecture enables progressive disclosure, see the Runtime environment section later in this guide.

## Workflows and feedback loops

### Use workflows for complex tasks

Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist that Claude can copy into its response and check off as it progresses.

__Example 1: Research synthesis workflow__ (for Skills without code):

This example shows how workflows apply to analysis tasks that don't require code. The checklist pattern works for any complex, multistep process.

__Example 2: PDF form filling workflow__ (for Skills with code):

Clear steps prevent Claude from skipping critical validation. The checklist helps both Claude and you track progress through multistep workflows.

### Implement feedback loops

__Common pattern:__ Run validator → fix errors → repeat

This pattern greatly improves output quality.

__Example 1: Style guide compliance__ (for Skills without code):

This shows the validation loop pattern using reference documents instead of scripts. The "validator" is STYLE_GUIDE.md, and Claude performs the check by reading and comparing.

__Example 2: Document editing process__ (for Skills with code):

The validation loop catches errors early.

## Content guidelines

### Avoid time-sensitive information

Don't include information that will become outdated:

__Bad example: Time-sensitive__ (will become wrong):

__Good example__ (use "old patterns" section):

The old patterns section provides historical context without cluttering the main content.

### Use consistent terminology

Choose one term and use it throughout the Skill:

__Good - Consistent:__

- Always "API endpoint"
- Always "field"
- Always "extract"

__Bad - Inconsistent:__

- Mix "API endpoint", "URL", "API route", "path"
- Mix "field", "box", "element", "control"
- Mix "extract", "pull", "get", "retrieve"

Consistency helps Claude parse and follow instructions.

## Common patterns

### Template pattern

Provide templates for output format. Match the level of strictness to your needs.

__For strict requirements__ (such as API responses or data formats):

__For flexible guidance__ (when adaptation is useful):

### Examples pattern

For Skills where output quality depends on seeing examples, provide input/output pairs just like in regular prompting:

Examples convey the desired style and level of detail to Claude more clearly than descriptions alone.

### Conditional workflow pattern

Guide Claude through decision points:

## Evaluation and iteration

### Build evaluations first

__Create evaluations BEFORE writing extensive documentation.__ This ensures your Skill solves real problems rather than documenting imagined ones.

__Evaluation-driven development:__

1. __Identify gaps:__ Run Claude on representative tasks without a Skill. Document specific failures or missing context
2. __Create evaluations:__ Build three scenarios that test these gaps
3. __Establish baseline:__ Measure Claude's performance without the Skill
4. __Write minimal instructions:__ Create just enough content to address the gaps and pass evaluations
5. __Iterate:__ Execute evaluations, compare against baseline, and refine

This approach ensures you're solving actual problems rather than anticipating requirements that may never materialize.

__Evaluation structure:__

### Develop Skills iteratively with Claude

The most effective Skill development process involves Claude itself. Work with one instance of Claude ("Claude A") to create a Skill that is used by other instances ("Claude B"). Claude A helps you design and refine instructions, while Claude B tests them in real tasks. This works because Claude models understand both how to write effective agent instructions and what information agents need.

__Creating a new Skill:__

1. __Complete a task without a Skill:__ Work through a problem with Claude A using normal prompting. As you work, you'll naturally provide context, explain preferences, and share procedural knowledge. Notice what information you repeatedly provide.
2. __Identify the reusable pattern:__ After completing the task, identify what context you provided that would be useful for similar future tasks.

   __Example:__ If you worked through a BigQuery analysis, you might have provided table names, field definitions, filtering rules (such as "always exclude test accounts"), and common query patterns.
3. __Ask Claude A to create a Skill:__ "Create a Skill that captures this BigQuery analysis pattern we just used. Include the table schemas, naming conventions, and the rule about filtering test accounts."
4. __Review for conciseness:__ Check that Claude A hasn't added unnecessary explanations. Ask: "Remove the explanation about what win rate means - Claude already knows that."
5. __Improve information architecture:__ Ask Claude A to organize the content more effectively. For example: "Organize this so the table schema is in a separate reference file. We might add more tables later."
6. __Test on similar tasks:__ Use the Skill with Claude B (a fresh instance with the Skill loaded) on related use cases. Observe whether Claude B finds the right information, applies rules correctly, and handles the task successfully.
7. __Iterate based on observation:__ If Claude B struggles or misses something, return to Claude A with specifics: "When Claude used this Skill, it forgot to filter by date for Q4. Should we add a section about date filtering patterns?"

__Iterating on existing Skills:__

The same hierarchical pattern continues when improving Skills. You alternate between:

- __Working with Claude A__ (the expert who helps refine the Skill)
- __Testing with Claude B__ (the agent using the Skill to perform real work)
- __Observing Claude B's behavior__ and bringing insights back to Claude A

1. __Use the Skill in real workflows:__ Give Claude B (with the Skill loaded) actual tasks, not test scenarios
2. __Observe Claude B's behavior:__ Note where it struggles, succeeds, or makes unexpected choices

   __Example observation:__ "When I asked Claude B for a regional sales report, it wrote the query but forgot to filter out test accounts, even though the Skill mentions this rule."
3. __Return to Claude A for improvements:__ Share the current SKILL.md and describe what you observed. Ask: "I noticed Claude B forgot to filter test accounts when I asked for a regional report. The Skill mentions filtering, but maybe it's not prominent enough?"
4. __Review Claude A's suggestions:__ Claude A might suggest reorganizing to make rules more prominent, using stronger language such as "MUST filter" instead of "always filter," or restructuring the workflow section.
5. __Apply and test changes:__ Update the Skill with Claude A's refinements, then test again with Claude B on similar requests
6. __Repeat based on usage:__ Continue this observe-refine-test cycle as you encounter new scenarios. Each iteration improves the Skill based on real agent behavior, not assumptions.

__Gathering team feedback:__

1. Share Skills with teammates and observe their usage
2. Ask: Does the Skill activate when expected? Are instructions clear? What's missing?
3. Incorporate feedback to address gaps in your own usage patterns

__Why this approach works:__ Claude A understands agent needs, you provide domain expertise, Claude B reveals gaps through real usage, and iterative refinement improves Skills based on observed behavior rather than assumptions.

### Observe how Claude navigates Skills

As you iterate on Skills, pay attention to how Claude actually uses them in practice. Watch for:

- __Unexpected exploration paths:__ Does Claude read files in an order you didn't anticipate? This might indicate your structure isn't as intuitive as you thought
- __Missed connections:__ Does Claude fail to follow references to important files? Your links might need to be more explicit or prominent
- __Overreliance on certain sections:__ If Claude repeatedly reads the same file, consider whether that content should be in the main SKILL.md instead
- __Ignored content:__ If Claude never accesses a bundled file, it might be unnecessary or poorly signaled in the main instructions

Iterate based on these observations rather than assumptions. The 'name' and 'description' in your Skill's metadata are particularly critical. Claude uses these when determining whether to trigger the Skill in response to the current task. Make sure they clearly describe what the Skill does and when it should be used.

## Anti-patterns to avoid

### Avoid Windows-style paths

Always use forward slashes in file paths, even on Windows:

- ✓ __Good:__ `scripts/helper.py`, `reference/guide.md`
- ✗ __Avoid:__ `scripts\\helper.py`, `reference\\guide.md`

Unix-style paths work across all platforms, while Windows-style paths cause errors on Unix systems.

### Avoid offering too many options

Don't present multiple approaches unless necessary:

## Advanced: Skills with executable code

The following sections focus on Skills that include executable scripts. If your Skill uses only markdown instructions, skip to Checklist for effective Skills.

### Solve, don't defer

When writing scripts for Skills, handle error conditions rather than deferring to Claude.

__Good example: Handle errors explicitly:__

__Bad example: Defer to Claude:__

Configuration parameters should also be justified and documented to avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will Claude determine it?

__Good example: Self-documenting:__

__Bad example: Magic numbers:__

### Provide utility scripts

Even if Claude could write a script, pre-made scripts offer advantages:

__Benefits of utility scripts:__

- More reliable than generated code
- Save tokens (no need to include code in context)
- Save time (no code generation required)
- Ensure consistency across uses

The preceding diagram shows how executable scripts work alongside instruction files. The instruction file (forms.md) references the script, and Claude can execute it without loading its contents into context.

__Important distinction:__ Make clear in your instructions whether Claude should:

- __Execute the script__ (most common): "Run `analyze_form.py` to extract fields"
- __Read it as reference__ (for complex logic): "See `analyze_form.py` for the field extraction algorithm"

For most utility scripts, execution is preferred because it's more reliable and efficient. See the following Runtime environment section for details on how script execution works.

__Example:__

### Use visual analysis

When inputs can be rendered as images, have Claude analyze them:

Claude's vision capabilities help analyze layouts and structures.

### Create verifiable intermediate outputs

When Claude performs complex, open-ended tasks, it can make mistakes. The "plan-validate-execute" pattern catches errors early by having Claude first create a plan in a structured format, then validate that plan with a script before executing it.

__Example:__ Imagine asking Claude to update 50 form fields in a PDF based on a spreadsheet. Without validation, Claude might reference non-existent fields, create conflicting values, miss required fields, or apply updates incorrectly.

__Solution:__ Use the workflow pattern shown earlier (PDF form filling), but add an intermediate `changes.json` file that gets validated before applying changes. The workflow becomes: analyze → __create plan file__ → __validate plan__ → execute → verify.

__Why this pattern works:__

- __Catches errors early:__ Validation finds problems before changes are applied
- __Machine-verifiable:__ Scripts provide objective verification
- __Reversible planning:__ Claude can iterate on the plan without touching originals
- __Clear debugging:__ Error messages point to specific problems

__When to use:__ Batch operations, destructive changes, complex validation rules, high-stakes operations.

__Implementation tip:__ Make validation scripts verbose with specific error messages such as "Field 'signature_date' not found. Available fields: customer_name, order_total, signature_date_signed" to help Claude fix issues.

### Package dependencies

Skills run in the code execution environment with platform-specific limitations:

- __claude.ai:__ Can install packages from npm and PyPI and pull from GitHub repositories
- __Claude API:__ Has no network access and no runtime package installation

List required packages in your SKILL.md and verify they're available in the Code execution tool documentation.

### Runtime environment

Skills run in a code execution environment with filesystem access, bash commands, and code execution capabilities. For the conceptual explanation of this architecture, see The Skills architecture in the overview.

__How this affects your authoring:__

__How Claude accesses Skills:__

1. __Metadata pre-loaded:__ At startup, the name and description from all Skills' YAML frontmatter are loaded into the system prompt
2. __Files read on-demand:__ Claude uses bash Read tools to access SKILL.md and other files from the filesystem when needed
3. __Scripts executed efficiently:__ Utility scripts can be executed through bash without loading their full contents into context. Only the script's output consumes tokens
4. __No context penalty for large files:__ Reference files, data, or documentation don't consume context tokens until actually read

- __File paths matter:__ Claude navigates your skill directory like a filesystem. Use forward slashes (`reference/guide.md`), not backslashes
- __Name files descriptively:__ Use names that indicate content: `form_validation_rules.md`, not `doc2.md`
- __Organize for discovery:__ Structure directories by domain or feature
  - Good: `reference/finance.md`, `reference/sales.md`
  - Bad: `docs/file1.md`, `docs/file2.md`
- __Bundle comprehensive resources:__ Include complete API docs, extensive examples, large datasets; no context penalty until accessed
- __Prefer scripts for deterministic operations:__ Write `validate_form.py` rather than asking Claude to generate validation code
- __Make execution intent clear:__
  - "Run `analyze_form.py` to extract fields" (execute)
  - "See `analyze_form.py` for the extraction algorithm" (read as reference)
- __Test file access patterns:__ Verify Claude can navigate your directory structure by testing with real requests

__Example:__

- `bigquery-skill/`
  - `SKILL.md` (overview, points to reference files)
  - `reference/`
    - `finance.md` (revenue metrics)
    - `sales.md` (pipeline data)
    - `product.md` (usage analytics)

When the user asks about revenue, Claude reads SKILL.md, sees the reference to `reference/finance.md`, and calls bash to read just that file. The sales.md and product.md files remain on the filesystem, consuming zero context tokens until needed. This filesystem-based model is what enables progressive disclosure. Claude can navigate and selectively load exactly what each task requires.

For complete details on the technical architecture, see How Skills work in the Skills overview.

### MCP tool references

If your Skill uses MCP (Model Context Protocol) tools, always use fully qualified tool names to avoid "tool not found" errors.

__Format:__ `ServerName:tool_name`

__Example:__

Where:

- `BigQuery` and `GitHub` are MCP server names
- `bigquery_schema` and `create_issue` are the tool names within those servers

Without the server prefix, Claude may fail to locate the tool, especially when multiple MCP servers are available.

### Avoid assuming tools are installed

Don't assume packages are available:

## Technical notes

### YAML frontmatter requirements

The SKILL.md frontmatter requires `name` and `description` fields with specific validation rules:

- `name`: Maximum 64 characters, lowercase letters/numbers/hyphens only, no XML tags, no reserved words
- `description`: Maximum 1,024 characters, non-empty, no XML tags

See the Skills overview for complete structure details.

### Token budgets

Keep SKILL.md body under 500 lines for optimal performance. If your content exceeds this, split it into separate files using the progressive disclosure patterns described earlier. For architectural details, see the Skills overview.

## Checklist for effective Skills

Before sharing a Skill, verify:

### Core quality

- Description is specific and includes key terms
- Description includes both what the Skill does and when to use it
- SKILL.md body is under 500 lines
- Additional details are in separate files (if needed)
- No time-sensitive information (or in "old patterns" section)
- Consistent terminology throughout
- Examples are concrete, not abstract
- File references are one level deep
- Progressive disclosure used appropriately
- Workflows have clear steps

### Code and scripts

- Scripts solve problems rather than defer to Claude
- Error handling is explicit and helpful
- No "voodoo constants" (all values justified)
- Required packages listed in instructions and verified as available
- Scripts have clear documentation
- No Windows-style paths (all forward slashes)
- Validation/verification steps for critical operations
- Feedback loops included for quality-critical tasks

### Testing

- At least three evaluations created
- Tested with Haiku, Sonnet, and Opus
- Tested with real usage scenarios
- Team feedback incorporated (if applicable)

## Next steps

Create and manage Skills in Claude Code

Upload and use Skills programmatically
