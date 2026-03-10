---
name: claude-md
description: >
  Audit and prune CLAUDE.md files, or record session learnings with a strict quality bar.
  Every instruction has a cost — this skill ensures only lines that prevent real mistakes survive.
  Use when: "CLAUDE.md見直して", "学びを記録して", "prune", "audit",
  or when the user asks to add/remove/review rules in CLAUDE.md or .claude/rules/.
---

# CLAUDE.md Manager

Two modes: **audit** (prune existing content) and **record** (capture learnings). Both apply the same quality bar.

## Core constraint

CLAUDE.md is context, not enforcement. It is loaded into the context window at the start of every session, consuming tokens alongside the conversation. The more lines, the higher the cost — and the lower the adherence. When a file is too long, rules get lost and Claude ignores them.

## Principles

### 1. Every instruction has a cost

Even correct instructions increase exploration steps and inference cost. Agents follow instructions faithfully — including unnecessary ones. The question is never "is this true?" but "does this prevent a mistake that would otherwise happen?"

A more precise bar: **would an experienced engineer unfamiliar with this specific repository get this wrong without being told?**

### 2. Only write what the agent cannot discover

If the agent can infer something from reading code, config files, README, or standard documentation, writing it in CLAUDE.md is redundant. Redundant information doesn't help — agents don't filter gracefully, and duplicate signals increase exploration without improving outcomes.

### 3. Write pointers, not descriptions

Prose descriptions of system state rot silently. File references and `@imports` break loudly when stale. Prefer routing to the right place (`@docs/auth.md for the token refresh flow`) over explaining inline. Use `@path/to/file` syntax for imports.

### 4. Enforce through mechanisms, not prompts

Style rules, formatting, and quality checks belong in linters, formatters, hooks, and CI — deterministic tools that are faster, cheaper, and 100% reliable. CLAUDE.md is for things that cannot be mechanically enforced.

### 5. Minimal is the goal

The official target is under 200 lines per CLAUDE.md file. Shorter is better. If a line can be removed without causing mistakes, remove it. Mentioning something — even a tool name — can anchor agent behavior toward it, even when irrelevant to the task.

## Judging each line

### Step 1: Does it belong to a high-value category?

These categories have earned their place through research and practice. Lines that fall into one of these skip the removal filter.

| Category | Why it stays |
|----------|-------------|
| Build/test/deploy commands | Used almost every session, low token cost, most researched effective content |
| Repo-specific tool routing | Prevents the agent from guessing the wrong tool |
| Non-obvious gotchas | Prevents mistakes the agent cannot avoid by reading code |
| Pointers to deep context | Routes the agent without bloating CLAUDE.md |

### Step 2: Does it survive the removal filter?

For lines that don't fall into a high-value category, ask:

1. **Would the agent get this wrong without being told?** → If no, remove
2. **Can a tool enforce this deterministically?** → Move to hook/linter
3. **Is this common knowledge for the tech stack?** → Remove

A line earns its place only when all three answers are "no."

### What always fails

- Style rules → linter/formatter + hooks
- "Write clean code" / "Follow best practices" → self-evident
- Architecture overview → agent reads the code
- File paths and directory structure → agent discovers these
- Framework conventions → agent already knows
- Skill listings → agent reads skill descriptions from `.claude/skills/`
- "Use X library" → only if the agent would actually guess wrong

## Audit mode

When the user asks to review, prune, or audit a CLAUDE.md.

1. Read the target CLAUDE.md, .claude/rules/*.md, and check for @imports
2. Count current lines (target: under 200, ideally under 100)
3. Apply the three-question test to every line/section
4. Classify each item:
   - **KEEP** — passes all three questions
   - **MOVE** — valuable but belongs in a different layer (specify where)
   - **REMOVE** — fails the test (state why in one line)
5. Present the classification to the user as a numbered list
6. After user approval, apply changes
7. Report: lines before → lines after

### Where to move things

Choose the right layer based on how the information should load:

| Layer | When it loads | Use for |
|-------|--------------|---------|
| CLAUDE.md | Every session, unconditionally | Commands, gotchas, routing pointers |
| .claude/rules/*.md | Every session (no `paths`) or on matching files (`paths` frontmatter) | File-type-scoped rules (e.g., API conventions only for `src/api/**/*.ts`) |
| @imports | Every session, expanded inline | Large stable references (README, package.json) |
| skills/ | On demand (invoked or auto-triggered) | Multi-step workflows, domain knowledge |
| hooks | Deterministically on tool events | Lint, format, test, safety gates |

Key insight: if a rule only applies to specific files, it costs less as a path-scoped rule in `.claude/rules/` than as a line in CLAUDE.md that loads every session.

### Red flags

- Sections that read like a README (written for humans, not agents)
- Lists of file paths or directory structures
- Style rules that overlap with configured linters
- Generic programming advice
- Duplicated information (same rule stated differently)
- Descriptions of how the system works (agent reads the code)
- Skill/command listings (agent reads descriptions from skills/)
- Information that changes frequently (will rot)

### Diagnostic lens

If something needs to be documented in CLAUDE.md because the agent keeps getting it wrong, ask: can the codebase itself be made clearer? A confusing codebase that trips an AI agent probably also trips human contributors. Fixing the root cause is better than documenting a workaround.

## Record mode

When the user asks to record a learning, or after a correction reveals a missing rule.

1. Identify the learning — what went wrong, what convention was missed
2. Apply the three-question test:
   - Would the agent get this wrong again without the rule?
   - Can a hook or linter enforce this instead?
   - Is this repo-specific or universal? File-scoped or global?
3. Choose the right home:
   - Hook → if it must happen every time with zero exceptions
   - .claude/rules/ with `paths` → if it applies only to certain files
   - Repo CLAUDE.md → if it's a repo-wide gotcha or command
   - Global ~/.claude/CLAUDE.md → if it applies across all projects
4. If it passes the bar:
   - Draft a one-line rule (imperative, specific, concrete enough to verify)
   - Show it to the user before writing
   - Check for existing similar rules (update, don't duplicate)
   - Check for conflicting rules (contradictions cause arbitrary behavior)
5. If it fails the bar, explain why and suggest the right home

### What a good rule looks like

```
# Good — specific, non-obvious, earns its place
Run `pnpm db:push` after schema changes (drizzle doesn't auto-migrate)
env vars added in code must also be added to `.env.example`

# Bad — vague, obvious, or enforceable by tools
Write clean, maintainable code
Use TypeScript strict mode  ← tsconfig enforces this
Always add types to function parameters  ← TypeScript enforces this
Follow the project's naming conventions  ← which ones? be specific or remove
```
