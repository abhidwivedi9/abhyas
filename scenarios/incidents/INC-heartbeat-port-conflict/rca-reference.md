# RCA Reference — Heartbeat crash-looping right after another team's deploy on the same host

## Incident summary

- Incident: INC-heartbeat-port-conflict
- Severity / duration / user impact: Sev-2, ~10 min, internal health
  check red
- SLO impact: none formalized yet (pre-Milestone 7)

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | An unrelated ad-hoc diagnostic process is started on legacy-vm and binds port 8080 |
| T+0 | heartbeat.service is restarted (as part of routine operation) and fails to bind the same port |
| T+~2m | HeartbeatServiceDown fires |

## Root cause

An unrelated, ad-hoc process started by another team bound TCP port 8080
on the same shared host, which heartbeat also requires. When heartbeat's
own process next restarted, it failed immediately at socket bind time with
`Address already in use` — a network-layer conflict entirely external to
heartbeat's own code or configuration.

## Contributing factors

- No process on this shared host reserves or documents which ports are
  claimed by which service, so an ad-hoc process was free to collide with
  a production port without any warning.
- The ad-hoc process was started without checking for existing listeners
  first.
- Shared-host port contention is an inherent risk of this deployment
  model (multiple independent services on one host, no per-service
  network namespace isolation) — this incident is a direct consequence of
  that architecture, not just this one mistake.

## What went well / what went poorly

- Good: the specific OSError message pointed directly at the true cause
  (port conflict, not application logic) with no ambiguity.
- Bad: no port registry or pre-flight check exists to prevent this class
  of collision before it happens.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Maintain a documented port allocation registry for shared hosts | prevent | Platform Engineer | P1 |
| 2 | Require ad-hoc/manual process starts on shared hosts to check for port conflicts first (`ss -ltn` before binding) | prevent | Platform Engineer | P2 |
| 3 | Longer-term: this whole incident class goes away once services move to isolated network namespaces (containers/pods) — track as motivation for Milestone 2+ | prevent | Platform Engineer | P3 |
