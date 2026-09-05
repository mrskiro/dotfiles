---
name: gh-dependabot-review
description: >
  "dependabot" "Dependabot PR" "依存関係更新" "review dependabot" — Review and
  merge open Dependabot PRs in the current repository, one at a time. Use when
  the user wants to triage automated dependency update PRs, or after Dependabot
  has opened multiple PRs that need attention.
allowed-tools: Bash(gh:*) Bash(git:*)
---

# Dependabot PR Review

Review all open Dependabot PRs in the current repository, one at a time.

## Context

- Open Dependabot PRs: !`gh pr list --author "app/dependabot" --json number,title,url --jq '.[] | "#\(.number) \(.title)"'`

## Workflow

If no Dependabot PRs are found, inform the user and stop.

Tell the user how many PRs are open, then process them **one at a time** — complete the full cycle for one PR before moving to the next.

### For each PR

#### 1. Gather information

Run these in parallel:
- `gh pr view <number> --json title,body,additions,deletions`
- `gh pr checks <number>`

#### 2. Summarize and recommend

Present a concise summary:
- **Dependency name** and version change (e.g., `react 19.2.3 → 19.2.4`)
- **Update type**: major / minor / patch
- **Key changes** from the changelog in the PR body (2-3 bullet points max)
- **CI status**: pass / fail / pending
- **Concerns**: Flag anything that warrants attention

For routine patch/minor updates with passing CI, recommend **merge**.

Dig deeper when:
- **Major version bumps** — Check for breaking changes mentioned in the changelog, search the codebase for deprecated APIs or patterns that may be affected
- **Version mismatches** — Compare against `engines` field, `catalog:` in pnpm-workspace.yaml, or other version constraints in the project
- **Security fixes** — Note the severity and what was fixed
- **Framework/tooling updates** (e.g., Next.js, TypeScript, Tailwind) — Check if config files or build setup need adjustments

Use Grep and Read to explore the codebase when needed. Think like a developer reviewing a dependency bump — what could break?

Give a clear recommendation:
- **Merge recommended** — No concerns, CI passes, safe update
- **Merge recommended + follow-up needed** — Safe to merge, but additional work is required afterward (e.g., update related config, align version constraints). Describe what needs to be done
- **Skip recommended** — The update is problematic (e.g., wrong major version for the project, CI failing, conflict pending rebase). Explain why and suggest an alternative if applicable

#### 3. Ask user

Use AskUserQuestion to ask the user what to do. Append "(Recommended)" to the recommended option label.

- **Merge**: `gh pr merge <number> --squash` (use squash merge; if it fails with merge commit error, try squash)
- **Skip**: Move to the next PR without action
- **Close**: `gh pr close <number>`

If follow-up work was identified, ask the user if they want to handle it now or later.

#### 4. Next PR

After the action is complete, move to the next PR. Gather fresh CI status — a previous merge may have caused conflicts that Dependabot is rebasing.

If CI is pending or the PR has conflicts, tell the user and recommend **skip** (they can re-run this command later when the rebase is done).

### After all PRs

Summarize what was done:
- PRs merged
- PRs skipped
- PRs closed
- Any items flagged for follow-up
