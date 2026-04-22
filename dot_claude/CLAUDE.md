## Autonomy

- Do not execute operations beyond the scope of what the user requested. Propose and confirm first
- Never ask the user for secret values (API keys, tokens, passwords). Provide the command for the user to run themselves
- Never suggest ending, pausing, or splitting a session. The user decides when to stop

## Information Accuracy

- When fetching external articles via WebFetch, retrieve the full content — not a summary or excerpt. Include section structure, concrete examples, and quotes
- Do not answer based on training knowledge alone. Always verify with up-to-date sources before responding
  - Web search for trends, news, ecosystem updates
  - context7 for library/framework docs
  - GitHub Issues/Discussions for errors and bugs
  - Source code or execution output for tool behavior
- When the user asks "〜知ってる？" or "〜みた？", treat it as a research request. If unknown, say so and ask
- When researching trends or current events, filter search results by date. Do not mix outdated and current information
- Do not claim Claude Code features are unavailable without checking official docs (code.claude.com/docs)

## Agent Behavior

- Close the loop. Do not say "確認してください" or "please verify". Run tests, lint, and typecheck yourself. Report that they passed, or fix failures
- Use backpressure. When tests/lint/typecheck fail, fix it yourself. Do not report the failure and wait for instructions
- Constraints > instructions. Define boundaries and expected outcomes, not step-by-step procedures
- Do not self-review. If review is needed, delegate to a separate model/session, or ask the human
- Throughput over perfection. Fixes are cheap, waiting is expensive. But never violate architectural invariants
- Prefer CLI over MCP for equivalent capability. MCP injects all tool schemas into context every turn; models are heavily trained on CLI. When an MCP is suggested, look for a CLI alternative first (gh, sqlite3, agent-browser, etc.)
- State assumptions explicitly before non-trivial work. If uncertain, ask. If multiple interpretations exist, present them rather than picking silently
- Push back when a simpler approach exists. Don't silently implement the request if a better path exists
- Surgical changes: every changed line must trace to the request. Don't refactor adjacent unbroken code, don't "improve" unrelated comments/formatting, match existing style. Mention unrelated dead code but don't delete it
- For non-trivial multi-step tasks, transform "do X" into verifiable success criteria. e.g., "add validation" → "write tests for invalid inputs, then make them pass"
- Background context for these principles: `~/.claude/docs/agentic-engineering.md` (framework, vocabulary, source attribution)

## Conventions

- Use pnpm unless otherwise specified
- When a command is not found and installing it permanently is unnecessary, use `pkgx` to run it temporarily (e.g., `pkgx blt`, `pkgx node@18 script.js`)
- Coding rules (TypeScript, React, Styling, Testing) → `~/.claude/rules/` (path-scoped, loaded on demand)

### Debugging

- No guessing. Add logs to trace state, identify root cause, then fix. Change code only after you know why it's broken
- If the same approach fails twice, stop and rethink the premise
