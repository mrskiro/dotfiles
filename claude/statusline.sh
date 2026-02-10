#!/bin/bash

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size')
usage=$(echo "$input" | jq '.context_window.current_usage')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens')

# Context window usage
if [ "$usage" != "null" ]; then
  current_tokens=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
  percent_used=$((current_tokens * 100 / context_size))
else
  percent_used=0
fi

# Format tokens (e.g., 15234 -> 15.2k)
format_tokens() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    printf "%.1fk" "$(echo "scale=1; $n / 1000" | bc)"
  else
    printf "%d" "$n"
  fi
}

# Account usage (cached, 5 min TTL)
CACHE_FILE="/tmp/claude_usage_cache"
CACHE_TTL=300

get_account_usage() {
  if [ -f "$CACHE_FILE" ]; then
    local cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE") ))
    if [ "$cache_age" -lt "$CACHE_TTL" ]; then
      cat "$CACHE_FILE"
      return
    fi
  fi

  local token
  token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  [ -z "$token" ] && return

  local response
  response=$(curl -s --max-time 5 \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

  if [ $? -eq 0 ] && echo "$response" | jq -e '.five_hour' > /dev/null 2>&1; then
    echo "$response" > "$CACHE_FILE"
    echo "$response"
  fi
}

usage_response=$(get_account_usage)

five_hour=""
seven_day=""
if [ -n "$usage_response" ]; then
  five_hour=$(echo "$usage_response" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
  seven_day=$(echo "$usage_response" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
fi

# Output
printf "%s" "$model"
printf " │ %d%%" "$percent_used"
printf " │ %s/%s" "$(format_tokens "$total_input")" "$(format_tokens "$total_output")"
[ -n "$five_hour" ] && printf " │ 5h:%.0f%%" "$five_hour"
[ -n "$seven_day" ] && printf " │ 7d:%.0f%%" "$seven_day"
exit 0
