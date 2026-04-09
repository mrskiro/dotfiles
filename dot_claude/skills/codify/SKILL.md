---
name: codify
description: >
  Codify session learnings into docs/, rules/, or CLAUDE.md so future sessions
  can discover them. Use when: a bug is fixed, a problem is solved, a design
  decision is made, a non-obvious gotcha is discovered, a workflow is established,
  or the user says "it works", "solved", "fixed", "なるほど", "わかった".
---

# Codify

Capture knowledge from this session and persist it so future sessions benefit.

## When to codify

- A bug was fixed (root cause + solution)
- A non-obvious gotcha was discovered
- A design decision or architectural choice was made
- A workflow or process was established
- A tool/library behavior was learned the hard way
- Requirements or specs were clarified
- The user corrected the agent's approach

## Process

### 1. Extract knowledge from the current conversation

Identify what was learned. Focus on:
- What was the problem?
- What was tried and didn't work?
- What was the solution and why does it work?
- What would prevent this category of issue in the future?

### 2. Check for existing docs

Search `docs/` and CLAUDE.md for related content. If a related doc already exists, **update it** instead of creating a new one. Avoid duplication.

### 3. Choose the right codify target

| Target | When to use |
|---|---|
| Test / linter rule | The issue can be caught mechanically. Always prefer this |
| `docs/<topic>.md` | Solutions, gotchas, design decisions, specs — anything worth more than one line |
| `.claude/rules/` with `paths` | Coding conventions scoped to specific file types |
| `CLAUDE.md` (one-line pointer) | Only add a pointer to docs/. Never add content directly |

Priority: test/linter > docs/ > rules/ > CLAUDE.md pointer.

Why this order:
- Tests fail loudly when broken — they self-enforce
- docs/ files are discoverable by grep and persist across sessions
- rules/ are injected fresh when matching files are touched
- CLAUDE.md degrades over time (injected at session start, effectiveness drops)

### 4. Write the doc

For `docs/` files:

```markdown
# <Title>

## Problem
What went wrong or what question came up.

## Solution
What works and why.

## Prevention
How to avoid this in the future (test, linter rule, hook, or convention).
```

Keep it concise. One page per topic. Use clear terminology — future sessions discover docs via grep.

### 5. Discoverability check

CLAUDE.md should be a map that points to docs/. After writing:
- If `docs/` is not mentioned in CLAUDE.md, propose adding a one-line pointer
- If CLAUDE.md already has a docs/ section, no change needed
- Never add the doc content to CLAUDE.md — only pointers

CLAUDE.md is capped at 200 lines (official recommendation). Every line must earn its place.

### 6. Commit

Stage the new/updated docs and any CLAUDE.md changes. Commit within the same session so the knowledge is immediately available to the next session via git.
