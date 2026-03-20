#!/bin/bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir')
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

five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Git branch
git_branch=""
if git_branch_raw=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_branch="$git_branch_raw"
elif git_branch_raw=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null); then
  git_branch="$git_branch_raw"
fi

# Output
printf "%s" "$model"
project_dir="${CLAUDE_PROJECT_DIR:-$cwd}"
rel_path="${cwd#"${project_dir%/*}/"}"
printf " │ %s" "$rel_path"
[ -n "$git_branch" ] && printf " │ %s" "$git_branch"
[ "$percent_used" -gt 0 ] && printf " │ %d%%" "$percent_used"
[ "$total_input" -gt 0 ] || [ "$total_output" -gt 0 ] && printf " │ %s/%s" "$(format_tokens "$total_input")" "$(format_tokens "$total_output")"
[ -n "$five_hour" ] && printf " │ 5h:%.0f%%" "$five_hour"
[ -n "$seven_day" ] && printf " │ 7d:%.0f%%" "$seven_day"
exit 0
