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

- Self-evaluation doesn't work (Anthropic: "agents confidently praise mediocre work")
- Same-context review is biased (the reviewer knows the reasoning and glosses over issues)
- Codex runs in its own process with no access to this conversation — both cross-model AND context-separated

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

## Principles

- The reviewer must not have the implementer's context
- Diff scope only — don't review pre-existing code
- Present Codex output verbatim — don't editorialize
- This is a second opinion, not a gate. The human decides
- Bias toward merging. P2 and below should not block a PR
- Pushback is allowed. The implementer can defer or disagree with findings
- False positives are expected with cross-model review. Filter, don't complain
