# INC-heartbeat-crashloop: Heartbeat service down, health checks failing

> **Severity:** Sev-2 · **Tier:** L1 · **Role:** SRE on-call · **Time-box:** 30 min

## What the pager says

```
[FIRING] HeartbeatServiceDown — health probe to legacy-vm:8080/health has
been failing for 2m. Service: heartbeat. Host: legacy-vm.
```

## What the customer / stakeholder says

> "The facility monitoring dashboard's been red for a few minutes. Can
> someone confirm the life-support telemetry service is actually down and
> not just a flaky check? We can't have blind spots on the CO2 and
> filtration systems."

## What you know

- Environment: legacy-vm (local lab)
- Started: ~2 minutes ago
- Recent changes: a deploy went out to `heartbeat` earlier today. No other
  changes recorded.

## Acceptance criteria

- [ ] `heartbeat.service` is healthy and staying up (not just restarted once)
- [ ] `grade.sh` passes
- [ ] RCA drafted using the postmortem template (see `rca-reference.md` for
  the model answer, but try writing your own first)

## Getting started

```
abhyasctl scenario start INC-heartbeat-crashloop
```

That drops you into the box. From there, you have full shell access:

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 20+ minutes? `walkthrough.md` is spoiler-gated — open it section by
section, hint by hint.
