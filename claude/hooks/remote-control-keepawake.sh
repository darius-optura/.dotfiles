#!/usr/bin/env bash
set -euo pipefail

PID_FILE="$HOME/.claude/.remote-control-caffeinate.pid"

is_running() {
  [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null
}

start_caffeinate() {
  if is_running; then
    printf 'keep-awake already ON (pid %s)\n' "$(cat "$PID_FILE")"
    return 0
  fi
  nohup caffeinate -d -i -s -m >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  disown 2>/dev/null || true
  printf 'keep-awake ON (pid %s)\n' "$(cat "$PID_FILE")"
}

stop_caffeinate() {
  if [[ -f "$PID_FILE" ]]; then
    pid=$(cat "$PID_FILE")
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    printf 'keep-awake OFF\n'
  else
    printf 'keep-awake already OFF\n'
  fi
}

status_caffeinate() {
  if is_running; then
    printf 'keep-awake ON (pid %s)\n' "$(cat "$PID_FILE")"
  else
    printf 'keep-awake OFF\n'
  fi
}

# CLI mode: explicit on/off/status arg
if [[ $# -gt 0 ]]; then
  case "$1" in
    on|start)   start_caffeinate ;;
    off|stop)   stop_caffeinate ;;
    status)     status_caffeinate ;;
    *) printf 'usage: %s [on|off|status]\n' "$0" >&2; exit 2 ;;
  esac
  exit 0
fi

# Hook mode: read JSON prompt from stdin
input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null || true)

case "$prompt" in
  /remote-control*) start_caffeinate >&2 ;;
esac

exit 0
