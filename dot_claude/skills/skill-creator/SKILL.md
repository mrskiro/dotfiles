---
name: skill-creator
description: >
  Create, improve, and validate Claude Code skills following official best practices.
  Use when creating a new skill, improving an existing skill, or turning a workflow into
  a reusable skill. Also use when writing SKILL.md files, choosing frontmatter fields,
  or designing skill structure. Triggers: "skill作って", "スキル作りたい", "create a skill",
  "improve this skill", "スキル改善", "SKILL.md書いて".
---

# Skill Creator

Guide the user through creating or improving a Claude Code skill.
Reference: https://code.claude.com/docs/en/skills

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

All fields are optional. Only `description` is recommended.

```yaml
---
name: kebab-case              # max 64 chars. Omit to use directory name
description: >                # under 1024 chars. Truncated at 250 chars in skill listing
  "trigger1" "trigger2" "trigger3" — [what it does].
  Lead with trigger phrases. Model matches on description prefix.
  Add "Do NOT use for..." if overtriggering is a risk.
disable-model-invocation: true  # User-only invocation. For workflows with side effects
user-invocable: false           # Claude-only invocation. For background knowledge
allowed-tools: Read, Grep       # Tools allowed without permission while skill is active
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

When referencing supporting files from SKILL.md, use imperative "read" instructions, not passive "see" links. The model may skip passive references.

```markdown
# Good — model reads the file before proceeding
**Before evaluating, read `references/criteria.md`.**

# Bad — model may skip this
For details, see [references/criteria.md](references/criteria.md)
```

#### context: fork

Runs in a subagent with isolated context. Requires explicit task instructions — guidelines alone without a task produce nothing. Use `agent` field to specify subagent type (Explore, Plan, general-purpose, or custom from .claude/agents/).

#### Description budget

All skill descriptions share a budget of 2% of the context window (fallback 16,000 chars). Descriptions beyond 250 chars are truncated per entry. **Lead with trigger phrases, not feature descriptions.** The model matches on the prefix of the description — if trigger phrases are buried at the end, they may be truncated and never seen.

### 4. Test

Run 2-3 realistic prompts with the skill. Check:
- Does it trigger when expected?
- Does the output match expectations?
- Is Claude wasting time on unproductive steps? (read the transcript)

### 5. Iterate

- Generalize from feedback — don't overfit to test cases
- Remove instructions that aren't pulling their weight
- If every test run writes the same helper script, bundle it in `scripts/`
- Explain the why behind instructions. Reasoning works better than rigid MUSTs

**Triggering issues:**
- Undertriggering → add more trigger phrases and technical keywords to description
- Overtriggering → add negative triggers ("Do NOT use for..."), narrow scope
- Debug: ask Claude "When would you use the [skill-name] skill?" — it will quote the description back

### Checklist

Before finalizing:
- [ ] name is kebab-case, max 64 chars
- [ ] description under 250 chars, trigger phrases at the start
- [ ] SKILL.md under 500 lines
- [ ] Large references in separate files
- [ ] disable-model-invocation set for side-effect skills
- [ ] Tested with 2+ realistic prompts
- [ ] Works from intended location (personal vs project)
