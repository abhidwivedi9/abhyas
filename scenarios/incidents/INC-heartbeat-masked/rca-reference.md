# RCA Reference — Heartbeat down, restart attempts having no effect

## Incident summary

- **Incident:** INC-heartbeat-masked
- **Severity / duration / user impact:** Sev-2, ~10 min, internal health check red
- **SLO impact:** none formalized yet (pre-Milestone 7)

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | A teammate, decommissioning an unrelated service, masks `heartbeat.service` by mistake (wrong unit name) |
| T+0 | The mask operation deletes the real unit file and replaces it with a `/dev/null` symlink |
| T+0 | The running heartbeat process is stopped as part of the same cleanup |
| T+~2m | `HeartbeatServiceDown` fires |

## Root cause

A unit was masked in error while a teammate was cleaning up a different,
deprecated service — most likely a wrong unit name typed during manual
cleanup. Masking is deliberately hard to reverse cheaply: it deletes the
real unit file, so simply unmasking does not restore service — the
original configuration has to be re-applied from source of truth (Ansible),
which is what actually resolved the incident.

## Contributing factors

- Manual, ad-hoc service cleanup on a live box instead of going through
  configuration management (no review, no diff, no confirmation of exact
  unit name before a destructive operation).
- No monitoring on unit `LoadState` — a masked critical service produces no
  distinct alert signal beyond the same "service down" page any other
  failure would generate, costing diagnosis time.

## What went well / what went poorly

- ✅ Root cause was found quickly once `Loaded: masked` was noticed.
- ✅ Recovery via re-running configuration management was fast and
  produced a known-good result (vs. hand-authoring a replacement unit).
- ❌ Manual, unreviewed service cleanup on a live box caused this entirely
  preventable incident.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Require decommissioning changes go through the same review/PR process as any other config change | prevent | Platform Engineer | P1 |
| 2 | Alert specifically on unexpected `LoadState=masked` for critical units | detect | SRE on-call | P2 |
| 3 | Document the mask/unmask + re-converge recovery procedure in the on-call runbook | mitigate | SRE on-call | P3 |
