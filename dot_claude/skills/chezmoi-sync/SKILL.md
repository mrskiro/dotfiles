---
name: chezmoi-sync
description: >
  "chezmoi update" "chezmoi pull" "chezmoi upgrade" "dotfiles sync" "chezmoi同期"
  "dotfiles更新" — Sync and upgrade chezmoi: pull dotfiles, resolve conflicts with
  user confirmation, and optionally upgrade chezmoi itself via Homebrew.
---

# Chezmoi Sync

Sync dotfiles from the remote repository and apply them. Optionally upgrade chezmoi itself.

## Steps

### 1. Upgrade chezmoi (if requested or outdated)

```
brew outdated chezmoi
```

If outdated, show the version diff and ask whether to upgrade. If yes:

```
brew upgrade chezmoi
```

### 2. Pull and apply dotfiles

```
chezmoi update
```

### 3. Check for conflicts

```
cd $(chezmoi source-path) && git status
```

If no unmerged paths, report updated files and stop.

### 4. Resolve conflicts

For each conflicting file:

1. Show the diff: `git diff <file>` — present both sides clearly (local = this PC, remote = upstream)
2. Ask the user: **local** or **remote**?
3. Edit the file to keep the chosen side, removing conflict markers
4. `git add <file>`

After all files are resolved:

```
git stash drop   # only if a stash exists
```

### 5. Apply

```
chezmoi apply
```

Report what changed.

## Notes

- Never auto-resolve conflicts — always show the diff and ask
- Never drop the stash before all conflicts are resolved
- The chezmoi source directory (`chezmoi source-path`) is where conflicts live, not the target files
- chezmoi-managed files are protected by a PreToolUse hook — edit the source path, not the target
