# ADR-0003: Local-first principle

- Status: Accepted
- Date: 2026-08-06

## Context

The reference deployment targets GKE across two regions. But a large share of
the audience — students, career-switchers, engineers in regions without cheap
cloud access — has no cloud budget. A learning platform that requires a paid
cloud account fails its mission. Meanwhile, some depth (managed load balancers,
Cloud SQL failover, Workload Identity) only exists in a real cloud.

## Decision

**Every milestone must run end-to-end on `kind`** with resource-trimmed
Kustomize overlay profiles. The GCP track is additive depth, never a
prerequisite. Concretely:

1. `meridianctl up` brings up the full current-milestone stack on kind on a
   16 GB laptop.
2. Every scenario's `inject.sh`/`grade.sh` pair must pass on kind; GCP-only
   scenarios are explicitly tagged and kept to a minority.
3. Cloud-managed components get in-cluster equivalents (Cloud SQL →
   CloudNativePG, Memorystore → in-cluster Redis, GCLB → NGINX/HAProxy track).
4. Each component's docs carry an AWS/Azure equivalence table so knowledge
   transfers across clouds.

## Consequences

- Doubles some implementation work (managed + in-cluster flavors) — accepted,
  because the comparison itself is curriculum ("why Memorystore vs self-run
  Redis" is an interview staple).
- Resource-trimmed profiles diverge from prod-realistic sizing; scenarios that
  depend on scale must document reduced-scale reproductions.
- CI runs the kind track on every PR; the GCP track runs on a schedule against
  a project the maintainers fund.
