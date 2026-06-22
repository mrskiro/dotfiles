---
name: agentic-audit
description: >
  "ハーネスチェック" "harness audit" "このリポジトリどう？" "何が足りない？"
  "CLAUDE.md見直して" "ツール棚卸し" "audit" — Comprehensive agentic engineering
  audit. Checks lifecycle controls, context quality, tool coverage, security,
  and verification capabilities. Outputs a single prioritized improvement list.
---

# Agentic Audit

Diagnose a repository's readiness for agentic engineering and identify what to improve next.

This combines three concerns into one audit:
- **Lifecycle controls** — what runs when (edit/commit/PR/continuous), and is feedback fast enough?
- **Context quality** — is CLAUDE.md a map or an encyclopedia? Are rules scoped correctly?
- **Tool coverage** — can the agent act on this project's stack, or only read code that talks to it?

## Process

### 1. Gather evidence

Read the actual files before judging. Score based on what exists, not assumptions.

**Project-level:**
- `CLAUDE.md` — conventions, commands, pointers
- `.claude/settings.json` — hooks, permissions
- `.claude/rules/` — path-scoped rules (list all)
- `.claude/skills/` — project skills (list all). **Also check nested `.claude/skills/` under sub-directories**: skills there load when working on files in that subtree, and on name clashes appear as `<dir>:<name>` so both stay available
- `.claude-plugin/plugin.json` — if present, the repo packages a Claude Code plugin (skills/commands/agents/hooks/monitors/lsp distributable via marketplace)
- `monitors/monitors.json` — background monitors (continuous-feedback tools that stream into the session)
- `.lsp.json` — LSP plugin definitions (agent code intelligence)
- `lefthook.yml` / `.husky/` — pre-commit config
- `tsconfig.json` / `biome.jsonc` / linter configs — type checking, lint strictness
- `.github/workflows/` — CI pipelines (list and scan key ones)
- `package.json` / `go.mod` / `Cargo.toml` etc. — tech stack
- `.mcp.json` — MCP connections
- `docs/` / `ADR/` — documentation that agents should discover

**Global-level:**
- `~/.claude/settings.json` — global hooks, deny list, permission mode
- `~/.claude/skills/` — global skills (list)

### 2. Lifecycle controls

**Before evaluating lifecycle controls, read `references/lifecycle.md`.**

Organize every control by **when it runs**.

| Stage | What to look for |
|---|---|
| **Every edit** (agentic-loop hooks: PreToolUse / PostToolUse / PostToolUseFailure / PostToolBatch) | lint, format, typecheck hooks; permission gates |
| **Every commit** (pre-commit) | lint, format, typecheck, test |
| **Every PR** (CI) | test suite, review agents, structural checks |
| **Continuous** (Routines / `/loop` / monitors) | dead code, dependency scanning, metrics, log tail-to-notification |
| **Session boundaries** (SessionStart / Stop / StopFailure / PreCompact / PostCompact) | env priming, context-rot mitigation, idle-state escalation |

For each stage: what's present, what's missing, any speed concerns.

Report as **one row per stage** — group all controls into a single cell per stage.

### 3. Context quality — including mechanism-choice audit

**Before evaluating context quality, read `references/context.md`.**

**Mechanism-choice audit** (from Anthropic's "Steering Claude Code" guide). For each CLAUDE.md item, flag wrong-mechanism anti-patterns:

| Pattern in CLAUDE.md | Should actually be | Why |
|---|---|---|
| "Every time X, always do Y" | Hook (`PostToolUse` / `PreToolUse`) | Instructions are advisory; hooks are deterministic |
| **"Never do X"** | Hook (exit 2) + Permission rule | Under prompt injection / long sessions / ambiguity, the model can fail to follow a prompted rule. Real guardrails must be deterministic. **Managed settings** for org-wide unbreakable enforcement |
| 30-line procedural runbook | Skill (`.claude/skills/`) | Procedures belong in skills that load only when invoked. CLAUDE.md is for facts (build commands, layout, conventions) |
| API-specific or path-specific rule without `paths:` | Rule with `paths:` frontmatter | Unscoped rule wastes context during unrelated work |
| Personal preferences in project-level CLAUDE.md | User-level `~/.claude/CLAUDE.md` or `./CLAUDE.local.md` (gitignored) | Team-shared file shouldn't carry personal style |
| Subdirectory-specific conventions in root CLAUDE.md | `app/api/CLAUDE.md` (on-demand) | Loads only when touching that subtree |

Reference: https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more

**System prompt redundancy check** (do this first):
- Get the current Claude Code built-in system prompt (visible at session start; ask user to paste relevant sections if not in context)
- Get the current chat model system prompt from https://platform.claude.com/docs/en/release-notes/system-prompts (ask user to fetch if needed)
- For each CLAUDE.md item, flag duplication or conflict with built-in
- Redo this check whenever Claude Code or the model is updated — built-in prompts evolve

**CLAUDE.md litmus test** — for each line:
- In Claude Code built-in system prompt? → mark **Redundant with built-in**
- In current chat model system prompt? → mark **Redundant with built-in** (note model dependency)
- Conflicts with built-in instruction? → mark **Conflicts with built-in**, flag for user decision
- Already known from training? → delete
- Enforced by hook/linter? → delete (hook is source of truth)
- Only applies to specific paths? → move to `.claude/rules/` with `paths`
- Pointer to docs/code? → keep (pointers are cheap)
- Non-obvious gotcha? → keep

**Structure checks:**
- Is CLAUDE.md a map (pointers to deeper docs) or an encyclopedia (everything inline)?
- Are there missing pointers to existing docs/, ADR/, README?

**Rules audit** — read the frontmatter of every file in `.claude/rules/`. For each:
- Does it have `paths`? If the content only applies to specific directories/file types, it should
- Does the content overlap with CLAUDE.md, hooks, or built-in system prompts? If so, one of them should be removed
- Is the content something Claude already knows from training? If so, delete

### 4. Tool coverage

**Before evaluating tool coverage, read `references/tools.md`.**

Assess whether the agent can **act on** this project's infrastructure.

- Detect tech stack from project files
- For each external service/data store: can the agent interact with it?
- Check MCP token efficiency (too many tools? deferred loading via `ToolSearch`?)
- Check skill quality (`description` + `when_to_use` combined under 1,536 chars? trigger phrases front-loaded? `disable-model-invocation` set for side-effect skills?)
- Check whether reusable capability is packaged as a **plugin** (`.claude-plugin/plugin.json` + marketplace) — single-repo skills/commands/hooks are fine, but anything shared across repos should be a plugin

### 5. Security boundaries

Anthropic's containment doctrine ("How We Contain Claude"): three risk categories × three defense layers.

**3 risk categories** — at minimum, ask: which of these does the harness mitigate?
- **User misuse** (intentional or careless harmful direction)
- **Model misbehavior** (overeager, creative path-around, agent-inferred parameters)
- **External attackers** (prompt injection via files / pages / tool outputs)

**3 defense layers** — environment / model / external content:
- Permission mode (`defaultMode`); managed settings for org-wide unbreakable enforcement
- Auto mode (model-classifier-based command screening) vs `--dangerously-skip-permissions` (zero protection)
- Destructive command blocking (PreToolUse hooks)
- Secret/credential protection (deny list)
- Config file protection (settings.json, lefthook.yml, tsconfig.json, linter configs)
- Generated code protection (gen/ directories)
- **Parameter-level permission rules** — `Tool(param:value)` syntax (e.g. `Agent(model:opus)` to block Opus subagents, `WebFetch(domain:*.example.com)` for subdomain wildcards)
- **Hook `args:` exec form** — hooks taking file paths must use `args: string[]` (no shell interpolation), not `command:` — prevents path injection
- **MCP `disallowedTools`** — for subagents, server-level specs (`mcp__server`, `mcp__*`) work in `disallowedTools`

**Lethal trifecta scan** (Simon Willison + Meta "Rule of Two"). For each enabled MCP server / skill / agent, flag combinations of all three:
1. Access to sensitive data
2. Exposure to untrusted content (web fetch / file reads from outside / external MCP outputs)
3. Ability to communicate externally (HTTP, write to remote)

Any combination of all three with no sandbox → high risk. Mitigation: break one of the three, or sandbox with kernel-level isolation (microVM / VM).

**Sandbox layer identification**:
- macOS: Seatbelt; Linux: Bubblewrap; Cloud: gVisor (claude.ai) / full VM (Cowork)
- Reference: `anthropic-experimental/sandbox-runtime` (open source)
- Both filesystem AND network isolation required (without one, the other is bypassable)
- Credentials: vault-backed with envelope encryption + signed request token. Placeholder injected at network boundary — agent never sees raw secret

**Known-incident checks** (from Anthropic's contain-claude post):
- Does project-local config (`.claude/settings.json` hooks) execute before user trust prompt? It shouldn't
- Symlink resolution must happen **before** path validation (else symlink inside allowed dir escapes to outside)
- Allowlist treated as capability grant, not destination filter — allowing api.anthropic.com means allowing file uploads to arbitrary Anthropic accounts
- Direct prompt injection via user message: only environment-layer defenses hold (model-layer can't catch "user said it themselves")

### 6. Verification capabilities

Can the agent prove its own work?

- **Tests**: runnable? Command in CLAUDE.md?
- **Browser/Mobile verification**: what tools? CLI preferred over MCP for token efficiency
- **Log access**: runtime logs, error tracking
- **Commit as gate**: does pre-commit include tests?
- **Review separation**: is the reviewer different from the implementer? Self-evaluation is unreliable across 5 independent sources (Anthropic, Bassim, Karpathy, Osmani, LangChain Rubrics)
- **Reviewer-readable evidence schema** (Osmani): does each skill / workflow produce an output a fresh-context reviewer can scan in seconds (diff + decision log + test output + reproducible steps)?
- **Outcomes / rubric loop**: does the harness have a `/goal`-style success criterion, a `RubricMiddleware`-style grader subagent with its own tools, or a Stop-hook that gates the turn until a check passes? "Looks done" without an external pass/fail signal is the single most common failure mode
- **Multi-tool heterogeneity** (Osmani's 4-reviewer experiment): if running multiple AI reviewers, are they deliberately different in character (e.g. one for correctness, one for security)? 93% of real findings were caught by exactly ONE of 4 tools — running 4 copies of the same model gives a single reviewer with a larger invoice
- **Verifier choice**: don't use Haiku as a strict-domain verifier (48% false-pass rate on legal eval). Default to **batch verification** (one judge call for full rubric) — ~10× cheaper than per-criterion with modest accuracy loss
- **Runtime smoke** (Shogun's "Step 8"): `codd verify` green is necessary but not sufficient. Build green ≠ DB running, test green ≠ dev server running, E2E green ≠ user can actually touch the change. Audit whether the harness gates "done" on `DB up + dev server up + smoke connectivity + real-browser E2E` for the kind of change just made
- **Cost telemetry**: is per-session / per-skill cost tracked (e.g. AgentsView, ccusage, LLM gateway with per-team budgets)? An agent that burns $12 on a CSS fix invisible to the user is a real failure mode
- **Eval-awareness risk**: when using web-enabled agents on public benchmarks, treat eval integrity as an adversarial problem — model can hypothesize being evaluated, identify the benchmark, decrypt answer keys (Anthropic Opus 4.6 BrowseComp)

### 7. Codebase readiness

- Type safety (strict mode, null checks)
- Module boundaries (packages, layers, domains)
- Framework conventions (established patterns)
- Test infrastructure (runner, fixtures, CI)
- Linter error messages: are they actionable for agents? (OpenAI: include repair instructions in error messages)

### 8. Present findings

**1. Lifecycle coverage** — one table, one row per stage (Every Edit / Every Commit / Every PR / Continuous). Present column and Gap column.

**2. Context quality** — CLAUDE.md litmus test results as a table (Delete / Keep / Move to rules/ / Convert to hook / Missing per line/block). Rules/ frontmatter audit table. Missing pointers.

**3. Tool coverage** — capability gaps, token efficiency issues, skill quality issues.

**4. Security** — what's protected, what's exposed.

**5. Verification** — what loops are closed, what can't be verified. Whether review separation exists.

**6. Prioritized improvements** — top 3-5 gaps ordered by impact. For each:
  - What's missing
  - Why it matters
  - Concrete next step

Wait for user approval before making changes.

## Principles

- Computational > Inferential. Deterministic checks first, LLM judgment where computation can't reach.
- Keep quality left. Fastest feedback at the earliest stage.
- Constraints > instructions. A hook that blocks is stronger than a CLAUDE.md that asks. Prompts can be overridden by injection, long context, or ambiguity — hooks can't.
- CLAUDE.md is a map, not an encyclopedia. Pointers to code/docs, not explanations. Under 200 lines.
- "Can the agent act on this, not just think about it?" — tools expand capability, not just knowledge.
- Implementer ≠ reviewer. Self-evaluation is unreliable across multiple independent sources.
- Process over prose, evidence over claim (Osmani). Workflows with checkpoints + evidence + defined exit criteria, not essays about how to do things well.
- Match isolation strength to user's capacity for oversight (Anthropic containment). A developer who reads bash and a knowledge worker who can't are not running the same threat model.
- Design for containment at the environment layer first, then steer behavior at the model layer (Anthropic). The deterministic boundary is what gets hit when the probabilistic layers miss.
- Code itself is the most important harness and context (Joshi via Fowler). Well-structured code with stable vocabulary lets you choose any model and stop worrying about prompt precision. **Cognitive debt** — vocabulary used without understanding — is amplified by LLMs.
- Skills should only be used for deliberate, infrequent workflows (Pritchard via Fowler). Many things that look like skill candidates should be hooks, computational sensors, or improved code instead. "Reaching for configuration when you should be reaching for architecture."
- Garbage collection. Set thresholds for deterministic steps, monitor, fix when exceeded. Maintain like gardening. Also: harness assumptions don't survive model upgrades — periodically test what can be removed.
