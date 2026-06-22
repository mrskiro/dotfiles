---
name: skill-creator
description: >
  "skill作って" "スキル作りたい" "create a skill" "improve this skill" "スキル改善"
  "SKILL.md書いて" "package this workflow" — Author or improve a skill (a directory
  with SKILL.md plus optional bundled resources like scripts/, references/, assets/).
  Use when the user wants to capture a workflow, set of conventions, or reusable
  knowledge that an agent should load on demand — even when they describe it as
  "make this repeatable", "turn this into a command", or "remember to do X every
  time" without saying "skill".
---

Author or improve a skill following the open Agent Skills format
(https://agentskills.io). The agent is the consumer — write for activation
accuracy and execution effectiveness, not for human reading.

A skill is **a workflow with checkpoints that produce evidence, ending in a
defined exit criterion** (Osmani). Not reference documentation. Not a
2,000-word essay on how to do X well. Process over prose. If you find
yourself writing reference material, stop — bundle it as `references/<topic>.md`
and have the skill point to it at the moment of need.

## Process

### 0. Should this even be a skill?

Skills are over-used (Pritchard via Fowler). Before writing one, ask:

| If yes → | Use instead | Why |
|---|---|---|
| Should this happen on every edit / commit / session-start, deterministically? | **Hook** in `settings.json` | Instructions are advisory; hooks always run |
| Is this a non-negotiable rule ("never do X") | **Hook (exit 2) + permission rule** | Under injection / long context / ambiguity the model can ignore prompted rules. Managed settings for org-wide unbreakable enforcement |
| Does it only apply to specific files / paths | **Path-scoped rule** (`paths:` frontmatter) | Loads only when relevant; fresher position in context |
| Is the agent struggling because the codebase is tangled or tests are inconsistent | **Fix the codebase / tests** | "Reaching for configuration when you should be reaching for architecture" (Pritchard). Point Claude at a test file you're proud of — that beats a `testing-skill` |
| Is this a fact the agent should hold all the time (build commands, monorepo layout, team conventions) | **CLAUDE.md** entry | Persistent across sessions |
| Is this a deliberate, infrequent procedural workflow (deploy, release, migrate, scaffolded review) | **Skill** | Procedures with steps and evidence belong here |

Reach for the simplest mechanism that fits. A skill that should have been a hook
either doesn't fire reliably or fires when it shouldn't.

### Categories that warrant a skill (Anthropic, "Lessons from building Claude Code")

When you do reach for a skill, the best ones cluster into nine categories.
Skills that straddle several confuse the agent.

1. **Library / API reference** — internal libraries, CLI wrappers, sandbox/egress configs
2. **Product verification** — drives a UI / CLI end-to-end, asserts state at each step. *Highest measurable impact* internally at Anthropic; worth an engineer-week
3. **Data fetching & analysis** — connect to data + monitoring stacks, encode dashboard IDs and field reference
4. **Business process / team automation** — standup-post, weekly-recap, ticket creation with schema enforcement
5. **Code scaffolding & templates** — new-workflow / new-migration / create-app
6. **Code quality & review** — adversarial-review (fresh-eyes subagent that critiques and iterates), code-style enforcer
7. **CI/CD & deployment** — babysit-pr, deploy-with-rollout, cherry-pick-prod
8. **Runbooks** — symptom → multi-tool investigation → structured report
9. **Infrastructure operations** — orphan cleanup with soak periods, dependency approval workflow, cost investigation

If your skill doesn't fit cleanly into one category, that's a sign to split it.

### 1. Locate context

If a workflow already happened in this conversation, extract it — tools used,
corrections made, inputs and outputs observed. Otherwise ask, one at a time:

1. What should the agent be able to do that it currently struggles with?
2. Trigger phrases — including indirect ones (what the user might actually type instead of the obvious keyword)
3. Where should it live?
   - `~/.claude/skills/<name>/` — personal, Claude Code
   - `<repo>/.claude/skills/<name>/` — project, Claude Code
   - `~/.agents/skills/<name>/` or `<repo>/.agents/skills/<name>/` — cross-tool

### 2. Pick the name

- 1-64 chars, lowercase letters/digits/hyphens only
- No leading or trailing hyphen, no `--`
- **Must match the parent directory name** (NFKC-normalized)
- Prefer gerund form (`processing-pdfs`, `analyzing-spreadsheets`)
- Avoid `helper`, `utils`, `tools`, `data` — too vague to trigger reliably
- Avoid `anthropic`, `claude` (Anthropic-specific reserved-word guidance)

### 3. Write the description (the trigger)

The description is the only thing the agent sees at startup; it carries the
entire activation decision. Lead with quoted trigger phrases — agents match
on the prefix, and the listing truncates the tail.

Template:

```yaml
description: >
  "trigger 1" "trigger 2" "日本語トリガー" — <one-sentence what>.
  Use when <when>, including <indirect cases like "even when they don't
  explicitly say X">. Do NOT use for <near-miss case> (use <other-skill> instead).
```

Rules:

- **Third person, imperative.** "Use when…" not "I help…" or "You can…"
- **Lead with quoted triggers.** Buried triggers beyond the truncation point are never seen by the matcher
- **List indirect contexts.** "even if they don't explicitly mention 'CSV'"
- **Negative trigger ("Do NOT use for: X (use Y instead)")** prevents misfire between similar skills — essential in any environment with more than ~5 skills
- **Both what and when.** What the skill does AND when to invoke it
- The `description` + `when_to_use` combined limit is **1,536 chars** in current Claude Code (was 1,024 in the Feb 2026 PDF guide; the spec evolved). Configurable via `maxSkillDescriptionChars`. Lead with triggers so the truncation tail is the loss-tolerant part
- Quote any value containing colons, or use a `>` block scalar — the validator
  parses with strictyaml, which rejects unquoted colons
- **`metadata.pattern: pipeline`-style fields do nothing** in Claude Code. Only `name` and `description` are used for trigger decisions. Writing pattern names in metadata is self-satisfaction unless your runtime actually reads them (Google ADK does; Claude Code doesn't)

### 4. Write the body

Open with one sentence framing what the agent does on activation.

Write **standing instructions** the agent re-applies whenever the relevant
condition arises ("when you encounter X, do Y") — not one-shot procedural
steps ("next, do X"). The body is typically loaded once on activation and
stays in context; instructions framed as a sequence may not get
re-evaluated when their moment arrives.

Then choose the patterns that fit. Skip the others — concise wins.

- **Numbered steps** for sequential workflows
- **Gotchas** — environment facts that defy reasonable assumptions (e.g.
  "the `users` table uses soft deletes; queries must include
  `WHERE deleted_at IS NULL`"). Highest-leverage section. Grow it every
  time you correct the agent.
- **Templates** when output format matters — show literal structure
- **Workflow checklist** (`- [ ]` items the agent copies and ticks off)
- **Validation loop** — "do work → run validator → fix → repeat"
- **Examples (input/output pairs)** when output style matters more than
  describable rules
- **Conditional branching** — lead with the decision, route from there

Skip:

- Explaining concepts the model already knows (HTTP, JSON, common tools)
- Generic advice like "handle errors appropriately" — name the errors and
  what to do for each
- Multiple equivalent options without a default

### Patterns to bake into procedural skills (multi-step workflows)

For skills with side effects (deploy, migrate, "fix-issue", evolve-feature), include:

- **Stop-and-ask gates** (Shogun's `codd-evolve`): list the specific conditions under which the skill must halt and ask the user. Examples: new lexicon term needed, breaking change to existing behavior, impact radius >N files, ambiguous scope. Without these, autonomous loops produce "complete" reports for work the user never authorized
- **Absolute constraints** ("Never do these"): explicit list of things the agent must not do mid-procedure (e.g. "don't edit source without updating design", "don't commit without user approval", "don't declare done without runtime smoke")
- **Runtime smoke check** as the final step ("Step 8"): `codd verify` green is necessary but not sufficient. Build green ≠ DB running, test green ≠ dev server running, E2E green ≠ user can actually touch the change. The terminal verification gate is the difference between a workflow and a "Silent Compliance" failure (家臣 false reports)
- **Anti-rationalization table** (Osmani): for each common skip-the-workflow excuse the agent might generate, pre-write a rebuttal. Examples: *"This task is too simple to need a spec"* → "Acceptance criteria still apply. Five lines is fine. Zero lines is not." *"I'll write tests later"* → "Later is the load-bearing word. There is no later. Write the failing test first." Pre-written rebuttals to lies the agent hasn't yet told

### Five non-negotiables to land in any non-trivial skill body (Osmani)

1. **Surface assumptions before building.** Wrong assumptions held silently are the most common failure mode
2. **Stop and ask when requirements conflict.** Don't guess
3. **Push back when warranted.** The agent is not a yes-machine
4. **Prefer the boring, obvious solution.** Cleverness is expensive
5. **Touch only what you're asked to touch.** Scope discipline is the single biggest determinant of whether a PR is mergeable

Keep `SKILL.md` under ~500 lines. Move detail to `references/<name>.md` and
tell the agent **when** to load each: "Read `references/api-errors.md` if the
API returns a non-200" beats "see references/ for details."

References stay **one level deep** from `SKILL.md`. For reference files
>100 lines, include a table of contents at the top. Use **forward slashes**
in all paths.

### 5. Add bundled resources only if needed

- `scripts/` — when the agent would otherwise reinvent the same logic each
  run. Pin versions. Make scripts non-interactive, accept all input via
  flags, output JSON to stdout, send diagnostics to stderr, exit with
  meaningful codes.
- `references/` — when SKILL.md approaches 500 lines
- `assets/` — templates, schemas, static data
- `hooks/` (Claude Code-only) — **on-demand hooks bundled in the skill**, active only while the skill runs. Examples from Anthropic's internal kit: a `/careful` skill that registers a `PreToolUse` hook blocking `rm -rf`, `DROP TABLE`, force-push, `kubectl delete` for the duration of the session; a `/freeze` skill that blocks any `Edit`/`Write` outside a specified directory. These are guardrails you only want active sometimes — bake them into the skill so they activate together
- `examples/` — input/output pairs that demonstrate the skill in action

Pinned one-off commands are often enough; no `scripts/` dir needed:
`uvx ruff@0.8.0 check .`, `npx eslint@9 --fix .`, `go run pkg@vX.Y.Z`.

To give the skill a memory across sessions: write to `${CLAUDE_PLUGIN_DATA}`
(stable persistent directory) — a `standups.log` append-only file, a
`history.jsonl`, a SQLite database. Next invocation, the skill reads its
own history and tells what's changed since last time.

### 6. Validate

```bash
# Install once:
uv tool install --from "git+https://github.com/agentskills/agentskills.git#subdirectory=skills-ref" skills-ref

# Validate:
skills-ref validate ./<skill-dir>
```

The validator allows only spec fields: `name`, `description`, `license`,
`compatibility`, `metadata`, `allowed-tools`. Any other top-level key is
flagged as "Unexpected fields in frontmatter."

For client-specific extensions (Claude Code: `disable-model-invocation`,
`user-invocable`, `model`, `paths`, `hooks`, …), see
`references/claude-code-extensions.md`. Skills using those extensions will
fail the validator — that's expected.

### 7. Test triggering

Run 3-5 prompts that should trigger the skill and 2-3 near-misses (prompts
that share keywords but need a different solution) that should NOT trigger.
If the agent gets it wrong, the description is wrong.

For rigorous evaluation (~20 queries × multiple runs, train/val split,
output quality assertions, blind judge, fresh-agent dogfooding), see
`references/evaluation.md`.

### 8. Iterate

When the agent makes a mistake using the skill:

- Add the correction to the gotchas section
- If a section caused the mistake, rewrite or remove it
- Generalize: don't add narrow patches for the specific failed case
- Drop instructions that aren't pulling their weight

## Frontmatter quick reference

| Field           | Required | Constraint                                                        |
|-----------------|----------|-------------------------------------------------------------------|
| `name`          | Yes      | ≤64 chars, kebab-case, matches directory                          |
| `description`   | Yes      | ≤1024 chars, non-empty                                            |
| `license`       | No       | SPDX identifier or bundled file (e.g. `LICENSE.txt`)              |
| `compatibility` | No       | ≤500 chars; runtime, package, or product requirements             |
| `metadata`      | No       | String→string map; use unique key names                           |
| `allowed-tools` | No       | Space-separated, experimental                                     |

```yaml
---
name: pdf-processing
description: >
  "process PDF" "fill form" — Extract text/tables from PDFs, fill forms,
  merge files. Use when the user is working with PDF documents, even when
  they don't explicitly say "PDF".
license: MIT
compatibility: Requires Python 3.11+ and pdfplumber
---
```

## Anti-patterns

- Description that doesn't lead with quoted trigger phrases
- Mixed POV: "I can help…" or "You can use this to…"
- Vague procedures like "handle errors appropriately"
- Three approaches with no default — pick one
- README, INSTALLATION, or CHANGELOG inside the skill directory
- A skill that combines unrelated domains (split it)
- Time-sensitive prose like "after August 2025…" — use a `## Old patterns`
  section with `<details>` instead
- Generic instructions about basics the model already knows
- **Configuration when you should reach for architecture** (Pritchard). A "testing skill" that complains about inconsistent test patterns is treating a symptom — fix the tests. Skills accumulate as a "junk drawer" if you reach for them as the default tool
- **Pushing the user with `A / B / C / D` choices in an autonomous loop.** Strategic decisions belong to the user; tactical decomposition (which file to update, which order, which test, which commit message) is the agent's job. A skill that interrupts every few minutes with multiple-choice prompts is throughput-killing — bake decisions into the skill via stop-and-ask gates only at *meaningful* boundaries (new lexicon term, breaking change, scope explosion). When in doubt, agree on "user expresses intent + approves; agent structures"
- Writing `pattern: pipeline` or other custom `metadata.*` fields and expecting Claude Code to behave differently — only `name` + `description` are read for triggering
- Skill that just gives info — could it be a hook, a path-scoped rule, or improved code instead?
- Self-reported "done" without a runtime verification gate

## On authority and humility

The published guides (Anthropic's "Complete Guide to Building Skills for
Claude", Google's "5 Agent Skill design patterns") are *starting points,
not final answers*. They're written by people who design the spec; you're
writing skills that hit production. Two things follow:

1. Read the public material, then ignore the parts that don't survive
   contact with your codebase. Public spec is "minimum useful." Battle-tested
   practice is "actually works."
2. Don't carry over things that look prestigious but do nothing. The
   `metadata.pattern` field is the canonical example — Google ADK reads it,
   Claude Code doesn't. Spec compliance ≠ runtime effect.

When in doubt, the most reliable signal is: **what survives your next 10
iterations of using this skill?** Authority is downstream of that.


