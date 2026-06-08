---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---

- Components must not know their layout context (parent elements like Card, Modal, Sidebar)
- Avoid useEffect for reacting to state changes — handle side effects directly in the event handler that triggers the change
- Do not write to `ref.current` during render. Refs are for mount-time DOM access, mount-once flags, or unmount-cleanup snapshots — not as a "sticky cache" during render. If you're tempted to write `ref.current.set(...)` while rendering (e.g. `useRef(new Map(...))` + `ref.current.set(id, value)` in the render path), the design is wrong: render must be pure, and mutating during render breaks Strict Mode's double-render and React Compiler's memoization. Either compute the value purely from props/state, or move the mutation into a useEffect / event handler
- `useRef(new Map(...))` and similar non-primitive initializers re-construct the value on every render even though only the first is used. Use `useState(() => new Map(...))` lazy init when you genuinely need a per-component instance
