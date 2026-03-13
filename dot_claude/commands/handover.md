---
description: Generate a handover document for session continuity when context is getting full
---

## Why this exists

Auto-compact loses context. This command creates a handover document that preserves the full conversation context in compact form, so a fresh session can continue without any loss.

The rule is simple: **nothing essential may be omitted**. If the user said it, decided it, rejected it, or discovered it during this session, the next session must know about it. Compact the information, but do not drop it.

## Step 1: Gather facts

Gather the current git state: status, diff stat, and recent 5 commits.

Then walk through the ENTIRE conversation from start to finish. Do not rely on memory of "what seemed important." Read every user message and every assistant response. Extract:

- The original goal and how it evolved over the session
- Every decision, including tentative ones and deferred ones
- Every approach that was tried and failed, with the exact reason
- Every user correction, preference, or constraint expressed
- Every error encountered and its resolution
- Every value, name, or configuration discussed (settled or not)
- Tool-specific quirks or issues discovered

## Step 2: Write the handover

Create `handover-YYYY-MM-DD_HHmm.md` in the repository root (local time).

Omit empty sections EXCEPT "Failed Approaches" — write "None" if nothing failed.

```
# Handover — YYYY-MM-DD HH:mm

**Branch**: [branch]
**Status**: [In Progress / Blocked / Ready for Review]

## Goal

[What the user wants to achieve. If the goal evolved, describe the evolution.]

## Completed

- [x] [Completed item with enough detail to verify]

## Not Yet Done

- [ ] [Remaining task — specific enough to act on without asking]

## Failed Approaches (Don't Repeat These)

[For each:]
- What was attempted
- Why it failed (error message, user rejection, design flaw, tool limitation)
- What replaced it

Include tool usage failures (wrong arguments, unsupported features, API quirks).

## Decisions Made

- **[FIRM]** [Decision] — [Rationale]
- **[TENTATIVE]** [Decision] — [Rationale]. Open to change.
- **[DEFERRED]** [Decision] — [Options discussed]. Blocked on [what].

## User Preferences & Constraints

[Everything the user expressed about how they want things done.]

## Current State

**Working**: [What's functional]
**In Progress**: [What's partially done — where it stopped]
**Broken**: [What's not working]
**Uncommitted Changes**: [From git status/diff]

## Code Context

[Show, don't describe. Include actual code:]
- Function signatures, interfaces created/modified
- API shapes, config values, CSS values discussed
- Non-obvious logic

## Resume Instructions

1. [Exact first action]
2. [Verification with expected outcome]

## Key Files

| File | Why It Matters |
|------|----------------|
| `path` | [Role] |

## Warnings

[Gotchas, intentional oddities, traps]
```

## Guidelines

- Walk the full conversation. Do not skip or skim. The most common failure is omitting something because it "seemed minor" — but the user remembers saying it, and will notice if it's missing.
- Compact the expression, not the information. "Use Inter, not system-ui (Pencil rejects system-ui)" is compact. Omitting it entirely is a loss.
- Mark decision certainty. "〜かな" ≠ decided.
- Show code, don't describe it.
- Do not read previous handover files. Each captures only the current session.
- After writing, print the path:
  `In your next session, reference: @handover-<filename>`
