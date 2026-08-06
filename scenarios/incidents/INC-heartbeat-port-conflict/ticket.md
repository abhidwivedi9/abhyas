# INC-heartbeat-port-conflict: Heartbeat crash-looping right after another team's deploy on the same host

> Severity: Sev-2 - Tier: L2 - Role: SRE on-call - Time-box: 20 min

## What the pager says

```
[FIRING] HeartbeatServiceDown - heartbeat.service has been inactive for 2m.
Host: legacy-vm.
```

## What the customer / stakeholder says

> "Another team just deployed a quick diagnostic tool on legacy-vm for
> some manual testing. Heartbeat went down right after. They swear it's
> unrelated."

## What you know

- Environment: legacy-vm (local lab)
- Started: ~2 minutes ago
- Recent changes: another team started an ad-hoc process on this shared
  host shortly before the page fired

## Acceptance criteria

- [ ] heartbeat.service is active and healthy
- [ ] grade.sh passes
- [ ] RCA drafted

## Getting started

```
abhyasctl scenario start INC-heartbeat-port-conflict
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 15+ minutes? walkthrough.md is spoiler-gated.
