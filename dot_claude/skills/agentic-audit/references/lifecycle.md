# Lifecycle Controls — Reference

## Concept

Controls should be distributed across the development lifecycle according to speed, cost, and criticality (Fowler: "Keep Quality Left"). The earlier you catch issues, the cheaper they are to fix.

## Two scorable rubrics for a 2026 audit

### LangChain 4-loop taxonomy (Loop Engineering, Jun 2026)

Grade the harness against each level. Higher loops require lower loops working.

| Loop | What it does | Concrete signals |
|---|---|---|
| **Loop 1: Agent** | Model calls tools repeatedly until task complete | `create_agent` / Claude Code itself / any tool-using agent loop |
| **Loop 2: Verification** | Grader checks output against rubric, retries with feedback if it fails | `/goal` condition, `RubricMiddleware`, `after_agent` hook, Anthropic Outcomes — agent self-evaluates against criteria, loops until satisfied or max_iterations |
| **Loop 3: Event-driven** | Cron / webhook / file-watch fires the agent | Routines (cloud cron), `/loop` (in-session), GitHub Actions, Channels, monitors. Agent runs continuously inside larger system |
| **Loop 4: Hill-climbing** | Trace analysis agent rewrites the harness itself | LangSmith Engine, OpenAI Codex-driven improvement loop, dreaming. Production traces → named issues → diagnosed root cause → drafted PR + new evaluator + offline eval dataset |

Level-4 is where value compounds. Most harnesses don't get there. Reference: https://blog.langchain.com/the-art-of-loop-engineering

### Böckeler's sensor matrix (4 cadences × 2 modalities)

Two axes: when does it run × is it deterministic or LLM-judged. Each cell should have at least one sensor when relevant.

| Cadence | Computational (deterministic) | Inferential (LLM judgment) |
|---|---|---|
| **In-session** (ms-seconds) | Type checker, ESLint, Semgrep/SAST, dependency-cruiser, GitLeaks pre-commit | Custom-prompted lint message that gives the agent self-correction guidance |
| **Pipeline** (seconds-minutes) | Same as in-session re-run on clean infra, full test suite, mutation testing | Cross-model review, judge panel with rubric |
| **Scheduled** (hours-days) | Dependency freshness, vulnerability scan, performance regression | Security review, data-handling review, modularity/coupling review with Vlad Khononov's "Modularity Skills" pattern |
| **Runtime** (production) | Error rates, latency, log alerts | LLM-as-judge on production traces (Engine-style), user-feedback clustering |

Two key innovations from this article:

- **Self-correction guidance** — custom ESLint formatters override default messages with extra context for self-correction. A "good kind of prompt injection". Example for `no-explicit-any`: explain that the agent should make a judgment call and suppress with `// eslint-disable-next-line ... -- (reason)` if introducing a type is unnecessary.
- **Threshold-with-justification** — for max-lines / cyclomatic-complexity, allow the agent to slightly *raise* a threshold with written justification, instead of binary suppress-or-comply. Constraints are preserved while avoiding refactor lock-in.

When AI is writing your tests, coverage tells you a LINE was executed, not that its IMPACT was verified. **Mutation testing** (Stryker, etc.) is the second-order sensor that fills that gap — critical when you let agents author tests without close review.

Reference: https://martinfowler.com/articles/sensors-for-coding-agents.html

## Speed thresholds

| Step | Threshold | Notes |
|---|---|---|
| PostToolUse hooks | < 5s | Single-file lint/typecheck. Slower = agent edit cycle degrades |
| Pre-commit | < 30s | Full lint + typecheck + fast tests. Slower = commit friction |
| Full build loop | < 1 min | build + test + lint + typecheck (Lopopolo) |
| CI pipeline | < 5 min | Full test suite + review |

If a step exceeds its threshold, flag it and propose monitoring.

## What belongs at each stage

### Every edit (agentic-loop hooks, ms)

The hook event family expanded considerably in 2025-26. Beyond `PostToolUse`, projects can wire:

- `PreToolUse` — permission gates, destructive-command blocking
- `PostToolUse` — lint/format/typecheck on edits
- `PostToolUseFailure` — react when a tool fails (auto-recovery, telemetry)
- `PostToolBatch` — fire once after a batch of edits, not per-file (cheaper for slow checks)
- `PermissionRequest` / `PermissionDenied` — log friction, escalate
- `FileChanged` / `CwdChanged` — reload context-scoped rules, refresh state
- `MessageDisplay` — transform or hide assistant message text as it streams to the user (default timeout 10s — keep it fast)

Hook **execution forms** and **outputs** to know about:

- `args: string[]` exec form — spawns the command directly without a shell, so path placeholders never need quoting (use this for any hook that takes file paths — prevents injection)
- `continueOnBlock: true` on `PostToolUse` — feeds the hook's rejection reason back to Claude so the turn continues with feedback, instead of erroring out
- `terminalSequence` JSON output — emit desktop notifications, set window titles, ring the bell, even when the hook has no controlling tty
- `hookSpecificOutput.additionalContext` on `Stop` / `SubagentStop` — give the model feedback and keep the turn going without being labeled a hook error

Use the cheapest event that fits the check.

- Single-file lint/format (computational, fast)
- Type error detection on edited file
- Readability checks (inferential, lightweight)
- Generated code write protection

### Every commit (pre-commit, seconds)
- Full lint + format
- Type checking (all affected packages)
- Fast test suite (bail on first failure)
- Dead code detection — for TypeScript/JavaScript projects, recommend [knip](https://knip.dev/) if not configured
- i18n / schema consistency checks

### Every PR (CI, minutes)
- Comprehensive test suite
- Dead code detection (knip in CI as quality gate)
- Structural/architectural checks
- Review agents (cross-model or specialized)
- Security scanning
- Breaking change detection

### Continuous

Three named mechanisms, each with a distinct cadence:

- **Routines** (`claude.ai/code/routines`, `CronCreate`) — cloud-side cron / API / GitHub-triggered scheduled agents. Best for daily/weekly sweeps that don't need a local session
- **`/loop`** — in-session recurring task (self-paced or interval-bound). Best for "watch this until done" during an active session
- **Background monitors** (`monitors/monitors.json`, the `Monitor` tool) — stream events from a long-running process into the session as notifications. Best for tail-log-and-react

Apply to:
- Dependency vulnerability scanning (Routine)
- Performance regression monitoring (Routine)
- Documentation drift detection (Routine)
- Long-running build / deploy / migration watch (`/loop` or `Monitor`)
- CI run-to-completion watch (`/loop` with 4-5min cache-aware polling, or `Monitor`)

### Session boundaries

Failure-path and context-rot events that often get ignored:

- `SessionStart` / `SessionEnd` — env priming, summary capture
- `Stop` / `StopFailure` — react when the agent comes to rest or dies mid-task
- `PreCompact` / `PostCompact` — preserve state across compaction boundaries (mitigates context rot). `PreCompact` can **block compaction** by exiting `2` or returning `{"decision": "block"}`
- `SubagentStart` / `SubagentStop` — orchestration controls, idle escalation
- `TaskCreated` / `TaskCompleted` — task-graph instrumentation
- `Elicitation` / `ElicitationResult` — MCP elicitation flows

## Anti-patterns

- Expensive checks at PostToolUse (slows every edit)
- Cheap checks only in CI (feedback too late)
- No tests in pre-commit (commit ≠ verified)
- No speed monitoring (gradual degradation goes unnoticed)

## Sources

- Fowler/Böckeler: Keep Quality Left, Computational vs Inferential
- Lopopolo: build loop < 1 min, gardening
- OpenAI: custom linter error messages with repair instructions
- Stripe Minions: Blueprints (deterministic + agent nodes)
- Bassim: backpressure
