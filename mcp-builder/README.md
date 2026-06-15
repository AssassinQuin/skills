# MCP Builder

Guide for creating high-quality MCP (Model Context Protocol) servers. Covers the full lifecycle: deep research → implementation → review → evaluation. Includes reference scripts for common patterns.

## Trigger

build MCP server、创建 MCP server、MCP 工具开发、MCP integration、mcp-builder

## Quick Start

```
/mcp-builder 创建一个 GitHub Actions 的 MCP server
/mcp-builder 帮我做一个 Notion MCP 集成
```

## Workflow

1. **Phase 1: Deep Research & Planning** — Understand the target service API, design tool interface
2. **Phase 2: Implementation** — Build with proper error handling, type safety, and documentation
3. **Phase 3: Review & Test** — Validate against MCP spec, test edge cases
4. **Phase 4: Create Evaluations** — Build evaluation suite for ongoing quality

## Key Principles

- Tools should be granular and composable
- Error messages must be actionable (tell the LLM what went wrong and how to fix it)
- Type safety at boundaries — validate all inputs
- Documentation is part of the tool (descriptions drive LLM tool selection)

## Directory Structure

```
SKILL.md                    # Core instructions
scripts/
  requirements.txt          # Python dependencies for MCP dev
  evaluation.py             # Evaluation framework template
  connections.py            # Connection management utilities
  example_evaluation.xml    # Example evaluation output
```

## MCP Documentation Library

The skill references official MCP documentation for:
- Core protocol specification
- SDK documentation (Python, TypeScript)
- Server implementation patterns
- Authentication and security best practices

## See Also

- coder — General coding orchestration
- skill-creator — Create skills (similar scaffolding patterns)
