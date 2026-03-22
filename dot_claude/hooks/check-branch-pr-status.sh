#!/usr/bin/env bash
# PreToolUse hook: block git commit on branches with merged/closed PRs
set -euo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only check git commit commands
case "$CMD" in
  git\ commit*) ;;
  *) exit 0 ;;
esac

BRANCH=$(git branch --show-current 2>/dev/null)

# main/master are always OK (direct commits are a separate concern)
case "$BRANCH" in
  main|master|"") exit 0 ;;
esac

# Check if this branch has a merged or closed PR
PR_STATE=$(gh pr list --head "$BRANCH" --state merged --json number --jq '.[0].number' 2>/dev/null)
if [ -n "$PR_STATE" ]; then
  jq -n --arg branch "$BRANCH" --arg pr "$PR_STATE" '{
    decision: "block",
    reason: ("Branch \"" + $branch + "\" has merged PR #" + $pr + ". Create a new branch from main for the next task.")
  }'
  exit 0
fi

PR_STATE=$(gh pr list --head "$BRANCH" --state closed --json number --jq '.[0].number' 2>/dev/null)
if [ -n "$PR_STATE" ]; then
  jq -n --arg branch "$BRANCH" --arg pr "$PR_STATE" '{
    decision: "block",
    reason: ("Branch \"" + $branch + "\" has closed PR #" + $pr + ". Create a new branch from main for the next task.")
  }'
  exit 0
fi

exit 0
