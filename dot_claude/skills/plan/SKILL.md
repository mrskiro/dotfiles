---
name: plan
description: >
  "計画して" "plan" "設計して" "何から始める" "分解して" "タスク分解" —
  Turn a goal into an actionable implementation plan. Interviews to resolve
  design decisions, decomposes into vertical slices, classifies HITL/AFK,
  and outputs a plan Markdown ready for implementation or dispatch.
---

# Plan

Turn a goal or feature request into an actionable implementation plan through structured exploration.

## Process

### 1. Understand the goal

Ask: "What do you want to achieve?" If already stated, confirm understanding in one sentence.

Then explore the codebase to understand the current state relevant to this goal. Do not ask the user what the user can discover from code.

### 2. Interview to resolve design decisions

**One question at a time** — the Interrogatory LLM pattern (Harper Reed via Fowler). The agent must be reminded of this often; it tends to drift toward bundled multi-questions. The user's bandwidth is the bottleneck — pile-on questioning kills the throughput the rest of the pipeline depends on.

For each question, provide your **recommended answer based on codebase exploration**. Use `AskUserQuestion` with concrete options so the user can select rather than type. This is the Henry v1.3.0 / Anthropic-best-practices pattern: don't make the user generate the answer from scratch — propose, let them confirm or redirect.

Focus on **strategic** decisions that affect implementation direction. Karpathy's split is the load-bearing one: the user owns spec design and oversight; the agent handles tactical decomposition. So ask about:

- What is the right data model / schema change?
- Where does this logic belong? (which layer, module, file)
- What existing patterns should this follow?
- What should this NOT do? (scope boundaries)

**Do NOT ask** about tactical decisions the agent can make on its own:
- Which file to update first
- What to name the variable
- Which test framework to use (when the project already has one)
- Commit message wording

Pile-on A/B/C/D choices on tactical decisions is throughput-killing and well-documented as an anti-pattern in autonomous loops (Shogun: "戦国時代なら切腹"). Decide, don't ask.

Stop interviewing when:
- The user says "enough" or "let's go"
- All branches of the design tree have been resolved
- Remaining decisions can be made during implementation without risk

### 3. Define the plan

Output a plan with these sections:

**Goal**: one sentence.

**Design decisions**: durable decisions resolved in Step 2. These survive implementation changes.

**Tasks**: decomposed as vertical slices (tracer bullets). Each task cuts through all layers end-to-end, not horizontal slices of one layer.

For each task:
- **What to build**: end-to-end behavior, not layer-by-layer steps
- **Done when**: verifiable acceptance criteria
- **Type**: HITL (needs human judgment during implementation) or AFK (can be dispatched autonomously)
- **Blocked by**: dependencies on other tasks, if any

**Out of scope**: what this plan explicitly does NOT cover.

### 4. Review with user

Present the plan. Ask:
- Does the granularity feel right?
- Any tasks that should be split or merged?
- Are the HITL/AFK classifications correct?

Iterate until approved.

### 5. Proceed

Once the plan is approved, invoke `/ship` with the plan. `/ship` handles implementation, review, and merge autonomously.

## Register awareness

Chelsea Troy (via Fowler) distinguishes four conversation registers, and plan-time sits in a specific one:

- **Exploring** — "I want to understand before touching anything"
- **Brainstorming** — "Generate options, I'll evaluate them separately"
- **Deciding** — "I need a recommendation with a rationale, not a list" ← *plan's register*
- **Implementing** — "The decision is made, help me build it"

This skill operates in **Deciding**. Don't dump every option you considered ("here are 5 schemas you could use") — give the recommendation with reasoning. If the user shifts to Implementing mid-conversation, that warrants a fresh session — say so and hand off via /ship.

## Principles

- **Explore before asking**. If the codebase has the answer, read it. Don't ask the user what you can discover.
- **One question at a time** with a recommendation attached (Interrogatory LLM + Henry's module-progressive pattern).
- **Strategic vs tactical** is the bright line. Strategic = user; tactical = agent decides without asking.
- **Vertical slices over horizontal**. Each task should be demoable on its own.
- **HITL/AFK is explicit**. Every task is classified. AFK tasks can be dispatched to background agents.
- **Decisions before implementation**. Resolve design questions upfront so implementation doesn't stall.
- **Lightweight by default**. No PRD, no user stories unless the user asks. Just goal → decisions → tasks. For complex specs, frozen `SPEC.md` as artifact at the end (Anthropic best practices): "Once the spec is complete, start a fresh session to execute it" — the new session has clean context focused on implementation.
- **[HUMAN]** markers indicate where human judgment is currently required. As models improve, these points can be automated.
- **Don't push the user with A/B/C/D when the agent can decide.** Strategic ≠ pile-on.

## Integration

- After plan approval: implement tasks, then `/ship` to deliver
- Design decisions worth preserving: `/codify` to docs/ or rules/
- Cross-model review of implementation: `/review`
