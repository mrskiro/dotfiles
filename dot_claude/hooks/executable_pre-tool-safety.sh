#!/usr/bin/env bash
# pre-tool-safety.sh — PreToolUse hook, Bash tool only.
#
# Scope: rules the auto-mode classifier cannot make for us.
#
# Generic destructive-command detection (rm -rf, DROP TABLE, TRUNCATE,
# kubectl delete, docker prune, terraform apply) used to live here. It is now
# the classifier's job: permissions.defaultMode is "auto" and
# autoMode.classifyAllShell routes every shell command through it, and the
# sandbox confines writes to the working directory on top of that. Re-adding
# regex rules for those only reintroduces the false positives that forced the
# build-artifact exception list this hook used to carry.
#
# What stays is what the classifier has no way to know:
#   1. Irreversible loss of *uncommitted* local state. A classifier reads
#      `git reset --hard` as routine git; it cannot see that there is unpushed
#      work in the tree.
#   2. Local policy that is a preference, not a danger.
set -euo pipefail

INPUT=$(cat)

CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

ALLOW='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'

if [ -z "$CMD" ]; then
  echo "$ALLOW"
  exit 0
fi

WARN=""

# --- 1. Irreversible loss of uncommitted work ---

# git reset --hard
if printf '%s' "$CMD" | grep -qE 'git\s+reset\s+--hard' 2>/dev/null; then
  WARN="Destructive: git reset --hard discards all uncommitted changes."
fi

# git checkout . / git restore .
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'git\s+(checkout|restore)\s+\.' 2>/dev/null; then
  WARN="Destructive: discards all uncommitted changes in the working tree."
fi

# chezmoi apply --force — overwrites dotfiles the runtime may have written
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'chezmoi\s+apply\s+.*--force' 2>/dev/null; then
  WARN="Blocked: chezmoi apply --force overwrites local changes. Run 'chezmoi diff' first, then either: (1) show the diff to the user and ask whether to merge into source, or (2) save the local diff, apply, then restore it."
fi

# --- 2. Local policy ---

# Skip hooks
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE '\-\-no-verify|(^|[;&|]\s*)LEFTHOOK=(0|false)\s' 2>/dev/null; then
  WARN="Skipping git hooks (--no-verify, LEFTHOOK=0) is not allowed. Fix the underlying issue."
fi

# --- Output ---
if [ -n "$WARN" ]; then
  WARN_ESCAPED=$(printf '%s' "$WARN" | sed 's/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$WARN_ESCAPED"
else
  echo "$ALLOW"
fi
