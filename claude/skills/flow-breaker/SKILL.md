---
name: flow-breaker
description: Manage flow-breaker tasks and check alarms. Use at session start to check status, and when the user asks to add/complete/snooze tasks or check their schedule.
allowed-tools: Bash(flow-breaker *)
---

# flow-breaker Task Manager

flow-breaker is a daily planner. A daemon on the Raspberry Pi holds the tasks. The `flow-breaker` CLI talks to it over HTTP.

Base URL (highest priority first): `FLOW_BREAKER_URL` env var → `~/.config/flow-breaker/client` → `http://localhost:7777`. On this Mac it is `https://rpi.tailec397d.ts.net`, which works only while Tailscale is connected.

## Alerts

Hooks do the monitoring; do not poll. SessionStart runs `flow-breaker nudge`. Every prompt runs `flow-breaker nudge --quiet`, which prints only when something is interrupt-worthy. There is no `watch` command.

When a nudge surfaces: mention it prominently, then continue the user's request. Never act on it unless the user asks.

## If the daemon is unreachable

`flow-breaker nudge` prints `⚠️ flow-breaker unreachable — tasks unknown`. Tell the user. The usual cause is that Tailscale is disconnected on the Mac. Do not say "the TUI is not running" — the TUI is not needed.

## Commands

Status:
- `flow-breaker nudge` — one-line status
- `flow-breaker status` — JSON status (`alarm_firing`, `overdue`, `upcoming`, `done`, `nudge`)
- `flow-breaker list` — today's active tasks
- `flow-breaker archive` — archived one-off tasks

Change tasks:
- `flow-breaker add HH:MM description [--repeat daily|once|weekdays|weekly|monthly] [--tags a,b] [--days Mon,Tue]`
- `flow-breaker capture <free text>` — schedules the text, or puts it in the inbox
- `flow-breaker done <query>` — mark a task done (id or text match)
- `flow-breaker snooze <id> [minutes]`

Examples:
- `flow-breaker add 09:00 Stand-up --repeat weekdays`
- `flow-breaker add 14:00 Call plumber --repeat once`
- `flow-breaker capture call mom tomorrow at 6pm`

Calendar:
- `flow-breaker cal-list` — today's events
- `flow-breaker cal-feeds` — configured feeds
- `flow-breaker cal-add <url|path> [--label name]` / `flow-breaker cal-remove <q>`

## Not available from the CLI

There are no `watch`, `edit`, `delete` or `dismiss` commands. To edit or delete one task, tell the user to use the TUI (`flow-breaker`, keys `e` / `d`). Never run `flow-breaker clear` unless the user explicitly asks — it deletes all tasks.

## Notes

- Always confirm task changes back to the user.
- Run `flow-breaker --help` if a command fails; the CLI may have changed.
