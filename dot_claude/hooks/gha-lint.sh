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

# pinact: auto-fix SHA pins
P=$(pinact run -u 2>&1) || ERRORS="pinact: $P"

# ghalint: security policy check (non-zero exit = violations found, not a failure)
# strip noise: timestamp, ERR prefix, program, version, reference URL
G=$(ghalint run --log-color auto 2>&1 \
  | sed 's/^.* ERR [^ ]* //; s/ program=[^ ]*//; s/ version=[^ ]*//; s/ reference=[^ ]*//' \
  || true)
if [ -n "$G" ]; then
  ERRORS="${ERRORS:+$ERRORS | }ghalint: $G"
fi

# actionlint: syntax check (non-zero exit = errors found)
A=$(actionlint -format '{{range .}}{{.Filepath}}:{{.Line}}: {{.Message}} {{end}}' 2>&1 || true)
if [ -n "$A" ]; then
  ERRORS="${ERRORS:+$ERRORS | }actionlint: $A"
fi

if [ -n "$ERRORS" ]; then
  echo "$ERRORS" >&2
  exit 2
fi
