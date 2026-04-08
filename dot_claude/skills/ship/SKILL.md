---
name: ship
description: >
  "shipして" "PRにして" "push" "できた" "実装終わった" "ship it" "create a PR" —
  implementation complete triggers. Autonomous pipeline: review → verify → commit →
  push → PR → CI fix → review-comment fix → squash merge. Goal is MERGED.
---

# Ship

Autonomous shipping pipeline. Goal: PR merged. Once invoked, runs to completion without human intervention.

## Context

- Branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`
- Diff against main: !`git diff $(git merge-base HEAD main 2>/dev/null || echo main)..HEAD --stat 2>/dev/null`

## Process

### 1. Pre-flight

- Not on main/master branch (abort if so)
- There are changes to ship (committed or uncommitted)
- If uncommitted changes exist, include them

### 2. Review

Run `/review` for cross-model quality verification.

If NEEDS ATTENTION with CRITICAL findings: fix, re-verify locally, then proceed.
If PASS or MEDIUM/LOW only: proceed.

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

### 7. PR review comments

Check for review comments:
```bash
PR_NUM=$(gh pr view --json number -q .number)
gh api "repos/:owner/:repo/pulls/$PR_NUM/comments" --jq '.[] | select(.in_reply_to_id == null) | {id, path, line, body, user: .user.login}'
```

If comments exist, invoke `/gh-review-fix` behavior:
- **AUTO-FIX**: clear mechanical fixes → fix, reply, push
- **NEEDS-HUMAN**: architectural/judgment questions → report and stop

After fixing, re-run CI check (back to Step 6).

### 8. Merge

When CI is green and no unresolved review comments:
```bash
gh pr merge --squash --delete-branch
```

### 9. Report

```
## Ship Complete

PR: <URL>
Status: MERGED
CI: GREEN
Review: PASS
Review comments: N fixed, M needs-human
Commits: <count>
```

Or if blocked:
```
## Ship Blocked

PR: <URL>
CI: <GREEN/RED>
Blocker: <what stopped autonomous completion>
  - CI red after 3 fix rounds, OR
  - Review comments need human judgment
Action needed: <what the user should do>
```

## Principles

- Goal is MERGED, not just PR created.
- Once started, run to completion. Do not ask for confirmation.
- Review before push. Local verification before push.
- Each fix is an atomic commit.
- 3 CI fix rounds max.
- AUTO-FIX review comments without asking. NEEDS-HUMAN = stop and report.
- Squash merge with branch deletion.
- **Context anxiety**: When context is running low, do NOT skip verification steps. Rushing to finish and cutting corners is worse than reporting "blocked due to context limits". Run every check even if context is tight.
