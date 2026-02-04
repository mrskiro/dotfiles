---
description: "Fix CI failures automatically and update PR"
allowed-tools: Bash(git:*), Bash(gh:*)
---

# Fix CI Failures

You are tasked with automatically detecting and fixing CI failures for the current PR, then pushing the fixes.

## Context

- Current branch: !`git branch --show-current`
- PR status: !`gh pr view --json number,title,statusCheckRollup`
- Recent commits: !`git log --oneline -5`

## Execution Steps

1. **Detect CI Failures**

   - Identify all failed CI checks from the PR status above
   - For each failure, get detailed logs using: `gh run view <run-id> --log-failed`

2. **Analyze and Fix**

   - Read the error logs carefully
   - Identify the root cause of each failure
   - Apply appropriate fixes based on the error type
   - Verify fixes work before committing

3. **Commit and Push**
   - Create a descriptive commit message
   - Push changes to update the PR

## Important Notes

- Fix all detected errors if possible
- If a fix is not possible automatically, report the issue to the user with details
- Always verify fixes before committing

## Expected Output

Provide a summary report including:

- List of CI failures detected
- Fixes applied for each failure
- Commit message and push status
- Any issues requiring manual intervention
