---
name: skill-creator
description: >
  "skill作って" "スキル作りたい" "create a skill" "improve this skill" "スキル改善" "SKILL.md書いて"
  — MUST use before writing any SKILL.md or creating skills/ directories. Covers skill
  creation, improvement, and workflow-to-skill conversion following official best practices.
  Do NOT use for reading/referencing existing skills.
---

# Skill Creator

Guide the user through creating or improving a Claude Code skill.

References:
- Claude Code skills: https://code.claude.com/docs/en/skills
- Open Agent Skills spec: https://github.com/agentskills/agentskills

Claude Code skills build on the open Agent Skills format. The spec only allows these frontmatter fields: `name`, `description`, `license`, `allowed-tools`, `metadata`, `compatibility`. Fields listed below like `disable-model-invocation`, `user-invocable`, `model`, `effort`, `context`, `agent`, `paths`, `hooks` are Claude Code-specific extensions — useful here, but non-portable to other agent platforms.

## Principles

- **Concise is key.** The context window is shared. Only add what Claude doesn't already know — project conventions, non-obvious gotchas, specific tool behavior. Skip explaining concepts already in training (HTTP, PDFs, databases). Challenge each paragraph: "Does this justify its token cost?"
- **Defaults over menus.** When multiple tools or approaches work, pick one default and briefly mention alternatives. Presenting equal options makes Claude deliberate instead of act.
- **Ground in real expertise.** Extract patterns from actual tasks (user sessions, corrections, failures), not LLM general knowledge. If you can't produce a concrete example, the skill isn't ready.
- **Calibrate specificity.** Match prescriptiveness to fragility. For fragile or consistency-critical ops, be explicit. For flexible tasks, explain the reasoning — reasoning generalizes, rigid MUSTs don't.

## Process

### 1. Capture intent

If the conversation already contains a workflow to capture, extract:
- What tools were used, in what sequence
- What corrections the user made
- Input/output formats observed

Then confirm with the user. If starting fresh, ask:
1. What should this skill enable Claude to do?
2. When should it trigger? (phrases, contexts)
3. What's the expected output?
4. Where should it live? (`~/.claude/skills/` for personal, `.claude/skills/` for project)

### 2. Interview

Ask about edge cases, dependencies, and success criteria. One question at a time.

### 3. Write SKILL.md

A skill is a directory with `SKILL.md` as the entrypoint:

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── references/        # Detailed docs, loaded when needed
├── examples/          # Example outputs
└── scripts/           # Executable code for deterministic tasks
```

#### Determine skill category

Before writing, identify which category fits:
- **Document & Asset Creation** — consistent output with templates and quality checklists
- **Workflow Automation** — multi-step processes with validation gates and iterative refinement
- **MCP Enhancement** — workflow guidance on top of an MCP server (MCP = kitchen, skill = recipe)

Also decide the framing:
- **Problem-first**: user describes an outcome → skill orchestrates tools
- **Tool-first**: user has an MCP connected → skill teaches best practices

#### Frontmatter

Only `description` is strictly recommended. `name` is derived from the directory when omitted.

```yaml
---
# Spec fields (portable across agent platforms)
name: kebab-case              # max 64 chars, lowercase, must match directory name
description: >                # max 1024 chars. Truncated at 250 chars in skill listing
  "trigger1" "trigger2" "trigger3" — [what it does].
  Lead with trigger phrases. Model matches on description prefix.
license: MIT                  # concise license identifier
compatibility: "..."          # max 500 chars. Environment requirements
metadata: {key: value}        # arbitrary key-value pairs
allowed-tools: Read, Grep     # pre-approved tools while skill is active

# Claude Code extensions (non-portable)
disable-model-invocation: true  # User-only invocation. For workflows with side effects
user-invocable: false           # Claude-only invocation. For background knowledge
model: opus                     # Model override while skill is active
effort: high                    # low | medium | high | max (Opus 4.6 only)
context: fork                   # Run in subagent (isolated context)
agent: Explore                  # Subagent type when context: fork
paths: "**/*.ts"                # Auto-load only when matching files are touched
hooks:                          # Hooks active only while skill runs
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "bash ${CLAUDE_SKILL_DIR}/scripts/check.sh"
---
```

Name rules (from spec): max 64 chars, lowercase letters/digits/hyphens only, no leading or trailing hyphens, no consecutive hyphens, must match the parent directory name.

#### Writing the description

The description is the primary triggering mechanism. Four principles:

- **Imperative phrasing.** "Use this skill when..." — not "This skill does..."
- **User intent, not mechanics.** Describe what the user is trying to achieve, not the skill's internals. The agent matches on what the user asked for.
- **Explicit scope including indirect references.** List contexts where the skill applies, including cases where the user doesn't name the domain: "even if they don't explicitly mention 'CSV' or 'analysis'."
- **Lead with trigger phrases.** The model matches on the prefix. Descriptions are truncated at 250 chars in the skill listing, so keyword-dense triggers must come first.

Before → After example:
- ❌ `Process CSV files.`
- ✅ `"CSV analysis" "clean this data" — Analyze CSV/TSV/Excel data: compute stats, add columns, generate charts, clean messy data. Use when the user has tabular data and wants to explore/transform/visualize it, even if they don't explicitly say "CSV" or "analysis".`

#### Invocation control

| Setting | User | Claude | Context loading |
|---|---|---|---|
| (default) | Yes | Yes | Description always loaded; full skill on invoke |
| `disable-model-invocation: true` | Yes | No | Description NOT loaded; full skill on user invoke |
| `user-invocable: false` | No | Yes | Description always loaded; full skill on invoke |

#### Content types

**Reference content** — knowledge Claude applies to current work (conventions, patterns, domain knowledge). Runs inline alongside conversation context.

**Task content** — step-by-step instructions for a specific action. Often paired with `disable-model-invocation: true`.

#### String substitutions

| Variable | Description |
|---|---|
| `$ARGUMENTS` | All args passed to `/skill-name` |
| `$ARGUMENTS[N]` / `$N` | Nth argument (0-based) |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Skill directory path |

#### Dynamic context injection

The syntax `!` followed by a backtick-wrapped shell command runs it before the skill content is sent to Claude. The output replaces the placeholder. This is preprocessing — Claude only sees the result. Example: writing `!` then `` `date` `` would inject the current date.

#### Progressive disclosure

Three levels:
1. **Metadata** (name + description) — always in context
2. **SKILL.md body** — loaded when skill triggers
3. **Bundled resources** — loaded on demand, referenced from SKILL.md

Keep SKILL.md under 500 lines. Move detailed reference to separate files.

When referencing supporting files from SKILL.md, use imperative instructions. The model may skip passive "see" links.

```markdown
**Before this step, read `references/criteria.md`.**
```

#### Recommended content patterns

Effective skills use these patterns — include the ones that fit:

- **Gotchas.** Document environment-specific facts that contradict reasonable assumptions (soft deletes, naming inconsistencies, non-obvious endpoints). High-leverage — Claude can't know these without being told.
- **Output templates.** For skills with required formats, provide concrete templates or examples rather than describing the format in prose.
- **Validation loops.** Instruct Claude to validate work before proceeding — via a checklist, a script, or a reference file.
- **Plan-validate-execute.** For batch or destructive operations, require an intermediate plan step that the user or Claude reviews before execution.

#### context: fork

Runs in a subagent with isolated context. Requires explicit task instructions — guidelines alone without a task produce nothing. Use `agent` field to specify subagent type (Explore, Plan, general-purpose, or custom from .claude/agents/).

#### Description budget

All skill descriptions share a budget of 2% of the context window (fallback 16,000 chars). Descriptions beyond 250 chars are truncated per entry. **Lead with trigger phrases, not feature descriptions.** The model matches on the prefix of the description — if trigger phrases are buried at the end, they may be truncated and never seen.

#### Bundled scripts

When including scripts in `scripts/`, design them for agent use:

- **Non-interactive.** Agents run in non-interactive shells. No TTY prompts, no blocking `read` calls. Accept everything via flags.
- **Clear `--help`.** Agents learn the interface by reading help output. List all flags, arguments, and examples.
- **Structured output.** JSON or CSV on stdout. Free-form text wastes tokens and parses unreliably.
- **Separate streams.** Data on stdout, diagnostics on stderr. Lets the agent pipe data without mixing in log noise.
- **Meaningful exit codes.** 0 for success, non-zero for failure with distinct codes for distinct failure modes.
- **Idempotent when possible.** Running twice should be safe. Add `--dry-run` for destructive operations.

### 4. Test

Run realistic prompts with the skill:
- **Should-trigger prompts** (3+): vary phrasing, explicitness, and detail. Does it trigger?
- **Should-NOT-trigger prompts** (2+): near-misses that share keywords but need different solutions. Does it correctly stay off?

Check the transcript:
- Does the output match expectations?
- Is Claude wasting time on unproductive steps from vague instructions?

### 5. Iterate

- Generalize from feedback — don't overfit to test cases
- Remove instructions that aren't pulling their weight
- If every test run writes the same helper script, bundle it in `scripts/`
- Explain the why behind instructions. Reasoning works better than rigid MUSTs

**Triggering issues:**
- Undertriggering → add more trigger phrases and technical keywords to description
- Overtriggering → add negative triggers ("Do NOT use for..."), narrow scope
- Debug: ask Claude "When would you use the [skill-name] skill?" — it will quote the description back

## Anti-patterns

- **Vague procedures.** "Handle errors appropriately" without specifics. Name the errors, state what to do for each.
- **Over-documenting basics.** Don't explain HTTP, PDFs, databases, common tools. Assume Claude knows.
- **Incoherent scope.** Don't combine unrelated domains in one skill. Keep to a single composable unit of work.
- **Presenting equal options.** Listing three approaches with no recommendation makes Claude deliberate. Pick one default.
- **Extraneous docs in skill dir.** No README.md, INSTALLATION.md, CHANGELOG.md inside the skill. The skill is for an agent, not a human reader. Auxiliary docs go elsewhere.
- **"When to use" buried in body.** The body loads after triggering — too late for trigger decisions. All triggering info goes in description.

## Checklist

Before finalizing:
- [ ] name is kebab-case, lowercase, matches directory name, max 64 chars
- [ ] description prefix (first 250 chars) has trigger phrases; full description under 1024 chars
- [ ] SKILL.md under 500 lines
- [ ] Large references in separate files
- [ ] disable-model-invocation set for side-effect skills
- [ ] Tested with should-trigger and should-NOT-trigger prompts
- [ ] No extraneous docs (README, INSTALLATION, CHANGELOG) inside skill dir
- [ ] Works from intended location (personal vs project)
