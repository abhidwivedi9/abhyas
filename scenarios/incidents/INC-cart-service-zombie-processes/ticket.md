# INC-cart-service-zombie-processes: Cart service process count climbing steadily, no obvious cause

> **Severity:** Sev-3 · **Tier:** L2 · **Role:** SRE on-call · **Time-box:** 20 min

## What the pager says

```
[FIRING] CartServiceProcessCountHigh — process count inside
abhyas-cart-service has grown steadily for the last 10 minutes.
```

## What the customer / stakeholder says

> "Monitoring's flagging that cart-service's process count keeps
> climbing. The app itself seems to be responding fine to requests
> though — nobody's noticed any customer impact yet."

## What you know

- Environment: Milestone 2 compose stack (cart-service, catalog-service, redis)
- Started: ~10 minutes ago, climbing steadily since
- Recent changes: someone ran a one-off maintenance/debug script inside
  the container earlier today

## Acceptance criteria

- [ ] Process count inside `cart-service` is back to normal and stable
- [ ] `grade.sh` passes
- [ ] RCA drafted — including why the app kept serving requests fine the
  whole time this was happening

## Getting started

```
abhyasctl scenario start INC-cart-service-zombie-processes
```

Investigate with plain `docker exec` and process-inspection commands —
same as you'd use on a real host.

Stuck for 15+ minutes? `walkthrough.md` is spoiler-gated.
