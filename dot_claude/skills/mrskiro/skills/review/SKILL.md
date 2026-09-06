---
name: review
description: >
  "レビューして" "review this" "コードレビュー" "PR ready" "PR作る前に確認"
  "diff レビュー" "code review" — Cross-vendor review: runs the bundled
  `code-review` skill and Codex CLI in parallel on the same diff, then
  reconciles the two result sets. Use when the user asks for a code review or
  wants a diff checked before pushing. Use `/code-review` alone instead when
  Codex is not installed or a Claude-only review is enough.
---

# Review

The bundled `code-review` skill is the review engine. Codex runs beside it as
the one signal Claude cannot produce. This skill only reconciles the two.

## Why this design

- **Don't reimplement the engine.** Bundled `code-review` already runs multiple
  agents, verifies each finding (`CONFIRMED` / `PLAUSIBLE`), requires a concrete
  failure scenario per finding, and can apply fixes (`--fix`) or post inline PR
  comments (`--comment`). It runs forked, so its intermediate work never enters
  this session's context.
- **Don't rebuild the ensemble.** Running N reviewers and aggregating them is
  what the bundled engine does internally, with a verify pass on top. Rebuilding
  that outside it buys nothing and costs context.
- **Review is a partial net, not a gate.** Every published measurement of LLM
  review, on every model generation, lands well short of catching all real
  issues. Report what was found; never say or imply the diff is clean because
  the review came back empty.
- **Run the cross-vendor lane whenever it is available.** Every bundled path,
  `ultra` included, is Claude, so Codex is the only signal from outside that
  family. Two families do not share blind spots the way two samples of one
  family do. Standing decision: if `codex` is on `PATH`, it runs.
- **Give Codex no rewrite authority.** The one failure mode that reproduces
  across settings is a reviewer that rewrites rather than reports: when
  uncertain it discards the writer's structure and restarts, turning correct
  code incorrect. Step 3 keeps Codex advisory. Adopt a Codex-only finding solely
  when reading the source lets you state the concrete failure.
- **Reconciliation is the whole job here.** Two lists, deduped, with cross-vendor
  hits promoted. Nothing else.

Superseded by this design: dynamically generated personas, N Sonnet reviewers,
and confidence scored by reviewer agreement ratio. The engine covers the first
two, and agreement among same-family reviewers measures shared priors as much as
truth.

### On evidence

This skill cites no benchmark numbers on purpose. As of 2026-09 the published
work is a model generation or more behind what runs here, measured on
single-file tasks rather than repo diffs, or vendor-run with an explicit
"not a leaderboard" caveat. Those numbers rot faster than this file gets edited,
so only the mechanisms above are written down.

## Step 1 — Target

```bash
BASE=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
git diff "$BASE"..HEAD --stat
```

If empty, fall back to `git diff --stat` (uncommitted). If still empty, stop and
say there is nothing to review.

## Step 2 — Run both in parallel

Send 2a and 2b **in one message with two tool calls**. Sequential messages
serialize them and waste minutes.

### 2a. Bundled engine

Call the Skill tool with `skill: "code-review"`. Pass the effort level the user
asked for as `args`, defaulting to `high`. Pass a PR number, branch, or path
through unchanged when the user named one.

Do not pass `--fix` or `--comment` from here. Both act on findings before this
skill has reconciled them; tell the user to run `/code-review --fix` directly
when that is what they want.

### 2b. Codex CLI

```bash
which codex >/dev/null 2>&1 || echo NOT_FOUND
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" && codex review --base main -c 'model_reasoning_effort="high"'
```

Timeout: 300000 ms. Append the user's focus ("security に注目して") as the
prompt argument when they gave one.

If `codex` is missing, run 2a alone and say the run had no cross-vendor signal:
`/code-review` on its own would have produced the same result.

## Step 3 — Reconcile

Bundled findings arrive already verified. **Do not re-verify them** — the fork
opened the source and attached a verdict. Spend the effort on the other groups.

| Group | What to do |
|---|---|
| Both vendors, same file + same root cause | Mark `CROSS-VENDOR`. Highest priority regardless of either side's own severity |
| Bundled only | Keep its severity and `CONFIRMED` / `PLAUSIBLE` verdict as-is |
| Codex only | Skeptical prior (see above). Open the cited file, read the surrounding code, then adopt or reject in one sentence citing what you saw. Adopt only when you can state the concrete failure; reject when it is mitigated upstream, out of diff scope, or wrong about the code |

Priority for the merge decision:

- **P0** — `CROSS-VENDOR`, or `CONFIRMED` + security / data loss / crash
- **P1** — `CONFIRMED` bug, or an adopted Codex finding of the same weight
- **P2** — everything else, including every `PLAUSIBLE` no second source reached

**Bias toward merging.** P2 never blocks. If only P2 findings remain, PASS.

## Output

```
## Review Results

**Verdict**: PASS / NEEDS ATTENTION
**Sources**: code-review (<effort>) + Codex   ← or "code-review only (codex not installed)"

### P0
#### [CROSS-VENDOR] <title>
- `path/to/file.ts:42`
- Both said: <one line per side>
- Failure: <concrete input/state → wrong output>

### P1
(same shape)

### P2
- `file:line` — <one line each>

### Rejected Codex findings
- `file:line` — <one-sentence reason from reading the source>
```

The rejected section is mandatory when there are rejections. Saying *why*
something was dropped is what makes the adopted list trustworthy.

## Gotchas

- **One message for Step 2.** Parallel tool calls in a single message; sequential
  messages roughly double the wall time.
- **Diff scope only.** Reject findings about pre-existing code the diff didn't
  touch, even when technically real.
- **Codex output goes into Step 3 verbatim.** Don't pre-summarize it — the
  adopt/reject decision needs the original wording to check against source.
- **No second consolidator agent.** Reconcile inline; spawning another agent
  duplicates context cost with no quality gain.
- **Pushback is evidence.** If the user disputes an adopted finding, re-open
  that one finding's source and decide again.

## Principles

- This is a second opinion, not a gate. The human decides.
- Bias toward merging. P2 does not block.
- Rejected findings are shown with reasons.
- False positives are expected with multi-model review. Filter, don't complain.

## When not to use this skill

- Claude-only review is fine, or Codex is not installed → `/code-review`
- Apply the fixes in the same run → `/code-review --fix`
- Post findings on a GitHub PR → `/code-review --comment`
- Deep multi-agent review in the cloud → `/code-review ultra`
