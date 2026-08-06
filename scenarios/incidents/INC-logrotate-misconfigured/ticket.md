# INC-logrotate-misconfigured: Audit finding: are heartbeat's logs actually being rotated?

> Severity: Sev-3 - Tier: L2 - Role: Platform Engineer - Time-box: 20 min

## What the pager says

(No pager alert — this came from a routine platform audit, not an outage.)

## What the customer / stakeholder says

> "Doing a quarterly review of our logrotate configs across the fleet.
> Can you confirm the life-support monitor's log rotation policy on this
> host is actually working, not just present? A few other hosts had
> configs that looked fine but silently weren't doing anything."

## What you know

- Environment: legacy-vm (local lab)
- A logrotate policy exists at /etc/logrotate.d/heartbeat
- No incident has occurred yet — this is a proactive check, the kind of
  thing that prevents a future INC-heartbeat-disk-full repeat

## Acceptance criteria

- [ ] Confirmed (not assumed) that heartbeat's real log files are covered
  by the rotation policy
- [ ] grade.sh passes
- [ ] RCA drafted (frame this as a near-miss, not an outage)

## Getting started

```
abhyasctl scenario start INC-logrotate-misconfigured
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 15+ minutes? walkthrough.md is spoiler-gated.
