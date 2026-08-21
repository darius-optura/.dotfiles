#!/usr/bin/env bash
# PreToolUse hook: when the session cwd is inside a git worktree
# (.../.claude/worktrees/<owner>/<branch>), block edits that target the
# main checkout instead of the active worktree. Edits outside the repo
# entirely (scratchpad, ~/.claude, /tmp) are allowed.

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')

# Only enforce when operating inside a worktree.
case "$cwd" in
  */.claude/worktrees/*) ;;
  *) exit 0 ;;
esac
[ -z "$path" ] && exit 0

main_root="${cwd%%/.claude/worktrees/*}"
rest="${cwd#*/.claude/worktrees/}"   # <owner>/<branch>[/...]
owner="${rest%%/*}"
rest2="${rest#*/}"
branch="${rest2%%/*}"
wt_root="$main_root/.claude/worktrees/$owner/$branch"

case "$path" in
  /*) abs="$path" ;;
  *)  abs="$cwd/$path" ;;
esac

# Inside the worktree -> allow (checked first; worktree is nested under main_root).
case "$abs" in
  "$wt_root"|"$wt_root"/*) exit 0 ;;
esac

# Inside the main checkout but outside the worktree -> DENY.
case "$abs" in
  "$main_root"|"$main_root"/*)
    reason="Blocked: '$abs' is in the main checkout, not the active worktree. You are working in '$wt_root' — edit the copy there instead."
    jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
    ;;
esac

exit 0
