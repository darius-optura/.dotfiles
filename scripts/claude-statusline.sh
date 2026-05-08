#!/usr/bin/env bash
# Claude Code status line — context, limits, model, cost, tokens, session, git, tasks

input=$(cat)

# ── helpers ──────────────────────────────────────────────────────────────────

RED=$'\e[31m'
YELLOW=$'\e[33m'
GREEN=$'\e[32m'
CYAN=$'\e[36m'
MAGENTA=$'\e[35m'
BLUE=$'\e[34m'
RESET=$'\e[0m'
DIM=$'\e[2m'
BOLD=$'\e[1m'

color_for_pct() {
  local pct=$1
  if   (( pct >= 80 )); then printf '%s' "$RED"
  elif (( pct >= 50 )); then printf '%s' "$YELLOW"
  else                       printf '%s' "$GREEN"
  fi
}

progress_bar() {
  local pct=$1
  local width=${2:-8}
  local filled=$(( pct * width / 100 ))
  (( filled > width )) && filled=$width
  local empty=$(( width - filled ))
  local bar=""
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty;  i++ )); do bar+="░"; done
  printf '%s' "$bar"
}

jval() { echo "$input" | jq -r "$1 // empty"; }

sep="${DIM} │ ${RESET}"
parts=()

# ── model ────────────────────────────────────────────────────────────────────

model=$(jval '.model.display_name')
if [ -n "$model" ]; then
  parts+=("${MAGENTA}${BOLD}${model}${RESET}")
fi

# ── context window ───────────────────────────────────────────────────────────

used_pct=$(jval '.context_window.used_percentage')
ctx_size=$(jval '.context_window.context_window_size')
input_tok=$(jval '.context_window.total_input_tokens')

if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  c=$(color_for_pct "$used_int")
  bar=$(progress_bar "$used_int" 8)

  # format token counts as compact (e.g. 45k/200k)
  tok_label=""
  if [ -n "$input_tok" ] && [ -n "$ctx_size" ]; then
    used_k=$(( input_tok / 1000 ))
    total_k=$(( ctx_size / 1000 ))
    tok_label=" ${DIM}${used_k}k/${total_k}k${RESET}"
  fi

  parts+=("${DIM}ctx${RESET} ${c}${bar} ${used_int}%${RESET}${tok_label}")
fi

# ── rate limits ──────────────────────────────────────────────────────────────

five_pct=$(jval '.rate_limits.five_hour.used_percentage')
seven_pct=$(jval '.rate_limits.seven_day.used_percentage')

if [ -n "$five_pct" ]; then
  five_int=$(printf '%.0f' "$five_pct")
  c=$(color_for_pct "$five_int")
  bar=$(progress_bar "$five_int" 6)
  parts+=("${DIM}5h${RESET} ${c}${bar} ${five_int}%${RESET}")
fi

if [ -n "$seven_pct" ]; then
  seven_int=$(printf '%.0f' "$seven_pct")
  c=$(color_for_pct "$seven_int")
  bar=$(progress_bar "$seven_int" 6)
  parts+=("${DIM}7d${RESET} ${c}${bar} ${seven_int}%${RESET}")
fi

# ── cost ─────────────────────────────────────────────────────────────────────

cost=$(jval '.cost.total_cost_usd')
if [ -n "$cost" ]; then
  cost_fmt=$(printf '$%.2f' "$cost")
  # color: green < $0.50, yellow < $2, red >= $2
  cost_cents=$(echo "$cost" | awk '{printf "%.0f", $1 * 100}')
  if   (( cost_cents >= 200 )); then cost_c="$RED"
  elif (( cost_cents >= 50  )); then cost_c="$YELLOW"
  else                               cost_c="$GREEN"
  fi
  parts+=("${cost_c}${cost_fmt}${RESET}")
fi

# ── lines changed ────────────────────────────────────────────────────────────

lines_add=$(jval '.cost.total_lines_added')
lines_rm=$(jval '.cost.total_lines_removed')
if [ -n "$lines_add" ] || [ -n "$lines_rm" ]; then
  line_info=""
  [ -n "$lines_add" ] && (( lines_add > 0 )) && line_info="${GREEN}+${lines_add}${RESET}"
  [ -n "$lines_rm" ] && (( lines_rm > 0 )) && line_info="${line_info}${line_info:+ }${RED}-${lines_rm}${RESET}"
  [ -n "$line_info" ] && parts+=("$line_info")
fi

# ── session duration ─────────────────────────────────────────────────────────

duration_ms=$(jval '.cost.total_duration_ms')
if [ -n "$duration_ms" ]; then
  total_s=$(( duration_ms / 1000 ))
  hrs=$(( total_s / 3600 ))
  mins=$(( (total_s % 3600) / 60 ))
  if (( hrs > 0 )); then
    dur_str="${hrs}h${mins}m"
  else
    dur_str="${mins}m"
  fi
  parts+=("${DIM}${dur_str}${RESET}")
fi

# ── git branch ───────────────────────────────────────────────────────────────

cwd=$(jval '.cwd')
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    parts+=("${CYAN} ${branch}${RESET}")
  fi
fi

# ── worktree ─────────────────────────────────────────────────────────────────

wt_name=$(jval '.worktree.name')
if [ -n "$wt_name" ]; then
  parts+=("${BLUE}⎇ ${wt_name}${RESET}")
fi

# ── caveman badge ────────────────────────────────────────────────────────────

caveman_badge=$(bash "${HOME}/.claude/hooks/caveman-statusline.sh" 2>/dev/null)
if [ -n "$caveman_badge" ]; then
  parts+=("$caveman_badge")
fi

# ── assemble ─────────────────────────────────────────────────────────────────

output=""
for (( i=0; i<${#parts[@]}; i++ )); do
  (( i > 0 )) && output+="$sep"
  output+="${parts[$i]}"
done

printf '%s' "$output"
