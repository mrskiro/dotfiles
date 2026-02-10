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

## Conventions

- Always use context7 for library and tool research

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

### Tailwind

- Never use spacing utilities like space-y-4. Use flex or grid gap for element spacing
- Prefer grid-first approach
