# INC-heartbeat-wrong-user: Heartbeat failing to start after a config change

> **Severity:** Sev-2 · **Tier:** L1 · **Role:** SRE on-call · **Time-box:** 20 min

## What the pager says

```
[FIRING] HeartbeatServiceDown — heartbeat.service has been inactive for 2m.
Host: legacy-vm.
```

## What the customer / stakeholder says

> "Someone was tightening up service accounts across the fleet earlier.
> The life-support monitor might have been touched — not sure."

## What you know

- Environment: legacy-vm (local lab)
- Started: ~2 minutes ago
- Recent changes: a fleet-wide service-account hardening pass ran earlier
  today, editing unit files directly on several boxes.

## Acceptance criteria

- [ ] `heartbeat.service` is active and healthy
- [ ] `grade.sh` passes
- [ ] RCA drafted

## Getting started

```
abhyasctl scenario start INC-heartbeat-wrong-user
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 15+ minutes? `walkthrough.md` is spoiler-gated.
