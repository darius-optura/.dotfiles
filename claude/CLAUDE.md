## flow-breaker

The `SessionStart` hook already runs `flow-breaker nudge`. If its output shows overdue tasks, mention them prominently before proceeding.

During long sessions, run `flow-breaker nudge` every 30 minutes to check for new overdue tasks. If the user asks you to monitor tasks, use `/loop 30m flow-breaker nudge` to automate this.

@RTK.md
