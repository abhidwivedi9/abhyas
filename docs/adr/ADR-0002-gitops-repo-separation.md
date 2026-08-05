# ADR-0002: Separate GitOps config repository

- Status: Accepted
- Date: 2026-08-06

## Context

With Argo CD as the GitOps engine (Milestone 6), the desired cluster state must
live in git. It could live inside the monorepo ([ADR-0001](ADR-0001-monorepo-strategy.md))
or in a dedicated repository.

Real enterprises overwhelmingly separate app source from deployment config:
different review policies, different write access, different change cadence,
and CD bots that commit image-digest bumps without touching app history.

## Decision

A dedicated repository, `meridian-gitops/`, is the **only** thing Argo CD
watches. Structure:

```
meridian-gitops/
├── clusters/{dev,staging,prod-usc1,prod-euw1}/
├── apps/        # per-service overlays, image tags pinned by CI
└── platform/    # addons: monitoring, mesh, secrets, policies
```

CI in the monorepo builds and signs images, then opens a PR against
`meridian-gitops` bumping the image digest. Humans (or automation with
policy gates) merge; Argo CD syncs.

## Consequences

- Mirrors enterprise reality; enables realistic GitOps-drift and sync-loop
  scenarios (a whole scenario category depends on this split).
- Clean audit trail of "what is deployed where" separate from code churn.
- Learners must manage two repos — an intentional, realistic friction.
- Local single-repo shortcuts are forbidden even on kind: zero
  `kubectl apply` to prod-like environments is a graded exit criterion.
