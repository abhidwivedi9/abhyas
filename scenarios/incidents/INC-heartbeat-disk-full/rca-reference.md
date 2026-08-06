# RCA Reference — Heartbeat health check green, but on-call suspects it's actually stuck

## Incident summary

- **Incident:** INC-heartbeat-disk-full
- **Severity / duration / user impact:** Sev-2, ~10 min, silent — the
  standard health check never went red; caught only because someone
  noticed the log viewer looked stale
- **SLO impact:** none formalized yet (pre-Milestone 7); this incident is
  itself an argument for why liveness-only SLIs are insufficient

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | `/var/log/heartbeat` fills to 100% (simulated runaway disk usage) |
| T+0 | Next log write in the heartbeat loop fails with `ENOSPC`; the background logging thread dies silently |
| T+0 | The HTTP health-check thread is unaffected and keeps returning `200` |
| T+~2m | A human notices the log viewer looks stale and escalates — no automated alert fired |

## Root cause

The service's health check only verifies that its HTTP thread is alive and
responding — it does not verify that the service's actual work (writing
heartbeat records) is still happening. When the log volume filled and the
logging thread crashed on `ENOSPC`, the process as a whole kept running
and kept reporting healthy, because Python's default behavior on an
uncaught exception in a non-main thread is to print a traceback and let
that one thread die, without affecting the rest of the process.

## Contributing factors

- Health check design only validates process liveness, not actual
  function — a shallow check that this incident specifically exposes as
  insufficient.
- No alerting on log staleness independent of the health check (this
  incident's own pager alert, `HeartbeatLogStale`, didn't exist until
  after this incident — a good example of an RCA action item becoming the
  detection mechanism for its own incident class).
- No disk usage alerting on the volume before it filled completely.

## What went well / what went poorly

- ✅ Once investigated, the root cause was clear from the journal and `df`.
- ❌ The standard health check gave false confidence for the entire
  duration of the incident.
- ❌ No proactive disk usage alerting existed.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Add disk usage alerting on log volumes before they reach 100% | prevent | Platform Engineer | P1 |
| 2 | Extend the health check to verify recent log activity, not just HTTP liveness | detect | Platform Engineer | P1 |
| 3 | Make the logging thread's failure crash the whole process (fail loud) instead of dying silently | prevent | Platform Engineer | P2 |
