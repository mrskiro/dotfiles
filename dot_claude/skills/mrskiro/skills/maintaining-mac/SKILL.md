---
name: maintaining-mac
description: >
  "月一メンテナンス" "PC掃除" "棚卸し" "容量が足りない" "アプリ整理"
  "brew" "brew upgrade" "brew cleanup" "brew outdated" —
  Periodic macOS housekeeping: upgrade Homebrew packages, take stock of what is
  actually installed, and reclaim disk. Use when the user wants periodic
  maintenance, mentions outdated/upgrade in a Homebrew context, wants to review
  installed apps, or is short on disk space.
---

# Mac Maintenance

Three parts: Homebrew, the applications actually installed, and disk. Run only what was
asked — but they lead into each other (a brew review surfaces unused casks; removing
those surfaces leftover data; that leads to the disk), so follow the thread when it
appears instead of stopping at the original boundary.

## Homebrew

### Brew or mise?

The question is **not** "does it need to be latest" but **"can a project pin it"**.

| Goes in | Because |
|---|---|
| **mise** | Language runtimes (`node`, `python`, `go`, `rust`, `bun`) and infra CLIs (`terraform`, `aws-cli`, `gcloud`) — a project's `.tool-versions` may need a specific version, even if the global setting is `latest` |
| **brew** | Single-version personal tools (`rg`, `fd`, `bw`, `gh`) — no project will ever pin them |

Most mise entries being `"latest"` is **not** a reason to move them to brew.

Never let the same tool live in both: PATH order decides the winner silently, and the
loser's version is invisible. Check with `which -a <tool>`.

### Casks self-update — don't fight it

`brew outdated --cask` reads the **actual installed app version**, not brew's Caskroom
record. A stale record is harmless and needs no action.

```
claude   record 0.7.1  actual 1.46388.3  ->  not listed (app is current)
arc      record 1.70.0 actual 1.157.0    ->  listed (app is genuinely behind)
```

- **Never run `brew upgrade --cask --greedy` routinely.** It re-downloads apps that
  already updated themselves, and disrupts running ones.
- Auto-update only runs when the app is launched, so rarely-used apps fall far behind.
  That is exactly what the plain check catches.

A Brewfile records **no versions**. A new machine gets the current version — stale local
records never transfer.

### Steps

1. `brew update`, then `brew outdated` / `brew outdated --cask` / `brew leaves`.
2. Classify: in `brew leaves` = direct install; not in it = dependency, upgraded with its
   parent. `brew leaves` also lists **orphaned dependencies** whose parent is gone —
   cross-check against `brew bundle dump`, which lists only explicitly-requested packages.
   For dependency-only packages, `brew uses --installed <pkg>` shows why they exist.
3. Show the list, get confirmation, then `brew upgrade`. `brew pin` / `unpin` to skip one.
   For broken linkage: `brew linkage <formula>` then `brew reinstall <formula>`.
4. `brew autoremove` and `brew cleanup`. `autoremove` skips anything with
   `installed_on_request: true` in its `INSTALL_RECEIPT.json` even with no dependents —
   build-time leftovers land this way; remove them with `brew uninstall` after confirming
   `brew uses --installed` is empty.

## Application inventory

Find what brew does **not** manage — that is where the stale, oversized apps hide.

```bash
# .app bundles brew placed
brew list --cask | while read -r c; do
  brew list --cask "$c" 2>/dev/null | grep -oE '/[^/]+\.app$' | sed 's|^/||'
done | sort -u > "$TMPDIR/brew-apps.txt"

# survey everything in /Applications against it
for p in /Applications/*.app; do
  mdls -raw -name kMDItemLastUsedDate "$p"        # last launched — the deciding signal
  du -sh "$p"                                     # size
  [ -e "$p/Contents/_MASReceipt" ] && echo "App Store"   # => root-owned, needs sudo
done
```

`mo uninstall --list` (from the `mole` formula) returns the same inventory as JSON,
including `source` (Homebrew / App Store / manual) — more reliable than hand-rolling this,
if it happens to be installed.

### Removing an app

The app bundle is usually the *smaller* half. Sweep all of these:

```
/Applications/<App>.app
~/Library/Application Support/<Name>
~/Library/Caches/<bundle-id>          and  ~/Library/Caches/<Name>
~/Library/Preferences/<bundle-id>.plist
~/Library/HTTPStorages/<bundle-id>    (+ .binarycookies)
~/Library/Saved Application State/<bundle-id>.savedState
~/Library/WebKit/<bundle-id>
```

Then confirm with `find ~/Library /Applications -maxdepth 2 -iname '*<bundle-id>*'`.

Two rules before deleting:

- **Name the user's data explicitly and confirm it survives.** A note vault, a photo
  library, a project directory often lives outside the app (`~/mrskiro/docs`,
  `~/Movies/*.imovielibrary`). State where it is and that it is untouched — or, if it will
  be deleted, say so before doing it.
- **Never replace or delete a running app.** `pgrep -f "/Applications/<App>.app"` first.
  This matters most for the terminal or IDE hosting the session.

Prefer `brew uninstall --cask <name>` when brew owns it; it purges the Caskroom entry too.

## Disk

Check these in order — the biggest wins are usually not in `/Applications`:

```
du -sh ~/.Trash              # can hold more than everything else combined
du -sh ~/Library/Caches      # per-app caches; brew's own is usually a rounding error
diskutil info / | grep 'Container Free Space'
```

`df` under-reports freed space because **APFS local snapshots hold deleted data**. Compare
against `diskutil info /` before concluding a deletion did nothing. `tmutil
listlocalsnapshots /` shows what is holding it.

Common large-but-regenerable items: Rust `target/`, `node_modules/`, VM images, Xcode
`DerivedData`, downloaded installers and ISOs.

## Gotchas

- **sudo does not work through Claude Code.** pkg-based casks (`zulu@17`,
  `google-japanese-ime`, `insta360-link-controller`) and App Store apps need `sudo`, which
  fails with "a terminal is required to read the password". Hand the user the command to
  run in their own terminal instead of retrying.
- **Untrusted taps silently skip update checks.** Homebrew 6.x requires `brew trust <tap>`;
  until then `brew bundle` fails and outdated checks are skipped, so tap packages freeze
  without warning. Record taps as `tap "owner/name", trusted: true`.
- **A CLI shipping as a cask is normal.** GoReleaser deprecated formula generation in
  favour of `homebrew_casks`, since Homebrew wants pre-built binaries in casks.
  "cask = .app" is outdated.
- **`mdls` needs Spotlight.** When it cannot reach the service it echoes the file path
  instead of the value, which silently corrupts a survey table. Verify with `mdutil -s /`.
- **PATH is lost in `$(...)` inside loops** when the script narrowed `PATH` at the top —
  `sed`/`head` suddenly "command not found". Set an explicit PATH or use absolute paths.
- **`find` may be shadowed by an alias.** This machine aliases it to `rtk find`, which
  rejects `-exec` and compound predicates. Use `/usr/bin/find` in scripts.

## Notes

- Always confirm before destructive operations (uninstall, autoremove, deleting data)
- Never upgrade silently — show the outdated list first
- Mention when a cask upgrade needs an app restart
