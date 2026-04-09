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

Interview one question at a time. For each question, provide your recommended answer based on codebase exploration. Use `AskUserQuestion` with concrete options so the user can select rather than type.

Focus on decisions that affect implementation direction:
- What is the right data model / schema change?
- Where does this logic belong? (which layer, module, file)
- What existing patterns should this follow?
- What should this NOT do? (scope boundaries)

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

## Principles

- **Explore before asking**. If the codebase has the answer, read it. Don't ask the user what you can discover.
- **Vertical slices over horizontal**. Each task should be demoable on its own.
- **HITL/AFK is explicit**. Every task is classified. AFK tasks can be dispatched to background agents.
- **Decisions before implementation**. Resolve design questions upfront so implementation doesn't stall.
- **Lightweight by default**. No PRD, no user stories unless the user asks. Just goal → decisions → tasks.
- **[HUMAN]** markers indicate where human judgment is currently required. As models improve, these points can be automated.

## Integration

- After plan approval: implement tasks, then `/ship` to deliver
- Design decisions worth preserving: `/codify` to docs/ or rules/
- Cross-model review of implementation: `/review`
