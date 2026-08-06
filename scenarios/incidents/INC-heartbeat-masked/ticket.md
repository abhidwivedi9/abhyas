# INC-heartbeat-masked: Heartbeat down, restart attempts having no effect

> **Severity:** Sev-2 · **Tier:** L1 · **Role:** SRE on-call · **Time-box:** 20 min

## What the pager says

```
[FIRING] HeartbeatServiceDown — heartbeat.service has been inactive for 2m.
Host: legacy-vm.
```

## What the customer / stakeholder says

> "Someone on the team was decommissioning an old, unrelated service on
> the monitoring host earlier today. Life-support telemetry's been down
> since shortly after."

## What you know

- Environment: legacy-vm (local lab)
- Started: ~2 minutes ago
- Recent changes: a teammate was cleaning up a deprecated service on this
  box earlier today. They believe their change was unrelated to heartbeat.

## Acceptance criteria

- [ ] `heartbeat.service` is active and healthy
- [ ] `grade.sh` passes
- [ ] RCA drafted

## Getting started

```
abhyasctl scenario start INC-heartbeat-masked
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 15+ minutes? `walkthrough.md` is spoiler-gated.
