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
Dispatch each as a subagent with `isolation: "worktree"`. Each worker:
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

Monitor CI:
```bash
gh run list --branch $(git branch --show-current) --limit 1 --json databaseId,status,conclusion
```

If empty, CI may not have started yet. Wait 10 seconds and retry up to 3 times before concluding no CI exists.

Wait if in progress: `gh run watch <run-id>`

If CI fails: diagnose from `gh run view --log-failed`, fix locally, verify, push. Maximum 3 rounds.

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
