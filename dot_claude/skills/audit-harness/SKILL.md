---
name: audit-harness
description: >
  Audit the project's harness using the Guides+Sensors framework.
  Use when: "ハーネスチェック", "harness audit", "backpressure確認",
  "ループ閉じてる？", or when starting a new project to verify quality gates.
---

# Audit Harness

Audit whether the project's harness lets agents work autonomously with confidence. Agent = Model + Harness.

A harness needs both **Guides** (feedforward — steer before action) and **Sensors** (feedback — observe and correct after action). Without both, you get either an agent that repeats mistakes (sensors-only) or one that encodes rules but never verifies they work (guides-only).

## Process

### 0. Gather evidence (MUST DO FIRST)

Before scoring anything, read the actual configuration files. Do not guess or rely on checklists alone.

**Read these files (project-level):**
- `.claude/settings.json` — hooks (PreToolUse, PostToolUse, WorktreeCreate), permissions (deny list)
- `CLAUDE.md` — project conventions, commands
- `.claude/rules/` — path-scoped rules (list directory)
- `.claude/skills/` — project skills (list directory)
- `lefthook.yml` or `.husky/` or `.git/hooks/` — pre-commit configuration
- `tsconfig.json` — strict mode, type checking config
- `.github/workflows/` — CI pipeline (list and read)
- `.worktreeinclude` — worktree file copy config

**Read these files (global-level, if accessible):**
- `~/.claude/settings.json` — global hooks, deny list, permission mode
- `~/.claude/skills/` — global skills (list directory)

**Score based on what you actually find in these files, not on assumptions.**

### 1. Check Guides (Feedforward)

Guides anticipate agent behavior and steer toward quality before code is written.

**Computational guides:**
- CLAUDE.md / rules/ — project conventions, commands, gotchas
- Code templates / golden files — examples the agent can follow
- Type definitions, schemas — structural constraints

**Inferential guides:**
- Skills with domain knowledge (architecture, design principles)
- Plan mode / specs — intent captured before implementation

### 2. Check Sensors (Feedback)

Sensors observe agent output and enable self-correction.

**Computational sensors (deterministic, fast):**
- PostToolUse hooks: lint, format, typecheck after every edit — check `.claude/settings.json` PostToolUse section
- Pre-commit hooks: lint + format + typecheck + test (gate before commit) — check `lefthook.yml` or `.husky/`
- Bypass prevention: `--no-verify` denied, config files protected — check global settings deny list and PreToolUse hooks
- Structural tests: architecture boundary enforcement

**Inferential sensors (LLM-based, slower):**
- Code review agents (cross-model or subagent)
- Custom judgment (adversarial review, design review)

### 3. Check Security Boundaries

Agents, generated code, and secrets should live in separate trust domains.

- Permission mode: check `~/.claude/settings.json` defaultMode and project deny list
- Destructive operation blocking: check PreToolUse hooks in both global and project settings
- Secret protection: check deny list for `wrangler secret`, `gh secret set`, etc.
- Config protection: check PreToolUse Edit/Write hooks for protected files (lefthook.yml, tsconfig.json, settings.json, etc.)

### 4. Check Closing the Loop

Can the agent verify its own output and iterate?

- Test execution: can the agent run tests? Is the command discoverable?
- Browser verification: for web projects, can the agent open pages and verify? Prefer CLI tools (agent-browser, playwright-cli) over MCP (Playwright MCP, Claude in Chrome) for token efficiency. Check if authentication is handled (session persistence, cookie management).
- Log access: can the agent read server logs, error tracking?
- Commit = verification gate: if pre-commit runs tests, committing IS completion — check lefthook.yml for test in pre-commit

### 5. Check Harnessability

How well does the codebase support harness construction?

- **Strong typing**: check tsconfig.json for strict, noUncheckedIndexedAccess, etc.
- **Clear module boundaries**: are there defined layers, packages, or domains? (enables architectural constraints)
- **Framework abstractions**: does the project use established frameworks? (reduces agent complexity)
- **Test infrastructure**: does a test runner, fixture system, and CI pipeline exist?
- **Legacy debt**: are there areas where harness is most needed but hardest to build?

### 6. Evaluate Keep Quality Left

Are controls distributed at the right lifecycle stage? Map what you found in Step 0 to the timeline:

| Stage | Speed | What should run here | Actually running? |
|---|---|---|---|
| PostToolUse (ms) | Fastest | lint, format, typecheck | Check settings.json PostToolUse |
| Pre-commit (s) | Fast | test (bail 1), full lint | Check lefthook.yml |
| Post-integration/CI (min) | Medium | comprehensive test suite, mutation testing, review agents | Check .github/workflows/ |
| Continuous monitoring | Ongoing | dead code, dependency scanning, runtime metrics | Check for scheduled CI jobs |

Check: are expensive controls running too early (slowing the agent) or cheap controls running too late (missing early)?

**Speed thresholds for deterministic steps:**
Deterministic steps (build, test, lint, typecheck, install) run repeatedly — every edit, every commit, every CI run. Faster is always better. Measure actual execution time and check against thresholds:

| Step | Threshold | How to check |
|---|---|---|
| Full build loop (build+test+lint+typecheck) | < 1 min | Time the full sequence |
| PostToolUse hooks | < 5s per edit | Check if hooks slow down the agent's edit cycle |
| pnpm install (worktree setup) | < 30s | Time WorktreeCreate hook |
| CI pipeline | < 5 min | Check GitHub Actions run duration |

If any step exceeds its threshold, flag it as a Gap and propose how to install monitoring:

- **CI duration monitoring**: add a step that measures and reports total pipeline time. Alert if it exceeds the threshold.
- **PostToolUse profiling**: time the hooks and report if they slow the edit cycle.
- **Threshold enforcement**: add CI checks that fail or warn when build/test time exceeds the defined limit.

The goal is not just to measure once, but to install a persistent monitoring mechanism in the repository so regressions are caught automatically. Treat it like gardening — continuously maintain, don't let it drift.

### 7. Five-Subsystem Score

Score each subsystem 1-5 based on evidence gathered in Step 0. Fix the lowest first.

| Subsystem | What to check | Score |
|---|---|---|
| Instructions | CLAUDE.md/rules/ quality, progressive disclosure, routing not dumping | 1-5 |
| State | feature_list.json, progress.md, session-handoff. Can a new session resume? | 1-5 |
| Verification | Tests, lint, typecheck, E2E. Can the agent prove its work? | 1-5 |
| Scope | WIP=1 enforced? Definition of done explicit? | 1-5 |
| Lifecycle | init.sh, clean-state checklist, handoff procedure | 1-5 |

5=exemplary, 4=good with gaps, 3=adequate, 2=weak, 1=missing.
**Bottleneck = lowest score. Focus improvement there.**

### 8. Present findings

**Subsystem Scores** — table with 5 scores and bottleneck identified

For each category (Guides, Sensors, Security, Closing the Loop, Harnessability):

**Covered** — controls that are in place, with type (computational/inferential). Cite which file contains the evidence.
**Gap** — missing controls, with suggestion
**Weak** — controls that exist but can be bypassed or are incomplete

Present as tables. Wait for user approval before making changes.

## Principles

- Agent = Model + Harness. Everything except the model is harness.
- Both Guides AND Sensors are needed. One without the other is incomplete.
- Computational > Inferential for reliability. Use inferential for what computational can't catch.
- Keep quality left. Fastest feedback at the earliest stage.
- Constraints > instructions. Pre-commit that blocks is stronger than CLAUDE.md that asks.
- Harnessability varies. Legacy codebases need harness most but support it least.
- Garbage collection. Deterministic steps (build, test, lint, install) run repeatedly. Set thresholds, monitor, emit signals when exceeded, and fix. Don't let drift accumulate — maintain continuously, like gardening.
