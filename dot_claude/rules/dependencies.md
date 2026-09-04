---
paths:
  - "**/package.json"
  - "**/pnpm-lock.yaml"
---

- A version bump is not the task. Read what changed between the current and target version, then adopt the improvements that apply to this codebase
- Verify against real output, not a passing check. When the package shapes a build artifact, diff that artifact across versions
- Report what you considered and did not adopt, and why
