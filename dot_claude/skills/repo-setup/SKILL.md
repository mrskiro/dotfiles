---
name: repo-setup
description: Apply standard GitHub repository settings via gh API. Use when creating a new repository, after "gh repo create", when the user says "setup the repo", "configure repo settings", "リポジトリの設定", "squash mergeにして", or when reviewing repository configuration. Also use when the user mentions branch protection, SHA pinning, or wants to align a repo with their standard settings.
argument-hint: "<owner/repo or repo URL>"
---

Apply a consistent set of GitHub repository settings via `gh api`. These settings reflect the owner's preferences observed across their active repositories (calect, mrskiro.dev, cptr).

## Workflow

### 1. Identify the target repository

- If an argument is provided, use it as the repo (e.g., `mrskiro/calect`)
- Otherwise, detect from the current git remote: `git remote get-url origin`
- Confirm the repo with the user before making changes

### 2. Fetch current settings

Run and display the current state so the user can see what will change:

```
gh api repos/{owner}/{repo} --jq '{
  has_wiki,
  has_projects,
  has_discussions,
  allow_squash_merge,
  allow_merge_commit,
  allow_rebase_merge,
  delete_branch_on_merge,
  squash_merge_commit_title,
  squash_merge_commit_message,
  visibility
}'
```

Also fetch Actions permissions:

```
gh api repos/{owner}/{repo}/actions/permissions
```

### 3. Apply repository settings

```
gh api repos/{owner}/{repo} -X PATCH \
  -F has_wiki=false \
  -F has_projects=false \
  -F has_discussions=false \
  -F allow_squash_merge=true \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true \
  -f squash_merge_commit_title=COMMIT_OR_PR_TITLE \
  -f squash_merge_commit_message=COMMIT_MESSAGES
```

### 4. Enable SHA pinning for Actions

```
gh api repos/{owner}/{repo}/actions/permissions -X PUT \
  -F enabled=true \
  -f allowed_actions=all \
  -F sha_pinning_required=true
```

This forces all GitHub Actions to use full-length commit SHA references instead of tags.

### 5. Branch protection (public repos only)

Check if the repo is public. If public, apply branch protection to the default branch:

```
gh api repos/{owner}/{repo}/branches/main/protection -X PUT \
  --input - <<EOF
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true
}
EOF
```

If private, branch protection API requires GitHub Pro. Instead:

1. Create a Claude Code hook to block direct pushes to main. Write `.claude/hooks/block-main-push.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

case "$CMD" in
  *git\ push*) ;;
  *) exit 0 ;;
esac

BRANCH=$(git branch --show-current 2>/dev/null)

case "$BRANCH" in
  main|master)
    jq -n '{
      decision: "block",
      reason: "Direct push to main is not allowed. Create a branch and open a PR."
    }'
    ;;
esac
```

Register it in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-main-push.sh"
          }
        ]
      }
    ]
  }
}
```

2. Guide the user to optionally create a ruleset in GitHub UI:
   `https://github.com/{owner}/{repo}/settings/rules`

### 6. Report

Show a before/after summary of what changed. Only report settings that actually changed — skip ones that were already correct.

Format:

```
## Repo Setup: {owner}/{repo}

| Setting | Before | After |
|---------|--------|-------|
| ...     | ...    | ...   |

Applied N changes. M settings were already correct.
```
