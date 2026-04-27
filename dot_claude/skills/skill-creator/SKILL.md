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

## Process

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
  explicitly say X">.
```

Rules:

- **Third person, imperative.** "Use when…" not "I help…" or "You can…"
- **List indirect contexts.** "even if they don't explicitly mention 'CSV'"
- **Both what and when.** What the skill does AND when to invoke it
- ≤1024 characters; one paragraph
- Quote any value containing colons, or use a `>` block scalar — the validator
  parses with strictyaml, which rejects unquoted colons

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

Pinned one-off commands are often enough; no `scripts/` dir needed:
`uvx ruff@0.8.0 check .`, `npx eslint@9 --fix .`, `go run pkg@vX.Y.Z`.

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
