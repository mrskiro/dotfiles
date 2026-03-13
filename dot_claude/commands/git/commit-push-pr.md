---
allowed-tools: Bash(git checkout:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*), Bash(gh pr create:*), Bash(gh pr edit:*)
description: Commit, push, and open a PR
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`

## PR Title Convention

Determine the PR title prefix based on the branch name:

| Branch Pattern                               | PR Title Prefix |
| -------------------------------------------- | --------------- |
| `feat/*`, `feat-*`, `feature/*`, `feature-*` | `feat:`         |
| `fix/*`, `fix-*`, `bugfix/*`, `bugfix-*`     | `fix:`          |
| `chore/*`, `chore-*`, `ci/*`, `ci-*`         | `chore:`        |
| `refactor/*`, `refactor-*`                   | `refactor:`     |

Example: Branch `feat/add-login` → PR title `feat: add login`

## Your task

Based on the above changes:

1. Create a new branch if on main (use appropriate prefix: `feat/`, `fix/`, `chore/`, `refactor/`)
2. **Filter changes**: Only include files that were changed in this session. If git diff shows changes to files that are clearly unrelated to the current task (e.g., changes from a different branch or previous session), exclude them by staging only the relevant files. NEVER use `git add -A` or `git add .`. Always add specific files by name.
3. Create a single commit with an appropriate message
4. Push the branch to origin
5. Create a pull request using `gh pr create --assignee @me`
   - PR title MUST follow the convention above based on branch name
   - Assignee MUST be set to `@me` (the current user)
   - If a PR already exists for this branch, update its title and body using `gh pr edit` instead
6. You have the capability to call multiple tools in a single response. You MUST do all of the above in a single message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
