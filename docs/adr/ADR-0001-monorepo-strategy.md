# ADR-0001: Monorepo for platform + application code

- Status: Accepted
- Date: 2026-08-06

## Context

Meridian spans ~11 microservices, IaC, CI/CD definitions, observability config,
security tooling, AI Ops components, and a 200+ scenario catalog. We must choose
between one repository, per-service repositories, or a hybrid.

Learners need to see the *whole company* at once — the seams between layers are
the core of the curriculum. Contributors need one clone, one CI, one place to
search. Real enterprises use both models, but the polyrepo overhead (version
skew, cross-repo PRs, N× CI setup) buys us nothing at this scale.

## Decision

A single monorepo (`meridian/`) holds application source, platform code, CI
definitions, observability, security, AI Ops, scenarios, runbooks, and docs.
Top-level layout is fixed in §5.1 of the architecture doc.

The **GitOps deployment config lives in a separate repository** — that split is
deliberate and covered by [ADR-0002](ADR-0002-gitops-repo-separation.md).

## Consequences

- One clone, one CI matrix, atomic cross-cutting changes (e.g. a scenario that
  touches an app, its alerts, and its runbook lands as one PR).
- CI must use path filtering to avoid rebuilding the world on every commit.
- Repo will grow large; scenario assets must stay text-based (no fat binaries).
- Learners experience the monorepo tooling tradeoffs first-hand — which is
  itself an interview topic.
