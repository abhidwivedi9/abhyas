# RCA Reference — Heartbeat failing to start after a config change

## Incident summary

- **Incident:** INC-heartbeat-wrong-user
- **Severity / duration / user impact:** Sev-2, ~5 min, internal health check red
- **SLO impact:** none formalized yet (pre-Milestone 7)

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | Fleet-wide service-account hardening edits unit files directly on hosts |
| T+0 | `heartbeat.service`'s `User=` line is changed to a nonexistent account (typo) |
| T+0 | Next restart fails immediately at systemd's USER resolution step |
| T+~2m | `HeartbeatServiceDown` fires |

## Root cause

A fleet-wide change hand-edited unit files directly on hosts rather than
through configuration management, introducing a typo in `heartbeat.service`'s
`User=` directive. Because the referenced account doesn't exist, systemd
fails before it can even attempt to exec the process — a distinct failure
mode (`status=217/USER`) from either an application crash or a file
permission issue, useful to recognize on sight.

## Contributing factors

- Direct, unreviewed edits to unit files on hosts instead of through
  Ansible — the same class of gap as INC-heartbeat-masked, recurring here
  with a different specific mistake.
- No validation step (e.g. `systemd-analyze verify`) run after manual unit
  file edits, which would have caught the invalid user before it caused an
  outage.

## What went well / what went poorly

- ✅ The specific systemd exit code (`217/USER`) pointed straight at the
  cause once noticed.
- ❌ Manual, unreviewed unit file edits across the fleet is a recurring
  root cause pattern worth addressing structurally, not incident by incident.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Route all unit-file changes through Ansible/config management, no direct host edits | prevent | Platform Engineer | P1 |
| 2 | Run `systemd-analyze verify` in CI or as a pre-change check for any unit file change | prevent | Platform Engineer | P2 |
| 3 | Note the recurring "hand-edited unit files on hosts" pattern across incidents in the next retro | mitigate | SRE on-call | P3 |
