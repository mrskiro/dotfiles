---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---

- Components must not know their layout context (parent elements like Card, Modal, Sidebar)
- Avoid useEffect for reacting to state changes — handle side effects directly in the event handler that triggers the change
