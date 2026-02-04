#!/bin/bash

input=$(cat)

current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
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

# Git branch
git_branch=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null)
  [ -n "$branch" ] && git_branch="$branch"
fi

# Current directory name
dir_name=$(basename "$current_dir")

# Format tokens (e.g., 15234 -> 15.2k)
format_tokens() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    printf "%.1fk" "$(echo "scale=1; $n / 1000" | bc)"
  else
    printf "%d" "$n"
  fi
}

# Output
printf "%s" "$model"
printf " │ %s" "$dir_name"
[ -n "$git_branch" ] && printf " │ ⎇ %s" "$git_branch"
printf " │ %d%%" "$percent_used"
printf " │ %s/%s" "$(format_tokens "$total_input")" "$(format_tokens "$total_output")"
