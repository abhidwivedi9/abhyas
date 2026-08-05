# Project Abhyas — Architecture & Roadmap

**The Fortune 500 Production Simulator for DevOps, SRE, Platform Engineering & AI Ops**

> Version 0.1.0 (Design Phase) · License: Apache-2.0 · Status: Milestone 0

---

## 1. Executive Summary

Project Abhyas is an open-source, self-hostable simulation of a Fortune 500 production
environment. It is not a tutorial repository. It is a **fictional company** — Sachid
Commerce Group (SCG) — with real microservices, real infrastructure-as-code, real CI/CD, real
GitOps, real observability, real security controls, and a **ticket-driven learning system**
that makes you operate the platform the way an on-call engineer at Google, Netflix, or
Uber would.

You don't read about a Kafka partition rebalance storm. You get paged for one at 02:00,
you triage it with real dashboards and real logs, you write the RCA, and you ship the
prevention work as a change request through the same pipeline production changes go through.

**The one-line positioning:** *KodeKloud's hands-on labs + Google's Online Boutique's
realism + SadServers' break/fix philosophy + the SRE Book's rigor — unified into a single
coherent company you can run on GKE (or locally on kind), with an AI Ops layer no existing
learning repo has.*

---

## 2. Competitive Landscape — What Exists, What's Missing

Based on analysis of the leading learning resources (knowledge current to early 2026 —
re-verify before publishing):

| Project | Strengths | Critical Gaps |
|---|---|---|
| `bregman-arie/devops-exercises` (70k+ ⭐) | Massive Q&A breadth, great interview prep | No running system. Zero hands-on. No architecture, no incidents, no AI Ops |
| `MichaelCade/90DaysOfDevOps` | Structured journey, community | Blog-style reading, not doing. No production scenarios, no enterprise architecture |
| Google `microservices-demo` (Online Boutique) | Real polyglot microservices on GKE, production-adjacent | It's a demo, not a curriculum. No incidents, no tickets, no debugging exercises, minimal docs on *operating* it |
| `kelseyhightower/kubernetes-the-hard-way` | Deep K8s internals | Single topic, no app layer, no CI/CD, no SRE practice, archived-in-spirit |
| SadServers / KillerCoda / iximiuz labs | Excellent break/fix scenarios | Isolated single-machine puzzles. No system context, no company, no career-shaped tasks. Mostly closed/hosted |
| KodeKloud / A Cloud Guru | Polished guided labs | Paid, closed-source, sandboxed. You never own or evolve the environment |
| `weaveworks/sock-shop` | Early microservices reference | Unmaintained, dated stack |
| CNCF landscape projects' own docs | Authoritative per-tool | No integration story — the hard part of DevOps is the seams *between* tools |
| Terraform module registries (`terraform-google-modules`) | Production-grade IaC patterns | Modules without a mission — no app to deploy, no failure to recover from |
| `dastergon/awesome-sre`, Google SRE Book | Canonical theory | Theory only. The gap between reading the SRE book and *doing* SRE is exactly the gap Abhyas fills |

**The synthesized gaps no one covers (Abhyas's moat):**

1. **A persistent company context.** Every existing resource is either topic-shaped or
   puzzle-shaped. None is *company-shaped*: a system you join, learn, break, and grow with
   across months, with organizational artifacts (tickets, RFCs, postmortems, on-call).
2. **The seams.** Terraform → GKE → Argo CD → Istio → Prometheus → PagerDuty-style alerting
   as one integrated pipeline, where a failure in one layer manifests as symptoms in another.
   This is where real engineers earn their pay and where every tutorial stops.
3. **Incident-driven learning with full forensic artifacts** — symptoms, logs, metrics,
   traces, RCA, prevention, and the interview question the scenario maps to.
4. **AI Ops as a first-class subsystem**, not a bolt-on: incident summarization, log
   analysis, an MCP server exposing the platform to AI agents, AI-validated deployments.
5. **Interview mapping.** Every scenario, design decision, and runbook explicitly maps to
   real interview questions (system design, troubleshooting, behavioral/STAR).
6. **Cost and compliance as gameplay** — budget overrun incidents and audit-failure
   scenarios, which zero learning repos touch.

---

## 3. The Fictional Company: Sachid Commerce Group

> **Sachid Commerce Group (SCG)** — *truth-consciousness, as code.*

Realism requires a business. All architecture decisions trace back to these constraints.

**Business:** Global e-commerce + embedded fintech under the **SwarnaPay** brand
(payments, ledger, fraud). This domain
is chosen deliberately — it forces the hardest problems: money-grade consistency,
event-driven flows, PCI-flavored compliance, Black-Friday-style traffic spikes, and
multi-region availability.

**Simulated scale (targets the system is *designed* for, load-tested at reduced scale):**

- 40M monthly active users, 3,000 checkout requests/sec peak (Black Friday scenario)
- 99.95% availability SLO on checkout path (≈ 21.9 min/month error budget)
- p99 checkout latency SLO: 800 ms; p99 product search SLO: 300 ms
- Two primary regions (`us-central1`, `europe-west1`) + DR posture for a third
- ~$180k/month simulated cloud budget (drives cost-optimization scenarios)

**Org simulation:** You rotate through roles — Platform Engineer, SRE on-call, DevOps
Engineer, Cloud Architect, Incident Commander. Tickets arrive addressed to your current role.

---

## 4. System Architecture

### 4.1 Application Layer — Microservices

Polyglot on purpose (mirrors real enterprises and interview expectations):

| Service | Language / Stack | Purpose | Interesting operational properties |
|---|---|---|---|
| `storefront-gateway` | NGINX + Envoy (edge) | API gateway, rate limiting, WAF hooks | TLS termination, cert rotation scenarios |
| `catalog-service` | Java / Spring Boot | Product catalog, search | JVM tuning, heap/GC incidents, connection pools |
| `cart-service` | Python / FastAPI | Shopping cart | Redis-backed, cache stampede scenarios |
| `checkout-service` | Java / Spring Boot | Order orchestration (saga pattern) | Distributed transaction failures, idempotency |
| `payment-service` | Java / Spring Boot | Payment authorization | PCI-style secrets handling, Vault integration |
| `ledger-service` | Java / Spring Boot + PostgreSQL | Double-entry ledger | Consistency > availability; failover drills |
| `inventory-service` | Python | Stock management | Kafka consumer lag incidents, exactly-once semantics |
| `fraud-service` | Python + Vertex AI | Real-time fraud scoring | ML serving latency, model rollback |
| `notification-service` | Python | Email/webhook fan-out | RabbitMQ, poison-message handling, DLQs |
| `recommendation-service` | Python + Vertex AI/Gemini | Personalization | Batch + online serving, feature drift |
| `loadgen` | Locust/k6 | Synthetic traffic, chaos load profiles | Drives every performance scenario |

### 4.2 Event Backbone & Data Layer

- **Kafka** (Strimzi on GKE; Confluent/Pub/Sub notes for comparison): `orders`, `payments`,
  `inventory`, `fraud-signals` topics. Schema registry + Avro. Consumer-lag SLOs.
- **Pub/Sub** for cross-region event replication (GCP-native comparison track).
- **RabbitMQ** for task queues (notification fan-out) — deliberately, so learners
  experience both broker models and can articulate the tradeoff in interviews.
- **PostgreSQL** (Cloud SQL HA + in-cluster CloudNativePG for the self-hosted track):
  ledger, orders. Read replicas, PITR, failover drills.
- **Redis** (Memorystore / in-cluster): cart state, rate-limit counters, cache tiers.
- **MongoDB**: catalog documents. Covers the "why Mongo here, Postgres there" interview.

### 4.3 Traffic & Mesh

- **Istio** service mesh: mTLS everywhere, canary via traffic splitting, fault injection
  (used as the chaos engine for scenarios), retry/timeout/circuit-breaking policies.
- **Cloud Load Balancer → Gateway API → Istio ingress** in GKE; **NGINX/HAProxy** track
  for the local/on-prem flavor so learners see both worlds.
- **Multi-region:** active/active for stateless tiers behind global LB; active/passive
  with promotion runbook for the ledger. Region-evacuation is a graded exercise.

### 4.4 Deployment Topology

```
                        ┌─────────────────────────────┐
   Users ──► Global LB ─┤  us-central1  │ europe-west1 │──► DR: us-east1 (pilot light)
                        └───────┬───────┴──────┬───────┘
                          GKE prod-usc1   GKE prod-euw1
                          (regional,      (regional,
                           3 zones)        3 zones)
   Environments: dev (kind/minikube or single GKE Autopilot) → staging → prod
   Node pools: general / high-mem (JVM) / spot (batch, loadgen) — cost scenarios live here
```

**Local-first principle:** Every milestone runs on `kind` with resource-trimmed profiles
(Kustomize overlays) so learners without cloud budgets lose nothing conceptually; the GCP
track adds managed-service depth. AWS/Azure equivalence tables accompany each component.

---

## 5. Platform Architecture

### 5.1 Repository Strategy

Monorepo for the platform + app code, **separate GitOps config repo** (mirrors real
enterprise separation and enables realistic GitOps-drift scenarios):

```
abhyas/                            # main monorepo
├── apps/                          # microservice source + Dockerfiles + unit tests
├── platform/
│   ├── terraform/                 # live envs (dev/staging/prod) + bootstrap
│   │   ├── modules/               # network, gke, cloudsql, iam, monitoring...
│   │   └── environments/
│   ├── ansible/                   # VM-based labs: hardening, patching, legacy sim
│   ├── kubernetes/                # base manifests (kustomize bases)
│   ├── helm/                      # in-house charts + wrapped upstream charts
│   ├── istio/                     # mesh policy as code
│   └── policies/                  # OPA/Gatekeeper, Kyverno constraints
├── ci/                            # GitHub Actions (primary), Jenkins (legacy track),
│   └── cloudbuild/                # Cloud Build (GCP-native track)
├── observability/                 # Prometheus rules, Grafana dashboards-as-code,
│                                  # Loki/ELK pipelines, OTel collector configs, SLOs
├── security/                      # Vault config, Trivy/SonarQube gates, threat models
├── aiops/                         # MCP server, agents, runbook generator, ChatOps bot
├── scenarios/                     # THE PRODUCT: incident & exercise catalog (see §7)
├── runbooks/                      # production runbooks (living docs, tested in drills)
├── docs/                          # architecture, ADRs, handbooks, interview guide
└── tools/                         # abhyasctl CLI: scenario injector, grader, resets

abhyas-gitops/                   # Argo CD watches this repo only
├── clusters/{dev,staging,prod-usc1,prod-euw1}/
├── apps/                          # per-service overlays, image tags pinned by CI
└── platform/                      # addons: monitoring, mesh, secrets, policies
```

### 5.2 CI/CD & GitOps Flow

```
PR → GitHub Actions: lint → unit tests → SonarQube gate → build → Trivy scan
   → sign (cosign) → push to Artifact Registry → integration tests (kind, ephemeral)
   → CD bot opens PR to abhyas-gitops bumping image digest
   → Argo CD syncs dev → automated smoke tests → promote staging → manual approval
   → Argo Rollouts canary in prod (5% → 25% → 100%) gated on Prometheus SLO analysis
   → AI deployment validator summarizes canary metrics diff before final promotion
```

- **Jenkins "legacy" track**: one service deliberately kept on a Jenkinsfile pipeline —
  because real enterprises are heterogeneous, migration off Jenkins is a graded project,
  and Jenkins questions remain interview staples.
- **Terraform workflow**: PR plan comments, OPA policy checks on plans, state in GCS with
  locking; OpenTofu compatibility maintained and documented. Drift detection runs nightly
  and *intentionally* fires scenarios.

### 5.3 Observability — the Chitaksh platform

- **Metrics:** Prometheus (kube-prometheus-stack) + Thanos for multi-cluster/global view.
- **Logs:** Loki (primary) with a parallel ELK lab track (enterprise reality + interviews).
- **Traces:** OpenTelemetry SDKs in every service → OTel Collector → Jaeger/Tempo.
- **SLOs as code:** Sloth/OpenSLO definitions → generated multi-window multi-burn-rate
  alerts (the Google SRE alerting model, implemented, not just described).
- **Dashboards as code:** Grafana provisioned from git; "dashboard archaeology" exercises
  where learners must find the *wrong* dashboard telling a misleading story.
- **Alerting:** Alertmanager → webhook "pager" (the `abhyasctl pager` simulates
  PagerDuty: acks, escalation policy, on-call schedule).

### 5.4 Security & Compliance

- Workload Identity, least-privilege IAM as Terraform, periodic access-review exercises.
- **Vault** + External Secrets Operator; GCP Secret Manager comparison track; secret
  rotation drills with intentional partial-rotation failure scenarios.
- Supply chain: Trivy (images + IaC), cosign signing, SLSA provenance, Dependabot.
- Policy as code: Gatekeeper/Kyverno (no `latest` tags, resource limits required,
  no privileged pods) — with a scenario where a policy blocks an emergency deploy.
- NetworkPolicies default-deny; Istio AuthorizationPolicies; mTLS strict.
- **Compliance sim:** a lightweight "SCG-SOC2/PCI" audit framework with evidence-collection
  exercises and a failed-audit incident scenario.

### 5.5 Disaster Recovery & Resilience

- Velero cluster backups, Cloud SQL PITR, cross-region replica promotion runbook.
- Defined RTO/RPO per tier (checkout: RTO 15 min / RPO 0; catalog: RTO 1 h / RPO 15 min).
- Quarterly-style **DR game days** as graded exercises: region evacuation, backup-restore
  under time pressure, "the backup is corrupt" twist scenario.
- Chaos engineering: Istio fault injection + Chaos Mesh experiment library, escalating
  from single-pod kills to zone loss to dependency brownouts.

---

## 6. AI Ops Architecture (the differentiator)

```
┌──────────────────────────── aiops/ ────────────────────────────┐
│  abhyas-mcp-server  ── exposes tools to any MCP client:      │
│    get_alerts, query_promql, query_logs(LogQL), get_traces,    │
│    kubectl_read, argo_status, tf_plan_summary, runbook_search  │
│                                                                │
│  abhigya-copilot      ── on page: pulls alerts+logs+traces,    │
│    drafts incident summary + ranked hypotheses + next commands │
│  deploy-validator     ── canary metric diff → natural-language │
│    risk assessment posted to the promotion gate                │
│  runbook-generator    ── drafts runbooks from resolved         │
│    incidents; humans review via PR (human-in-the-loop always)  │
│  cost-analyst         ── weekly spend anomaly report + rightsizing PRs │
│  chatops-bot          ── /abhyas diagnose checkout-service   │
└────────────────────────────────────────────────────────────────┘
```

Design principles: **read-only by default**, every write action goes through a PR or an
explicit human approval; Gemini via Vertex AI on the GCP track, any Claude/OpenAI-compatible
endpoint via config for the local track; all agent prompts and evals live in-repo so
*building AI Ops* is itself part of the curriculum (this doubles as AI-engineering interview prep).

Learning arc: use the tools → read their implementation → extend them (add a tool to the
MCP server as a graded ticket) → evaluate them (agent eval harness against replayed incidents).

---

## 7. The Learning System — Ticket-Driven, Incident-Driven

### 7.1 Formats

Every unit of work arrives as a corporate artifact, never as a lesson:

- **JIRA-style tickets** (`ABH-1042`) with acceptance criteria, story points, sprint context
- **Incidents** (`INC-2026-0117`) delivered by `abhyasctl scenario start <id>`, which
  injects the actual fault into your running environment and starts the pager
- **Change Requests** with CAB-style approval templates and rollback plans
- **RCA assignments** with the blameless postmortem template (timeline, contributing
  factors, action items) — graded against a rubric
- **Architecture Review Requests** (RFC/ADR format, design doc + review comments to address)
- **Customer complaints & exec escalations** (ambiguous, symptom-only — like real life)

### 7.2 Scenario Anatomy (every one of the 200+ scenarios ships with)

```
scenarios/incidents/INC-kafka-consumer-lag-storm/
├── ticket.md            # what the pager/customer says (symptoms only)
├── inject.sh            # abhyasctl hook that creates the real fault
├── walkthrough.md       # SPOILER-gated: investigation path, exact commands,
│                        #   the logs/metrics/traces you should have found
├── rca-reference.md     # model RCA: root cause, resolution, prevention
├── interview.md         # the interview questions this maps to + strong answers
└── grade.sh             # automated verification the fix is real (not kubectl-delete-pod theater)
```

Difficulty tiers: **L1** (single service, obvious signal) → **L2** (cross-service, one
misleading signal) → **L3** (multi-layer: e.g., a Terraform change caused an IAM change
that broke workload identity that manifests as image pull failures) → **L4** (Sev-1 game
day: cascading failure, you are Incident Commander, comms required, exec updates on a timer).

### 7.3 Scenario Catalog (categories × target counts, ~220 total)

Kubernetes & workloads (35) · Networking/DNS/TLS (20) · Databases & data (25) ·
Kafka/messaging (18) · CI/CD & GitOps failures (22) · Terraform/IaC (15) ·
Observability failures & alert storms (15) · Security incidents & IAM (20) ·
Performance & capacity (20) · Cost overruns (10) · DR & region loss (12) ·
Compliance/audit (8) · AI Ops build-and-extend tickets (15+).

Each category's index lists which FAANG-style interview questions it trains for.

---

## 8. Roadmap — Milestones

Each milestone ships: working implementation + tests + at least the listed scenarios +
runbooks + docs/ADRs + interview-handbook chapter. **A milestone is done only when its
`grade.sh` suite passes and its scenarios run end-to-end on kind.**

| # | Milestone | Core deliverables | Scenarios | Exit criteria (sample) |
|---|---|---|---|---|
| 0 | **Blueprint** (this doc) | Architecture, roadmap, repo scaffolding, CONTRIBUTING, coding standards, ADR-0001..0005 | — | Repo public, CI green on empty scaffold |
| 1 | **Foundations: Linux, Git, Bash** | `abhyasctl` v0, dev container, Ansible-provisioned "legacy VM" lab | 12 (broken services, disk pressure, perms, cron, systemd) | Learner can triage a broken VM to green in <30 min |
| 2 | **Containers & first service** | `catalog-service` + `cart-service`, hardened multi-stage Dockerfiles, compose dev env | 10 (OOM kills, zombie procs, layer bloat, registry auth) | Images <200MB, non-root, Trivy clean |
| 3 | **Kubernetes core (kind)** | All core services on kind, Kustomize bases/overlays, probes, resources, HPA | 20 (CrashLoopBackOff taxonomy, DNS, probes-lie scenarios, evictions) | Full app serves checkout on kind |
| 4 | **CI (GitHub Actions + Jenkins legacy)** | Full PR pipeline, SonarQube, Trivy gates, ephemeral integration envs | 12 (flaky tests, cache poisoning, broken gate, secret leak in logs) | PR-to-signed-image <10 min |
| 5 | **Terraform & GCP landing zone** | Network, GKE, IAM, Artifact Registry modules; state mgmt; OpenTofu parity | 15 (state lock, drift, destroy-protection saves, IAM propagation) | `terraform plan` clean on all envs; policy checks enforced |
| 6 | **GitOps (Argo CD) + Helm** | abhyas-gitops repo live, app-of-apps, Argo Rollouts canary | 14 (sync loops, drift, pruning disasters, helm hook failures) | Zero kubectl-apply to prod; canary auto-aborts on SLO breach |
| 7 | **Observability** | Prom/Thanos, Loki, OTel+Jaeger, SLOs-as-code, dashboards-as-code, pager sim | 15 (alert storm, cardinality explosion, sampling lies, silent SLO burn) | Multi-burn-rate alerts fire correctly in injected burn test |
| 8 | **Data & events** | Kafka (Strimzi), RabbitMQ, Postgres HA, Redis, Mongo; saga checkout flow | 25 (consumer lag, rebalance storms, poison msgs, replica lag, failover) | Checkout survives broker-node kill with zero lost orders |
| 9 | **Service mesh & traffic** | Istio, mTLS strict, circuit breaking, fault injection as chaos engine | 14 (sidecar OOM, mTLS cert expiry, retry storms, 503 taxonomies) | Region-internal p99 overhead <10 ms documented |
| 10 | **Security & secrets** | Vault + ESO, workload identity, policies, supply chain (cosign/SLSA) | 20 (rotation partial-failure, leaked key drill, policy-blocks-hotfix) | Secret rotation drill completes <20 min, zero downtime |
| 11 | **Multi-region & DR** | prod-euw1 cluster, global LB, ledger failover, Velero, DR runbooks | 12 (region evac game day, corrupt backup twist, split-brain) | Region evacuation meets RTO 15 min in graded drill |
| 12 | **Performance, capacity, cost** | Load profiles (k6), JVM tuning guide, rightsizing, spot strategy, budgets | 20 (Black Friday sim, memory leak hunt, $40k overrun incident) | Black Friday sim passes SLOs at 3k rps on documented budget |
| 13 | **AI Ops** | MCP server, incident copilot, deploy validator, runbook generator, ChatOps, agent eval harness | 15 build/extend tickets + AI-assisted replays of past incidents | Copilot's hypothesis ranked top-3 correct on ≥70% of replayed incidents |
| 14 | **Capstone & interview engine** | 6 Sev-1 game days, Incident Commander sim, full interview handbook (system design + troubleshooting + behavioral bank mapped to scenarios), certification-style final assessment | 6 L4 game days | Learner completes a cold Sev-1 with passing IC rubric |

**Sequencing rationale:** app-before-platform-before-scale mirrors how you'd actually
join a company; every layer added becomes new failure surface for scenarios in later
milestones (e.g., Milestone 11's best scenarios break things built in 5, 6, and 8).

---

## 9. Repository Quality Standards

- **Docs:** Diátaxis structure (tutorials/how-to/reference/explanation); every component
  gets an ADR; architecture diagrams in Mermaid + D2, rendered in CI.
- **Testing:** unit (per service), integration (ephemeral kind in CI), e2e smoke
  (post-sync Argo hooks), IaC tests (Terratest), policy tests (OPA/conftest), and
  **scenario tests** — every `inject.sh`/`grade.sh` pair runs in a weekly CI matrix so
  scenarios never rot (the #1 killer of learning repos).
- **Versioning:** SemVer per milestone; conventional commits; release notes automated;
  `main` always deployable to kind in one command (`abhyasctl up`).
- **Contribution:** CONTRIBUTING.md, scenario-authoring guide + template (the community
  growth engine — contributors add scenarios, the highest-leverage contribution type),
  CODEOWNERS, security policy with private disclosure path.
- **Handbooks:** Operations Handbook (how SCG runs prod), On-Call Handbook
  (escalation, comms templates, IC role), Interview Handbook (grows one chapter per milestone).

## 10. Success Metrics

- A learner completing Milestones 1–8 can pass a mid-level SRE/DevOps loop; 1–14 targets
  senior loops. Track via community-reported interview outcomes.
- Scenario health: 100% of scenarios green in weekly CI.
- Community: scenario contributions accepted from ≥20 external contributors in year one.
- The recommendation test: appears in "best repo to learn DevOps" threads organically.

---

*Next step: Milestone 0 completion — repo scaffolding, `abhyasctl` skeleton, ADRs 0001–0005
(monorepo strategy, GitOps repo separation, local-first principle, polyglot service choices,
AI Ops read-only principle), and the scenario template. Then Milestone 1 kicks off with
sprint ABH-Sprint-1 and its first 12 tickets.*
