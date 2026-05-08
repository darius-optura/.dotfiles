---
name: flow-breaker
description: Manage flow-breaker tasks and monitor alarms. Auto-activates at session start to check status and begin alarm monitoring. Use when user asks to add/edit/complete/delete tasks or check their schedule.
allowed-tools: Bash(flow-breaker *)
---

# flow-breaker Task Manager

You are connected to flow-breaker, a terminal daily planner. You can manage tasks and monitor alarms through its CLI/socket interface.

## On Session Start

1. Run `flow-breaker nudge` to check current status
2. Surface any overdue tasks or alarms to the user immediately
3. Start the alarm monitoring loop (see below)

## Alarm Monitoring Loop

Start a long-poll watch to get real-time alarm notifications:

1. Run `flow-breaker watch --timeout 55` in background
2. When it returns, check the JSON output:
   - `{"event":"alarm_fired","task":{...}}` → Tell the user immediately: "🚨 ALARM: [task desc] at [time] — would you like to mark it done, snooze, or dismiss?"
   - `{"event":"alarm_dismissed"}` → Alarm was handled in the TUI, no action needed
   - `{"event":"task_added","task":{...}}` → A task was added (possibly from TUI)
   - `{"event":"timeout"}` → No events, just re-launch watch
3. After processing, re-launch the watch command
4. If watch fails (TUI not running), fall back to `flow-breaker nudge` every 60 seconds

## Task Management Commands

### Add a task
```bash
flow-breaker add HH:MM description [--repeat daily|once|weekdays|weekly|monthly] [--tags a,b] [--days Mon,Tue]
```

Examples:
- `flow-breaker add 09:00 standup --repeat weekdays`
- `flow-breaker add 14:30 dentist appointment --repeat once`
- `flow-breaker add 12:00 lunch --repeat daily --tags health`

### Mark task done
```bash
flow-breaker done <id>
```

### Edit a task (requires TUI running)
```bash
flow-breaker edit <id> [--time HH:MM] [--desc new description] [--repeat daily] [--tags a,b] [--days Mon,Tue]
```

### Delete a task (requires TUI running)
```bash
flow-breaker delete <id>
```

### Dismiss a task (requires TUI running)
```bash
flow-breaker dismiss <id>
```

### Snooze a task (requires TUI running)
```bash
flow-breaker snooze <id> [minutes]
```

## Status Queries

- `flow-breaker nudge` — one-liner status (works always)
- `flow-breaker status` — full JSON status
- `flow-breaker list` — list active tasks
- `flow-breaker cal-list` — today's calendar events

## Responding to Alarm Events

When you receive an alarm_fired event:
1. Immediately notify the user with the task details
2. Ask what they want to do: done, snooze, or dismiss
3. Execute their choice using the appropriate command
4. The watch loop will pick up the alarm_dismissed event automatically

## Important Notes

- Task IDs are numeric (shown in brackets when adding tasks, or in status JSON)
- Commands that modify tasks (edit, delete, dismiss, snooze) require the TUI to be running
- The add command works both with and without the TUI running
- Always confirm task changes back to the user
