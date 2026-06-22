---
name: review
description: >
  "レビューして" "review this" "コードレビュー" "PR ready" "/review" —
  cross-model code review via Codex CLI. Reviews diff against base branch
  from a separate model with no shared context. Run before creating a PR.
---

# Review

Review the current diff using Codex CLI for cross-model, context-separated evaluation.

## Why this matters

- Self-evaluation doesn't work (Anthropic: "agents confidently praise mediocre work"). 5 independent sources have now converged on the same conclusion (Anthropic, Bassim, Karpathy, Osmani, LangChain Rubrics).
- Same-context review is biased — the reviewer knows the reasoning and glosses over issues. Addy Osmani: agent-written PRs leave the human reviewer as "the first human being to ever lay eyes on this code" — review wasn't built to recover missing intent.
- Codex runs in its own process with no access to this conversation — both cross-model AND context-separated.
- **Heterogeneity > redundancy**. A 2026 experiment ran 4 AI reviewers in parallel over 146 PRs and 679 findings: **93.4% of distinct flagged locations were caught by exactly ONE of the 4 tools, 6% by two, almost none by three, NONE by all four.** Running 4 copies of the same model = a single reviewer with a larger invoice. So when running multiple reviewers, deliberately pick different characters (e.g. one for everyday correctness, one for production-failure severity).
- A reviewer **prompted to find gaps will find some even when the work is sound** — that's what it was asked to do. Tell the reviewer to flag only gaps that affect correctness or stated requirements; treat the rest as optional.

## Process

### 1. Determine base branch and diff

```bash
BASE=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
git diff "$BASE"..HEAD --stat
```

If empty, check uncommitted changes: `git diff --stat`

### 2. Check Codex CLI availability

```bash
which codex >/dev/null 2>&1 && echo "FOUND" || echo "NOT_FOUND"
```

If NOT_FOUND: fall back to a Claude Code subagent review (context-separated but same model). Tell the user cross-model is unavailable.

### 3. Run Codex review

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"
TMPERR=$(mktemp /tmp/codex-review-XXXXXX.txt)
codex review --base main -c 'model_reasoning_effort="high"' 2>"$TMPERR"
```

Timeout: 5 minutes (`timeout: 300000`).

If the user gave specific focus (e.g., "security に注目して"), append it as the prompt argument to `codex review`.

### 4. Parse and present results

Present Codex output verbatim. Do not summarize or truncate.

Determine verdict:
- Any P1 finding → **NEEDS ATTENTION**
- P2 only or no findings → **PASS**

```
## Review Results (Codex)

**Verdict**: PASS / NEEDS ATTENTION

<codex output verbatim>
```

Parse cost from stderr if available:
```bash
grep "tokens used" "$TMPERR" 2>/dev/null || echo "tokens: unknown"
rm -f "$TMPERR"
```

### 5. Cross-model comparison (if Claude review was already done)

If this session already ran a Claude-side review (e.g., via subagent or prior analysis), compare:

```
## Cross-Model Analysis

Both found: [overlapping findings]
Only Codex: [unique to Codex]
Only Claude: [unique to Claude]
Agreement rate: X%
```

### 6. Classify and handle findings

Classify each finding by priority:
- **P0**: production will break if merged. Must fix before PR.
- **P1**: significant issue (security, data loss, logic error). Fix before PR.
- **P2**: improvement (style, minor edge case, refactor suggestion). Defer — log as TODO or backlog, do not block the PR.

The implementing agent (or human) may **pushback or defer** review findings:
- Defer: "valid but not in scope for this PR" → acknowledged, not fixed
- Pushback: "disagree with the assessment" → explain why, reviewer accepts or escalates

**Bias toward merging.** The goal is to ship, not to achieve perfection per commit. Small non-blocking issues are better addressed in follow-up than blocking the PR.

Diff scope only — ignore findings about unchanged code.

## Fallback: subagent review

If Codex CLI is unavailable, spawn a Claude Code subagent with a review-specific prompt. The subagent gets a fresh context (no access to this conversation) but uses the same model.

```
Review this diff for: logic errors, security vulnerabilities, edge cases not covered by tests, leaky test assertions, and architectural drift. Only review changes in the diff — ignore pre-existing code. For each finding, state severity (CRITICAL/HIGH/MEDIUM/LOW) and confidence (0-100). Suppress findings below confidence 70.
```

## Capturing intent for the reviewer

The reviewer's hardest job is reconstructing intent that never made it into the diff. Help it:

- The agent that implemented the change wrote it down somewhere (plan, scratch notes, thinking trace). Surface that **as a decision log on the PR body** — "alternatives weighed", "constraints honored", "out of scope". This collapses most of the reviewer's reconstruction cost.
- Tier the diff by risk before review starts: config tweak earns a linter + glance, payments path earns the full stack (types, tests, two AI reviewers, security pass).
- Watch for the patterns GitHub's review guide flags specifically for agent PRs: removed tests, skipped lint, lowered coverage thresholds, duplicated helper that already exists elsewhere, and **untrusted input flowing into a prompt** (latent prompt injection). Read the test changes more carefully than the code — agents fix tests to match new broken behavior.

## Verifier-model caveats

- **Do not use Haiku as a strict-domain verifier.** LangChain × Harvey measured Claude Haiku 4.5 at **48.4% per-criterion / 34.7% batch false-pass rate** on the legal-agent benchmark — that's the wrong failure mode for high-stakes review (you want misses to be conservative, not permissive).
- **Default to batch verification** (one judge call for the whole rubric) over per-criterion. Roughly **10× cheaper** with modest accuracy loss; per-criterion is for tasks where each criterion has a narrow decision window worth paying for.
- Even frontier verifiers disagree ~4-5% with each other; chasing 100% match is unrealistic.

## Principles

- The reviewer must not have the implementer's context
- Diff scope only — don't review pre-existing code
- Present Codex output verbatim — don't editorialize
- This is a second opinion, not a gate. The human decides
- Bias toward merging. P2 and below should not block a PR
- Pushback is allowed. The implementer can defer or disagree with findings
- False positives are expected with cross-model review. Filter, don't complain
- **Heterogeneity over redundancy** when running multiple reviewers — different characters surface different classes of bug
- **Tell the reviewer the bar.** "Flag gaps in correctness or stated requirements only" beats an open-ended "find problems" prompt every time
