---
name: context-engineering
description: >
  Audit CLAUDE.md, .claude/rules/, hooks, and skills for context efficiency.
  Use when: "context engineering", "CLAUDE.md見直して", "prune", "audit",
  "ルール分離", "コンテキスト", or when reviewing harness configuration quality.
---

# Context Engineering Audit

Audit and improve the context configuration of the current project.

## What you audit

1. **CLAUDE.md** (project + global `~/.claude/CLAUDE.md`)
2. **`.claude/rules/`** (path-scoped rules)
3. **`settings.json`** (hooks configuration)
4. **`.claude/skills/`** (skill structure)

## Step 1: Gather state

Read all of the following that exist:
- `CLAUDE.md` (project root)
- `~/.claude/CLAUDE.md` (global)
- All files in `.claude/rules/`
- `.claude/settings.json` and `~/.claude/settings.json` (hooks section)
- List `.claude/skills/` directory

Also scan the codebase to understand what tools, frameworks, and linters are in use.

## Step 2: Litmus test every line in CLAUDE.md

For each line or rule block in CLAUDE.md, evaluate:

| Question | If yes |
|----------|--------|
| Does Claude already know this from training? (standard language/framework conventions) | **Delete** |
| Is this enforced by a hook or linter in settings.json? | **Delete** (the hook is the source of truth) |
| Does this only apply to specific file types? | **Move to `.claude/rules/`** with `paths` frontmatter |
| Is this inferrable by reading the code or config files? | **Delete** |
| Is this a pointer to another file or resource? | **Keep** (pointers are cheap) |
| Is this a non-obvious gotcha that would cause mistakes? | **Keep** |
| Is this a build/test/deploy command? | **Keep** |

## Step 3: Check rules/ structure

- Are there rules that should have `paths` frontmatter but don't?
- Are there rules in CLAUDE.md that belong in `rules/`?
- Are there redundant rules (same thing in CLAUDE.md and rules/)?

## Step 4: Check hooks coverage

- Are there rules in CLAUDE.md that could be a hook instead? (hooks are deterministic, CLAUDE.md is probabilistic)
- Is there a PostToolUse hook for lint/format on file edit?
- Is there a PreToolUse hook for destructive command blocking?

## Step 5: Check for missing pointers

CLAUDE.md should serve as a map. Check if the project has documentation that CLAUDE.md doesn't point to:

- `docs/` directory with markdown files
- `ADR/` or `adr/` directory
- `README.md` with project-specific setup or architecture
- `CONTRIBUTING.md`
- `ARCHITECTURE.md` or similar design docs
- Schema files, API specs, or other reference material

If any exist and CLAUDE.md has no `@path` pointer or mention of them, propose adding a pointer. Pointers are cheap (one line) and help Claude discover deep context on demand.

## Step 6: Present findings

Group findings into:

**Delete** — lines that don't pass the litmus test, with reason
**Move to rules/** — lines that should be path-scoped, with suggested `paths` frontmatter
**Convert to hook** — rules that should be mechanically enforced
**Keep** — lines that earn their place, with reason
**Missing** — things the project should have but doesn't

Present as a table. Wait for user approval before making any changes.

## Step 7: Execute approved changes

Only after user says "proceed" or approves specific items:
- Edit CLAUDE.md (remove/rewrite lines)
- Create or update files in `.claude/rules/`
- Propose hook configurations for `settings.json`

## Principles

- CLAUDE.md is a User Message injected at session start. It degrades over time (context rot). Shorter = better adherence.
- `.claude/rules/` with `paths` are injected when matching files are first accessed — fresher position in context.
- Hook > Linter > CLAUDE.md. If it can be enforced mechanically, don't rely on CLAUDE.md.
- One line, imperative, specific, verifiable. No vague guidance.
- CLAUDE.md is a map, not an encyclopedia. Pointers to code/docs, not explanations.
