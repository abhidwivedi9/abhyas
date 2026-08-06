# RCA Reference — Cart service repeatedly restarting, customers losing cart contents

## Incident summary

- Incident: INC-cart-service-oom-crashloop
- Severity / duration / user impact: Sev-1, ~10 min, active carts lost on
  every restart (Redis-backed state survives, but in-flight requests
  during a kill do not)
- SLO impact: cart-service availability SLO breached for the duration

## Timeline (all times UTC, relative to injection)

| Time | Event |
|---|---|
| T+0 | A resource-rightsizing pass sets cart-service's memory limit to 20MB, well under its ~43MB idle footprint |
| T+0 | Container restarts (per the rightsizing rollout) and immediately OOMs before finishing startup |
| T+0 onward | Continuous crash loop - every restart attempt fails identically |
| T+~2m | CartServiceRestartLoop fires |

## Root cause

A memory-rightsizing pass set cart-service's container memory limit to
20MB without first measuring actual usage. The application needs roughly
40-50MB just to start (Python interpreter + FastAPI + Redis client
overhead, before serving a single request), so every restart attempt hit
the kernel OOM killer before the process could finish initializing - a
self-sustaining crash loop with no code-level cause at all.

## Contributing factors

- The rightsizing pass set limits from an assumption or a template value
  rather than measured actual usage (docker stats / historical
  monitoring data).
- No pre-deployment smoke test caught the undersized limit before it
  reached a running service - the rollout itself caused the incident
  immediately, with no gap between "changed" and "broken."
- No canary/gradual rollout for the rightsizing change - it appears to
  have applied fleet-wide at once, per the ticket.

## What went well / what went poorly

- Good: OOMKilled and RestartCount gave an unambiguous signal once
  checked - no real ambiguity once someone knew to look there.
- Bad: the rightsizing change itself had no safety margin or validation
  step before rolling out.

## Action items

| # | Action | Type | Owner role | Priority |
|---|---|---|---|---|
| 1 | Base resource-rightsizing changes on measured usage with real headroom (e.g. 2-3x observed idle), never a flat template value | prevent | Platform Engineer | P0 |
| 2 | Roll out resource-limit changes gradually (canary a subset of hosts/replicas first) rather than fleet-wide at once | prevent | Platform Engineer | P1 |
| 3 | Add a startup smoke check that fails a resource-limit rollout if the target container can't reach a healthy state within N seconds | detect | Platform Engineer | P1 |
