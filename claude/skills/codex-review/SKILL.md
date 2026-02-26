---
name: codex-review
description: Run code review using Codex CLI. Use when the user wants to review uncommitted changes, a specific commit, or branch diff with Codex.
argument-hint: "[--uncommitted | --base <branch> | --commit <sha>]"
disable-model-invocation: true
allowed-tools: Bash(git diff *), Bash(git status *), Bash(git log *), Bash(codex review *)
---

Run `codex review` to perform code review and present the results to the user.

## Prerequisites

Requires `codex` CLI. If not installed, tell the user to run `npm i -g @openai/codex`.

## Determine review target

If arguments are provided, pass them through directly.

If no arguments, run this single pipeline:

1. `git diff HEAD --name-only` to get all uncommitted files (staged + unstaged)
2. Exclude: `*.txt`, `*.jsonl`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`
3. Single-quote paths with glob characters (`[`, `]`)
4. Pipe everything in one call: `git diff HEAD -- 'file1' 'file2' ... | codex review -`

Do not split into multiple codex review calls. One call with all files.

If no changed files remain after filtering, fall back to `codex review --uncommitted`.

## Other modes

Only when explicitly requested by the user:

- `codex review --uncommitted` — all uncommitted changes including untracked (slower)
- `codex review --base <branch>` — diff against a branch
- `codex review --commit <sha>` — review a specific commit

Note: `--uncommitted` and `[PROMPT]` cannot be combined.

## Handle results

Present the `codex review` output to the user as-is. If issues are found, ask whether the user wants to fix them.
