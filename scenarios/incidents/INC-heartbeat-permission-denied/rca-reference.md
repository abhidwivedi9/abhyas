# RCA Reference — Heartbeat won't start after routine server maintenance

## Incident summary

- **Incident:** INC-heartbeat-permission-denied
- **Severity / duration / user impact:** Sev-2, ~5 min, internal health check red
- **SLO impact:** none formalized yet (pre-Milestone 7)

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | Overnight maintenance strips the execute bit from `heartbeat.py` |
| T+0 | Next `systemctl restart heartbeat` (or a routine restart) fails immediately |
| T+~2m | `/health` probe failures accumulate past alert threshold |
| T+2m | `HeartbeatServiceDown` fires |

## Root cause

A maintenance script that normalized file permissions across `/opt`
(intended for a different directory tree) also touched
`/opt/heartbeat/heartbeat.py`, removing its execute bit. `heartbeat.service`
runs this file directly as `ExecStart`, so systemd cannot even fork the
process — this is an OS-level permission failure, not an application bug,
which is why there is no Python traceback anywhere in the journal.

## Contributing factors

- The maintenance script's file-permission scope was too broad — it should
  have been scoped to its intended target directory only.
- No monitoring on "does this file still have its expected permissions,"
  so the drift was silent until the next restart surfaced it.
- No post-maintenance smoke test that would have caught this immediately
  after the script ran, rather than on next natural restart.

## What went well / what went poorly

- ✅ The health check caught it quickly once the service actually failed.
- ❌ The maintenance script had no scoping/dry-run safeguard.
- ❌ Nothing validated service health immediately after maintenance ran.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Scope the maintenance script's permission changes to its intended path only | prevent | Platform Engineer | P1 |
| 2 | Add a post-maintenance smoke check that restarts and verifies key services | detect | SRE on-call | P2 |
| 3 | Track expected file modes for critical paths (config drift detection) | detect | Platform Engineer | P3 |
