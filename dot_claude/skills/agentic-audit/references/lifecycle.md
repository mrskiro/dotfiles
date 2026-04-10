# Lifecycle Controls — Reference

## Concept

Controls should be distributed across the development lifecycle according to speed, cost, and criticality (Fowler: "Keep Quality Left"). The earlier you catch issues, the cheaper they are to fix.

## Speed thresholds

| Step | Threshold | Notes |
|---|---|---|
| PostToolUse hooks | < 5s | Single-file lint/typecheck. Slower = agent edit cycle degrades |
| Pre-commit | < 30s | Full lint + typecheck + fast tests. Slower = commit friction |
| Full build loop | < 1 min | build + test + lint + typecheck (Lopopolo) |
| CI pipeline | < 5 min | Full test suite + review |

If a step exceeds its threshold, flag it and propose monitoring.

## What belongs at each stage

### Every edit (PostToolUse, ms)
- Single-file lint/format (computational, fast)
- Type error detection on edited file
- Readability checks (inferential, lightweight)
- Generated code write protection

### Every commit (pre-commit, seconds)
- Full lint + format
- Type checking (all affected packages)
- Fast test suite (bail on first failure)
- i18n / schema consistency checks

### Every PR (CI, minutes)
- Comprehensive test suite
- Structural/architectural checks
- Review agents (cross-model or specialized)
- Security scanning
- Breaking change detection

### Continuous (scheduled)
- Dead code detection
- Dependency vulnerability scanning
- Performance regression monitoring
- Documentation drift detection

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
