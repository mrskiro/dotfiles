# Context Quality — Reference

## Concept

Context is a scarce resource. CLAUDE.md is injected as a user message at session start and degrades over time (context rot). Every token must earn its place.

## CLAUDE.md litmus test

For each line, apply these questions in order:

**Delete if:**
| Question | Reason |
|---|---|
| Does Claude already know this from training? | Standard conventions don't need stating |
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
| A constraint that can't be enforced by hooks? | "Constitutional" rules (Block: constitutions, not suggestions) |

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
| `Admin routing conventions` | **Move to rules/** | Only applies to apps/admin/ |
| `No pointer to docs/testing.md` | **Missing** | Existing doc not discoverable |
| `Format with biome` | **Convert to hook** | Should be PostToolUse, not CLAUDE.md |

Categories:
- **Delete** — doesn't pass litmus test
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
