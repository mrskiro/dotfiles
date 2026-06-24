---
name: codify
description: >
  "codify" "なるほど" "わかった" "it works" "solved" "fixed" — Codify session
  learnings into docs/, rules/, or CLAUDE.md so future sessions can discover
  them. Use when a bug is fixed, a problem is solved, a design decision is
  made, a non-obvious gotcha is discovered, or a workflow is established.
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
| Test / linter rule / hook | The issue can be caught mechanically. Always prefer this |
| **Skill's Gotchas section** | The learning surfaced *while a specific skill was active*. Skill Gotchas sections are the highest-signal content in a skill (Anthropic). Grow them every time the agent makes a mistake using the skill |
| **Skill's anti-rationalization table** | The agent generated a plausible-sounding excuse to skip a step. Add the excuse + a written rebuttal to the table so the next session sees the pre-written counter (Osmani) |
| **Skill-private data via `${CLAUDE_PLUGIN_DATA}`** | The learning is operational state ("last time I deployed, the migration was at v3") not prose. Append to `${CLAUDE_PLUGIN_DATA}/<skill>/log.jsonl` or similar |
| **Security context file** (versioned, default-loaded) | The learning is a "never do X" rule with stakes. Prompt-only rules don't survive injection / long context / ambiguity — pair with a deterministic gate (VibeSec pattern, Thoughtworks via Fowler) |
| `docs/<topic>.md` | Solutions, gotchas, design decisions, specs — anything worth more than one line that isn't skill-private |
| `.claude/rules/` with `paths` | Coding conventions scoped to specific file types |
| `CLAUDE.md` (one-line pointer) | Only add a pointer to docs/. Never add content directly |

Priority: **test/linter/hook > skill-internal (Gotchas, anti-rationalization, plugin data) > security context file > docs/ > rules/ > CLAUDE.md pointer.**

Why this order:
- Tests / hooks fail loudly when broken — they self-enforce, never degrade
- Skill-internal content lives where the relevant workflow is anyway — it's already in context when needed
- Security context files are versioned and paired with deterministic gates
- docs/ files are discoverable by grep and persist across sessions
- rules/ are injected fresh when matching files are touched
- CLAUDE.md degrades over time (injected at session start, effectiveness drops, every line costs tokens for every engineer on the team)

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

### 7. "What can I stop doing?" (Anthropic)

Codify is usually about *adding* — but each addition is a future maintenance cost. Before committing, scan the surrounding area for things that can now be **removed**:

- Old workarounds that the fixed bug obsoletes
- CLAUDE.md lines or rule sections that the new test/hook now enforces
- Skill Gotchas entries that the underlying code change has resolved
- Comments explaining a constraint that no longer holds
- Multiple equivalent explanations of the same thing in different docs

Harness assumptions don't survive model upgrades or codebase changes. Anthropic's framing: as models improve, what we encode in harness goes stale. Periodically — and especially when codifying a related fix — test what can be removed. Prefer deleting two things while adding one over piling up indefinitely.

## On vocabulary and cognitive debt

When codifying, watch for new terms entering the codebase's vocabulary (Joshi via Fowler — "Code as a shared conceptual model"). LLMs generate plausible code with familiar-looking structures faster than teams build shared understanding of what those structures mean. If the fix introduces a new term (`delivery_target`, `coherence_chain`, `outcome_grader`), the codify target should include a one-line definition — even just in the skill body or docs/glossary.md. Without that, the term spreads through generated code as **cognitive debt**: structures with names but no shared meaning.
