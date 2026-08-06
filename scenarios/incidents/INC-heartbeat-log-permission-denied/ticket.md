# INC-heartbeat-log-permission-denied: Heartbeat health check green, but is it actually logging?

> **Severity:** Sev-2 · **Tier:** L2 · **Role:** SRE on-call · **Time-box:** 20 min

## What the pager says

```
[FIRING] HeartbeatLogStale — heartbeat.log on legacy-vm has not been
written to in over 60s, but the service reports active.
```

## What the customer / stakeholder says

> "Same complaint as last time — dashboard's green, but I don't trust it.
> A security hardening pass touched file ownership across `/var/log`
> earlier today. Can you confirm heartbeat is genuinely fine?"

## What you know

- Environment: legacy-vm (local lab)
- Started: ~2 minutes ago
- Recent changes: a security hardening pass tightened ownership on several
  log directories earlier today.

## Acceptance criteria

- [ ] Heartbeat is genuinely healthy — logging is current, not just
  reporting "active"
- [ ] `grade.sh` passes
- [ ] RCA drafted

## Getting started

```
abhyasctl scenario start INC-heartbeat-log-permission-denied
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 15+ minutes? `walkthrough.md` is spoiler-gated.
