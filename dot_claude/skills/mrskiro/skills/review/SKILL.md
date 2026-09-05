---
name: review
description: >
  "レビューして" "review this" "コードレビュー" "PR ready" "/review"
  "PR作る前に確認" "diff レビュー" "code review" — Multi-agent code review
  combining Codex CLI (cross-vendor) with N dynamically-generated persona
  reviewers (Sonnet) and a defending consolidator (Opus). Use when the user
  asks for a code review, mentions getting a PR ready, or wants a diff
  checked before pushing — even when they don't explicitly say "Codex" or
  "multi-agent".
---

# Review

Multi-agent review of the current diff. Codex (cross-vendor outsider) runs alongside N Claude reviewers each scoped to a dynamically-generated persona. A consolidator opens the actual source files, defends each finding (adopt/reject with reason), and attaches a confidence score.

## Why this design

- **Codex is the only true cross-vendor signal** — different process, different vendor. Claude family cannot replicate this internally, so Codex stays.
- **Single-reviewer AI output is noisy.** Multi-Review (arXiv:2509.01494) shows N independent reviews + aggregation lifts recall ~118% (n=10). Mixture-of-Agents (arXiv:2406.04692) shows heterogeneous prompts beat homogeneous.
- **Without defense, output is a longer noisy list.** A consolidator that opens source files and justifies adopt/reject is what turns "indications" into "findings".

## Architecture

```
Step 1  Haiku subagent → persona generation (2-3 reviewers from diff semantics)
Step 2  parallel       → Codex CLI  +  Sonnet × N (one per persona)
Step 3  Opus inline    → defense + confidence + final output
```

## Step 1 — Diff and personas

### 1a. Determine base and diff

```bash
BASE=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
git diff "$BASE"..HEAD --stat
DIFF_FILE=$(mktemp /tmp/review-diff-XXXXXX.patch)
git diff "$BASE"..HEAD > "$DIFF_FILE"
```

If empty, fall back to uncommitted: `git diff --stat` and `git diff > "$DIFF_FILE"`. If still empty, stop and tell the user there is nothing to review.

### 1b. Generate personas via Haiku subagent

Spawn one Agent with `model: "haiku"` and `subagent_type: "general-purpose"`. Pass the diff path. Ask for 2-3 personas as strict JSON.

Prompt template:

> Read the diff at `<DIFF_FILE>` (use Read or `cat`). Propose 2-3 reviewer personas based on what the change actually does. Personas reflect *change semantics*, not file extensions: auth-touching → "Security Auditor"; DB migration → "Database Migration Specialist"; perf-sensitive hot path → "Performance Engineer". Output strict JSON only, no prose, no fences: `{"personas":[{"name":"...","focus":"...","what_to_look_for":"..."}]}`. Use 2 if the change is narrow, 3 if it spans multiple concerns. Never more than 3.

Bounds rationale: <2 loses ensemble effect; >3 hits diminishing returns (cost +67% for +15-25% recall at n=3→5 per Multi-Review).

If the subagent returns prose, retry once with "respond with strict JSON only, no prose, no fences."

## Step 2 — Parallel reviews

Run 2a and 2b **in a single message with multiple tool calls** so they execute concurrently. Sequential messages serialize them and waste minutes.

### 2a. Codex CLI

```bash
which codex >/dev/null 2>&1 && echo FOUND || echo NOT_FOUND
```

If FOUND:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"
TMPERR=$(mktemp /tmp/codex-review-XXXXXX.txt)
codex review --base main -c 'model_reasoning_effort="high"' 2>"$TMPERR"
```

Timeout: 300000 ms. If the user gave specific focus ("security に注目して"), append it as the prompt argument to `codex review`.

If NOT_FOUND, skip Codex and continue with persona reviewers only. State the degradation in the final output.

### 2b. Persona reviewers (Sonnet × N)

For each persona from Step 1, spawn an Agent with `model: "sonnet"` and `subagent_type: "general-purpose"`. Pass the diff path and the persona definition. Send all reviewer Agent calls in the **same message** as the Codex Bash call (full parallelism).

Per-reviewer prompt rules (include verbatim):

- Stay in your focus area. Do **not** flag issues outside your specialty — recall comes from the ensemble, not from any one reviewer being exhaustive.
- Maximum **5 findings**. Pick by severity, not coverage.
- Open the actual source files (not just the diff hunk) to verify surrounding context before flagging.
- Diff scope only. Do not flag pre-existing code untouched by this diff.
- Severity buckets:
  - **CRITICAL** — security vulnerability, data loss risk, prod crash
  - **WARNING** — bug, incorrect behavior, significant maintainability concern
  - **SUGGESTION** — improvement, non-blocking
- Output strict JSON only: `{"persona":"<name>","findings":[{"severity":"CRITICAL|WARNING|SUGGESTION","file":"...","line":N,"issue":"...","why":"..."}]}`. No prose, no fences.

## Step 3 — Defense and consolidation (inline)

Once Codex output and all persona JSON outputs are collected, the running agent is the consolidator. Do this inline — do not spawn another agent. The session model should be Opus for best judgment; if not, defense quality is reduced but the workflow still runs.

### 3a. Defend every finding

For every finding (Codex + each persona):

1. Open the cited source file. Read the surrounding code, not just the diff hunk.
2. Decide **adopt** or **reject**:
   - Adopt if the issue is real after reading context.
   - Reject if mitigated elsewhere (validation upstream, sanitized at boundary, guarded by surrounding code), out of diff scope, or factually wrong about the code.
3. Write a one-sentence reason that cites what you saw in the source (not just "looks fine").

### 3b. Dedupe and confidence

Group findings that point to the same underlying issue (same file + same root cause), even if worded differently. For each group:

| Confidence | Rule |
|------------|------|
| **HIGH**   | ≥66% of reviewers flagged it, OR verified critical bug after source check |
| **MEDIUM** | ≥40% of reviewers, OR single reviewer + source-verified non-critical |
| **LOW**    | Single reviewer, unverified, or style only |

"Reviewers" = actual count N (Codex counts as 1 if it ran; otherwise N is just persona count). Compute the ratio against actual N — a 2-reviewer run and a 4-reviewer run must both produce sensible scores.

### 3c. Priority for the PR decision

- **P0** = CRITICAL severity + HIGH confidence → must fix before merge
- **P1** = CRITICAL + MEDIUM, or WARNING + HIGH → fix before PR
- **P2** = anything else → defer, do not block

**Bias toward merging.** P2 findings do not block. If only P2 findings remain, verdict is PASS.

## Output format

```
## Review Results

**Verdict**: PASS / NEEDS ATTENTION
**Reviewers**: N (Codex + <persona1>, <persona2>, ...)

### Adopted findings (priority order)

#### [P0 / HIGH] <issue title>
- File: `path/to/file.ts:42`
- Severity: CRITICAL
- Confidence: HIGH (3/3 reviewers)
- Issue: <what is wrong>
- Source check: <what you saw when you opened the file>

(repeat P0 → P1 → P2)

### Rejected findings (transparency)

#### <issue title> — REJECTED
- Raised by: <reviewer name>
- Reason: <one sentence with source evidence>

(repeat)

### Cross-model agreement
- Both Codex and ≥1 persona: <count>
- Codex only: <count>
- Persona only: <count>
```

The rejected section is mandatory when there are rejections. Transparency about *why* something was rejected is what lets downstream agents and humans trust the adopted list.

## Gotchas

- **Run Step 2 in a single message.** Multiple tool calls in one message run in parallel; sequential messages serialize them and roughly N× the wall time.
- **Strict JSON from subagents.** If a subagent returns prose, retry once with "respond with strict JSON only, no prose, no fences." If it fails twice, parse what you can and note the degradation.
- **Diff scope only.** Reject any finding about pre-existing code untouched by this diff, even if the finding is technically real — out of scope.
- **Confidence ratio uses actual N.** If Codex was unavailable and you ran with 2 personas, HIGH still requires 2/2 (≥66%), not 2/4. Never use a fixed denominator.
- **Codex output is verbatim input to defense.** Do not pre-summarize Codex before consolidation — defense needs the original wording to verify against source.
- **No re-spawn of consolidator.** The current session does consolidation inline. Spawning another Opus agent duplicates context cost without quality gain.
- **Pushback is allowed.** If the user disagrees with an adopted finding, treat the disagreement as new evidence and re-run Step 3a for that one finding only.
- **No fixed personas list.** Personas come from diff semantics. Do not maintain a static "Security/Performance/Readability" set — the article's whole point is dynamic personas tied to what the change actually does.

## Fallback when Codex is unavailable

Run Step 2b only (persona reviewers). State in the output:

> Cross-vendor signal unavailable (Codex CLI not found). Running with Claude persona reviewers only. Recall is reduced; consider installing Codex CLI.

Confidence still uses actual N, so internal consistency holds.

## Principles

- The reviewer must not have the implementer's context (subagents are fresh).
- Diff scope only.
- Defense is mandatory — every adopted finding cites source evidence.
- Rejected findings are shown with reasons (transparency).
- Bias toward merging. P2 does not block.
- This is a second opinion, not a gate. The human decides.
- False positives are expected with multi-model review. Filter, don't complain.
