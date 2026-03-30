---
name: brew
description: Periodic Homebrew maintenance — upgrade packages, remove orphaned dependencies, and review installed packages. Use when the user says "brew", "brew upgrade", "brew cleanup", "update packages", "brew outdated", or wants to do periodic Homebrew housekeeping.
---

# Brew Maintenance

Periodic Homebrew maintenance: upgrade all packages, clean up orphans, and review what's installed.

## Context

- Tools that should always be latest go in Brew
- Tools requiring version pinning (Node.js, etc.) are managed by Mise, not Brew
- `brew upgrade` (no arguments) is the safest approach — it keeps the entire dependency tree consistent
- Upgrading a dependency automatically checks and rebuilds its dependents if linkage breaks

## Steps

### 1. Check current state

Run these in parallel and present results as a single summary:

- `brew update` — refresh formulae
- `brew outdated` — list upgradable packages
- `brew leaves` — list explicitly installed packages (not pulled in as dependencies)

### 2. Classify outdated packages

Present a table classifying each outdated package:

| Category | How to identify | Action |
|---|---|---|
| Direct install | appears in `brew leaves` | upgrade |
| Dependency only | not in `brew leaves` | upgraded automatically with parent |
| Cask | appears in `brew outdated --cask` | upgrade |

For dependency-only packages, run `brew uses --installed <pkg>` and show what depends on them so the user understands why they exist.

### 3. Upgrade

After showing the summary, ask the user for confirmation, then run:

```
brew upgrade
```

If the user wants to skip specific packages, use `brew pin <pkg>` before upgrading and `brew unpin <pkg>` after.

Report any errors. For broken linkage, check with `brew linkage <formula>` and fix with `brew reinstall <formula>`.

### 4. Clean up

```
brew autoremove   # remove orphaned dependencies
brew cleanup      # remove old versions and cache
```

Report what was removed.

### 5. Review installed packages (optional)

Show the `brew leaves` list and ask "Anything here you no longer use?"

For any package the user flags as unused:
1. `brew uninstall <pkg>`
2. `brew autoremove` to cascade-remove orphaned dependencies

## Notes

- Always confirm before destructive operations (uninstall, autoremove)
- Always show the outdated list before upgrading — never upgrade silently
- Mention if a Cask upgrade requires an app restart
