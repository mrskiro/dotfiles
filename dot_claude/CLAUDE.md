## Autonomy

- Do not execute operations beyond the scope of what the user requested. Propose and confirm first
- Never ask the user for secret values (API keys, tokens, passwords). Provide the command for the user to run themselves
- Never suggest ending, pausing, or splitting a session. The user decides when to stop

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

- Use pnpm unless otherwise specified
- When a command is not found and installing it permanently is unnecessary, use `pkgx` to run it temporarily (e.g., `pkgx blt`, `pkgx node@18 script.js`)
- Coding rules (TypeScript, React, Styling, Testing) → `~/.claude/rules/` (path-scoped, loaded on demand)

### Debugging

- No guessing. Add logs to trace state, identify root cause, then fix. Change code only after you know why it's broken
- If the same approach fails twice, stop and rethink the premise
