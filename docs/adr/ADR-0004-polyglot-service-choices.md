# ADR-0004: Polyglot service stack

- Status: Accepted
- Date: 2026-08-06

## Context

We could build all ~11 services in one language (simpler to maintain) or
deliberately mix stacks. Real Fortune 500 estates are heterogeneous, and each
runtime brings its own operational failure modes — which are exactly what the
scenario catalog needs.

## Decision

Polyglot on purpose, with each choice earning its place through the
operational lessons it uniquely teaches:

| Stack | Services | Operational curriculum it unlocks |
|---|---|---|
| Java / Spring Boot | catalog, checkout, payment, ledger | JVM heap/GC incidents, connection-pool exhaustion, JVM tuning, saga pattern |
| Python / FastAPI | cart, inventory, fraud, notification, recommendation | async pitfalls, GIL/worker sizing, Kafka consumer semantics, ML serving |
| NGINX + Envoy | storefront-gateway | TLS termination, cert rotation, rate limiting, WAF hooks |
| Locust / k6 | loadgen | load profiles, chaos load, Black Friday sims |

Data stores are likewise mixed (PostgreSQL, Redis, MongoDB, Kafka, RabbitMQ) so
learners can argue the tradeoffs — "why Mongo here, Postgres there" and
"Kafka vs RabbitMQ" are permanent interview fixtures.

## Consequences

- Higher maintenance surface: two language toolchains, multiple base images,
  broader CI matrix. Accepted as curriculum, not cost.
- Contributors need touch only one stack per change; CODEOWNERS routes reviews.
- No Go/Node service at launch — revisit if a scenario category demands one
  (supersede this ADR rather than silently adding stacks).
