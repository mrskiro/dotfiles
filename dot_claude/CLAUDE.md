# Core Principles

- KISS (Keep It Simple, Stupid)
  - Solutions must be straightforward and easy to understand.
  - Avoid over-engineering or unnecessary abstraction.
  - Prioritise code readability and maintainability.

- YAGNI (You Aren't Gonna Need It)
  - Do not add speculative features or future-proofing unless explicitly required.
  - Focus only on immediate requirements and deliverables.
  - Minimise code bloat and long-term technical debt.

## Autonomy & Security

- Complete the requested task autonomously. Do not defer decisions
- Do not execute operations beyond the scope of what the user requested. Propose and confirm first
- Never ask the user for secret values (API keys, tokens, passwords). Provide the command for the user to run themselves

## Information Accuracy

- Do not answer based on training knowledge alone. Always verify with up-to-date sources before responding
  - Web search for trends, news, ecosystem updates
  - context7 for library/framework docs
  - GitHub Issues/Discussions for errors and bugs
  - Source code or execution output for tool behavior
- When the user asks "〜知ってる？" or "〜みた？", treat it as a research request. If unknown, say so and ask
- When researching trends or current events, filter search results by date. Do not mix outdated and current information
- Do not claim Claude Code features are unavailable without checking official docs (code.claude.com/docs)

## Conventions

### CLI Tools

- When a command is not found and installing it permanently is unnecessary, use `pkgx` to run it temporarily (e.g., `pkgx blt`, `pkgx node@18 script.js`)

### Package Manager

- Use pnpm unless otherwise specified

### TypeScript

- Use type instead of interface
- Prefer functional approach
- Use arrow functions instead of function declarations
- Use named exports
- Never use 'any' type
- Never use tsx or ts-node to run TypeScript. Node.js natively executes TypeScript (`node script.ts`)
- Use Intl APIs (e.g. `Intl.DateTimeFormat`) for date/number formatting instead of manual string manipulation

### React

- Components must not know their layout context (parent elements like Card, Modal, Sidebar)
- Avoid useEffect for reacting to state changes — handle side effects directly in the event handler that triggers the change

### Styling

- Styling must be done in CSS whenever possible. Do not use JavaScript for styling purposes
- Use modern CSS features proactively (e.g. :has(), :is(), :where(), container queries, cascade layers)
- Never use arbitrary values (e.g., `px-[12px]`) when a preset utility exists (e.g., `px-3`)

### Testing

- Follow AAA (Arrange-Act-Assert). Each test must be self-contained — no shared helper functions
- Verify the test fails before fixing the bug (Red-Green). If pass/fail doesn't match expectations, the test itself is broken

### Debugging

- No guessing. Add logs to trace state, identify root cause, then fix. Change code only after you know why it's broken
- If the same approach fails twice, stop and rethink the premise

## gstack

Available skills from gstack (`~/.claude/skills/gstack/`):
/plan-ceo-review, /plan-eng-review, /plan-design-review, /design-consultation, /review, /ship, /browse, /qa, /qa-only, /qa-design-review, /setup-browser-cookies, /retro, /document-release
