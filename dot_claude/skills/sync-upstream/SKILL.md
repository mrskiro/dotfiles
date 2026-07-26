---
name: sync-upstream
description: >
  "Opus 5出た" "新しいモデルが出た" "モデル更新された" "CCアップデートした"
  "システムプロンプト変わった" "何が削れる" "CLAUDE.mdが古い" "前提が古くない"
  "new model shipped" "sync upstream" — Re-fit the local context engineering
  (`~/.claude/CLAUDE.md`, `rules/`, `skills/`, `docs/`) to a newly shipped Claude
  model or Claude Code version. Reads the built-in system prompt to find guidance
  the runtime now covers on its own (delete), and the migration guide, spec, and
  feature docs to find capabilities and behavioral shifts worth taking up (adopt).
  Use when a release lands, when a rule's stated rationale no longer matches how
  the tool behaves, or when guidance is suspected stale — including indirect
  prompts like "この指示まだ要る？". Do NOT use for a broad repository health
  audit, for usage-log analysis, or for authoring a skill.
---

Reconcile the local context engineering against what upstream now provides.
Two source classes pointing in two directions: the **built-in system prompt**
says what to delete; **release and spec documentation** says what to adopt.
A run that only prunes has done half the job.

## Scope

In scope: `~/.claude/CLAUDE.md`, `~/.claude/rules/`, `~/.claude/skills/`,
`~/.claude/docs/`, and the project `CLAUDE.md` when one is loaded.

Out of scope: hooks, sandbox, MCP server config, permissions. Those are harness,
not context engineering. A release rarely invalidates them, and pulling them in
makes this skill too broad to activate precisely.

## 1. Pin what you are diffing against

Establish both versions before reading anything — every finding downstream is
scoped to them, and a wrong baseline invalidates the whole run.

- **Model**: the exact ID from your own environment block, e.g. `claude-opus-5[1m]`
- **Claude Code**: `claude --version`

Put both at the top of the report. If the model actually running differs from the
one pinned in settings, say so and audit against what runs.

## 2. Built-in system prompt — the delete side

**Your own context is the ground truth.** The built-in system prompt for this
session is already loaded; read it there. Fetched or mirrored copies describe
versions you are not running — reach for them only to diff *across* versions,
and say so when you do.

For each line of local guidance, ask what the built-in already covers, and mark it:

- **Redundant** — the built-in says this. Propose deletion, quoting both sides
- **Conflicting** — the built-in says the opposite. Stop and ask; do not resolve it yourself
- **Additive** — keep, silently

Quote both sides on every deletion. A deletion the reader cannot check is a
deletion they cannot approve.

Judgement lives here, so resist mechanical matching. Guidance can be redundant in
substance while sharing no vocabulary with the built-in, and two lines can share
vocabulary while meaning different things. Read for what each one *causes*.

## 3. Release documentation — the adopt side

Source classes, in descending value:

| Source | Yields |
|---|---|
| Model migration guide | Behavioral shifts to re-tune for (verbosity, delegation, verification, scope) |
| Runtime feature docs | New fields, settings, and tools the guidance should start using |
| Format/spec docs | Constraints that changed under the artifacts you maintain |
| Published system prompts | How the vendor phrases things now — a style reference, not a mandate |

Two failure modes to look for beyond "what's new":

- **Stale rationale.** A rule whose *conclusion* still holds but whose stated
  *reason* is now false. These survive audits that only check conclusions, and
  they teach the next reader something untrue
- **Prose where a mechanism now exists.** Guidance that asks the model not to do
  something, when the runtime has since gained a way to make it impossible.
  Constraints beat instructions; a new mechanism turns an old instruction into debt

## 4. Report, then apply

Report before editing. One table per direction:

**Delete** — file, quoted local line, quoted built-in line that covers it.
**Adopt** — what changed upstream, which file should absorb it, and the concrete edit.

Then apply only what the user approves, one file at a time.

Close by writing the baseline to `${CLAUDE_PLUGIN_DATA}/last-sync.md`: the two
versions from step 1, the date, and one line per accepted change. The next run
reads it first and diffs forward from there instead of starting cold. Do not
keep per-model guidance files — see gotchas.

## Stop and ask

- Local guidance **conflicts** with the built-in rather than duplicating it
- A deletion would remove a safety-critical prohibition, even one the built-in
  appears to cover — the built-in can change under you; an explicit prohibition is cheap
- The proposed edit touches a file outside the scope above
- More than half of a file is proposed for deletion — that is a rewrite, and
  the user should choose it deliberately

## Never

- Edit before the report is shown and approved
- Delete guidance because it looks generic. Only because the built-in demonstrably covers it
- Trust a mirrored system prompt over your own loaded context
- Claim a concept is missing from a file because a keyword search came back empty

## Gotchas

- **String absence is not concept absence.** Grepping for a term and finding zero
  hits proves the term is absent, nothing more. The concept is routinely present
  under different words, in a section titled something else. Read the file's
  structure before concluding anything is missing — this is the single most common
  way a run produces confident, wrong findings.
- **Two layers get conflated.** A portable format spec and the runtime that
  implements it will both define limits, and they will differ without either being
  wrong. When two numbers disagree, check whether they are describing the same
  thing before calling it a contradiction.
- **Per-model files rot.** Checked-in `overlays/<model>.md` files look tidy and
  fall behind within one or two releases; the largest public harness repos carry
  overlays for models nobody runs anymore. Keep only the baseline marker and
  re-derive judgements each run.
- **The local health check is a different job.** Tooling that audits usage counts,
  unused extensions, and context cost works from local data and never fetches
  upstream. It cannot see redundancy against a system prompt, and this skill
  should not re-implement what it already does. Run both; they do not overlap.
- **Guidance written for a prior model can invert.** A practice the vendor once
  recommended can become an anti-pattern in a later generation. "It was correct
  when written" is not evidence that it is correct now.
