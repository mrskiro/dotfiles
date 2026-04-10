---
name: agentic-audit
description: >
  "ハーネスチェック" "harness audit" "このリポジトリどう？" "何が足りない？"
  "CLAUDE.md見直して" "ツール棚卸し" "audit" — Comprehensive agentic engineering
  audit. Checks lifecycle controls, context quality, tool coverage, security,
  and verification capabilities. Outputs a single prioritized improvement list.
---

# Agentic Audit

Diagnose a repository's readiness for agentic engineering and identify what to improve next.

This combines three concerns into one audit:
- **Lifecycle controls** — what runs when (edit/commit/PR/continuous), and is feedback fast enough?
- **Context quality** — is CLAUDE.md a map or an encyclopedia? Are rules scoped correctly?
- **Tool coverage** — can the agent act on this project's stack, or only read code that talks to it?

## Process

### 1. Gather evidence

Read the actual files before judging. Score based on what exists, not assumptions.

**Project-level:**
- `CLAUDE.md` — conventions, commands, pointers
- `.claude/settings.json` — hooks, permissions
- `.claude/rules/` — path-scoped rules (list all)
- `.claude/skills/` — project skills (list all)
- `lefthook.yml` / `.husky/` — pre-commit config
- `tsconfig.json` / `biome.jsonc` / linter configs — type checking, lint strictness
- `.github/workflows/` — CI pipelines (list and scan key ones)
- `package.json` / `go.mod` / `Cargo.toml` etc. — tech stack
- `.mcp.json` — MCP connections
- `docs/` / `ADR/` — documentation that agents should discover

**Global-level:**
- `~/.claude/settings.json` — global hooks, deny list, permission mode
- `~/.claude/skills/` — global skills (list)

### 2. Lifecycle controls

Organize every control by **when it runs**. See `references/lifecycle.md` for detailed criteria.

| Stage | What to look for |
|---|---|
| **Every edit** (PostToolUse) | lint, format, typecheck hooks |
| **Every commit** (pre-commit) | lint, format, typecheck, test |
| **Every PR** (CI) | test suite, review agents, structural checks |
| **Continuous** (scheduled) | dead code, dependency scanning, metrics |

For each stage: what's present, what's missing, any speed concerns.

Report as **one row per stage** — group all controls into a single cell per stage.

### 3. Context quality

Evaluate whether context is efficient and well-structured. See `references/context.md` for detailed criteria.

**CLAUDE.md litmus test** — for each line:
- Already known from training? → delete
- Enforced by hook/linter? → delete (hook is source of truth)
- Only applies to specific paths? → move to `.claude/rules/` with `paths`
- Pointer to docs/code? → keep (pointers are cheap)
- Non-obvious gotcha? → keep

**Structure checks:**
- Is CLAUDE.md a map (pointers to deeper docs) or an encyclopedia (everything inline)?
- Are there missing pointers to existing docs/, ADR/, README?

**Rules audit** — read the frontmatter of every file in `.claude/rules/`. For each:
- Does it have `paths`? If the content only applies to specific directories/file types, it should
- Does the content overlap with CLAUDE.md or hooks? If so, one of them should be removed
- Is the content something Claude already knows from training? If so, delete

### 4. Tool coverage

Assess whether the agent can **act on** this project's infrastructure. See `references/tools.md` for detailed criteria.

- Detect tech stack from project files
- For each external service/data store: can the agent interact with it?
- Check MCP token efficiency (too many tools? deferred loading enabled?)
- Check skill quality (description under 250 chars? trigger phrases front-loaded?)

### 5. Security boundaries

- Permission mode (defaultMode)
- Destructive command blocking (PreToolUse hooks)
- Secret/credential protection (deny list)
- Config file protection (settings.json, lefthook.yml, tsconfig.json, linter configs)
- Generated code protection (gen/ directories)

### 6. Verification capabilities

Can the agent prove its own work?

- **Tests**: runnable? Command in CLAUDE.md?
- **Browser/Mobile verification**: what tools? CLI preferred over MCP for token efficiency
- **Log access**: runtime logs, error tracking
- **Commit as gate**: does pre-commit include tests?
- **Review separation**: is the reviewer different from the implementer? (same model self-reviewing is unreliable — Anthropic, Bassim)

### 7. Codebase readiness

- Type safety (strict mode, null checks)
- Module boundaries (packages, layers, domains)
- Framework conventions (established patterns)
- Test infrastructure (runner, fixtures, CI)
- Linter error messages: are they actionable for agents? (OpenAI: include repair instructions in error messages)

### 8. Present findings

**1. Lifecycle coverage** — one table, one row per stage (Every Edit / Every Commit / Every PR / Continuous). Present column and Gap column.

**2. Context quality** — CLAUDE.md size and verdict (map vs encyclopedia), rules/ issues, missing pointers.

**3. Tool coverage** — capability gaps, token efficiency issues, skill quality issues.

**4. Security** — what's protected, what's exposed.

**5. Verification** — what loops are closed, what can't be verified. Whether review separation exists.

**6. Prioritized improvements** — top 3-5 gaps ordered by impact. For each:
  - What's missing
  - Why it matters
  - Concrete next step

Wait for user approval before making changes.

## Principles

- Computational > Inferential. Deterministic checks first, LLM judgment where computation can't reach.
- Keep quality left. Fastest feedback at the earliest stage.
- Constraints > instructions. A hook that blocks is stronger than a CLAUDE.md that asks.
- CLAUDE.md is a map, not an encyclopedia. Pointers to code/docs, not explanations.
- "Can the agent act on this, not just think about it?" — tools expand capability, not just knowledge.
- Implementer ≠ reviewer. Self-evaluation is unreliable.
- Garbage collection. Set thresholds for deterministic steps, monitor, fix when exceeded. Maintain like gardening.
