# INC-XXXX-NNNN: <symptom-only title, e.g. "Checkout latency spiking, customers reporting timeouts">

> **Severity:** Sev-2 · **Tier:** L2 · **Role:** SRE on-call · **Time-box:** 60 min

<!-- SYMPTOMS ONLY. Never name the root cause, the faulty component, or the
     fix anywhere in this file. Write it the way the page/customer would. -->

## What the pager says

```
[FIRING] <AlertName> — <alert summary as Alertmanager would render it>
```

## What the customer / stakeholder says

> <verbatim-style complaint or exec escalation. Ambiguous is realistic.>

## What you know

- Environment: <dev | staging | prod-usc1 | kind-local>
- Started: <relative time, e.g. "~10 minutes ago">
- Recent changes: <what a real responder would see in the change feed — may be
  misleading, may be empty>

## Acceptance criteria

- [ ] Service restored / SLO burn stopped
- [ ] `grade.sh` passes
- [ ] RCA drafted using the postmortem template (L2+ only)

## Getting started

```
abhyasctl scenario start <scenario-id>
```

Stuck for 20+ minutes? `walkthrough.md` is spoiler-gated — open it section by
section.
