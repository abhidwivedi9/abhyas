# Project Meridian

**The Fortune 500 Production Simulator for DevOps, SRE, Platform Engineering & AI Ops**

> Version 0.1.0 · Milestone 0 (Blueprint) · License: Apache-2.0

Meridian is an open-source, self-hostable simulation of a Fortune 500 production
environment: a fictional company — **Meridian Commerce Group** — with real
microservices, real infrastructure-as-code, real CI/CD, real GitOps, real
observability, real security controls, and a **ticket-driven learning system**.

You don't read about a Kafka partition rebalance storm. You get paged for one at
02:00, triage it with real dashboards and logs, write the RCA, and ship the
prevention work through the same pipeline production changes go through.

Read the full design: [ARCHITECTURE_AND_ROADMAP.md](ARCHITECTURE_AND_ROADMAP.md)

## Repository layout

```
apps/           microservice source + Dockerfiles + unit tests
platform/       terraform, ansible, kubernetes, helm, istio, policies
ci/             GitHub Actions (primary), Jenkins (legacy track), Cloud Build
observability/  Prometheus rules, dashboards-as-code, OTel, SLOs
security/       Vault config, scanning gates, threat models
aiops/          MCP server, incident copilot, deploy validator, ChatOps
scenarios/      THE PRODUCT: incident & exercise catalog
runbooks/       production runbooks (living docs, tested in drills)
docs/           architecture, ADRs, handbooks, interview guide
tools/          meridianctl CLI: scenario injector, grader, resets
```

## Quick start (Milestone 0)

```
python tools/meridianctl/meridianctl.py --help
```

`meridianctl up` (one-command kind bring-up) lands in Milestone 3.

## Status

| Milestone | Status |
|---|---|
| 0 — Blueprint & scaffolding | 🔨 in progress |
| 1 — Foundations: Linux, Git, Bash | ⏳ |
| 2 — Containers & first service | ⏳ |
| 3+ | see roadmap |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The highest-leverage contribution is a
new scenario — start from [scenarios/TEMPLATE](scenarios/TEMPLATE/).

## License

Apache-2.0 — see [LICENSE](LICENSE).
