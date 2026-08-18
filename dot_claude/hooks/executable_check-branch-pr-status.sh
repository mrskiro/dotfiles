#!/usr/bin/env bash
# PreToolUse hook: block git commit on branches with merged/closed PRs
set -euo pipefail

# This hook is a convenience guard, not a safety boundary, so every probe below
# must fail open. `2>/dev/null` alone does not do that under `set -e`: it hides
# the message but still propagates the exit code, killing the script before the
# check runs. Each substitution therefore needs its own `|| ...` fallback.
INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || CMD=""

# Only check commands that contain git commit (handles chained commands like eval ... && git commit)
case "$CMD" in
  *git\ commit*) ;;
  *) exit 0 ;;
esac

# Determine the git directory: if the command starts with cd, resolve that directory.
#
# Parsed with parameter expansion rather than `sed` + `eval`. Both were wrong:
# BSD sed (macOS) does not understand `\s`, so the substitution never matched and
# `$TARGET` kept the whole command line — which `eval` then ran, executing the very
# `git commit` this hook exists to be able to block, before deciding anything.
GIT_DIR="."
case "$CMD" in
  cd[[:space:]]*)
    TARGET=${CMD#cd}
    TARGET=${TARGET#"${TARGET%%[![:space:]]*}"}
    # A quoted path may contain spaces, so it ends at its closing quote; an
    # unquoted one ends at the first separator (whitespace covers newlines too).
    case "$TARGET" in
      \"*) TARGET=${TARGET#\"}; TARGET=${TARGET%%\"*} ;;
      \'*) TARGET=${TARGET#\'}; TARGET=${TARGET%%\'*} ;;
      *)   TARGET=${TARGET%%[[:space:];\&|]*} ;;
    esac
    # A literal tilde reaches us unexpanded because the command arrives as a
    # string the shell never word-expanded. The patterns escape it rather than
    # quoting it, which SC2088 would read as a failed expansion.
    case "$TARGET" in
      \~)   TARGET="$HOME" ;;
      \~/*) TARGET="$HOME/${TARGET#*/}" ;;
    esac
    if [ -n "$TARGET" ] && [ -d "$TARGET" ]; then
      GIT_DIR="$TARGET"
    fi
    ;;
esac

# Scratchpad and other non-repo directories have no branch to check. Bail before
# spending a git round-trip on them, which used to cost seconds and then die.
git -C "$GIT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

BRANCH=$(git -C "$GIT_DIR" branch --show-current 2>/dev/null) || BRANCH=""

# main/master are always OK (direct commits are a separate concern)
case "$BRANCH" in
  main|master|"") exit 0 ;;
esac

# Target the repo explicitly rather than letting gh infer it from the cwd: the
# committed-to directory is often a worktree the hook was not launched from.
# A repo with no origin, or one not on GitHub, has no PRs to look up.
GH_REPO=$(git -C "$GIT_DIR" remote get-url origin 2>/dev/null) || GH_REPO=""
case "$GH_REPO" in
  *github.com*) ;;
  *) exit 0 ;;
esac

# Check if this branch has a merged or closed PR.
# One `gh pr list` call instead of two: each is a network round-trip (~0.5s), and this
# hook is on a short timeout. On timeout the hook is cancelled and the guard silently
# does not run, so halving the round-trips halves that exposure.
# `--state closed` would also return merged PRs, so filter on `.state` instead.
# MERGED takes priority over CLOSED, matching the previous two-step order.
PR=$(gh pr list --repo "$GH_REPO" --head "$BRANCH" --state all --json number,state \
  --jq '(map(select(.state == "MERGED"))[0] // map(select(.state == "CLOSED"))[0]) | select(.) | "\(.state) \(.number)"' 2>/dev/null) || PR=""

if [ -n "$PR" ]; then
  case "${PR%% *}" in
    MERGED) PR_LABEL="merged" ;;
    *) PR_LABEL="closed" ;;
  esac
  jq -n --arg branch "$BRANCH" --arg pr "${PR#* }" --arg label "$PR_LABEL" '{
    decision: "block",
    reason: ("Branch \"" + $branch + "\" has " + $label + " PR #" + $pr + ". Create a new branch from main for the next task.")
  }'
  exit 0
fi

exit 0
