---
name: ship
description: >
  "shipして" "PRにして" "push" "できた" "実装終わった" "実装して" "作って"
  "ship it" "create a PR" "build this" "implement" —
  Autonomous pipeline from implementation to merged PR. Handles: implement
  (with subagent worktree dispatch for multi-task plans) → review → verify →
  commit → push → PR → CI fix → review-comment fix → squash merge. Goal is MERGED.
---

# Ship

Autonomous pipeline. Goal: changes implemented, reviewed, verified, and merged. Once invoked, runs to completion without human intervention.

## Context

- Branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`
- Diff against main: !`git diff $(git merge-base HEAD main 2>/dev/null || echo main)..HEAD --stat 2>/dev/null`

## Process

### 0. Route

Determine what mode to run in:

**A. Changes already exist** (uncommitted changes or commits ahead of main):
→ Skip to Step 2 (Review). Implementation is done.

**B. A plan exists** (passed as argument, or `/plan` output in context):
→ Go to Step 1 (Implement from plan).

**C. A task description is given** (user describes what to build):
→ Create a branch, implement directly, then proceed to Step 2.

### 1. Implement from plan

Read the plan. For each task, respecting dependency order:

**Single task or small change:**
Implement directly in the current session on a feature branch.

**Multiple independent tasks (AFK classified):**
ALWAYS dispatch each task as a separate subagent with `isolation: "worktree"`. Do not implement them sequentially in the main session. Newer Claude models (Opus 4.7+) tend to spawn fewer subagents by default — this instruction overrides that tendency.

Each worker:
1. Creates a feature branch
2. Reads the task description and acceptance criteria
3. Explores relevant codebase
4. Implements the change
5. Runs local verification (test/lint/typecheck)
6. Commits and creates a PR

**HITL tasks:**
Implement in the main session. Ask the user for judgment where needed.

After all tasks are implemented and PRs created, proceed to Step 2 for each PR.

### 2. Review

Run `/review` for cross-model quality verification.

- P0/P1 findings: fix, re-verify locally, then proceed.
- P2 findings: defer — log as TODO, do not block the PR.
- Implementer may pushback on findings if they disagree. Bias toward merging.

### 3. Local verification

Run the project's test/lint/typecheck commands. Read CI workflow or CLAUDE.md if unsure what to run.

If any check fails: fix, re-verify. Do not proceed with failing checks.

### 3.5. Runtime smoke (the "Step 8" gate)

**Build green ≠ DB up. Test green ≠ dev server up. E2E green ≠ user can touch the change.** All three are common reality at Shogun-style autonomous-loop sites where the agent reports "complete" while the stack is actually down.

For changes that affect runtime behavior (anything UI-facing, anything that touches a service boundary, anything that loads at startup), gate the merge on actual runtime smoke before pushing further:

- DB / dependent services up? (`docker ps | grep <container>` or equivalent)
- Dev server up and serving? (`curl -sf http://127.0.0.1:<port>/<entry>` returns 200)
- Smoke connectivity through the change (login flow, the specific button, the specific request) actually exercises the new code path
- For UI: real-browser interaction against the running server, not just E2E test green

If any of this fails, the change isn't done — even with all CI green. Pure-code refactors / docs changes / non-runtime config changes can skip this step, but flag the skip explicitly in the commit message ("docs-only, skipped runtime smoke").

### 4. Commit

- Each logical change = one atomic commit
- Format: `<type>: <summary>` (feat/fix/chore/refactor/docs)
- Small changes (< 50 lines, < 4 files) = single commit is fine

### 5. Push and create PR

```bash
git push -u origin $(git branch --show-current)
```

Create PR if none exists:
```bash
gh pr create --title "<type>: <summary>" --body "<changes summary>" --assignee @me
```

If PR already exists: push only.

### 6. CI monitoring and fix

Wait for all checks to finish:
```bash
gh pr checks --watch --fail-fast
```

If CI fails: identify the failed check from `gh pr checks` output, diagnose from `gh run view <run-id> --log-failed`, fix locally, verify, push. Maximum 3 rounds.

If CI fails after 3 rounds: consider rework (discard branch, recreate from scratch) before reporting blocked.

### 7. PR review comments

Check for review comments:
```bash
PR_NUM=$(gh pr view --json number -q .number)
gh api "repos/:owner/:repo/pulls/$PR_NUM/comments" --jq '.[] | select(.in_reply_to_id == null) | {id, path, line, body, user: .user.login}'
```

If comments exist:
- **P0/P1**: fix, reply, push
- **P2**: defer or pushback with explanation
- **NEEDS-HUMAN**: architectural/judgment questions → report and stop

After fixing, re-run CI check (back to Step 6).

### 8. Merge

When CI is green and no unresolved P0/P1 review comments:
```bash
gh pr merge --squash --delete-branch
```

### 9. Report

```
## Ship Complete

PR: <URL>
Status: MERGED
CI: GREEN
Review: PASS (P0: 0, P1: 0 fixed, P2: N deferred)
Commits: <count>
```

Or if blocked:
```
## Ship Blocked

PR: <URL>
CI: <GREEN/RED>
Blocker: <what stopped autonomous completion>
Action needed: <what the user should do>
```

After completion, suggest `/codify` if design decisions or learnings emerged during implementation.

## Anti-rationalization table

LLMs are excellent at rationalization. Before declaring a ship done, recognize and reject these excuses (Osmani):

| Excuse the agent (or a tired engineer) might generate | Rebuttal |
|---|---|
| "Tests pass, ship it" | Passing tests are *evidence*, not *proof*. Did you check runtime? Did you verify user-visible behavior? Did a human read the diff? |
| "I'll do the runtime smoke after merge" | "After" is the load-bearing word. There is no after. If the change can break user-visible behavior, smoke before merge |
| "This change is too small for a review" | Run /review anyway — it costs cents and catches the off-by-one you didn't see |
| "Re-running CI will fix the flake" | A flake unexamined is a bug shipped. Note the flake explicitly even when retrying |
| "I'll write the test later — the impl is obvious" | If it were obvious, you wouldn't have changed it. Write the failing test first |
| "The CI failure isn't related to my change" | Prove it. Reproduce, isolate, comment. Don't merge until the proof exists |

## Principles

- Goal is MERGED, not just PR created.
- Once started, run to completion. Do not ask for confirmation.
- Bias toward merging. P2 findings do not block.
- Pushback is allowed. The implementer can defer or disagree with review findings.
- Review before push. Local verification before push.
- Each fix is an atomic commit.
- 3 CI fix rounds max. If stuck, consider rework (discard and regenerate) over repeated patching.
- AUTO-FIX review comments without asking. NEEDS-HUMAN = stop and report.
- Squash merge with branch deletion.
- **Context anxiety**: When context is running low, do NOT skip verification steps. Report "blocked due to context limits" rather than cutting corners.
- **Evidence over claim** (Osmani): every step terminates in concrete evidence — passing test output, build exit code, runtime smoke output, reviewer sign-off. "Seems right" never closes the loop.
- **Capture intent for the reviewer** when dispatching subagents to worktrees. Each worker should leave a decision log on its PR body (alternatives weighed, constraints honored, out of scope) so the eventual reviewer isn't "the first human to ever lay eyes on this code"
- **Auto mode `-p` abort behavior**: in headless mode (which is how worktree subagents run), Anthropic auto mode terminates the process after 3 consecutive classifier denials or 20 total. Don't dispatch tasks that are likely to trip the classifier (broad shell access, force-push, prod credentials) — the worker will die mid-task with no human to fall back to.
