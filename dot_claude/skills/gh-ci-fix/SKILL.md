---
name: gh-ci-fix
description: >
  "CIが落ちた" "CI fix" "CI直して" "make CI green" "CIグリーンにして" —
  Fix CI failures locally until green. Monitors the CI run for the current
  branch, diagnoses failures from logs, fixes locally, verifies, and pushes.
  Repeats up to 3 rounds. Also use after pushing when CI might fail.
---

# CI Fix

Fix CI failures for the current branch. Detect → diagnose → fix locally → verify → push. Repeat until green or 3 rounds.

## Context

- Branch: !`git branch --show-current`
- Latest CI run: !`gh run list --branch $(git branch --show-current) --limit 1 --json databaseId,status,conclusion,name,headSha 2>/dev/null || echo "no runs found"`

## Process

### 1. Wait for CI if in progress

If the latest run is `in_progress` or `queued`:
```bash
gh run watch <run-id>
```

### 2. Check result

If `conclusion` is `success` → report "CI is green" and stop.
If `conclusion` is `failure` → proceed.

### 3. Get failure details

```bash
gh run view <run-id> --log-failed 2>&1 | tail -100
```

Read the output. Identify the failing step and root cause.

### 4. Fix locally

Based on the error:
- Lint/format → run the project's lint fix command
- Type error → fix the type
- Test failure → understand why it fails, fix code or test
- Build failure → fix compilation

**Verify locally before pushing** — run the same checks that CI runs. Read the CI workflow file if needed to know what commands to run:
```bash
cat .github/workflows/ci.yml
```

### 5. Commit and push

```bash
git add <fixed-files>
git commit -m "fix: <what was fixed>"
git push
```

Each fix is a separate atomic commit.

### 6. Repeat

Go back to step 1. Wait for the new CI run.

**Maximum 3 rounds.** If still failing after 3 fix-push cycles, stop and report:
- What was tried
- What remains broken
- Why further automated fixing is unlikely to help

## Principles

- Always verify locally before pushing. Don't waste CI minutes on untested fixes.
- Fix the root cause, not the symptom.
- Each fix = one atomic commit with a descriptive message.
- 3 rounds max. Diminishing returns beyond that.
