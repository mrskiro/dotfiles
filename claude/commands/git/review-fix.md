---
description: "Fix PR review comments automatically"
allowed-tools: Bash(git:*), Bash(gh:*)
---

# PR Review Fix Command

Automatically fetch PR review comments and fix issues that require action.

## Context

- Current branch: !`git branch --show-current`
- PR info: !`gh pr view --json number,url`
- Repository: (use `gh api` - it automatically resolves `:owner/:repo` placeholders)

## Your Task

1. **Fetch and Analyze Review Comments**

   - Extract PR number from the PR info above
   - Use `gh api "repos/:owner/:repo/pulls/{pr_number}/comments"` to get review comments
   - Extract the following information for each comment:
     - `id`: Comment ID (needed for replying)
     - `path`: Target file
     - `line`: Target line number
     - `body`: Comment content
     - `user.login`: Reviewer name
   - Filter out reply comments (where `in_reply_to_id` is not null)
   - Group comments by file and line
   - If no actionable comments are found, report this to the user and exit gracefully

2. **Present Comments and Ask for Action**

   - For each review comment:
     - Show the file path, line number, reviewer name, and comment content
     - Read the relevant code context around the commented line
     - Assess whether the comment requires action based on these criteria:
       - **Action required**: Fix requests, bug reports, improvement suggestions
       - **No action required**: Questions, confirmations, approvals
     - **Ask the user whether to fix this comment** using the AskUserQuestion tool
     - Present your assessment and reasoning for the recommendation

3. **Implement Fixes**

   - For comments that the user approves to fix:
     - Read the target file and line
     - Apply fixes based on the comment
     - Follow project coding conventions (@CLAUDE.md)
   - Combine all fixes into a single commit

4. **Reply to Review Comments**

   - After fixing each comment, reply to it using:
     ```bash
     gh api -X POST "repos/:owner/:repo/pulls/{pr_number}/comments/{comment_id}/replies" \
       -f body="Fixed in [commit hash]. [Brief description of the fix]"
     ```
   - **IMPORTANT**: You must include the PR number in the path
   - Include the commit hash and a brief explanation of what was changed

5. **Commit and Push**
   - Commit message example: `fix: address PR review comments`
   - Report summary of fixes to user
   - Push to update the PR

## Expected Output

Provide a summary report including:

- Number of review comments found
- Comments approved vs. skipped by user
- Files modified and fixes applied
- Commit hash and push status
- Replies sent to reviewers

Example format:

```
Review comments: 5
Fixed: 3
Skipped: 2
Modified files: src/utils.ts, src/api.ts
Commit: abc1234
Push: success
Replies sent: 3
```

## Error Handling

- If no PR exists for current branch, inform user and exit
- If API calls fail (rate limiting, network errors), report the error with details
- If push fails due to conflicts, instruct user to pull and resolve conflicts manually
- If commit fails, show git error and ask user to resolve issues

## Important Notes

- Always get user approval before applying any fixes
- Show relevant code context when asking for approval
- Skip already resolved comments (with replies or resolved status)
- Always verify code consistency before committing
- Reply to each addressed comment to notify the reviewer
