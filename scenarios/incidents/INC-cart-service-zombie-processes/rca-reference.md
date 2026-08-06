# RCA Reference — Cart service process count climbing steadily, no obvious cause

## Incident summary

- Incident: INC-cart-service-zombie-processes
- Severity / duration / user impact: Sev-3, ~15 min, no customer-facing
  impact observed (caught before process-table exhaustion)
- SLO impact: none - this incident is about a latent risk, not an outage

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | A one-off maintenance script starts running inside cart-service's container, forking a child every second without reaping any of them |
| T+0 onward | Each exited child is orphaned to PID 1 (uvicorn), which never reaps unrelated processes - zombie count climbs steadily |
| T+~10m | Process-count monitoring crosses its alert threshold |

## Root cause

A maintenance/debug script was run inside the container that repeatedly
forked child processes without ever calling `wait()` on them. Because the
container's PID 1 (`uvicorn`, the application itself) is not a real init
system and has no reason to reap processes it never created, every
orphaned child became a permanent zombie once the script's own process
line ended. The application continued serving requests normally
throughout, since zombie processes consume negligible resources - the
real risk was process-table exhaustion if left unaddressed, not
immediate performance impact.

## Contributing factors

- The container has no proper init process (`tini`/`--init`) to reap
  orphaned children automatically, which is the standard hardening
  measure that would have prevented this from being a lasting problem.
- The one-off script was run directly against a running production-like
  container rather than in an isolated, disposable environment.
- No pre-existing alert on zombie-process count specifically - it was
  caught by a broader process-count metric, not a targeted signal.

## What went well / what went poorly

- Good: broad process-count monitoring caught this well before it became
  a real outage (process-table exhaustion).
- Bad: the container lacks the standard hardening (proper init) that
  would make this class of issue self-healing instead of accumulating
  indefinitely.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Add a proper init (`tini` or Docker's `--init`) to the container so orphaned children get reaped automatically | prevent | Platform Engineer | P1 |
| 2 | Require one-off scripts to run in a disposable container/exec session, not directly inside a running production container | prevent | Platform Engineer | P2 |
| 3 | Add a dedicated zombie-process-count alert, distinct from general process-count monitoring, for faster root-cause identification next time | detect | Platform Engineer | P3 |
