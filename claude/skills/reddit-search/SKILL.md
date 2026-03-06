---
name: reddit-search
description: Search Reddit posts via public JSON API. Use when the user says "search Reddit", "what does Reddit think about...", "reviews of...", "opinions on...", or wants to explore English-speaking community discussions, reviews, trends, and threaded debates on any topic.
argument-hint: "<search query>"
---

Search Reddit using the public JSON API and present top posts sorted by score (upvotes) and comment count.

## When to use this vs Web Search

Reddit search is for real user opinions, experience reports, and community discussions. Use Web Search instead when the user needs official docs, articles, or structured information.

## Executing the search

Use the argument as the search query and run:

```
curl -s "https://www.reddit.com/search.json?q=<URL-encoded query>&sort=relevance&t=<time>&limit=20" \
  -H "User-Agent: claude-code-reddit-search/1.0"
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `q` | argument as-is | Search query. Use `subreddit:name` to filter by subreddit |
| `sort` | `relevance` | Sort order: relevance, hot, top, new, comments |
| `t` | `week` | Time filter: hour, day, week, month, year, all |
| `limit` | `20` | Number of results (max 100) |

### Default time range

Choose the time range based on user intent. Reddit threads take time to develop good discussions, so the right range depends on the question type:

| Intent | Time | Examples |
|--------|------|----------|
| Breaking news, outages | `week` | "is X down?", "this week's..." |
| Trends, what's popular | `month` | "what's trending?", "lately..." |
| Reviews, comparisons | `year` or `all` | "reviews of...", "X vs Y" |

When the user doesn't specify a time range, infer from context. Default to `month` when uncertain — `week` often returns too few results.

### Subreddit-scoped search

When the user specifies a subreddit, use a different endpoint:

```
curl -s "https://www.reddit.com/r/<subreddit>/search.json?q=<query>&restrict_sr=on&sort=relevance&t=<time>&limit=20" \
  -H "User-Agent: claude-code-reddit-search/1.0"
```

## Parsing the response

Extract post data from `data.children[]`. Each entry's `data` contains:

| Field | Content |
|-------|---------|
| `title` | Post title |
| `selftext` | Body text (truncate to ~200 chars if long) |
| `subreddit` | Subreddit name |
| `author` | Author username |
| `score` | Upvote count |
| `num_comments` | Comment count |
| `permalink` | Post path (prepend `https://www.reddit.com`) |
| `created_utc` | Post timestamp (Unix) |

## Presenting results

Sort by score and comment count, then present top posts with:

- **Title** (linked)
- Subreddit, author
- Score and comment count
- Brief summary of body text (if available)

End with a concise summary of overall sentiment — what opinions dominate, whether consensus exists.

## Notes

- The public JSON API is rate-limited (~10 requests/min without auth). Fine for personal use.
- Always include the User-Agent header — requests without it may be rejected.
- NSFW content can be filtered via `over_18: true` but is not filtered by default.
