---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
---

- Follow AAA (Arrange-Act-Assert). Each test must be self-contained — no shared helper functions
- Verify the test fails before fixing the bug (Red-Green). If pass/fail doesn't match expectations, the test itself is broken
