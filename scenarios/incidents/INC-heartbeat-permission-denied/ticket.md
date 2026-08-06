# INC-heartbeat-permission-denied: Heartbeat won't start after routine server maintenance

> **Severity:** Sev-2 · **Tier:** L1 · **Role:** SRE on-call · **Time-box:** 20 min

## What the pager says

```
[FIRING] HeartbeatServiceDown — heartbeat.service has been inactive for 2m.
Host: legacy-vm.
```

## What the customer / stakeholder says

> "Facilities ran routine file cleanup on the tank-monitoring host
> overnight. Life-support telemetry's been down since. Nothing in the
> change log about the monitor itself."

## What you know

- Environment: legacy-vm (local lab)
- Started: ~2 minutes ago
- Recent changes: overnight maintenance script touched file ownership and
  permissions across `/opt`. No application code changes.

## Acceptance criteria

- [ ] `heartbeat.service` is active and healthy
- [ ] `grade.sh` passes
- [ ] RCA drafted (see `rca-reference.md` for the model answer after you try)

## Getting started

```
abhyasctl scenario start INC-heartbeat-permission-denied
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 15+ minutes? `walkthrough.md` is spoiler-gated.
