#!/usr/bin/env bash
# pre-tool-safety.sh — PreToolUse hook for destructive command detection
# Runs on every Bash tool call in bypassPermissions mode.
# Returns permissionDecision:"deny" for dangerous commands.
# Safe exceptions (build artifacts) are allowed through.
set -euo pipefail

INPUT=$(cat)

CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

ALLOW='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'

if [ -z "$CMD" ]; then
  echo "$ALLOW"
  exit 0
fi

CMD_LOWER=$(printf '%s' "$CMD" | tr '[:upper:]' '[:lower:]')

# --- Safe exceptions for rm -rf ---
if printf '%s' "$CMD" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*\s+|--recursive\s+)' 2>/dev/null; then
  SAFE_ONLY=true
  RM_ARGS=$(printf '%s' "$CMD" | sed -E 's/.*rm\s+(-[a-zA-Z]+\s+)*//;s/--recursive\s*//')
  for target in $RM_ARGS; do
    case "$target" in
      */node_modules|node_modules|*/\.next|\.next|*/dist|dist|*/__pycache__|__pycache__|*/\.cache|\.cache|*/build|build|*/\.turbo|\.turbo|*/coverage|coverage|*/.wrangler|.wrangler)
        ;;
      -*)
        ;;
      *)
        SAFE_ONLY=false
        break
        ;;
    esac
  done
  if [ "$SAFE_ONLY" = true ]; then
    echo "$ALLOW"
    exit 0
  fi
fi

# --- Destructive pattern checks ---
WARN=""

# rm -rf / rm -r / rm --recursive
if printf '%s' "$CMD" | grep -qE 'rm\s+(-[a-zA-Z]*r|--recursive)' 2>/dev/null; then
  WARN="Destructive: recursive delete. This permanently removes files."
fi

# DROP TABLE / DROP DATABASE
if [ -z "$WARN" ] && printf '%s' "$CMD_LOWER" | grep -qE 'drop\s+(table|database)' 2>/dev/null; then
  WARN="Destructive: SQL DROP detected. This permanently deletes database objects."
fi

# TRUNCATE
if [ -z "$WARN" ] && printf '%s' "$CMD_LOWER" | grep -qE '\btruncate\b' 2>/dev/null; then
  WARN="Destructive: SQL TRUNCATE detected. This deletes all rows from a table."
fi

# git push --force / git push -f
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'git\s+push\s+.*(-f\b|--force)' 2>/dev/null; then
  WARN="Destructive: git force-push rewrites remote history."
fi

# git reset --hard
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'git\s+reset\s+--hard' 2>/dev/null; then
  WARN="Destructive: git reset --hard discards all uncommitted changes."
fi

# git checkout . / git restore .
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'git\s+(checkout|restore)\s+\.' 2>/dev/null; then
  WARN="Destructive: discards all uncommitted changes in the working tree."
fi

# Skip hooks
if printf '%s' "$CMD" | grep -qE '\-\-no-verify|(^|[;&|]\s*)LEFTHOOK=(0|false)\s' 2>/dev/null; then
  WARN="Skipping git hooks (--no-verify, LEFTHOOK=0) is not allowed. Fix the underlying issue."
fi

# kubectl delete
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'kubectl\s+delete' 2>/dev/null; then
  WARN="Destructive: kubectl delete removes Kubernetes resources."
fi

# docker rm -f / docker system prune
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'docker\s+(rm\s+-f|system\s+prune)' 2>/dev/null; then
  WARN="Destructive: Docker force-remove or prune."
fi

# terraform apply (without plan file)
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'terraform\s+apply' 2>/dev/null; then
  WARN="Caution: terraform apply modifies infrastructure."
fi

# chezmoi apply --force
if [ -z "$WARN" ] && printf '%s' "$CMD" | grep -qE 'chezmoi\s+apply\s+.*--force' 2>/dev/null; then
  WARN="Blocked: chezmoi apply --force overwrites local changes. Run 'chezmoi diff' first, then either: (1) show the diff to the user and ask whether to merge into source, or (2) save the local diff, apply, then restore it."
fi

# --- Output ---
if [ -n "$WARN" ]; then
  WARN_ESCAPED=$(printf '%s' "$WARN" | sed 's/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$WARN_ESCAPED"
else
  echo "$ALLOW"
fi
