# Scenario Authoring Guide

Scenarios are Abhyas's product. This guide is the contract every scenario
must meet. Start by copying `scenarios/TEMPLATE/`.

## The six files (+ metadata)

| File | Purpose | Hard rules |
|---|---|---|
| `scenario.yaml` | metadata for `abhyasctl` + CI | valid tier/category/milestone |
| `ticket.md` | what the pager/customer says | **symptoms only** — no root cause anywhere |
| `inject.sh` | creates the real fault | idempotent, sandbox-only, observable via telemetry |
| `walkthrough.md` | spoiler-gated investigation path | exact commands + expected output, `<details>` gates |
| `rca-reference.md` | model blameless RCA | root cause ≠ trigger; action items typed prevent/detect/mitigate |
| `interview.md` | interview mapping | ≥1 troubleshooting + 1 design + 1 STAR |
| `grade.sh` | verifies the fix is real | fails on symptom-only fixes; <5 min on kind |

## Quality bar

1. **The fault must be real.** `inject.sh` breaks the actual running system in
   a way visible through metrics/logs/traces. No "pretend there's an outage."
2. **The grade must be honest.** `grade.sh` re-checks the *root cause state*,
   not just the symptom. Deleting a pod must never pass a config-fault scenario.
3. **Misleading signals are a feature** (L2+): include one plausible red
   herring, and make the walkthrough explain why it's a red herring.
4. **Reduced-scale honesty:** if the real-world version needs 3k rps, document
   how the kind-scale reproduction preserves the mechanism.
5. **No rot:** every scenario runs in the weekly CI matrix
   (inject → wait → grade-must-fail → apply reference fix → grade-must-pass).

## Difficulty tiers

- **L1** — single service, obvious signal, one-step fix.
- **L2** — cross-service, one misleading signal.
- **L3** — multi-layer causality (e.g. Terraform → IAM → workload identity →
  image pulls).
- **L4** — Sev-1 game day: cascading failure, Incident Commander role, comms
  artifacts required.

## Naming

- Incidents: `scenarios/incidents/INC-<short-slug>/`
- Project tickets: `scenarios/tickets/ABH-<short-slug>/`
- Slugs describe the *mechanism*, not the symptom (the directory name is a
  spoiler surface learners only see after starting via `abhyasctl`).
