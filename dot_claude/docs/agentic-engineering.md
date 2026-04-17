# Agentic Engineering

Background context for Claude Code sessions. Read alongside CLAUDE.md's Agent Behavior section. The goal is for any session to operate within the agentic engineering framework without needing prior context.

## Framework

Agentic engineering is the umbrella concept. Harness engineering is one element within it (Level 6 in the 8 levels below).

Workflow common structure across sources: **Plan → Implement → Review → Ship → Learn**

Orchestration progresses in three stages: establishing the workflow → orchestrating tasks within it → orchestrating the workflow itself.

### 8 Levels (Bassim Eledath)

| Level | Name | Description |
|---|---|---|
| L1-2 | Tab Complete / Agent IDE | Most engineers have passed |
| L3 | Context Engineering | Increase information density of context |
| L4 | Compounding Engineering | Accumulate learnings in CLAUDE.md/docs/ for next session |
| L5 | MCP & Skills | Give agents access to DBs, APIs, CI pipelines |
| L6 | Harness Engineering | Environment design, feedback loops, automated verification |
| L7 | Background Agents | Agents running autonomously in background |
| L8 | Autonomous Agent Teams | Agents coordinating directly |

L3-L5 must be solid before L6-L8. Otherwise automation amplifies mistakes.

Source: https://www.bassimeledath.com/blog/levels-of-agentic-engineering

## Vocabulary

- **Harness**: Everything other than the model. System prompts, tools, MCPs, skills, hooks, sandbox, orchestration logic. (Source: LangChain "Agent = Model + Harness")
- **Guides**: Feedforward controls that steer agent behavior before action. AGENTS.md, coding conventions, skills. (Source: Böckeler)
- **Sensors**: Feedback controls that observe agent output after action. Tests, linters, code review. (Source: Böckeler)
- **Computational vs Inferential**: Deterministic controls (tests, linters, type checkers) vs AI-based controls (review agents, judges). (Source: Böckeler)
- **Backpressure**: Type checks, tests, linters, pre-commit hooks that force agents to self-correct without human intervention. Test success is silent, failures only output details. (Source: HumanLayer)
- **Closing the loop**: Giving agents the ability to verify their own work — run tests, check logs, observe browser output, query databases. (Source: Peter Steinberger)
- **Meta-harness**: Designing the harness itself as a swappable foundation, so components can evolve independently as models improve. (Source: Anthropic Managed Agents)
- **Agent navigability**: "What Claude can't see doesn't exist." Knowledge in Slack threads or human heads is invisible to agents. Encode in repo. (Source: OpenAI)

## Why the principles in CLAUDE.md exist

### Close the loop
Agents that can't verify their own work require human intervention at every step. Build environments where agents can run tests, check logs, and observe outputs themselves. The slowness is not the agent's capability — it's the environment being undefined.
Sources: OpenAI Harness Engineering, Ramp Inspect, Peter Steinberger.

### Use backpressure
Linters, type checks, and tests that fail loudly and pass silently force agents to self-correct without polluting context. 4000 lines of "all tests passed" output puts agents into hallucination mode. Show only what needs action.
Sources: HumanLayer, Mitchell Hashimoto.

### Constraints > instructions
Step-by-step prompts ("do A, then B, then C") become outdated and ignored as soon as one step fails. Define boundaries and expected outcomes ("continue until all tests pass"). Trust the agent within the constraints.
Source: Bassim Eledath.

### Do not self-review
Anthropic confirmed agents praise their own clearly low-quality work confidently. Generator-Evaluator separation is needed — review must come from a different model or a different instance with a review-specific prompt.
Source: Anthropic harness-design-long-running-apps.

### Throughput over perfection
"Fixes are cheap, waiting is expensive" in systems where agent throughput far exceeds human attention. Test flakes are handled in follow-up. PRs are short-lived. Don't block forever on perfect first attempts.
Source: OpenAI, Ryan Lopopolo (Latent Space).

### What can I stop doing?
Harnesses encode assumptions about what models can't do. As models improve, those assumptions go stale. Periodically test what can be removed. The harness space shifts with model capabilities, not just shrinks.
Source: Anthropic Harnessing Claude's Intelligence.

### Repository as the system of record
What is not in the repository does not exist for the agent. Slack discussions, in-head decisions, and external documents are invisible. Encode everything that future agents (or new team members) need.
Source: OpenAI Harness Engineering.

### Prefer CLI over MCP
MCP injects all tool schemas into the system prompt every turn — high context cost, interferes with auto-compaction. Models are heavily trained on bash and CLI. The exception is multi-surface tools (same binary exposes both CLI and MCP), where MCP is fine for use cases like authenticated external services.
Sources: Lopopolo (Latent Space), HumanLayer, Justin Poehnelt.

## Primary sources

- Bassim 8 Levels: https://www.bassimeledath.com/blog/levels-of-agentic-engineering
- Böckeler Harness Engineering: https://martinfowler.com/articles/harness-engineering.html
- OpenAI Harness Engineering: https://openai.com/index/harness-engineering/
- Anthropic Harnessing Claude's Intelligence: https://claude.com/blog/harnessing-claudes-intelligence
- Anthropic Scaling Managed Agents: https://www.anthropic.com/engineering/managed-agents
- LangChain Agent Harness: https://blog.langchain.com/the-anatomy-of-an-agent-harness/
- Lopopolo Latent Space: https://www.latent.space/p/harness-eng
- Karpathy Agentic Engineering: https://thenewstack.io/vibe-coding-is-passe/
