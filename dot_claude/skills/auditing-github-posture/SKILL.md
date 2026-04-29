---
name: auditing-github-posture
description: >
  "github posture" "github audit" "github settings check" "ベストプラクティス"
  "branch protection確認" "うちのrepo大丈夫？" "セキュリティ設定見て"
  "新しいrepo作ったから設定見て" "org全体scan" "ghqr" "ghqrみたいに" — Audit a
  GitHub repository or organization against ~57 best-practice rules. Reports
  findings grouped by severity. Use when the user wants to assess GitHub
  security posture, branch protection coverage, Dependabot/secret-scanning
  state, org-wide defaults, Actions permissions, Copilot policy, or whether a
  freshly-created repo is correctly configured — even when they don't mention
  "audit" or "posture" explicitly. Skip for applying settings (use a
  setting-up-repo style skill for that).
compatibility: Requires Node 18+ and the gh CLI authenticated with at least
  read:org and repo scopes (copilot scope optional for Copilot policy checks).
---

This skill runs `scripts/audit.mjs` to evaluate one repository or one
organization against ~57 best-practice rules and prints a markdown report to
stdout. The audit is **read-only** — it never mutates GitHub state.

Reference: rule list and severity mapping draw on
[microsoft/ghqr](https://github.com/microsoft/ghqr).

## Activation

Run the bundled script. Do not reimplement the checks inline.

```bash
# Single repository
node ~/.claude/skills/auditing-github-posture/scripts/audit.mjs --repo OWNER/REPO

# Whole organization (org settings + every non-archived repo)
node ~/.claude/skills/auditing-github-posture/scripts/audit.mjs --org NAME

# JSON instead of markdown
node ~/.claude/skills/auditing-github-posture/scripts/audit.mjs --org NAME --json

# Include archived repos in --org scan
node ~/.claude/skills/auditing-github-posture/scripts/audit.mjs --org NAME --include-archived
```

When the user provides only a slug like `acme` or `acme/widget`, infer the
mode from shape: `OWNER/REPO` → `--repo`, single token → `--org`.

## What gets checked

- **Repository (~31 rules)**: branch protection (legacy + rulesets), Dependabot
  alerts and config, CodeQL, SECURITY.md / CODEOWNERS / dependabot.yml file
  presence, deploy keys, collaborators, description / topics / dormancy,
  auto-delete-branch-on-merge, Discussions.
- **Organization (~22 rules)**: 2FA enforcement, web commit signoff, default
  repo permission, members creating public repos, security manager team,
  org-wide defaults applied to new repos (Dependabot, secret scanning, push
  protection, GHAS, dependency graph), Actions permissions (allowed actions,
  default workflow token write/read), Copilot policy (seat assignment, public
  code suggestions, inactive seats), org-aggregate Dependabot / code-scanning /
  secret-scanning open-alert counts, EMU detection.
- **Manual checks**: 15 items that the GitHub API cannot verify (audit log
  streaming to SIEM, secret-scanning custom patterns, IP allowlist, etc.) are
  appended as a checklist at the end of every report.

Enterprise scope is **out of scope** for this skill — it requires GHEC
enterprise admin tokens. If the user has one and needs enterprise-level audit
log / GHAS / aggregate alert checks, recommend running upstream
[microsoft/ghqr](https://github.com/microsoft/ghqr) directly.

## Token scopes

| Mode | Required | Optional |
|---|---|---|
| `--repo` | `repo` | — |
| `--org` | `read:org`, `repo` | `copilot` (for org-cop-* rules) |

The script calls `gh auth status`, parses scopes, and prints a warning to
stderr when scopes are missing. It does not abort — checks that need missing
scopes are silently skipped (the corresponding API call returns 403/404 and
the rule simply doesn't fire).

To add scopes interactively:

```bash
gh auth refresh -s read:org,copilot
```

Read `references/token-scopes.md` for a full mapping of which scope unlocks
which rule when the user asks.

## Gotchas

- **Single-repo `--repo` is the only path that uses the full GraphQL query**
  (collaborators, deploy keys, vulnerability alert severities). The org-wide
  `--org` mode reuses the same per-repo query so it gets full data per repo,
  unlike upstream ghqr which deliberately strips those fields in batch mode
  to stay under GraphQL complexity limits. On large orgs (>50 active repos),
  expect rate-limit warnings — gh will pause automatically.

- **This report shows more findings than ghqr's `.md` report.** Upstream
  ghqr's markdown renderer drops per-aspect evaluations
  (`evaluation:dependabot:`, `evaluation:code_scanning:`,
  `evaluation:discussions:`, `evaluation:collaborators:`,
  `evaluation:deploy_keys:`) — those only appear in its `.xlsx` output. This
  skill prints all of them. Findings like `repo-sec-007` (no
  `dependabot.yml`), `repo-sec-008` (no CodeQL), `repo-comm-001` (Discussions
  disabled), `repo-acc-002` (direct collaborators) will appear here even
  though they don't appear in a side-by-side ghqr md report. This is
  intentional.

- **Branch protection has two backends.** Legacy `branchProtectionRule` and
  modern repository `rulesets`. The script checks legacy first; if absent it
  falls back to rulesets. When a repo is protected only by rulesets, expect a
  `repo-bp-014` info finding to confirm — that's the modern path and not a
  problem.

- **Archived repos skip most checks.** Anything that requires a write to fix
  (branch protection, security policy, CODEOWNERS, dependabot config) is
  silently skipped for archived repos because the user can't fix them anyway.

- **EMU detection is heuristic.** The script probes `GET
  /orgs/{org}/external-groups`; if it returns 200, the org is treated as EMU
  and `org-sec-001` (no 2FA required) is replaced with `org-sec-006` (EMU info
  only). False negatives are possible with non-admin tokens.

- **Don't suggest `ghqr` install via the official `install.sh`.** It drops the
  binary into the current working directory rather than `$PATH`. This skill
  exists because that installer is sloppy and the underlying logic is just
  `gh api` + a YAML rule list.

- **Output format.** Markdown is the default and goes to stdout. Pipe to a
  file or `glow`/`mdcat` for nicer rendering. `--json` returns the raw
  evaluation tree, useful for piping into jq or for automation.

- **Skill files are intentionally generic.** Targets (org / repo names) are
  passed as runtime arguments. Never bake org names, repo names, or token
  values into the skill itself.

## Reporting

Default markdown layout:

1. Header (target / mode / timestamp)
2. For `--repo`: one repo block with severity-sorted finding table
3. For `--org`: org block + per-repo blocks + aggregate counts
4. Manual-checks checklist (the 15 items that can't be auto-verified)

Severity order: 🔴 critical → 🟠 high → 🟡 medium → 🟢 low → ℹ️ info.

When the user wants a remediation plan rather than a raw audit, follow the
audit with the `setting-up-repo` skill on the affected repos to apply
standard settings, instead of doing it inline.

## When to fall back to upstream ghqr

Recommend the user install and run `ghqr` directly when:

- They need enterprise-scope checks (audit log streaming, GHAS enterprise
  defaults, enterprise-wide aggregate alerts).
- They want the `.xlsx` workbook deliverable with formatting / charts for a
  non-engineering audience.
- They specifically want the upstream remediation-plan structure (30/60/90-
  day sprints with effort sizing).
