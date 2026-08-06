# RCA Reference — Heartbeat service down, health checks failing

> Model blameless postmortem. Compare your own RCA against this **after**
> resolving the incident. Graded per the rubric in
> `docs/handbooks/postmortem-rubric.md`.

## Incident summary

- **Incident:** INC-heartbeat-crashloop
- **Severity / duration / user impact:** Sev-2, ~8 min, health checks red;
  no external customer impact in this scenario (internal service)
- **SLO impact:** heartbeat has no formal SLO yet (pre-Milestone 7); treated
  as an availability incident on the service's own health check

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | Bad deploy introduces a one-character typo in `heartbeat.py`'s import |
| T+0 | `systemctl restart heartbeat` picks up the broken file |
| T+0 onward | Service enters a continuous crash loop — crashes on import, systemd restarts it, crashes again, indefinitely (never self-terminates) |
| T+~2m | `/health` probe failures accumulate past alert threshold |
| T+2m | `HeartbeatServiceDown` fires |

## Root cause

The deployed `heartbeat.py` contained `import http.serverx` instead of
`import http.server` — a typo that raises `ModuleNotFoundError` on the very
first line executed. Because the error occurs at import time, every single
restart attempt fails identically and immediately; there is no partial
success and no self-healing possible — the process will crash on the next
attempt exactly as it did on this one, forever, until the underlying file is
fixed. The service stayed down until a human intervened not because systemd
gave up, but because *nothing* about retrying could ever succeed.

## Contributing factors

- No pre-deploy syntax/import check on `heartbeat.py` before it reached the
  box — a `python3 -m py_compile` or unit test run would have caught this
  before it ever started.
- No CI gate on this path yet (Milestone 4 introduces one for the app layer).
- No restart-limit action configured to escalate a runaway crash loop (e.g.
  paging louder, or stopping retries) — the unit burned restarts
  indefinitely rather than surfacing a harder failure signal.

## What went well / what went poorly

- ✅ The health check caught the outage correctly and quickly (~2 min).
- ✅ systemd's restart limiting prevented a noisy infinite crash loop from
  masking the real signal.
- ❌ Nothing validated the file before it was deployed — the bug should
  never have reached the box.
- ❌ No automated rollback existed; recovery required manual investigation.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Add a pre-deploy syntax check (`py_compile` or lint) for `heartbeat.py` | prevent | Platform Engineer | P1 |
| 2 | Configure a restart-limit action (e.g. give up and alert louder after N failures) instead of restarting forever | detect | Platform Engineer | P2 |
| 3 | Track this as motivation for Milestone 4's CI gate (build/test before deploy) | prevent | Platform Engineer | P3 |
