---
name: remember
description: >
  "あの作業どこ" "あの会話どこ" "昨日何やった" "前にやった" "前のセッション"
  "過去のセッション" "履歴検索" "セッション検索" "remember" "where did I"
  "what did I do" "previous session" "across projects" — Search past Claude Code
  sessions across all projects with AND keyword matching against
  ~/.claude/projects/**/*.jsonl. Use when the user is trying to recall something
  from a previous session, especially across projects, even when they don't
  explicitly say "session" or "search" — phrases like "あれどこに書いた"
  "前にやったやつ" "他のリポジトリで似たようなことやった気がする" also trigger.
  Skip when the user asks only about the current project's recent changes
  (`git log` is enough).
---

# Remember

Search past Claude Code sessions across all projects. Streams every JSONL under
`~/.claude/projects/**/*.jsonl`, applies AND keyword matching against user /
assistant / summary text, and returns hits ranked by role-weighted score.

## How to invoke

```bash
node ~/.claude/skills/remember/search.mjs <keyword>... [flags]
```

Space-separated keywords are AND-matched (case-insensitive). Stdout is JSON
Lines (one hit per line); stderr has a one-line summary.

## Flags

| Flag | Default | Meaning |
|---|---|---|
| `--or` | off (AND) | Match if **any** keyword appears (default requires all) |
| `--since <duration>` | none | Time window. `7d` `24h` `30m` |
| `--project <name>` | none | Substring match against the recorded `cwd` (e.g. `calect`) |
| `--role <role>` | none | One of `user` / `assistant` / `summary` |
| `--limit <n>` | 10 | Top N hits |
| `--max-snippet <n>` | 150 | Max snippet length in chars |
| `--verbose` / `-v` | off | Add `cwd` / `score` / `matched` / `file` to each hit |

`--since` is also a strong speedup: files older than the window are skipped via
mtime before opening.

In OR mode, score is `role_weight × matched_token_count`, so a hit covering
more keywords ranks above a hit covering fewer.

## Output fields

Each stdout line is a compact JSON object — only what's needed downstream:

- `sessionId`: session UUID
- `project`: basename of the recorded `cwd` (e.g. `me`, `calect`)
- `timestamp`: ISO 8601
- `role`: `user` / `assistant` / `summary`
- `snippet`: excerpt centred on the first matched token

Build the resume command from `sessionId`: `claude --resume <sessionId>`.

`--verbose` additionally emits `cwd`, `score` (role weight), and `file` (full
JSONL path) — only enable when you actually need them.

Stderr: `Found N matches across M sessions, showing top K`.

## How to present results to the user

1. Lead with the **count and scope** (e.g. "12 hits across all projects, top 5 below").
2. Show the **top 3–5 hits** with project, relative date, role, snippet, and a
   `claude --resume <sessionId>` line built from `sessionId`.
3. If the user wants to dig into one, hand them the resume command. **Do not
   run `claude --resume` yourself** — it would hijack a separate session in
   another process.
4. On zero hits, suggest dropping a token or trying a different surface form
   (kana/kanji, English/Japanese spelling, snake_case vs camelCase).

## Iterative search strategy (the most important section)

AND search misses whenever the past session used different surface forms. Past
Claude on the same query has already failed this way — never assume the first
search is authoritative. Iterate **before** giving up:

1. **First pass — broad**: try with **1 distinctive token** (a proper noun, a
   rare word, the most unusual term in the user's request). Default AND with
   one token = simple substring search.
2. **If 0 hits or no relevant hits, vary the surface form**:
   - 漢字 ↔ ひらがな ↔ カタカナ (`認証` / `にんしょう` / `ニンショー`)
   - English ↔ 日本語 (`auth` / `認証` / `OAuth`)
   - snake_case ↔ camelCase ↔ kebab-case (`refresh_token` / `refreshToken` / `refresh-token`)
   - Synonyms / paraphrases the user might have used at the time
3. **If still 0, switch to `--or`** with 2–4 candidate tokens covering different
   phrasings. OR-mode ranks by matched-token count × role weight, so multi-token
   hits float to the top. Use this to discover the actual phrasing.
4. **Once the right session is found**, re-run AND with narrower tokens to pull
   the specific message.

Anti-pattern: searching with `--limit 10 keywordA keywordB` (AND), getting 5
unrelated hits, and concluding the data isn't there. Always vary the query
**at least twice** before declaring zero results.

## Query tips

- **Japanese is substring-matched**, no word boundaries. `認証` matches `再認証` and `認証フロー`.
- **No regex** — fixed strings only.
- **Filter by role** when intent is clear: `--role user` for "what did I ask",
  `--role assistant` for "what did Claude say", `--role summary` for compaction summaries.
- **Always pass `--since`** when the time window is known. Big speedup.
- **Watch out for self-pollution**: hits from the *current* session about
  searching for the topic can crowd out the actual past session. Add `--since`
  with an upper bound (e.g. exclude today by combining `--since 30d` with manual
  filtering when needed) or filter results by reading timestamps.

## What is searched

- Included: `user` (human turns), `assistant` (text blocks only), `summary`
  (session summaries written by compaction)
- Excluded: `attachment` / `system` / `permission-mode` / `file-history-snapshot`
  records, `thinking` blocks, `tool_use` / `tool_result` (signal-to-noise too low)

## Gotchas

- Project directories on disk are path-encoded (slashes replaced by hyphens,
  e.g. `-Users-<user>-path-to-repo`). The `project` field does not use that —
  it pulls `basename(cwd)` from the record itself, so display names look normal.
- Old sessions can be tens of MB. Always pass `--since` if you can.
- The same session may appear in multiple hits. Don't dedupe at this layer; let
  the caller group by `sessionId` when presenting.
- A few records lack `sessionId` (rare). For those, the field is `null` and no resume command can be built.

## Out of scope

- Weekly summarisation / cross-session learning extraction → separate skill
- SessionStart hook injection of related past sessions → separate work

## Design notes

- Single Node file, zero dependencies (Node stdlib only: fs / path / os / readline)
- No DB, no cache. Streams JSONL on every run, concurrency 10
- Not packaged as MCP. Reasoning: this skill is personal, not distributed, so
  cman's rationales (avoid per-command permission prompts; restrict arbitrary
  Python execution) don't apply. Adding `Bash(node:.claude/skills/remember/*)`
  to the allowlist is sufficient.
