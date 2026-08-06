# RCA Reference — Heartbeat health check green, but is it actually logging?

## Incident summary

- **Incident:** INC-heartbeat-log-permission-denied
- **Severity / duration / user impact:** Sev-2, ~8 min, silent — health
  check stayed green throughout
- **SLO impact:** none formalized yet (pre-Milestone 7)

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | A security hardening pass changes `/var/log/heartbeat/heartbeat.log`'s owner to `root` |
| T+0 | Next log write attempt raises `PermissionError`; the background logging thread dies silently |
| T+0 | The HTTP health-check thread is unaffected and keeps returning `200` |
| T+~2m | A human escalates based on the stale log viewer, same as the prior disk-full incident |

## Root cause

A security hardening pass intended to tighten ownership on log directories
changed the owner of `heartbeat.log` itself to `root`, removing the
`heartbeat` service account's write access to its own log file. This is
the second incident in a row (see `INC-heartbeat-disk-full`) where the
service's background logging thread died independently of its HTTP health
thread — the health check's blind spot is now a recognized, recurring
pattern, not a one-off.

## Contributing factors

- The hardening pass changed file ownership without accounting for which
  service accounts need write access to which paths — an incomplete
  inventory of "what needs to write here."
- The health check gap identified in the prior disk-full incident's action
  items had not yet been implemented, so this incident recurred through
  the exact same undetected path.
- No pre-deployment testing of the hardening pass against a running
  instance of each affected service.

## What went well / what went poorly

- ✅ Diagnosis was faster this time — the on-call recognized the pattern
  from the prior incident immediately.
- ❌ The same class of gap (health check blind to background thread
  failures) caused two separate incidents because the fix wasn't
  implemented after the first one.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Actually implement the health-check-includes-log-activity fix from `INC-heartbeat-disk-full`'s action items — this is the second incident it would have prevented | detect | Platform Engineer | P0 |
| 2 | Require hardening passes to enumerate every service account that needs write access before applying ownership changes | prevent | Security | P1 |
| 3 | Add a specific runbook entry for "health green but log stale," since this pattern has now recurred | mitigate | SRE on-call | P2 |
