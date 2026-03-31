#!/usr/bin/env bash
# PreToolUse hook: block git commit on branches with merged/closed PRs
set -euo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only check commands that contain git commit (handles chained commands like eval ... && git commit)
case "$CMD" in
  *git\ commit*) ;;
  *) exit 0 ;;
esac

# Determine the git directory: if command starts with cd, resolve that directory
GIT_DIR=""
case "$CMD" in
  cd\ *)
    TARGET=$(printf '%s' "$CMD" | sed -E 's/^cd\s+([^ ;&|]+).*/\1/')
    TARGET=$(eval printf '%s' "$TARGET" 2>/dev/null)
    if [ -d "$TARGET" ]; then
      GIT_DIR="$TARGET"
    fi
    ;;
esac

if [ -n "$GIT_DIR" ]; then
  BRANCH=$(git -C "$GIT_DIR" branch --show-current 2>/dev/null)
  GH_REPO=$(git -C "$GIT_DIR" remote get-url origin 2>/dev/null)
else
  BRANCH=$(git branch --show-current 2>/dev/null)
  GH_REPO=""
fi

# main/master are always OK (direct commits are a separate concern)
case "$BRANCH" in
  main|master|"") exit 0 ;;
esac

# Build gh args for repo targeting
GH_REPO_ARGS=()
if [ -n "$GH_REPO" ]; then
  GH_REPO_ARGS=(--repo "$GH_REPO")
fi

# Check if this branch has a merged or closed PR
PR_STATE=$(gh pr list "${GH_REPO_ARGS[@]+"${GH_REPO_ARGS[@]}"}" --head "$BRANCH" --state merged --json number --jq '.[0].number' 2>/dev/null)
if [ -n "$PR_STATE" ]; then
  jq -n --arg branch "$BRANCH" --arg pr "$PR_STATE" '{
    decision: "block",
    reason: ("Branch \"" + $branch + "\" has merged PR #" + $pr + ". Create a new branch from main for the next task.")
  }'
  exit 0
fi

PR_STATE=$(gh pr list "${GH_REPO_ARGS[@]+"${GH_REPO_ARGS[@]}"}" --head "$BRANCH" --state closed --json number --jq '.[0].number' 2>/dev/null)
if [ -n "$PR_STATE" ]; then
  jq -n --arg branch "$BRANCH" --arg pr "$PR_STATE" '{
    decision: "block",
    reason: ("Branch \"" + $branch + "\" has closed PR #" + $pr + ". Create a new branch from main for the next task.")
  }'
  exit 0
fi

exit 0
