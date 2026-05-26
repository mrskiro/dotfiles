#!/usr/bin/env bash
# gha-lint.sh — PostToolUse hook for GitHub Actions workflow linting
# Runs pinact (auto-fix pins), ghalint (security policies), actionlint (syntax).
# Only triggers on .github/workflows/ and .github/actions/ files.
set -euo pipefail

INPUT=$(cat)

FILE=$(printf '%s' "$INPUT" | jq -re '.tool_input.file_path // empty' 2>/dev/null) || exit 0

case "$FILE" in
  */.github/workflows/*|*/.github/actions/*) ;;
  *) exit 0 ;;
esac

ROOT=$(git -C "$(dirname "$FILE")" rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT"

ERRORS=""

# pinact: auto-fix SHA pins.
# Authenticate via gh's token so GitHub API tag lookups use the 5000/h limit
# instead of the unauthenticated 60/h that pinact otherwise hits.
export GITHUB_TOKEN="${GITHUB_TOKEN:-$(gh auth token 2>/dev/null || true)}"
P=$(pinact run -u --min-age 7 2>&1) || ERRORS="pinact: $P"

# ghalint: security policy check (non-zero exit = violations found, not a failure)
# strip noise: timestamp, ERR prefix, program, version, reference URL
if command -v ghalint >/dev/null 2>&1; then
  G=$(ghalint run --log-color auto 2>&1 \
    | sed 's/^.* ERR [^ ]* //; s/ program=[^ ]*//; s/ version=[^ ]*//; s/ reference=[^ ]*//' \
    || true)
  if [ -n "$G" ]; then
    ERRORS="${ERRORS:+$ERRORS | }ghalint: $G"
  fi
fi

# actionlint: syntax check (non-zero exit = errors found)
if command -v actionlint >/dev/null 2>&1; then
  A=$(actionlint -format '{{range .}}{{.Filepath}}:{{.Line}}: {{.Message}} {{end}}' 2>&1 || true)
  if [ -n "$A" ]; then
    ERRORS="${ERRORS:+$ERRORS | }actionlint: $A"
  fi
fi

if [ -n "$ERRORS" ]; then
  echo "$ERRORS" >&2
  exit 2
fi
