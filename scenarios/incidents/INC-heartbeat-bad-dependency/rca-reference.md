# RCA Reference — Heartbeat won't come back up after a maintenance window

## Incident summary

- Incident: INC-heartbeat-bad-dependency
- Severity / duration / user impact: Sev-2, ~10 min, internal health
  check red
- SLO impact: none formalized yet (pre-Milestone 7)

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | A maintenance window decommissions an internal service that heartbeat's unit still hard-depends on (Requires=) |
| T+0 | heartbeat.service is stopped as part of the same maintenance window |
| T+0 | Attempting to start heartbeat again fails immediately: the required unit no longer exists |
| T+~2m | HeartbeatServiceDown fires |

## Root cause

heartbeat.service's unit file declared a hard dependency
(`Requires=ghost-dependency.service`) on another internal service. During
a maintenance window, that dependency was decommissioned without first
confirming nothing still required it. Because `Requires=` is a hard
dependency (unlike the softer `Wants=`), systemd refuses to even attempt
starting heartbeat once the required unit can no longer be found — an
immediate, hard outage for the dependent service rather than a gradual
degradation.

## Contributing factors

- No dependency audit was performed before decommissioning the internal
  service — nothing checked what else on the host declared it as a
  Requires=.
- The maintenance window's runbook (if one existed) did not include a
  step to verify dependent units would still start after the change.

## What went well / what went poorly

- Good: the specific "Unit ... not found" error pointed directly and
  unambiguously at the cause.
- Bad: no dependency check was performed before decommissioning
  something else still relied on — this is a process gap, not a technical
  one.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Require a dependency audit (grep Requires=/Wants= across unit files) before decommissioning any service | prevent | Platform Engineer | P0 |
| 2 | Prefer Wants= over Requires= where a hard failure isn't actually the desired behavior | prevent | Platform Engineer | P2 |
