# RCA Reference — Audit finding: are heartbeat's logs actually being rotated?

## Incident summary

- Incident: INC-logrotate-misconfigured
- Severity / duration / user impact: Sev-3, near-miss (caught by audit,
  not by an outage) — framed deliberately differently from other RCAs in
  this catalog, since nothing actually broke yet
- SLO impact: none — this is prevention, not recovery

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T-? | A prior edit to the logrotate config introduces a one-character path typo |
| T-? to T+0 | The typo goes unnoticed; the config "exists" and looks syntactically fine in casual review |
| T+0 | A quarterly platform audit specifically checks whether configs actually function, not just whether they're present, and catches it |

## Root cause

A one-character typo in the logrotate config's path pattern
(`/var/log/heatbeat/` instead of `/var/log/heartbeat/`) caused the
rotation policy to match zero real files. logrotate does not treat an
empty match as an error — it silently has nothing to do for that block —
so nothing about running it manually or via cron looked broken. The
config remained silently non-functional until specifically dry-run
against the real directory structure.

## Contributing factors

- logrotate's lenient handling of empty glob matches means a typo like
  this produces no error signal anywhere by default.
- Whatever process introduced this typo (a prior manual edit) was not
  itself verified with `logrotate -d` at the time — the same audit
  technique that eventually caught it wasn't applied when the change
  was made.
- No automated, recurring check exists to catch this class of drift —
  it was only found because of a manual quarterly audit, not
  continuously.

## What went well / what went poorly

- Good: the quarterly audit process worked exactly as intended and
  caught a real gap before it caused an outage.
- Bad: this gap could have existed for an arbitrarily long time between
  audits — this was luck of timing, not a systematic guarantee.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Add `logrotate -d` verification as a required step whenever a logrotate config is edited | prevent | Platform Engineer | P1 |
| 2 | Add an automated periodic check (not just quarterly manual audit) that dry-runs every logrotate policy and alerts if any config matches zero files | detect | Platform Engineer | P1 |
