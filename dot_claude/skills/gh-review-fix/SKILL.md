---
name: gh-review-fix
description: >
  "レビューコメント対応" "review fix" "PR comments" "レビュー指摘直して" —
  Fix PR review comments autonomously. Fetches review comments, classifies as
  auto-fixable or needs-human, fixes what it can, replies to reviewers. Use
  when a PR has unresolved review comments.
---

# PR Review Fix

Fetch PR review comments, classify, fix, and reply. Autonomous — no confirmation needed for clear fixes.

## Context

- Branch: !`git branch --show-current`
- PR: !`gh pr view --json number,url,reviewDecision 2>/dev/null || echo "no PR"`

## Process

### 1. Fetch review comments

```bash
PR_NUM=$(gh pr view --json number -q .number)
gh api "repos/:owner/:repo/pulls/$PR_NUM/comments" --jq '.[] | select(.in_reply_to_id == null) | {id, path, line, body, user: .user.login}'
```

Also check for review-level comments (not inline):
```bash
gh api "repos/:owner/:repo/pulls/$PR_NUM/reviews" --jq '.[] | select(.state == "CHANGES_REQUESTED") | {id, body, user: .user.login}'
```

If no actionable comments: report "No unresolved review comments" and stop.

### 2. Classify each comment

For each comment, determine:

**AUTO-FIX** — clear, mechanical fixes:
- Bug fix requests with obvious solution
- Style/naming suggestions
- Missing error handling the reviewer pointed out
- Dead code removal
- Import ordering

**NEEDS-HUMAN** — judgment required:
- Architecture direction questions
- Design trade-off discussions
- "Should we..." or "What about..." questions
- Scope expansion suggestions

### 3. Fix AUTO-FIX items

For each AUTO-FIX comment:
1. Read the file and context
2. Apply the fix
3. Verify locally (lint/typecheck at minimum)

### 4. Reply to comments

For fixed comments:
```bash
gh api -X POST "repos/:owner/:repo/pulls/$PR_NUM/comments/{comment_id}/replies" \
  -f body="Fixed in $(git rev-parse --short HEAD). <brief description>"
```

For NEEDS-HUMAN comments: do not reply. Report them in the summary.

### 5. Commit and push

```bash
git add <fixed-files>
git commit -m "fix: address PR review comments"
git push
```

### 6. Report

```
## Review Comments

Fixed: N (auto-fix)
Needs human: M
Skipped: K (already resolved)

### Fixed
- [file:line] <what was fixed> — replied to @reviewer

### Needs Human
- [file:line] @reviewer: "<comment>" — requires judgment on <topic>
```

## Principles

- AUTO-FIX items: fix without asking. Reply to the reviewer.
- NEEDS-HUMAN items: report, don't guess. Don't make architectural decisions autonomously.
- Each fix round is one atomic commit.
- Verify locally before pushing.
