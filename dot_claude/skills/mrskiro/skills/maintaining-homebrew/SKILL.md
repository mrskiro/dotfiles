---
name: maintaining-homebrew
description: >
  "brew" "brew upgrade" "brew cleanup" "update packages" "brew outdated" —
  Periodic Homebrew maintenance: upgrade packages, clean up orphans, and review
  installed packages. Use when the user wants periodic Homebrew housekeeping or
  mentions outdated/upgrade in a Homebrew context.
---

# Brew Maintenance

Periodic Homebrew maintenance: upgrade packages, clean up orphans, and review what's installed.

## Brew or mise?

The question is **not** "does it need to be latest" but **"can a project pin it"**.

| Goes in | Because |
|---|---|
| **mise** | Language runtimes (`node`, `python`, `go`, `rust`, `bun`) and infra CLIs (`terraform`, `aws-cli`, `gcloud`) — a project's `.tool-versions` may need a specific version, even if the global setting is `latest` |
| **brew** | Single-version personal tools (`rg`, `fd`, `bw`, `gh`) — no project will ever pin them |

Most mise entries being `"latest"` is **not** a reason to move them to brew. The option to pin per project is the point.

Never let the same tool live in both: PATH order decides the winner silently, and the loser's version is invisible. Check with `which -a <tool>`.

## Casks self-update — don't fight it

`brew outdated --cask` reads the **actual installed app version**, not brew's Caskroom record. A stale record is harmless and needs no action.

```
claude   record 0.7.1  actual 1.46388.3  ->  not listed (app is current)
arc      record 1.70.0 actual 1.157.0    ->  listed (app is genuinely behind)
```

So:
- **Never run `brew upgrade --cask --greedy` routinely.** It re-downloads apps that already updated themselves, and disrupts running ones.
- Only what appears in plain `brew outdated --cask` is genuinely behind.
- Auto-update only runs when the app is launched, so rarely-used apps fall far behind. That is exactly what this check catches.

A Brewfile records **no versions** (`cask "notion"`, not a version). A new machine therefore gets the current version — stale local records never transfer.

## Steps

### 1. Check current state

- `brew update`
- `brew outdated` / `brew outdated --cask`
- `brew leaves`

### 2. Classify

| Category | How to identify | Action |
|---|---|---|
| Direct install | in `brew leaves` | upgrade |
| Dependency only | not in `brew leaves` | upgraded with its parent |
| Cask | in `brew outdated --cask` | upgrade |

`brew leaves` also lists **orphaned dependencies** whose parent is gone. Cross-check with `brew bundle dump`, which lists only explicitly-requested packages — anything in `leaves` but not in the dump is an orphan.

For dependency-only packages, run `brew uses --installed <pkg>` to show why they exist.

### 3. Upgrade

Show the list, get confirmation, then `brew upgrade`. To skip a package, `brew pin` before and `brew unpin` after.

For broken linkage: `brew linkage <formula>` then `brew reinstall <formula>`.

### 4. Clean up

```
brew autoremove
brew cleanup
```

`autoremove` skips anything with `installed_on_request: true` in its `INSTALL_RECEIPT.json`, even with no dependents. Build-time leftovers often land this way — remove them with `brew uninstall` after confirming `brew uses --installed` is empty.

### 5. Review installed packages (optional)

Show `brew leaves` and the cask list, and ask what is no longer used. Useful decision data:

```
mdls -name kMDItemLastUsedDate /Applications/<App>.app   # last launched
du -sh /Applications/<App>.app                            # size
```

For anything flagged: `brew uninstall` then `brew autoremove`.

## Gotchas

- **sudo does not work through Claude Code.** pkg-based casks (`zulu@17`, `google-japanese-ime`, `insta360-link-controller`) and MAS-installed apps need `sudo`, which fails with "a terminal is required to read the password". Hand the user the command to run in their own terminal instead of retrying.
- **Untrusted taps silently skip update checks.** Homebrew 6.x requires `brew trust <tap>`; until then `brew bundle` fails and outdated checks are skipped, so tap packages freeze without warning. Record taps in the Brewfile as `tap "owner/name", trusted: true`.
- **A CLI shipping as a cask is normal.** GoReleaser deprecated formula generation in favour of `homebrew_casks`, since Homebrew wants pre-built binaries in casks. "cask = .app" is outdated.
- **Never replace a running app.** Check with `pgrep -f "/Applications/<App>.app"` first. This matters most for the terminal or IDE hosting the session.
- **Disk space may not appear to drop.** APFS local snapshots hold deleted data; compare `df` with `diskutil info /` (Container Free Space).

## Notes

- Always confirm before destructive operations (uninstall, autoremove)
- Never upgrade silently — show the outdated list first
- Mention when a cask upgrade needs an app restart
