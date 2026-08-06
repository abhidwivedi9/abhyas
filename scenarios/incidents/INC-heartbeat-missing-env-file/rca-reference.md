# RCA Reference — Heartbeat completely refuses to start after a partial config rollout

## Incident summary

- Incident: INC-heartbeat-missing-env-file
- Severity / duration / user impact: Sev-2, ~5 min, internal health
  check red
- SLO impact: none formalized yet (pre-Milestone 7)

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | A config rollout adds an EnvironmentFile= reference to heartbeat's unit but the referenced file is never actually shipped |
| T+0 | Next restart fails immediately — systemd refuses to even attempt starting the process |
| T+~2m | HeartbeatServiceDown fires |

## Root cause

A configuration rollout updated heartbeat's systemd unit to reference an
environment file (`EnvironmentFile=/etc/heartbeat/heartbeat.env`) intended
to carry new configuration, but the actual file was never deployed —
an incomplete, partial rollout. Because `EnvironmentFile=` without a
leading `-` is mandatory by systemd's own semantics, the missing file
caused the unit to fail at the job-start step entirely, before the
application process was ever launched.

## Contributing factors

- The rollout that changed the unit file and the rollout that was
  supposed to ship the environment file were not applied atomically —
  one landed without the other.
- No validation step (`systemd-analyze verify`, or simply attempting a
  restart) was run immediately after the unit file change to catch the
  incompleteness before it caused an outage.

## What went well / what went poorly

- Good: the specific "Failed to load environment files" message pointed
  directly at the cause with no ambiguity.
- Bad: a partial, non-atomic rollout was allowed to reach the host at all.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Ship unit file changes and any files they reference as a single atomic change, not separate steps | prevent | Platform Engineer | P1 |
| 2 | Run `systemd-analyze verify` (or attempt an immediate restart) right after any unit file change, before considering the rollout complete | prevent | Platform Engineer | P1 |
