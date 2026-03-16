---
name: claude-md
description: >
  Audit and prune CLAUDE.md files, or record session learnings with a strict quality bar.
  Use when: "CLAUDE.md見直して", "学びを記録して", "prune", "audit",
  or when the user asks to add/remove/review rules in CLAUDE.md or .claude/rules/.
---

# CLAUDE.md Best Practices

CLAUDE.md loads into the context window every session. More lines = higher token cost + lower adherence.

## Quality bar

**Write only what the agent cannot discover from code, config, or docs — and would get wrong without being told.**

Earns its place:
- Build/test/deploy commands
- Repo-specific tool routing
- Non-obvious gotchas
- Pointers to deep context (`@path/to/file`)

Never earns its place:
- Anything inferable from code or config
- Anything a linter/formatter/hook can enforce
- Framework conventions the agent already knows
- Skill listings (auto-loaded from skills/)
- Vague guidance ("write clean code")
- Architecture overview or file structure (agent reads the code)
- Information that changes frequently (will rot)

If something needs documenting because the agent keeps getting it wrong, consider whether the codebase itself can be made clearer first.

## Where to put things

| Layer | When |
|-------|------|
| CLAUDE.md | Every session. Commands, gotchas, pointers |
| .claude/rules/ (with `paths`) | Rules scoped to specific files |
| @imports | Stable references expanded inline |
| skills/ | On-demand workflows, domain knowledge |
| hooks | Must happen every time, zero exceptions |
| ~/.claude/CLAUDE.md | Cross-project rules |

If a rule only applies to specific files, a path-scoped rule in `.claude/rules/` costs less than a line in CLAUDE.md.

## Writing rules

One line, imperative, specific, verifiable.

```
# Good
Run `pnpm db:push` after schema changes (drizzle doesn't auto-migrate)
env vars added in code must also be added to `.env.example`

# Bad
Write clean, maintainable code
Follow the project's naming conventions
```
