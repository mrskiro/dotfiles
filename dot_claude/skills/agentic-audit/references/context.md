# Context Quality — Reference

## Concept

Context is a scarce resource — the "attention budget" of a transformer (n² pairwise relationships). CLAUDE.md is injected at session start and degrades as the window fills (context rot). Every token must earn its place.

**Context engineering** (Anthropic): "finding the smallest set of high-signal tokens that maximize the likelihood of a desired outcome." Each turn, decide what enters and what doesn't. As models improve, smarter models require *less* prescriptive engineering.

## Just-in-time context (the 2026 default)

Instead of pre-processing all relevant data upfront, agents maintain **lightweight identifiers** — file paths, stored queries, web links, table descriptions — and use tools to load data on demand at runtime. Folder hierarchies, naming conventions, and timestamps become signals (`test_utils.py` in `/tests` implies different purpose than the same name in `/src/core_logic/`).

A hybrid strategy is often best: some context preloaded (CLAUDE.md), the rest discovered through exploration (glob, grep, just-in-time file reads).

When auditing, ask: is the agent forced to swallow large blobs upfront, or given lightweight indices + the means to navigate?

## Long-horizon context techniques

For tasks that exceed a single context window:

1. **Compaction** — summarize older messages and reinitialize with the summary. Native compaction now exists server-side. `PreCompact` hooks can save artifacts before, `PostCompact` after. The lightest touch: tool result clearing.
2. **Structured note-taking** (agentic memory) — agent writes notes to disk outside context. NOTES.md / SQLite / `${CLAUDE_PLUGIN_DATA}`. Anthropic's memory tool gives agents a file-based memory store; **dreaming** scheduled processes review past sessions and curate memories between runs.
3. **Sub-agent architectures** — specialized sub-agents with fresh context handle focused tasks. Lead coordinates; sub-agents return only condensed summaries (1-2K tokens). Sub-agents can nest up to 5 levels deep.
4. **Initializer + Coding agent split** (Anthropic's long-running harness) — first session writes `init.sh`, `claude-progress.txt`, a JSON feature list (all initially "failing"), and an initial git commit. Every subsequent session: run `pwd`, read progress + git log + feature list, choose ONE highest-priority unfinished feature, commit + update progress. JSON over Markdown (less likely to be overwritten).

## Context forking (rewind / branch / preserve)

Treat the context window as a downwards-growing stack: push/pop only at user-message boundaries. Random access in the middle is forbidden (cache misses, breaks agent's internal file-tracking state).

Three uses, built into modern CLIs (Claude Code `/rewind` / Esc-Esc):
1. **Rewind to course-correct** — agent missed something
2. **Fork to explore design paths** — accumulate research, then fork into multiple architectures
3. **Fork to salvage context** — after a 40K-token blob enters context, rewind and approach differently

## Code as harness (the most important context)

Joshi via Fowler: "well-structured code with abstractions forming a well-defined vocabulary itself acts as the most important part of the harness and context." When code has stable abstractions with clear semantics, you can swap LLM models freely and stop worrying about prompt precision.

**Cognitive debt** (Joshi, arxiv:2603.22106): words/abstractions/structures used without their meaning being understood. LLMs amplify this — they generate plausible code with familiar-looking structures that compiles and passes basic tests, but the team doesn't understand the conceptual model behind them. **Generative debt** (Voronin via Fowler): cruft the model reproduces because it sees it as precedent.

Audit signal: does the codebase teach the agent its vocabulary, or does the agent have to invent one?

## VibeSec: security context file pattern

For things that absolutely must not happen (no public buckets, no excessive token permissions, no secrets in code), prompt instructions are not enough — under pressure / injection / ambiguity, the model can ignore them.

The **security context file** (Thoughtworks via Fowler) is a structured rules document loaded into every session by default, versioned, reviewed like code, and paired with deterministic gates (SAST, credential scanning, infra validation). Audit: when something dangerous must not happen, is the rule backed by a deterministic gate, or only by prompt prose?

## 4 conversation registers (Chelsea Troy via Fowler)

When auditing CLAUDE.md and skills, distinguish which register each piece is written for:
- **Exploring** — "I want to understand before touching anything"
- **Brainstorming** — "Generate options, I'll evaluate them separately"
- **Deciding** — "I need a recommendation with a rationale, not a list"
- **Implementing** — "The decision is made, help me build it"

A CLAUDE.md that conflates all four registers creates whiplash. Register-changes warrant new conversations with fresh context.



## CLAUDE.md litmus test

For each line, apply these questions in order:

**Delete if:**
| Question | Reason |
|---|---|
| Is this already in Claude Code's built-in system prompt? | Built-in is source of truth; CLAUDE.md duplication is dead weight |
| Is this in the current chat model's system prompt (Opus/Sonnet/Haiku)? | Already enforced when using that model |
| Standard training-level knowledge? | Conventions don't need stating |
| Is this enforced by a hook or linter? | Hook is source of truth |
| Only applies to specific file types/paths? | **Move to `.claude/rules/`** with `paths` |
| Inferable by reading code or config? | One `ls` or `cat` away |
| A long explanation or tutorial? | Move to docs/, keep pointer |
| Info that changes frequently? | Will go stale |

**Keep if:**
| Question | Reason |
|---|---|
| A build/test/deploy command? | Claude can't guess project-specific commands |
| A pointer to docs/, rules/, ADR/? | Pointers are cheap (1 line) |
| A non-obvious gotcha? | Prevents repeated mistakes |
| A project convention that differs from defaults? | Claude will assume defaults otherwise |
| An architectural decision or boundary? | "Always do / Ask first / Never do" |
| A dev environment quirk? | Env vars, startup prerequisites |
| A constraint that can't be enforced by hooks or system prompts? | "Constitutional" rules (Block: constitutions, not suggestions) |

## System prompt redundancy check

Claude Code's built-in system prompt and chat model system prompts evolve. CLAUDE.md items duplicating these become dead weight.

**Sources to check:**
- **Claude Code built-in system prompt**: visible at session start in the active session — ask the user to paste the relevant sections (especially "Doing tasks", "Tone and style", "Executing actions with care") if they aren't already in context
- **Chat model system prompt** (Opus 4.7, Sonnet 4.6, etc.): https://platform.claude.com/docs/en/release-notes/system-prompts — ask the user to fetch the latest if relevant

**Common overlaps to flag:**
- "KISS / YAGNI / Don't over-engineer" → Claude Code has "Don't add features...beyond what the task requires"
- "No error handling for impossible scenarios" → Claude Code has this verbatim
- "Don't add comments explaining what code does" → Claude Code has "Default to writing no comments"
- "Avoid backwards-compatibility hacks" → Claude Code has this

**Conflicts to flag (let user decide which wins):**
- "Always confirm before acting" (CLAUDE.md) vs "Make a reasonable attempt now, not interviewed first" (Opus 4.7 chat `<acting_vs_clarifying>`)
- "Caution over speed" (CLAUDE.md) vs "Throughput over perfection" (CLAUDE.md own existing principle) — same author may have inconsistencies
- "Stop when confused" (CLAUDE.md) vs "see it through to a complete answer rather than stopping partway" (Opus 4.7 chat)

**Process:**
1. Get current built-in prompts (Claude Code session start + chat model release notes)
2. For each CLAUDE.md line, check if it's duplicated by built-in → mark "Redundant with built-in"
3. Check for items contradicting built-in → present the trade-off, let user decide which wins
4. Note: this check should be redone whenever Claude Code or the model is updated (built-in prompts change)

## CLAUDE.md structure

**Map (good):**
- ~100 lines (OpenAI recommendation)
- Pointers to docs/, ADR/, schema files
- Build/test/deploy commands
- Non-obvious gotchas only
- Progressive disclosure: overview → deeper docs on demand

**Encyclopedia (bad):**
- 300+ lines of inline explanations
- File-by-file descriptions of codebase
- Standard conventions Claude already knows
- Information that changes frequently
- Long tutorials or guides

## Rules scoping

`.claude/rules/` with `paths` frontmatter are injected when matching files are first accessed. This means:
- Fresher position in context (less affected by context rot)
- Only loaded when relevant (saves tokens)
- Rules should have `paths` when they apply to specific directories or file types

Check for:
- Rules in CLAUDE.md that should be in `.claude/rules/`
- Rules in `.claude/rules/` missing `paths` frontmatter
- Redundancy between CLAUDE.md and rules/

## Missing pointers

CLAUDE.md should point to discoverable resources:
- `docs/` directory
- `ADR/` or `adr/` directory
- README.md, CONTRIBUTING.md, ARCHITECTURE.md
- Schema files, API specs
- Design documents

If these exist but CLAUDE.md doesn't mention them, the agent won't discover them.

## Hook vs CLAUDE.md decision

- Can it be checked mechanically? → **Hook** (deterministic, always runs)
- Applies to specific paths only? → **rules/** (loaded when relevant, fresher context position)
- Requires judgment across all files? → **CLAUDE.md** (always loaded, but degrades over time)
- Reliability order: **Hook > Linter > rules/ > CLAUDE.md**

## Output format

For each CLAUDE.md file audited, classify every line/block into one of these categories and present as a table:

| Line/Block | Action | Reason |
|---|---|---|
| `pnpm test` | **Keep** | Build command, not inferable |
| `Use arrow functions` | **Delete** | Biome enforces this |
| `Don't add features beyond requested` | **Redundant with built-in** | Claude Code system prompt covers this |
| `Admin routing conventions` | **Move to rules/** | Only applies to apps/admin/ |
| `No pointer to docs/testing.md` | **Missing** | Existing doc not discoverable |
| `Format with biome` | **Convert to hook** | Should be PostToolUse, not CLAUDE.md |
| `Always confirm before acting` | **Conflicts with built-in** | Opus 4.7 chat: "make a reasonable attempt now". Choose intentionally |

Categories:
- **Delete** — doesn't pass litmus test
- **Redundant with built-in** — duplicated by Claude Code or chat model system prompt
- **Conflicts with built-in** — contradicts a built-in instruction; flag for explicit user choice
- **Move to rules/** — should be path-scoped with `paths` frontmatter
- **Convert to hook** — should be mechanically enforced
- **Keep** — earns its place
- **Missing** — something the project has but CLAUDE.md doesn't point to

For rules/ audit, present as:

| Rule file | paths? | Issue |
|---|---|---|
| admin-design-system.md | ✅ paths: apps/admin/** | OK |
| gitnexus.md | ❌ no paths | Should scope to refactoring contexts |

## Sources

- OpenAI: AGENTS.md ~100 lines, map not encyclopedia, progressive disclosure
- SWM: growth → move to skills/docs, CLAUDE.md becomes TOC
- learn-harness-engineering: 200 lines max, Lost in the Middle effect
- Bassim: same direction as OpenAI
