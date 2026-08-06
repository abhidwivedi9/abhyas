# INC-cart-service-oom-crashloop: Cart service repeatedly restarting, customers losing cart contents

> **Severity:** Sev-1 · **Tier:** L1 · **Role:** SRE on-call · **Time-box:** 20 min

## What the pager says

```
[FIRING] CartServiceRestartLoop — abhyas-cart-service has restarted 5+ times
in the last 2 minutes.
```

## What the customer / stakeholder says

> "Support's getting reports of shopping carts randomly emptying out mid-
> session. Whatever's happening, it's happening right now, live."

## What you know

- Environment: Milestone 2 compose stack (cart-service, catalog-service, redis)
- Started: ~2 minutes ago
- Recent changes: a resource-rightsizing pass touched container memory
  limits across the fleet earlier today, aiming to trim cloud spend

## Acceptance criteria

- [ ] `cart-service` is stable — not restarting
- [ ] `grade.sh` passes
- [ ] RCA drafted, including what "rightsizing" got wrong here

## Getting started

```
abhyasctl scenario start INC-cart-service-oom-crashloop
```

Investigate with plain `docker` commands — `docker ps`, `docker inspect`,
`docker stats` all work exactly the way they would on a real host.

Stuck for 15+ minutes? `walkthrough.md` is spoiler-gated.
