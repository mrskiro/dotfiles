---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

- Prefer functional approach
- Never use tsx or ts-node to run TypeScript. Node.js natively executes TypeScript (`node script.ts`)
- Use Intl APIs (e.g. `Intl.DateTimeFormat`) for date/number formatting instead of manual string manipulation
