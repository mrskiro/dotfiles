---
name: flywheel
description: >
  "フライホイール" "flywheel" "usage analysis" "harness improvement" —
  Analyze BigQuery usage data and propose harness improvements. Run periodically to drive the improvement cycle.
allowed-tools: Bash Read Glob Grep
---

Cross-reference accumulated Claude Code usage data (BigQuery) with current harness state, detect Fowler's 4 signal types, and output concrete improvement proposals.

## Prerequisites

- `bq` CLI available (part of gcloud SDK)
- GCP project with `claude_code_telemetry` dataset (tables: `sessions`, `tool_uses`, `api_calls`)
- Incremental load script: `scripts/flywheel/parse-sessions.ts` (me repo)

Before running queries, verify access by running `bq ls`. If it fails, ask the user to authenticate with `gcloud auth application-default login` and confirm which GCP project to use, then **stop**.

## Step 0: Determine analysis period

Query the sessions table for the latest `started_at` to check data freshness.

- Latest data > 3 days old → suggest incremental load and **stop**
- Latest data ≤ 3 days old → analyze the last 2 weeks

## Step 1: Fetch data

**Before this step, read `references/queries.md` for the exact SQL queries.**

Run `bq query --use_legacy_sql=false --format=json` to fetch:

1. Skill usage frequency (by skill_name)
2. Tool usage frequency (by tool_name, top 20)
3. Agent spawns (by agent_type)
4. MCP tool usage (by mcp_tool)
5. Per-project summary (sessions, cost_usd)
6. Weekly cost trend
7. Bash command patterns (grouped by first word, top 10)
8. Friction events (user corrections, hook blocks, tool rejections) + sessions with most friction + hook block patterns
9. Workflow deviation detection

## Step 2: Read current harness state

Use Read / Glob to check:

1. Current project's `CLAUDE.md` (if exists)
2. `~/.claude/CLAUDE.md` (global)
3. `.claude/skills/*/SKILL.md` — project skill names (Glob directory names only)
4. `~/.claude/skills/*/SKILL.md` — global skill names
5. `~/.claude/settings.json` hooks section

## Step 3: Detect 4 signals

Cross-reference Step 1 data with Step 2 harness state.

### Context Signal (CLAUDE.md / rules improvements)

- Same Bash arguments/paths/config values repeated across multiple sessions → should be codified in CLAUDE.md or rules
- A project has disproportionately high cost or tool_calls → its CLAUDE.md may lack context

### Instruction Signal (skill improvements)

- Existing skills with 0 usage → candidates for deletion or trigger improvement
- High-frequency skills → improving them yields highest ROI
- Explore agent ratio too high → skills may lack sufficient context specification

### Workflow Signal (skill candidates + workflow deviations)

- Frequent tool call combinations not covered by existing skills → new skill candidates
- High-frequency Bash command patterns → should become skills or aliases
- **Workflow deviations**: sessions where expected procedures were not followed (use deviation queries from `references/queries.md`)
  - Example: skill file created without invoking /skill-creator
  - Example: CLAUDE.md edited without running /agentic-audit first

### Failure Signal (guardrail additions)

- **Hook blocks**: which hooks fire most often, and whether the model learns from being blocked (does the same block pattern recur in the same session?)
- **User corrections**: sessions with high correction counts suggest the model is missing context or instructions
- **Tool rejections**: user rejecting tool use suggests the model is taking unwanted actions
- Cross-reference high-friction sessions with their project → identify which projects need better CLAUDE.md/rules

## Step 4: Output

Print to terminal in the following format. **Do not save to files.**

```
# Flywheel Analysis (YYYY-MM-DD — YYYY-MM-DD)

## Context Signal
- [Specific proposal: which artifact to change and how]

## Instruction Signal
- [Skill improvement / deletion proposals]

## Workflow Signal
- [Skill candidates + deviations detected]

## Failure Signal
- [Guardrail addition proposals]

## Summary
- Sessions / Cost / Top skills / Unused skills
```

## Proposal criteria

**Before applying these criteria, read `references/criteria.md`.**

Improvement target priority:
```
test/lint > hook > .claude/rules/ > docs/ > CLAUDE.md
```

Proposal filters:
- **Recurrence**: do not propose for one-off events
- **Mechanically enforceable?**: if yes → test/lint/hook. CLAUDE.md is last resort
- **Overlap with existing rules?**: skip if CLAUDE.md or rules already cover it
- **Constraints > instructions**: propose as constraints ("X is prohibited") not instructions ("please do X")
