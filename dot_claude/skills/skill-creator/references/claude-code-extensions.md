# Claude Code Extensions

These behaviors and frontmatter fields are specific to Claude Code. The
non-spec frontmatter fields will fail `skills-ref validate` and be ignored
by other agents (Cursor, Goose, OpenAI Codex, Gemini CLI, …). Use only
for skills that are Claude Code-only.

Source: https://code.claude.com/docs/en/skills

## Contents

- [Frontmatter fields](#frontmatter-fields)
- [Invocation control](#invocation-control)
- [String substitutions](#string-substitutions)
- [Dynamic context injection](#dynamic-context-injection)
- [Description budget](#description-budget)
- [`context: fork` (subagent isolation)](#context-fork-subagent-isolation)
- [Runtime behavior](#runtime-behavior)
- [Discovery and overrides](#discovery-and-overrides)
- [Permissions integration](#permissions-integration)

## Frontmatter fields

```yaml
when_to_use: ...                 # Extra trigger context; appended to description
arguments: [issue, branch]       # Named positional args for $issue / $branch
argument-hint: "[issue-number]"  # Autocomplete hint shown after the slash command
disable-model-invocation: true   # User-only invocation. For side-effecting workflows
user-invocable: false            # Claude-only invocation. For background knowledge
model: opus                      # Model override while active; or `inherit`
effort: high                     # low | medium | high | xhigh | max (model-dependent)
context: fork                    # Run in a subagent (isolated context)
agent: Explore                   # Subagent type when context: fork
paths: "**/*.ts"                 # Auto-load only when matching files are touched
shell: bash                      # `bash` (default) or `powershell` for `!` blocks
hooks:                           # Hooks active only while the skill runs
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "bash ${CLAUDE_SKILL_DIR}/scripts/check.sh"
```

In Claude Code, all frontmatter fields are technically optional —
`name` falls back to the directory name, `description` falls back to the
first paragraph of the body. The agentskills spec validator still
**requires** both, so write them explicitly for portability.

`when_to_use` lets you keep *what* in `description` and put trigger
phrases / example requests in `when_to_use`. Both are merged into the
listing the model sees, capped at 1,536 chars combined per entry.

`arguments` declares names for positional args so you can write `$issue`
instead of `$ARGUMENTS[0]`. Names map by order:
`arguments: [issue, branch]` makes `$issue` the first arg and `$branch`
the second.

`shell: powershell` runs `!` blocks via PowerShell on Windows; requires
`CLAUDE_CODE_USE_POWERSHELL_TOOL=1`.

## Invocation control

| Setting | User can invoke | Claude can invoke | Description loaded? |
|---|---|---|---|
| (default) | Yes | Yes | Always |
| `disable-model-invocation: true` | Yes | No | Not loaded at startup |
| `user-invocable: false` | No | Yes | Always |

`disable-model-invocation: true` also prevents the skill from being
preloaded into subagents. Use for skills with side effects you don't
want the agent to trigger speculatively.

`user-invocable: false` only hides the skill from the `/` menu. It does
**not** block programmatic Skill-tool invocation by Claude. To block
that, use `disable-model-invocation: true`.

## String substitutions

Available in SKILL.md when the skill is invoked:

| Variable | Description |
|---|---|
| `$ARGUMENTS` | All args passed to `/skill-name` |
| `$ARGUMENTS[N]` / `$N` | Nth positional argument (0-based) |
| `$<name>` | Named positional argument from the `arguments` frontmatter |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Absolute path to the skill directory |

Indexed args use shell-style quoting: `/my-skill "hello world" second`
expands `$0` to `hello world` and `$1` to `second`. `$ARGUMENTS` always
expands to the full string as typed.

If `$ARGUMENTS` doesn't appear in the skill content but args were passed,
Claude Code appends `ARGUMENTS: <input>` to the end so the agent still
sees them.

## Dynamic context injection

Backtick-wrapped shell commands prefixed with `!` execute at
preprocessing time. Their output replaces the placeholder before the
skill is sent to the model:

```
Branch: !`git branch --show-current`
Latest commit: !`git log -1 --oneline`
```

For multi-line commands, use a fenced block opened with ` ```! `:

````
```!
node --version
npm --version
git status --short
```
````

The agent sees the *output*, not the command. Useful for injecting
fresh state when the skill activates.

To disable shell execution for non-bundled skills (typically in managed
settings), set `"disableSkillShellExecution": true`. Each command is
then replaced with `[shell command execution disabled by policy]`.
Bundled and managed skills are not affected.

## Description budget

All skill descriptions share roughly 1% of the context window, with an
8,000-char fallback. Per-entry combined `description` + `when_to_use`
text is capped at **1,536 chars regardless of budget**. Skill names are
always included; descriptions themselves are what gets trimmed when
the catalog approaches the limit.

**Lead with trigger phrases.** Buried triggers beyond the truncation
point are never seen by the matcher.

To raise the limit, set `SLASH_COMMAND_TOOL_CHAR_BUDGET` (env var), or
trim `description` and `when_to_use` at the source.

## `context: fork` (subagent isolation)

Runs the skill in a subagent with its own isolated context. The skill
content becomes the subagent's prompt; it has no access to the parent
conversation. The main conversation only sees the subagent's final
result. Useful when:

- The skill produces large intermediate output the main context
  shouldn't hold
- The skill's instructions might conflict with active conversation
  context
- You want clean, repeatable execution

Requires explicit task instructions in the body — guidelines alone
produce nothing in a forked context. Use `agent` to specify the
subagent type: `Explore`, `Plan`, `general-purpose`, or a custom
agent from `.claude/agents/`. Default: `general-purpose`.

Two integration directions:

| Approach | System prompt | Task | Also loads |
|---|---|---|---|
| Skill with `context: fork` | From the agent type | SKILL.md content | CLAUDE.md |
| Subagent with a `skills` field | The subagent's body | Claude's delegation message | Preloaded skills + CLAUDE.md |

## Runtime behavior

### Skill content is injected once

When invoked, rendered SKILL.md is added to the conversation as a single
message and stays for the rest of the session. Claude Code does **not**
re-read the file in later turns. Implications for authoring:

- Write **standing instructions** ("when you encounter X, do Y"), not
  one-time procedural steps ("next, do X")
- If a skill stops affecting behavior mid-session, the content is
  usually still in context — the model is choosing other tools.
  Strengthen the description and instructions, or use hooks to enforce
  behavior deterministically
- Re-invoke the skill to re-inject its content if it has been compacted
  out

### Auto-compaction

When the context fills and Claude Code summarizes older messages, each
**most recent** invocation of a skill is re-attached after the summary
with the first 5,000 tokens preserved. Re-attached skills share a
25,000-token budget, filled starting from the most recently invoked.
Skills older in the call order may drop entirely.

If a skill seems to have lost its effect after compaction, re-invoke
it to restore the full content.

### Live change detection

Claude Code watches skill directories. Adding, editing, or deleting a
skill under `~/.claude/skills/`, project `.claude/skills/`, or a
`--add-dir` directory's `.claude/skills/` takes effect within the
current session. Creating a top-level skill directory that didn't
exist at session start requires a Claude Code restart.

### Nested `.claude/skills/`

Skills in nested `.claude/skills/` directories are auto-detected when
working on files beneath them. In a monorepo,
`packages/frontend/.claude/skills/` loads when files inside
`packages/frontend/` are touched.

### `--add-dir` exception

`--add-dir` grants file access without configuration loading,
**except** for `.claude/skills/`, which is auto-loaded. Other config
(sub-agents, commands, output styles) is not. CLAUDE.md from
`--add-dir` is also not loaded by default; set
`CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` to enable it.

### Extended thinking

Including the word `ultrathink` anywhere in skill content enables
extended thinking for that activation.

## Discovery and overrides

| Scope | Path | Applies to |
|---|---|---|
| Enterprise | Managed settings | All users in the organization |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All projects |
| Project | `<repo>/.claude/skills/<name>/SKILL.md` | Just this project |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where the plugin is enabled |

Override order on name collision: **enterprise > personal > project**.
Plugin skills use a `plugin-name:skill-name` namespace so they never
collide with other scopes.

If `.claude/commands/foo.md` and `.claude/skills/foo/SKILL.md` both
exist, both expose `/foo` and the skill wins. Custom commands have
been merged into skills; existing `.claude/commands/` files keep
working, but new work should go in `.claude/skills/`.

## Permissions integration

`allowed-tools` (frontmatter) grants permission to listed tools while
the skill is active — without prompting. It does not restrict tool
availability; everything else still goes through the normal permission
system.

To control which skills Claude can invoke through the Skill tool:

```text
# Deny all skill invocation
Skill

# Allow / deny specific skills
Skill(commit)              # exact match
Skill(review-pr *)         # prefix match with any args
Skill(deploy *)            # deny prefix
```

`user-invocable: false` only hides from the `/` menu; it does **not**
block Skill-tool access. Use `disable-model-invocation: true` to
block programmatic invocation entirely.

Built-in commands `/init`, `/review`, `/security-review` are exposed
via the Skill tool. Others like `/compact` are not.
