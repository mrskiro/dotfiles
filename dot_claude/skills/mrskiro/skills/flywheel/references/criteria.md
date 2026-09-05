# Proposal Criteria

How to convert detected signals into actionable improvement proposals.

## Improvement target priority

```
test/lint > hook > .claude/rules/ > docs/ > CLAUDE.md
```

| Target | When to use | Rationale |
|---|---|---|
| test/lint | Issue is mechanically detectable/preventable | Tests fail loudly — self-enforcing |
| hook | Can auto-check before/after tool execution | Does not depend on human attention |
| .claude/rules/ | Scoped to specific file patterns | Injected fresh via `paths`. Higher fidelity than CLAUDE.md |
| docs/ | Needs multi-line explanation | Discoverable via grep. CLAUDE.md holds only pointers |
| CLAUDE.md | None of the above apply | 200-line cap. Effectiveness degrades in later context |

## Proposal filters

### Do NOT propose for

- **One-off events**: issues that won't recur. Exclude patterns appearing in only 1 session
- **Already addressed**: similar rule exists in CLAUDE.md or rules/
- **Model limitations**: root cause is model capability, not missing rules

### Proposal format

- **Constraints > instructions**: "X is prohibited" not "please do X"
- **Be specific**: not "improve CLAUDE.md" but "add 'Biome config path is X' to ## Rules in CLAUDE.md"
- **Include evidence**: cite which data triggered the proposal (e.g., "same path specified in 3 sessions")

## Unused skill judgment

- 0 usage in analysis period → candidate
- Exclude:
  - Recently created skills (< 2 weeks old)
  - Condition-specific skills (CI fix, review fix, etc.) — low frequency is normal
- Propose "consider improving trigger, merging, or removing" — never "delete this"
