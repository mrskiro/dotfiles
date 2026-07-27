---
name: sync-upstream
description: >
  "新しいモデルが出た" "モデル更新された" "CCアップデートした" "新しいバージョン出た"
  "システムプロンプト変わった" "何が削れる" "CLAUDE.mdが古い" "前提が古くない"
  "new model shipped" "sync upstream" — When a new Claude model or Claude Code
  version ships, re-fit the local environment to it. Reads the built-in system
  prompt to find guidance Claude Code now covers on its own (delete), and the
  release notes, migration guide, and specs to find capabilities and behavioural
  shifts worth taking up (adopt). Covers `~/.claude/` and the project's loaded
  configuration — guidance, skills, and settings alike. Use when a release lands,
  when a rule's stated rationale no longer matches how the tool actually behaves,
  or when guidance is suspected stale — including indirect prompts like
  "この指示まだ要る？". Do NOT use for a general health check of the setup, for
  usage-log analysis, or for authoring configuration from scratch.
---

Reconcile the local environment against what upstream now provides. Two source
classes pointing in two directions: the **built-in system prompt** says what to
delete; **release and specification documentation** says what to adopt. A run
that only prunes has done half the job.

## Scope

`~/.claude/` and whatever the current project loads: guidance (`CLAUDE.md`,
`rules/`, `docs/`), skills, and configuration (`settings.json` — model and effort
selection, hooks, permissions — plus `.mcp.json`).

**The boundary is a question, not a file list.** In scope means a release changed
something that makes this wrong, or newly possible:

- A pinned model or effort level that a later release supersedes
- A permission or hook rule naming a tool that was added, renamed, or removed
- An MCP decision whose cost basis moved when the runtime changed how tools load
- Guidance whose stated rationale describes behaviour Claude Code no longer has

Configuration matters as much as prose here, and often more: the fix for guidance
that asks the model not to do something is frequently a rule that makes it
impossible, which means the destination is a settings file. A pass that can read
the prose but not touch the mechanism can only ever half-finish.

Out of scope is anything you would change for reasons unrelated to a release —
the codebase itself, and the broad "is this setup any good" question. **If you
cannot name the upstream change that motivates an edit, it belongs in a different
pass.**

## 1. List what is loaded, and where it is really written

Enumerate before diffing. Past the obvious `~/.claude/CLAUDE.md`, look for
the project `CLAUDE.md` and any nested ones, `rules/` entries whose `paths:`
frontmatter means they load only for matching files, and skills whose bodies load
only on invocation. Something you did not enumerate is something you cannot audit;
something you assume is loaded but is not produces findings that change nothing.

**Resolve the write target before you plan any edit.** Dotfiles are often
generated from a source tree by a manager such as chezmoi, stow, yadm, or Nix, and
editing the deployed copy means the next apply silently reverts your work. Check
whether each file is managed, and record the source path you will actually edit
alongside it. A run whose edits get reverted reports success and changes nothing.

Check which side is ahead, not just which side is canonical. Expect the deployed
copy to be ahead: the runtime writes settings there itself when a dialog is
accepted or a mode is switched, and it has no idea a source tree exists. So a
managed setup drifts on its own, without anyone editing the wrong file, and
writing to the source and applying destroys whatever the runtime recorded. When
the two diverge, say so and stop — reconciling them is the owner's call, and not
what this run was asked to do.

## 2. Pin what you are diffing against

Fix both before reading anything else — every finding is scoped to them, and
pinning the wrong pair invalidates the run.

- **Model**: the exact ID from the environment block of your system prompt,
  including any context-window suffix
- **Claude Code**: `claude --version`

Prefer what the session reports over what `settings.json` requests. When they
disagree, say so and audit against the one that is actually running — that
disagreement is itself a finding.

## 3. Built-in system prompt — the delete side

**Your own context is the ground truth.** Claude Code's system prompt for this
session is already loaded; read it there. Mirrored copies on the web describe
versions you are not running — reach for them only to diff *across* versions, and
say so when you do.

For each piece of local guidance, ask what the built-in already covers:

- **Redundant** — the built-in says this. Propose deletion, quoting both sides
- **Conflicting** — the built-in says the opposite. Stop and ask; do not resolve it yourself
- **Additive** — keep, silently

Quote both sides on every deletion. A deletion the reader cannot check is a
deletion they cannot approve.

Judgement lives here, so resist mechanical matching. Guidance can be redundant in
substance while sharing no vocabulary with the built-in, and two lines can share
vocabulary while meaning different things. Read for what each one *causes*.

## 4. Release documentation — the adopt side

**None of this is in your context; go and fetch it.** Search the vendor's
documentation and engineering blog for the two versions pinned in step 2. Do not
answer from training knowledge about anything released after your cutoff, and do
not assume a document still sits at the address it used to — find it by searching
for the release, not by recalling a URL.

Source classes, in descending value:

| Source | Yields |
|---|---|
| Model migration guide | Behavioural shifts to re-tune for — verbosity, delegation, verification, scope discipline |
| Claude Code release notes and docs | New settings, frontmatter fields, tools, and hook events the setup should start using |
| Format and spec docs | Constraints that changed under the artifacts being maintained |
| Published system prompts | How the vendor phrases things now. A style reference, not a mandate |

**Configuration needs enumerating, not skimming.** Prose you can read for what
changed; a settings file you cannot, because what is missing from it leaves no
trace. List the keys the runtime accepts, subtract the ones in use, and read what
is left — its own JSON Schema, if it declares one, is the cheapest complete list.
Most of the remainder will be irrelevant and that is fine; the point is that a
setting worth adopting is invisible until something enumerates it. Reading a
config file only for what it contains finds stale values and never finds absent
ones.

Beyond "what is new", two failure modes are worth hunting specifically:

- **Stale rationale.** A rule whose *conclusion* still holds but whose stated
  *reason* has become false. These survive audits that only check conclusions, and
  they teach the next reader something untrue
- **Prose where a mechanism now exists.** Guidance asking the model not to do
  something, when the runtime has since gained a way to make it impossible.
  A new mechanism turns an old instruction into debt

## 5. Report, then apply

Report before editing. One table per direction:

**Delete** — the file, the quoted local line, and the quoted built-in line that
covers it.
**Adopt** — what changed upstream, which file should absorb it, and the concrete
edit.

**Account for every artifact step 1 enumerated**, in a third table: audited with
findings, audited with none, or skipped and why. An artifact you looked at and
found clean is a result and belongs in the report; silence about it is
indistinguishable from never having opened it, and the reader cannot tell which
they are getting. Skipping is allowed — running out of room, or a surface the
request excluded — but only when named.

Then apply only what is approved, one file at a time — to the write target
resolved in step 1, not to the deployed copy.

## Stop and ask

- Local guidance **conflicts** with the built-in rather than duplicating it
- A deletion would remove a safety-critical prohibition, even one the built-in
  appears to cover. The built-in can change without warning; an explicit
  prohibition is cheap insurance
- The proposed edit falls outside the scope question above
- More than half of one file is proposed for deletion. That is a rewrite, and it
  should be chosen deliberately rather than arrived at

## Never

- Edit before the report is shown and approved
- Read `settings.json` or `.mcp.json` whole. They carry secrets in `env` blocks,
  request headers, and hook command strings. Read only the keys the check needs,
  and never quote a value you did not need to read
- Delete guidance because it looks generic. Only because the built-in demonstrably
  covers it
- Trust a mirrored system prompt over the one loaded in your own context
- Claim a concept is missing from a file because a keyword search came back empty
- Call a setting, field, or flag removed because it is absent from a schema, a
  reference table, or any other list you did not have to be the vendor to publish.
  Absence there is equally consistent with never having been documented. Removal
  needs positive evidence — a changelog entry, a migration note, or the product's
  own source — and without it the entry stays

## Gotchas

- **String absence is not concept absence.** Searching for a term and finding
  nothing proves the term is absent, and nothing more. The concept is routinely
  present under different words, in a section titled something else. Read the
  file's structure before concluding anything is missing — this is the single
  most common way a run produces confident, wrong findings.
- **Two layers get conflated.** A portable format spec and the Claude Code
  implementation of it will both define limits, and those limits will differ
  without either being wrong. When two numbers disagree, establish that they
  describe the same thing before calling it a contradiction.
- **A file updated once is rarely updated everywhere.** The most common shape of
  stale guidance is not a wholly outdated file but a current claim and an obsolete
  one sitting in the same document, because a past pass fixed the prose and missed
  the table, the example, or the summary line. Grep every file you touch for its
  own key terms and read all the hits, not the first.
- **Per-model files rot.** Checked-in per-model overlays look tidy and fall behind
  within one or two releases; large, actively maintained public setups carry
  overlays for models nobody runs anymore. Re-derive every judgement from what is
  in front of you.
- **The local health check is a different job.** Tooling that audits usage counts,
  unused extensions, and context cost works from local data and never fetches
  upstream, so it cannot see redundancy against a system prompt. Run both; they do
  not overlap, and neither should re-implement the other.
- **Guidance written for a prior model can invert.** A practice the vendor once
  recommended can become an anti-pattern a generation later. "It was correct when
  written" is not evidence that it is correct now.
