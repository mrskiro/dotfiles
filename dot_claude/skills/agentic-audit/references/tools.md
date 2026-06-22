# Tool Coverage — Reference

## Concept

Tools expand what the agent can **do**, not just what it **knows**. For each external service, data store, and infrastructure component the project uses, the agent should be able to act on it directly.

## Detection

Scan these files to understand the project's tech stack:
- `package.json` / `go.mod` / `Cargo.toml` / `pyproject.toml`
- Deployment config: `wrangler.toml`, `vercel.json`, `fly.toml`, `Dockerfile`
- `docker-compose.yml` (databases, caches, queues)
- `.env.example` / `.env.sample` (external service references)
- Framework config files

## Capability assessment

For each detected component, ask: **can the agent act on this, or only read code that talks to it?**

Don't use a fixed checklist — derive categories from the project itself. A web app, a native app, a CLI tool each have different needs.

For gaps, **web search** for available MCP/CLI options. Don't rely on training knowledge.

## MCP vs CLI decision

| Factor | MCP | CLI |
|---|---|---|
| Authentication | Built-in OAuth/API key UX | Manual setup |
| Token cost | Schema injected every turn (unless deferred) | Only output enters context |
| Composability | Can't pipe with bash | Full bash integration |
| Recommendation | External services with auth needs | Everything else |

**Tool search** is on by default. When on, MCP/tool schemas surface by name only and the model fetches the full schema via `ToolSearch` on demand — dramatically reducing per-turn schema cost. Disabled by default on Vertex AI and when `ANTHROPIC_BASE_URL` points to a non-first-party host. Override via the `ENABLE_TOOL_SEARCH` env var (`true` / `false` / `auto:N%`). Verify with `/doctor`.

If an MCP server exposes 60+ tools, it's likely too heavy. Consider CLI alternatives, mcporter wrapping, or enabling deferred loading.

## Three advanced tool-use primitives (Anthropic, late 2025)

Each addresses a different bottleneck. Layer them strategically.

| Bottleneck | Primitive | Mechanism |
|---|---|---|
| Tool definitions consuming >10K tokens upfront | **Tool Search Tool** | Mark tools `defer_loading: true`. Only `tool_search_tool_regex` (or BM25 / embedding variant) loaded by default. Agent searches by capability ("github"); only matching tools expand. 85% reduction in token usage. Opus 4.5 accuracy 79.5% → 88.1% on MCP eval |
| Large intermediate results polluting context (10K-row reads, 50-call workflows) | **Programmatic Tool Calling** | Mark tools with `allowed_callers: ["code_execution_..."]`. Agent writes Python that calls tools in code-execution sandbox. Intermediate results stay in sandbox; only final output enters context. 37% token reduction; GAIA 46.5% → 51.2% |
| Wrong parameters / similar-tool confusion | **Tool Use Examples** | Sample tool calls (1-5) in tool definitions show format conventions, nested-structure patterns, optional-parameter correlations. 72% → 90% accuracy on complex parameter handling |

Plus **Code Execution with MCP** (Cloudflare "Code Mode" pattern): present MCP servers as TypeScript/Python file trees the agent reads selectively. Agent code filters/transforms data before it touches the model. 150K → 2K tokens (98.7%). Bonus: PII can be tokenized at the MCP-client boundary so sensitive data flows through the workflow without ever entering the model.

## CLI vs MCP — refined decision (2026)

The "prefer CLI over MCP" default still holds, but two principled exceptions exist:

1. **Auth-gateway use** (Sean Lynch via Simon Willison): if MCP's only role is isolating an auth flow outside the agent's context window, that's a legitimate use even when a CLI exists. "Maybe the idealized form of MCP is just an auth gateway."
2. **GUI / native apps with no CLI surface** (Poehnelt): when verifying a desktop app or browser-rendered output, an in-process MCP server (with `set_text`, `screenshot`, `wait_idle`, `get_diagnostics`) is the right answer because the alternative is human-in-the-loop screenshot capture. The verify loop becomes ~10s instead of stalled.

## MCP tool-search bypass

For MCP servers whose tools must always be in context (e.g. small high-frequency tool sets), set `alwaysLoad: true` in the MCP server config — all tools from that server skip tool-search deferral and are always available.

## Debugging / iteration tools

Check whether the project knows about these (often missing from CLAUDE.md):

- `--safe-mode` flag and `CLAUDE_CODE_SAFE_MODE` env — start Claude Code with all customizations (CLAUDE.md, plugins, skills, hooks, MCP servers) disabled, for troubleshooting which customization is interfering
- `disableBundledSkills` setting + `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS` — hide bundled skills, workflows, and built-in slash commands from the model (useful for evaluating project skills in isolation)
- `/reload-skills` — re-scan skill directories without restarting the session (skill iteration loop)
- `/reload-plugins` — pick up plugin-provided skills without restart
- `/doctor` — surface config issues, skill listing budget overflow, MCP server scope drift

## Plugin management

If the project produces or consumes plugins, look for:

- `claude plugin init <name>` — scaffolds a new plugin in `.claude/skills/`
- `claude plugin list [--enabled|--disabled]` — installed plugins inventory
- `claude plugin details <name>` — plugin's component inventory and projected per-session token cost
- `claude plugin prune` — remove orphaned auto-installed dependencies
- `claude plugin tag` — create release git tags for plugins with version validation
- Marketplaces: `anthropics/claude-plugins-official`, `anthropics/claude-plugins-community`

## Agent view (`claude agents`)

A new dispatch surface added in 2026: one screen for every Claude Code session (running, blocked, done). Worth flagging when present:

- `claude agents` opens the view; `claude agents --json` for scripting (tmux status bars, session pickers)
- Background-session flags: `--add-dir`, `--settings`, `--mcp-config`, `--plugin-dir`, `--permission-mode`, `--model`, `--effort`, `--dangerously-skip-permissions`
- `/resume` works for background sessions (marked `bg` in the list)
- Sub-agents can now spawn their own sub-agents up to 5 levels deep — orchestration auditing must account for this

## Deferred tools to look for

The harness now ships many non-MCP tools that also load on demand (visible in `<system-reminder>` lists at session start). Flag if the project's agentic workflows would benefit but aren't using them:

- `Workflow` — deterministic multi-agent orchestration (fan-out, pipelines, judge panels)
- `ScheduleWakeup` / `CronCreate` / `CronList` / `CronDelete` — scheduled re-invocation, recurring agents (Routines)
- `Monitor` — stream events from background processes into the session
- `EnterWorktree` / `ExitWorktree` — isolated git worktrees for parallel mutations
- `SendMessage` / `TaskCreate` / `TaskUpdate` / `TaskList` — sub-agent addressing, task graph
- `RemoteTrigger` / `PushNotification` — cross-surface coordination
- `WebFetch` / `WebSearch` — research without leaving the session

## Skill quality checks

Per official spec (code.claude.com/docs/en/skills):
- `SKILL.md` under 500 lines
- `description` + `when_to_use` **combined** under 1,536 chars (configurable via `maxSkillDescriptionChars`); front-load trigger phrases
- `disable-model-invocation: true` for side-effect / destructive skills (still usable via `/slash`)
- `allowed-tools` / `disallowed-tools` set when tool surface needs constraining (`allowed-tools` is stable, not experimental)
- `paths` frontmatter where the skill is path-scoped
- `when_to_use` written as standing-instruction triggers, not procedural steps
- No duplicates between project and global skills
- Reusable across repos? → package as a plugin (`.claude-plugin/plugin.json`) and distribute via marketplace

## Extension surfaces to inventory

A 2026 audit should look beyond skills/commands. Each surface has a distinct distribution and runtime model:

| Surface | Where | What it's for |
|---|---|---|
| Skills | `~/.claude/skills/` or `.claude/skills/` | Standing instructions, model-invoked or `/slash` |
| Commands | `.claude/commands/` | Stable `/slash` entry points (skill frontmatter applies) |
| Agents | `.claude/agents/` | Sub-agent definitions (Explore, Plan, custom) |
| Hooks | `settings.json` `hooks` block | Deterministic event handlers |
| Output styles | `~/.claude/output-styles/` | Behavioral overlays (Default, Proactive, Explanatory, Learning, custom) |
| Workflows | `.claude/workflows/` | Saved deterministic orchestration scripts |
| Routines | claude.ai/code/routines | Cloud cron / API / GitHub-triggered scheduled agents |
| Monitors | `monitors/monitors.json` (plugin) | Background streams piped into the session |
| LSP plugins | `.lsp.json` (plugin) | Language-server-backed code intelligence |
| MCP servers | `.mcp.json` / `settings.json` | External tool/resource adapters |
| Plugins | `.claude-plugin/plugin.json` + marketplace | Bundle of any of the above for distribution |

## Browser verification tools

For web projects, the agent needs to verify its work visually.

Preference order (token efficiency):
1. CLI tools (agent-browser, playwright-cli) — output only enters context when called
2. Browser MCP — schema injected every turn

Check authentication handling: agent-browser supports named sessions, profiles, and state save/load for authenticated pages.

## Sources

- Lopopolo: MCP bearish, CLI + shim daemon preferred
- SWM: MCP for auth-required external services, CLI for everything else
- Bassim: agent-browser over Playwright MCP
- agent-browser docs: Rust native, 6% token difference, authentication support
