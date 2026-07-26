---
name: sync-upstream
description: >
  "新しいモデルが出た" "モデル更新された" "アップデートした" "新しいバージョン出た"
  "システムプロンプト変わった" "何が削れる" "設定が古い" "前提が古くない"
  "new model shipped" "sync upstream" — When a new model or a new version of the
  agent runtime ships, re-fit the local setup to it. Reads the runtime's built-in
  system prompt to find local guidance the runtime now covers on its own (delete),
  and the release notes, migration guide, and format specs to find capabilities and
  behavioural shifts worth taking up (adopt). Use when a release lands, when a
  rule's stated rationale no longer matches how the tool actually behaves, or when
  guidance is suspected stale — including indirect prompts like "この指示まだ要る？".
  Do NOT use for a general health check of the setup, for usage-log analysis, or
  for authoring configuration from scratch.
compatibility: >
  Requires a runtime whose own system prompt is visible in the session, and network
  access to the vendor's release and specification documentation.
---

Reconcile the local environment against what upstream now provides. Two source
classes pointing in two directions: the **built-in system prompt** says what to
delete; **release and specification documentation** says what to adopt. A run
that only prunes has done half the job.

## Scope

**The boundary is a question, not a file list.** In scope means a release changed
something that makes this wrong, or newly possible:

- A pinned model, effort level, or similar selection that a later release supersedes
- A permission or event-hook rule naming a capability that was added, renamed, or removed
- An external-tool decision whose cost basis moved when the runtime changed how tools load
- Guidance whose stated rationale describes behaviour the runtime no longer has

Configuration matters as much as prose here, and often more: the fix for guidance
that asks the model not to do something is frequently a rule that makes it
impossible, which means the destination is a config file. A pass that can read the
prose but not touch the mechanism can only ever half-finish.

Out of scope is anything you would change for reasons unrelated to a release —
the codebase itself, and the broad "is this setup any good" question. **If you
cannot name the upstream change that motivates an edit, it belongs in a different
pass.**

## 1. Enumerate what the runtime actually loads

Before diffing anything, list the artifacts this setup loads: always-loaded
guidance, path-scoped or conditionally-loaded rules, skills or commands, and
runtime configuration (model and effort selection, permission rules, event hooks,
external tool wiring).

They live in two places: the user-level configuration directory and the project
root. Read the runtime's own documentation for which files it loads and in what
order. An artifact you did not enumerate is one you cannot audit, and a file you
assume is loaded but is not will produce findings that change nothing.

## 2. Pin what you are diffing against

Fix both before reading anything else — every finding is scoped to them, and a
wrong baseline invalidates the run.

- **Model**: the exact identifier for the session you are in, including any
  variant suffix
- **Runtime**: its version string

Prefer what the session reports over what the configuration requests. When they
disagree, say so and audit against the one that is actually running.

## 3. Built-in system prompt — the delete side

**Your own context is the ground truth.** The runtime's system prompt for this
session is already loaded; read it there. Fetched or mirrored copies describe
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

Source classes, in descending value:

| Source | Yields |
|---|---|
| Model migration guide | Behavioural shifts to re-tune for — verbosity, delegation, verification, scope discipline |
| Runtime release notes and feature docs | New fields, settings, and mechanisms the setup should start using |
| Format and specification docs | Constraints that changed under the artifacts being maintained |
| Published system prompts | How the vendor phrases things now. A style reference, not a mandate |

Beyond "what is new", two failure modes are worth hunting specifically:

- **Stale rationale.** A rule whose *conclusion* still holds but whose stated
  *reason* has become false. These survive audits that only check conclusions, and
  they teach the next reader something untrue
- **Prose where a mechanism now exists.** Guidance asking the model not to do
  something, when the runtime has since gained a way to make it impossible.
  A new mechanism turns an old instruction into debt

## 5. Report, then apply

Report before editing. One table per direction:

**Delete** — the artifact, the quoted local line, and the quoted built-in line
that covers it.
**Adopt** — what changed upstream, which artifact should absorb it, and the
concrete edit.

Then apply only what is approved, one artifact at a time.

Close by recording the baseline somewhere durable — the runtime's persistent data
location for the skill if it has one, otherwise a file alongside the configuration:
the two versions from step 2, the date, and one line per accepted change. The next
run reads it first and diffs forward instead of starting cold. Record the baseline
only; do not keep per-model guidance files (see Gotchas).

## Stop and ask

- Local guidance **conflicts** with the built-in rather than duplicating it
- A deletion would remove a safety-critical prohibition, even one the built-in
  appears to cover. The built-in can change without warning; an explicit
  prohibition is cheap insurance
- The proposed edit falls outside the scope question above
- More than half of one artifact is proposed for deletion. That is a rewrite, and
  it should be chosen deliberately rather than arrived at

## Never

- Edit before the report is shown and approved
- Read a configuration or credential-bearing file whole. Settings and tool wiring
  carry secrets in environment blocks, request headers, and command strings. Read
  only the keys the check needs, and never quote a value you did not need to read
- Delete guidance because it looks generic. Only because the built-in demonstrably
  covers it
- Trust a mirrored system prompt over the one loaded in your own context
- Claim a concept is missing from an artifact because a keyword search came back empty

## Gotchas

- **String absence is not concept absence.** Searching for a term and finding
  nothing proves the term is absent, and nothing more. The concept is routinely
  present under different words, in a section titled something else. Read the
  artifact's structure before concluding anything is missing — this is the single
  most common way a run produces confident, wrong findings.
- **Two layers get conflated.** A portable format specification and the runtime
  implementing it will both define limits, and those limits will differ without
  either being wrong. When two numbers disagree, establish that they describe the
  same thing before calling it a contradiction.
- **Per-model files rot.** Checked-in per-model overlays look tidy and fall behind
  within one or two releases; large, actively maintained public setups carry
  overlays for models nobody runs anymore. Keep the baseline record and re-derive
  judgements each run instead.
- **The local health check is a different job.** Tooling that audits usage counts,
  unused extensions, and context cost works from local data and never fetches
  upstream, so it cannot see redundancy against a system prompt. Run both; they do
  not overlap, and neither should re-implement the other.
- **Guidance written for a prior model can invert.** A practice the vendor once
  recommended can become an anti-pattern a generation later. "It was correct when
  written" is not evidence that it is correct now.
