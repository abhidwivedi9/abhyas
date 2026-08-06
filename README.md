# Project Abhyas

**The Enterprise Production Simulator for DevOps, SRE, Platform Engineering & AI Ops**

> Version 0.1.0 · Milestone 1 complete, Milestone 2 in progress · License: Apache-2.0

Abhyas (अभ्यास, *practice*) is an open-source, self-hostable simulation of a
real production environment: a company — **Sachid Aquatics** — with real
microservices, real infrastructure-as-code, real CI/CD, real GitOps, real
observability, real security controls, and a **ticket-driven learning system**.
It's dual-purpose by design: an enterprise-depth DevOps/SRE training ground
*and* a genuine foundation an aquarium/aquascaping business could actually be
built on later — same codebase, same standards, no shortcuts taken for either goal.

You don't read about a Kafka partition rebalance storm. You get paged for one at
02:00, triage it with real dashboards and logs, write the RCA, and ship the
prevention work through the same pipeline production changes go through.

Read the full design: [ARCHITECTURE_AND_ROADMAP.md](ARCHITECTURE_AND_ROADMAP.md)

## Naming

| Name | Sanskrit root | What it names |
|---|---|---|
| **Abhyas** | अभ्यास — practice through repetition | The platform: this repo, `abhyasctl`, `ABH-` tickets |
| **Sachid** | सच्चिद् — *sat-chit*, truth-consciousness | The company: Sachid Aquatics |
| **SwarnaPay** | स्वर्ण — gold | Sachid Aquatics' payments/ledger arm |
| **Chitaksh** | चित् + अक्ष — the perceiving eye | The observability platform (metrics, logs, traces, SLOs) |
| **Abhigya** | अभिज्ञ — the knower | The AI Ops incident copilot (engineer-facing) |
| **Anshu** | अंशु — a ray of light | The customer-facing AI aquarium assistant — recommendations, compatibility, setup guidance |
| **Kinker** | किंकर — devoted caretaker | The customer-care service and support philosophy |

## Repository layout

```
apps/           microservice source + Dockerfiles + unit tests
platform/       terraform, ansible, kubernetes, helm, istio, policies
ci/             GitHub Actions (primary), Jenkins (legacy track), Cloud Build
observability/  Prometheus rules, dashboards-as-code, OTel, SLOs
security/       Vault config, scanning gates, threat models
aiops/          MCP server, Abhigya incident copilot, deploy validator, ChatOps
scenarios/      THE PRODUCT: incident & exercise catalog
runbooks/       production runbooks (living docs, tested in drills)
docs/           architecture, ADRs, handbooks, interview guide
tools/          abhyasctl CLI: scenario injector, grader, resets
```

## Quick start

Requires Docker Desktop running — nothing else to install (no Vagrant/VirtualBox,
no cloud account, $0 cost).

```
python tools/abhyasctl/abhyasctl.py up            # build + start the full stack
python tools/abhyasctl/abhyasctl.py scenario list  # see available scenarios
python tools/abhyasctl/abhyasctl.py scenario start INC-heartbeat-crashloop
python tools/abhyasctl/abhyasctl.py dashboard      # live status page, http://localhost:4000
```

`abhyasctl up` extends to also bring up a `kind` Kubernetes cluster in Milestone 3.

## Status

Live, real-time view: `abhyasctl dashboard` (milestone progress + which scenario
is currently firing, checked live against the running lab — see
[docs/progress.json](docs/progress.json) for the raw data).

| Milestone | Status |
|---|---|
| 0 — Blueprint & scaffolding | ✅ done |
| 1 — Foundations: Linux, Git, Bash | ✅ done — 12/12 scenarios |
| 2 — Containers & first service | 🔨 in progress |
| 3+ | see roadmap |

A dedicated **UI milestone** (Customer, Admin, Vendor, Operations, and AI
Assistant portals) is planned once the backend/platform layers are further
along — see §11 of the architecture doc.

## Interview prep

Every scenario maps to real interview questions — see the
[Interview Handbook](docs/handbooks/interview-handbook.md), or the
"Interview Prep" section of `abhyasctl dashboard`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The highest-leverage contribution is a
new scenario — start from [scenarios/TEMPLATE](scenarios/TEMPLATE/).

## License

Apache-2.0 — see [LICENSE](LICENSE).
