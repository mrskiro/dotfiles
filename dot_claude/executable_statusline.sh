#!/bin/bash
# Claude Code status line. Two lines, sized for narrow split panes.
#   line 1: model, effort, worktree (or branch)
#   line 2: context usage bar, 5h / 7d rate limits
# Input schema: https://code.claude.com/docs/en/statusline
#
# bash 3.2 (the macOS system bash) corrupts multibyte literals when they are
# appended to a variable under a UTF-8 locale: `b="$b▓"` drops the leading
# byte. Byte semantics keep the box-drawing glyphs intact, and every string we
# measure is ASCII, so ${#s} and ${s:0:n} stay correct.
export LC_ALL=C

input=$(cat)

# One jq call, one field per line. Empty fields stay as empty lines.
i=0
while IFS= read -r line; do
  f[$i]="$line"
  i=$((i + 1))
done < <(
  jq -r '[
    .model.display_name // "",
    .effort.level // "",
    (if .fast_mode then "fast" else "" end),
    (.worktree.name // .workspace.git_worktree // ""),
    (.context_window.used_percentage // 0 | floor),
    (if .exceeds_200k_tokens then "1" else "" end),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.workspace.current_dir // .cwd // "")
  ] | .[] | tostring' <<<"$input"
)

model=${f[0]}
effort=${f[1]}
fast=${f[2]}
worktree=${f[3]}
pct=${f[4]}
exceeds=${f[5]}
five_hour=${f[6]}
seven_day=${f[7]}
cwd=${f[8]}

cols=${COLUMNS:-80}

DIM=$'\033[2m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'
RESET=$'\033[0m'

# Green under 50%, yellow under 80%, red at or above.
heat() {
  local n=${1%%.*}
  if [ "$n" -ge 80 ]; then printf "%s" "$RED"
  elif [ "$n" -ge 50 ]; then printf "%s" "$YELLOW"
  else printf "%s" "$GREEN"
  fi
}

truncate() {
  local s=$1 max=$2
  if [ ${#s} -gt "$max" ]; then
    printf "%s…" "${s:0:$((max - 1))}"
  else
    printf "%s" "$s"
  fi
}

# "Opus 5 (1M context)" -> "Opus 5 1M"
model=${model/ (1M context)/ 1M}
model=$(truncate "$model" 20)

# Fall back to the branch (or short SHA) outside a worktree.
label=$worktree
if [ -z "$label" ]; then
  label=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null) ||
    label=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null) ||
    label=""
fi

# Segments carry their rendered width separately, because the escape codes in
# the string itself make ${#...} useless for fitting the line to the terminal.
head=$CYAN$model$RESET
head_w=${#model}

if [ -n "$effort" ] || [ -n "$fast" ]; then
  head="$head $DIM│$RESET "
  head_w=$((head_w + 3))
  if [ -n "$effort" ]; then
    head="$head$DIM$effort$RESET"
    head_w=$((head_w + ${#effort}))
  fi
  if [ -n "$fast" ]; then
    head="$head $YELLOW$fast$RESET"
    head_w=$((head_w + 1 + ${#fast}))
  fi
fi

tail=""
tail_w=0
add_tail() { # $1 color, $2 plain text
  tail="$tail $DIM│$RESET $1$2$RESET"
  tail_w=$((tail_w + 3 + ${#2}))
}

add_tail "$(heat "$pct")" "ctx $pct%"
[ -n "$exceeds" ] && add_tail "$RED" ">200k"
if [ -n "$five_hour" ]; then
  printf -v n "%.0f" "$five_hour"
  add_tail "$(heat "$n")" "5h $n%"
fi
if [ -n "$seven_day" ]; then
  printf -v n "%.0f" "$seven_day"
  add_tail "$(heat "$n")" "7d $n%"
fi

# The worktree name gets whatever width is left, and is dropped entirely when
# that is not enough to stay readable.
mid=""
if [ -n "$label" ]; then
  budget=$((cols - head_w - tail_w - 4))
  [ "$budget" -gt 24 ] && budget=24
  [ "$budget" -ge 6 ] && mid=" $DIM│$RESET $(truncate "$label" "$budget")"
fi

printf "%s%s%s\n" "$head" "$mid" "$tail"

exit 0
