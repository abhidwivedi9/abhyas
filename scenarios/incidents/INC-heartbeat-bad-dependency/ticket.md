# INC-heartbeat-bad-dependency: Heartbeat won't come back up after a maintenance window

> Severity: Sev-2 - Tier: L2 - Role: SRE on-call - Time-box: 20 min

## What the pager says

```
[FIRING] HeartbeatServiceDown - heartbeat.service has been inactive for 2m.
Host: legacy-vm.
```

## What the customer / stakeholder says

> "We took the life-support monitor down briefly for a planned
> maintenance window and decommissioned an old internal dependency it
> used to rely on at the same time. It should have been updated to not
> need that anymore, but it won't come back up."

## What you know

- Environment: legacy-vm (local lab)
- Started: right after the maintenance window ended
- Recent changes: a related internal service was decommissioned during
  the same maintenance window

## Acceptance criteria

- [ ] heartbeat.service is active and healthy
- [ ] grade.sh passes
- [ ] RCA drafted

## Getting started

```
abhyasctl scenario start INC-heartbeat-bad-dependency
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 15+ minutes? walkthrough.md is spoiler-gated.
