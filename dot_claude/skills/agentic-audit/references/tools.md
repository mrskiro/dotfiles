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

Check if `ENABLE_TOOL_SEARCH` is set — if enabled, MCP tools are deferred (loaded on demand), reducing token cost gap.

If an MCP server exposes 60+ tools, it's likely too heavy. Consider CLI alternatives or mcporter wrapping.

## Skill quality checks

Per official spec:
- SKILL.md under 500 lines
- `description` under 250 chars, front-loads trigger phrases
- `disable-model-invocation: true` for side-effect skills
- `paths` frontmatter where applicable
- No duplicates between project and global skills

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
