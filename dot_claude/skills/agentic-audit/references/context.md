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

**Two distinct baselines — do not conflate them:**
- **Claude Code harness system prompt** (PRIMARY for CLAUDE.md): this is the surface CLAUDE.md is actually loaded into. It is already loaded in the active session — read it there rather than asking the user for a paste. Holds the operative rules on confirmation ("hard-to-reverse or outward-facing → confirm first"), tone, executing-with-care. Do not go looking for section names you remember; the set changes between releases, and a section you cannot find may have been folded into another rather than dropped.
- **The model's published system prompt** (SECONDARY / reference): Anthropic's published prompt for the model on first-party surfaces — https://platform.claude.com/docs/en/release-notes/system-prompts . A *different product's harness* from Claude Code, so treat it as a style reference and a read on the model's baseline character, not a source of rules for this one.

**Generation discipline (re-derive every model bump):**
- Stamp every finding with the **date and the generation you audited on** — the Claude Code version and the model the session is running, read from the session rather than recalled. Built-in prompts change on the order of weeks, so an unstamped finding cannot be re-checked later.
- **Do not hardcode tag names or version numbers into this file.** Structure shifts between generations: a tag can be renamed, or folded into another, without the guidance itself changing. Enumerate the prompt fresh each audit; don't trust a stale one-line summary (force the fetch to list every heading).
- **The newest model's published prompt may not exist yet** — it lags release by weeks. When absent, fall back to the Claude Code harness prompt (self-visible); that, not the consumer prompt, is what actually governs CLAUDE.md.

**Common overlaps to flag:**
- "KISS / YAGNI / Don't over-engineer" → Claude Code has "Don't add features...beyond what the task requires"
- "No error handling for impossible scenarios" → Claude Code has this verbatim
- "Don't add comments explaining what code does" → Claude Code has "Default to writing no comments"
- "Avoid backwards-compatibility hacks" → Claude Code has this

**Conflicts to flag (let user decide which wins).** The pairs below are shapes to
recognise, quoted from prompts of the day rather than the one you are running —
confirm the built-in still says its half before reporting the conflict:
- "Always confirm before acting" (CLAUDE.md) vs "make a reasonable attempt now, not interviewed first" (model baseline). Note: the Claude Code harness already scopes confirmation to *hard-to-reverse / outward-facing* actions, so a broad "always confirm" is stricter than both baselines — and "whether to stop" is really the **permission mode (auto mode)**'s job, not CLAUDE.md's.
- "Caution over speed" vs "Throughput over perfection" — internal CLAUDE.md inconsistency (same author). Resolve by scoping confirmation to irreversible/outward only; the two stop conflicting once scoped.
- "Stop when confused" (CLAUDE.md) vs "see it through to a complete answer rather than stopping partway" (model baseline)

**Process:**
1. Get current built-in prompts (Claude Code session start + chat model release notes)
2. For each CLAUDE.md line, check if it's duplicated by built-in → mark "Redundant with built-in"
3. Check for items contradicting built-in → present the trade-off, let user decide which wins
4. Note: this check should be redone whenever Claude Code or the model is updated (built-in prompts change)

## Placement & load behavior

**Where a project CLAUDE.md can live (both official, equal priority):**
- `./CLAUDE.md` (repo root) — most discoverable to humans / other tools; conventional, the AGENTS.md-style entry point.
- `./.claude/CLAUDE.md` — co-located with `rules/`, `skills/`, `settings.json`; keeps root clean.

**Load order** (broadest → most specific; concatenated, not overridden): managed policy → `~/.claude/CLAUDE.md` (user) → project (`./CLAUDE.md` or `./.claude/CLAUDE.md`) → `./CLAUDE.local.md`. Directories *above* cwd load in full at launch; subdirectory files load on demand.

**Loaded in full regardless of length.** A long CLAUDE.md is not truncated — it is all injected, just with degraded adherence. "Size" is an *adherence* budget, not a load cap. (Contrast: auto memory's `MEMORY.md` loads only its first 200 lines / 25KB.)

**`@import` does NOT save context.** Imported files are expanded and loaded in full at launch. Imports help organization, not token cost. The only true reducers: **determinism** (→ hook, leaves context entirely) and **path-scoping** (→ rules with `paths`, load only when relevant). Relocating always-on prose from CLAUDE.md to a no-paths rule or a near-always-read child file is filing, not saving.

**`<!-- HTML comments -->` are stripped before injection** (outside code blocks) — use for maintainer notes at zero token cost.

## CLAUDE.md structure

**Map (good):**
- Under ~200 lines (Anthropic official memory docs; OpenAI ~100). Adherence degrades past ~80 lines, collapses well before 200
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

## Monorepo & nested CLAUDE.md

- **Parent dirs load at launch; a subdirectory's `CLAUDE.md` loads on demand** when Claude reads a file in that dir. Put app-specific guidance in `apps/<app>/CLAUDE.md` so it loads only when working there.
- Root CLAUDE.md should hold only **cross-cutting / monorepo-wide** facts; push app-specific commands down to the app's CLAUDE.md.
- **Don't create a child file that just relocates duplication.** If the content already lives in README / docs/ / a path-scoped rule, the fix is to *delete* from root, not copy it into a child (a child file is still loaded; moving duplication ≠ removing it).
- `claudeMdExcludes` (settings) skips ancestor CLAUDE.md files from other teams that aren't relevant.
- **Audit for**: per-app conventions stuck in root; a child CLAUDE.md duplicating root/README; "split" PRs that relocate instead of dedupe.

## Auto memory (second memory system)

Since Claude Code v2.1.59, a parallel store Claude writes itself: `~/.claude/projects/<project>/memory/MEMORY.md` (+ topic files). The first 200 lines / 25KB of `MEMORY.md` load every session — competing for the same budget as CLAUDE.md.

- A context-quality audit must inspect `MEMORY.md` too, not just CLAUDE.md. Stale/duplicated auto-memory is also dead weight.
- CLAUDE.md (you write) vs auto memory (Claude writes): don't duplicate. If Claude keeps re-learning the same thing, promote it to CLAUDE.md and prune the auto-memory copy.
- Both are advisory context, not enforcement — neither replaces a hook.

## AGENTS.md interop

Claude Code reads `CLAUDE.md`, not `AGENTS.md`. If a repo uses `AGENTS.md` for other agents, don't maintain two — have `CLAUDE.md` `@AGENTS.md`-import it (or symlink), then append Claude-specific notes. Flag repos where both exist and diverge.

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
| `Always confirm before acting` | **Conflicts with built-in** | Model baseline: "make a reasonable attempt now". The harness already scopes confirm to irreversible/outward, and "whether to stop" is the permission mode's job. Choose intentionally |

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

- **Anthropic official — best practices** (code.claude.com/docs/en/best-practices): ✅Include / ❌Exclude table; litmus "would removing this cause Claude to make mistakes?" (verified 2026-06)
- **Anthropic official — memory** (code.claude.com/docs/en/memory): placement options, under-200-lines, load order, nested/monorepo loading, auto memory, `claudeMdExcludes`, AGENTS.md interop, HTML-comment stripping, `@import` semantics (verified 2026-06)
- OpenAI: AGENTS.md ~100 lines, map not encyclopedia, progressive disclosure
- SWM: growth → move to skills/docs, CLAUDE.md becomes TOC
- learn-harness-engineering: 200 lines max, Lost in the Middle effect
- Bassim: same direction as OpenAI
