# RCA Reference — Daily report cron job has stopped producing output

## Incident summary

- Incident: INC-daily-report-not-executable
- Severity / duration / user impact: Sev-3, ~15 min, internal report
  freshness only
- SLO impact: none formalized yet (pre-Milestone 7)

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | A permissions cleanup across /opt strips the execute bit from daily_report.sh |
| T+0 | Every subsequent cron run fails silently with "Permission denied" |
| T+~15m | report.log staleness crosses the alert threshold |

## Root cause

A broad permissions cleanup removed the execute bit from
daily_report.sh, so cron's attempt to run it fails immediately with a
permission error rather than actually executing the script. This is the
second incident traced back to an overly broad permissions/ownership
change touching files it shouldn't have (see also
INC-heartbeat-permission-denied), reinforcing that broad, unscoped cleanup
scripts are a recurring root cause category on this host.

## Contributing factors

- The cleanup script's scope was not narrow enough to avoid touching
  script files that must remain executable.
- No monitoring on whether critical scripts still have their expected
  permissions after any bulk operation.

## What went well / what went poorly

- Good: staleness alerting caught this within the time-box.
- Bad: this is the second permissions-cleanup-caused incident on this
  host; the underlying process gap (unscoped bulk permission changes)
  still hasn't been fixed at the process level.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Scope all bulk permission/ownership scripts narrowly and dry-run them before applying | prevent | Platform Engineer | P0 |
| 2 | Add a periodic check that critical scripts still have their expected mode bits | detect | Platform Engineer | P2 |
