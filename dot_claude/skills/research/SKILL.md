---
name: research
description: Multi-source research combining web search, X (Twitter), and Reddit for well-rounded answers. Use when the user asks about trends, ecosystem comparisons, developer sentiment, tool adoption, "what are people using for...", "what's the latest on...", or any question that benefits from triangulating multiple information sources. Also trigger when the user says "research", "investigate", or "look into".
argument-hint: "<research topic>"
---

Research a topic by combining multiple information sources in parallel, then synthesize the findings into a single answer.

## Why this skill exists

Any single source has blind spots. Blog posts lag behind reality. X captures the moment but lacks depth. Reddit has depth but skews toward vocal opinions. Combining them produces a more complete and honest picture.

## Sources

| Source | What it's good for | How |
|--------|-------------------|-----|
| WebSearch | Official docs, blog posts, structured articles | Call WebSearch tool directly |
| X (Twitter) | Real-time developer reactions, breaking news, hot takes | xAI Responses API with x_search (see below) |
| Reddit | In-depth discussions, experience reports, comparisons | Public JSON API (see below) |

## Workflow

1. **Run all three sources in parallel** — do not wait for one to finish before starting another. Use the argument as the search query, adapting it for each source's strengths.

2. **Synthesize** — after all sources return, combine the findings. Do not just concatenate results. Identify:
   - Points of agreement across sources
   - Contradictions or nuances
   - Information unique to one source

3. **Present** — give the user a unified answer with source attribution. End with a "Sources" section listing the key links from all three sources.

## Adapting queries per source

The raw argument rarely works perfectly for all three. Adjust:

- **WebSearch**: Add the current year. Use technical terms. Target docs and articles.
- **X**: Keep it short. Use terms the dev community actually tweets about. Consider Japanese and English queries if the topic has a Japanese community.
- **Reddit**: Think about which subreddit would discuss this. Add context words like "experience", "recommend", "vs".

## When to skip a source

Not every question needs all three. Use judgment:

- Pure technical fact-checking → WebSearch alone may suffice
- "What are people saying about X?" → X and Reddit, skip WebSearch
- User explicitly names a source → honor that, but suggest others if relevant

When skipping a source, briefly note why (e.g., "Skipped Reddit — this is a breaking news question better suited to X").

---

## X (Twitter) search

Search via xAI Responses API with `x_search` tool.

### Authentication

Read `XAI_API_KEY` from `.claude/settings.local.json` env. If missing, direct user to https://console.x.ai/team/default/api-keys.

### Execution

```
curl -s https://api.x.ai/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $XAI_API_KEY" \
  -d '{
    "model": "grok-4-1-fast",
    "input": [{"role": "user", "content": "<query> — focus on recent posts with high engagement (likes, bookmarks). Include poster handle, summary, and engagement level for each."}],
    "tools": [{"type": "x_search", "x_search": {"from_date": "<7 days ago>", "to_date": "<today>"}}]
  }'
```

Default to the last 7 days unless the user specifies a different range.

Optional parameters for the `x_search` tool:

| Parameter | Purpose | Constraint |
|-----------|---------|------------|
| `allowed_x_handles` | Only these accounts | Max 10. Cannot combine with excluded |
| `excluded_x_handles` | Exclude these accounts | Max 10. Cannot combine with allowed |
| `from_date` / `to_date` | Date range | ISO8601 (YYYY-MM-DD) |

### Response parsing

Find `type: "message"` entries in the `output` array and extract `content[].text`. Include poster handles, summaries, engagement scale, and links from citations when available.

---

## Reddit search

Search via Reddit's public JSON API.

### Execution

```
curl -s "https://www.reddit.com/search.json?q=<URL-encoded query>&sort=relevance&t=<time>&limit=20" \
  -H "User-Agent: claude-code-reddit-search/1.0"
```

| Parameter | Default | Options |
|-----------|---------|---------|
| `sort` | `relevance` | relevance, hot, top, new, comments |
| `t` | `month` | hour, day, week, month, year, all |
| `limit` | `20` | max 100 |

For subreddit-scoped search: `/r/<subreddit>/search.json?q=<query>&restrict_sr=on&...`

### Subreddit selection

Reddit's global search returns noisy, general-audience results. Always prefer subreddit-scoped searches. Pick 1-3 subreddits where the topic's practitioners actually discuss it, then run separate queries per subreddit.

Common subreddits by domain:

| Domain | Subreddits |
|--------|-----------|
| AI coding tools | r/ClaudeCode, r/cursor, r/CopilotCodex |
| LLM / AI infra | r/LocalLLaMA, r/MachineLearning |
| MCP / agent protocols | r/mcp |
| General dev | r/programming, r/webdev, r/node |
| DevOps / infra | r/devops, r/selfhosted |
| Specific languages | r/rust, r/golang, r/typescript |

If unsure which subreddit fits, do one broad search first to see which subreddits appear in results, then re-search scoped to the most relevant ones.

### Time range heuristics

| Intent | Time |
|--------|------|
| Breaking news, outages | `week` |
| Trends, what's popular | `month` |
| Reviews, comparisons | `year` or `all` |

### Response parsing

Extract from `data.children[].data`: `title`, `selftext` (truncate ~200 chars), `subreddit`, `score`, `num_comments`, `permalink` (prepend `https://www.reddit.com`). Sort by score and comment count.
