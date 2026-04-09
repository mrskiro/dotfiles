---
name: audit-tools
description: >
  Audit MCP/CLI connections, skills, and external resource access for the current project.
  Use when: "ツール棚卸し", "MCP確認", "スキル整理", "what tools do we have",
  "audit tools", or when starting work on a new project to understand what's available.
---

# Audit Tools

Assess whether the AI agent's capabilities match the project's needs. The goal of MCP/CLI/skills is to expand what the agent can do — not just what it knows.

## Process

### 1. Scan project inventory

Detect the tech stack from:
- `package.json` / `Cargo.toml` / `go.mod` / `pyproject.toml` etc.
- Deployment config: `wrangler.toml`, `vercel.json`, `fly.toml`, `Dockerfile` etc.
- `docker-compose.yml` (databases, caches, queues)
- `.env.example` / `.env.sample` (external service references)
- Framework config files (`next.config.*`, `vite.config.*`, etc.)

### 2. Check capability coverage

For each external service, data store, and infrastructure component detected in Step 1, ask: **can the agent act on this, or only read code that talks to it?**

Derive the categories from the project itself — don't use a fixed checklist. A web app, a native app, a CLI tool, and an infrastructure repo each have different capability needs.

For each gap found, **web search** for available MCP/CLI options. Do not rely on training knowledge — this domain changes constantly.

### 3. Evaluate current MCP/CLI setup

Read `.mcp.json` and `~/.claude/settings.json` for configured tools.

Evaluate each:
- **Token efficiency**: If `ENABLE_TOOL_SEARCH` is enabled, MCP tools are deferred and the token cost difference between MCP and CLI is smaller. If disabled, MCPs inject full schemas every turn — prefer CLI. Also check if an MCP exposes too many tools (e.g., 60+), which increases context cost even with deferred loading.
- **Redundancy**: Multiple tools covering the same capability (e.g., two monitoring tools).

### 4. Audit existing skills

List all skills in `.claude/skills/` and `~/.claude/skills/`:

**Quality checks** (per official skill spec):
- SKILL.md under 500 lines
- `description` under 250 chars, front-loads the use case
- `disable-model-invocation: true` for side-effect skills
- `paths` frontmatter where applicable

**Structural checks**:
- **Duplicates**: skills that overlap in purpose (project vs global)
- **Stale**: skills referencing files/tools that no longer exist
- **Coverage gaps**: repeating workflows not yet captured as skills

### 5. Present findings

**Capability Coverage** — table showing each relevant category, current tool, and status (covered / gap)
**Available** — MCP/CLI connections and skills currently set up, with token efficiency notes
**Suggested** — connections or skills worth adding, with source URL and rationale
**Improve** — existing tools/skills that could be better
**Remove** — redundant or token-inefficient tools/skills

Present as tables. Wait for user approval before making changes.

## Principles

- "Can the agent act on this, not just think about it?"
- Check if `ENABLE_TOOL_SEARCH` is set. If enabled, MCP tools are deferred (loaded on demand via ToolSearch), reducing the token efficiency gap between MCP and CLI. If disabled, MCPs inject full schemas every turn — prefer CLI in that case.
- Fewer tools > more tools. Each MCP/skill consumes context budget.
- Do not recommend tools from training knowledge. Always web search for the latest options.
