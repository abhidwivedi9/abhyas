# INC-heartbeat-disk-full: Heartbeat health check green, but on-call suspects it's actually stuck

> **Severity:** Sev-2 · **Tier:** L2 · **Role:** SRE on-call · **Time-box:** 25 min

## What the pager says

```
[FIRING] HeartbeatLogStale — heartbeat.log on legacy-vm has not been
written to in over 60s, but the service reports active.
```

## What the customer / stakeholder says

> "The dashboard says life-support telemetry is healthy and green, but
> something feels off — the log viewer hasn't refreshed in a while. Can
> you actually confirm it's working, not just confirm the check passes?
> If the CO2 monitor's actually gone silent, that's a welfare problem,
> not just a metrics gap."

## What you know

- Environment: legacy-vm (local lab)
- Started: ~2 minutes ago
- Recent changes: none reported. `systemctl status` and the `/health`
  endpoint both currently report the service as fine.

## Acceptance criteria

- [ ] `heartbeat.service` is genuinely healthy — logging is current, not
  just reporting "active"
- [ ] `grade.sh` passes
- [ ] RCA drafted, including why the standard health check didn't catch this

## Getting started

```
abhyasctl scenario start INC-heartbeat-disk-full
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 20+ minutes? `walkthrough.md` is spoiler-gated.
