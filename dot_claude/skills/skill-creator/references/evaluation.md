# Skill Evaluation

Two complementary axes:

1. **Trigger evaluation** — does the skill activate on the right prompts?
2. **Output quality evaluation** — does the activated skill produce better
   results than no skill (or the previous version)?

## Contents

- [Trigger evaluation](#trigger-evaluation)
- [Output quality evaluation](#output-quality-evaluation)
- [Iterating with a fresh agent](#iterating-with-a-fresh-agent)
- [Multi-model testing](#multi-model-testing)

## Trigger evaluation

Build ~20 queries: 8-10 should-trigger and 8-10 should-NOT-trigger. The
strong negative cases are **near-misses** — prompts that share keywords or
concepts but actually need a different solution.

```json
[
  {"query": "I have a CSV with revenue in col C — add a profit margin column", "should_trigger": true},
  {"query": "what's the quickest way to convert this json file to yaml", "should_trigger": false}
]
```

Run each query 3 times; compute trigger rate. Pass threshold: 0.5.

Split into train (~60%) / validation (~40%) and only use train failures to
guide changes — otherwise you overfit. 5 iterations is usually enough.

If under-triggering: broaden scope, add context phrasing, list indirect
references. If over-triggering: add specificity about what the skill does
*not* do; clarify the boundary with adjacent skills. Don't paste exact
keywords from failing queries — that's overfitting; generalize the
category instead.

Debug shortcut: ask the agent "When would you use the [skill-name]
skill?" — it quotes the description back. The mismatch tells you what to
fix.

## Output quality evaluation

Run each test case **with skill** and **without skill** (or vs the previous
version) in clean contexts. Subagents work well — each starts with no
authoring context. Capture timing per run:

```
workspace/iteration-1/
├── eval-name/
│   ├── with_skill/    { outputs/, timing.json, grading.json }
│   └── without_skill/ { outputs/, timing.json, grading.json }
└── benchmark.json
```

`timing.json` per run: `{ "total_tokens": ..., "duration_ms": ... }`.

**Add assertions after the first run**, not before — you don't know what
"good" looks like until you've seen output.

Good assertions are observable and specific:

- ✅ "The output is valid JSON"
- ✅ "The chart has labeled axes"
- ❌ "The output is good" (too vague)
- ❌ "Uses exactly the phrase 'Total Revenue: $X'" (too brittle)

Compute delta in `benchmark.json`: pass-rate gain vs token / time cost. A
skill that adds 13s for +50pp pass rate is worth it; doubling tokens for
+2pp probably isn't.

When iterating, scan patterns:

- Always-pass in both → drop the assertion (no signal)
- Always-fail in both → fix or replace
- Pass with-skill / fail without → real value, study why
- High stddev → ambiguous instructions, tighten with examples
- Time/token outliers → read the transcript

For comparing two skill versions, use **blind comparison** — present both
outputs to a judge model without revealing which version produced which.

## Iterating with a fresh agent

Author the skill with one agent (call it A); run real tasks with a fresh,
separate instance (B) that has only the skill loaded — no authoring
conversation, no shared context. B reveals where the skill silently relied
on context only A had.

Bring B's failures back to A:

> "When B was asked for a regional report, it forgot to filter test
> accounts even though the skill mentions filtering. Maybe the rule isn't
> prominent enough."

A proposes structural fixes. Re-run with B. Repeat.

While running, watch how B navigates the skill:

- Unexpected exploration order → structure isn't intuitive
- Missed references → make links imperative ("Read X" not "see X")
- Repeated re-reads of one file → that content might belong inline
- Ignored bundled files → unsignaled or unnecessary
- Wasted steps on vague instructions → tighten or remove

Tune from observed behavior, not assumptions.

## Multi-model testing

Test against every model the skill will run on. Stronger models tolerate
sparse instructions; weaker ones need more detail and explicit structure.
What works on a frontier model may underperform on a smaller one. The
weakest model in your tier sets the floor.
