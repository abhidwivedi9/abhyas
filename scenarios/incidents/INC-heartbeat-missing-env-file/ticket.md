# INC-heartbeat-missing-env-file: Heartbeat completely refuses to start after a partial config rollout

> Severity: Sev-2 - Tier: L1 - Role: SRE on-call - Time-box: 20 min

## What the pager says

```
[FIRING] HeartbeatServiceDown - heartbeat.service has been inactive for 2m.
Host: legacy-vm.
```

## What the customer / stakeholder says

> "There was a partial rollout earlier today meant to add some new
> configuration to the life-support monitor. It might not have fully
> completed."

## What you know

- Environment: legacy-vm (local lab)
- Started: ~2 minutes ago
- Recent changes: a config rollout to heartbeat started earlier today;
  unclear if it finished

## Acceptance criteria

- [ ] heartbeat.service is active and healthy
- [ ] grade.sh passes
- [ ] RCA drafted

## Getting started

```
abhyasctl scenario start INC-heartbeat-missing-env-file
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 15+ minutes? walkthrough.md is spoiler-gated.
