# BigQuery Queries

Replace `@start_date` and `@end_date` with the analysis period.

## Data freshness check

```sql
SELECT MAX(started_at) as latest
FROM claude_code_telemetry.sessions
```

## 1. Skill usage frequency

```sql
SELECT skill_name, COUNT(*) as count
FROM claude_code_telemetry.tool_uses
WHERE skill_name IS NOT NULL
  AND timestamp BETWEEN @start_date AND @end_date
GROUP BY skill_name
ORDER BY count DESC
```

## 2. Tool usage frequency (top 20)

```sql
SELECT tool_name, COUNT(*) as count
FROM claude_code_telemetry.tool_uses
WHERE timestamp BETWEEN @start_date AND @end_date
GROUP BY tool_name
ORDER BY count DESC
LIMIT 20
```

## 3. Agent spawns

```sql
SELECT agent_type, COUNT(*) as count
FROM claude_code_telemetry.tool_uses
WHERE agent_type IS NOT NULL
  AND timestamp BETWEEN @start_date AND @end_date
GROUP BY agent_type
ORDER BY count DESC
```

## 4. MCP tool usage

```sql
SELECT mcp_tool, COUNT(*) as count
FROM claude_code_telemetry.tool_uses
WHERE mcp_tool IS NOT NULL
  AND timestamp BETWEEN @start_date AND @end_date
GROUP BY mcp_tool
ORDER BY count DESC
```

## 5. Per-project summary

```sql
SELECT
  project_name,
  COUNT(*) as sessions,
  SUM(total_tool_calls) as tool_calls,
  ROUND(SUM(total_cost_usd), 2) as cost_usd
FROM claude_code_telemetry.sessions
WHERE started_at BETWEEN @start_date AND @end_date
GROUP BY project_name
ORDER BY cost_usd DESC
```

## 6. Weekly cost trend

```sql
SELECT
  DATE_TRUNC(started_at, WEEK) as week,
  COUNT(*) as sessions,
  ROUND(SUM(total_cost_usd), 2) as cost_usd
FROM claude_code_telemetry.sessions
WHERE started_at BETWEEN @start_date AND @end_date
GROUP BY week
ORDER BY week
```

## 7. Bash command patterns

```sql
SELECT
  SPLIT(bash_command, ' ')[OFFSET(0)] as cmd_prefix,
  COUNT(*) as count
FROM claude_code_telemetry.tool_uses
WHERE tool_name = 'Bash'
  AND bash_command IS NOT NULL
  AND timestamp BETWEEN @start_date AND @end_date
GROUP BY cmd_prefix
ORDER BY count DESC
LIMIT 10
```

## 8. Friction events summary

```sql
SELECT event_type, COUNT(*) as count
FROM claude_code_telemetry.friction_events
WHERE timestamp BETWEEN @start_date AND @end_date
GROUP BY event_type
ORDER BY count DESC
```

### Sessions with most friction

```sql
SELECT
  f.session_id,
  s.project_name,
  s.started_at,
  COUNT(*) as friction_count,
  COUNTIF(f.event_type = 'user_correction') as corrections,
  COUNTIF(f.event_type = 'hook_block') as hook_blocks,
  COUNTIF(f.event_type = 'tool_rejection') as rejections
FROM claude_code_telemetry.friction_events f
JOIN claude_code_telemetry.sessions s ON f.session_id = s.session_id
WHERE f.timestamp BETWEEN @start_date AND @end_date
GROUP BY f.session_id, s.project_name, s.started_at
ORDER BY friction_count DESC
LIMIT 10
```

### Hook block patterns

```sql
SELECT
  REGEXP_EXTRACT(detail, r'Blocked: (.+?)\\n') as block_reason,
  COUNT(*) as count
FROM claude_code_telemetry.friction_events
WHERE event_type = 'hook_block'
  AND timestamp BETWEEN @start_date AND @end_date
GROUP BY block_reason
ORDER BY count DESC
```

## 9. Workflow deviation detection

Detect sessions where expected procedures were not followed.

### Skill files created without /skill-creator

```sql
SELECT DISTINCT s.session_id, s.started_at, s.project_name
FROM claude_code_telemetry.tool_uses t
JOIN claude_code_telemetry.sessions s ON t.session_id = s.session_id
WHERE t.file_path LIKE '%/skills/%/SKILL.md'
  AND t.tool_name IN ('Write', 'Edit')
  AND t.timestamp BETWEEN @start_date AND @end_date
  AND t.session_id NOT IN (
    SELECT session_id
    FROM claude_code_telemetry.tool_uses
    WHERE skill_name = 'skill-creator'
      AND timestamp BETWEEN @start_date AND @end_date
  )
```

### Adding new deviation rules

Follow the same pattern. Examples:
- CLAUDE.md edited directly without running /agentic-audit first
- /ship used without /review in the same session
