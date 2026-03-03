# Memory

When this memory is loaded, always declare "ユーザーメモリを読み込みました"

## Core Principles

- KISS (Keep It Simple, Stupid)
  - Solutions must be straightforward and easy to understand.
  - Avoid over-engineering or unnecessary abstraction.
  - Prioritise code readability and maintainability.

- YAGNI (You Aren’t Gonna Need It)
  - Do not add speculative features or future-proofing unless explicitly required.
  - Focus only on immediate requirements and deliverables.
  - Minimise code bloat and long-term technical debt.

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

### Package Manager

- Use pnpm unless otherwise specified

### TypeScript

- Use type instead of interface
- Prefer functional approach
- Use arrow functions instead of function declarations
- Use named exports
- Avoid variable declarations unless referenced multiple times. Inline expressions enable better type inference while keeping scope narrow
- Do not use barrel files (re-export via index.ts)
- Unless instructed by user or constrained by framework, keep implementations in a single file when feasible
- Never use 'any' type

### React

- Components must not know their layout context (parent elements like Card, Modal, Sidebar)
  Each component should focus only on its own responsibilities, not where it will be used
  This improves separation of concerns, reusability, testability, and maintainability
- Prefer useEffect for DOM event subscribe/unsubscribe (cleanup handles removal automatically)
- Avoid useEffect for reacting to state changes — handle side effects directly in the event handler that triggers the change
- Derive values from existing state instead of storing redundant state (e.g., use a boolean + JSX ternary instead of storing label strings)
- When a value can be inferred from another ref/state, do not create a separate ref for it
- Do not pass implementation details (e.g., DOM nodes) as props — pass use-case-specific functions or values instead
- Do not specify optional parameters with their default values

### Styling

- Styling must be done in CSS whenever possible. Do not use JavaScript for styling purposes
- Use modern CSS features proactively (e.g. :has(), :is(), :where(), container queries, cascade layers)

#### Tailwind

- Never use spacing utilities like space-y-4. Use flex or grid gap for element spacing
- Prefer grid-first approach
- Never use arbitrary values (e.g., `px-[12px]`) when a preset utility exists (e.g., `px-3`)
