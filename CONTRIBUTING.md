# Contributing to Project Abhyas

Thanks for helping build the production simulator. Contributions of every kind
are welcome, but **scenarios are the highest-leverage contribution** — they are
the product.

## Ground rules

- **Conventional commits** (`feat:`, `fix:`, `docs:`, `scenario:`, `chore:`).
- `main` must always be deployable to kind in one command (`abhyasctl up`,
  from Milestone 3 onward).
- Every component change ships with docs; every significant decision gets an ADR
  in `docs/adr/`.
- Scenarios must pass their own `grade.sh` in CI. A scenario that can't verify
  its fix is theater, not training.

## Contributing a scenario

1. Copy `scenarios/TEMPLATE/` to `scenarios/incidents/INC-<short-slug>/` (or
   `scenarios/tickets/ABH-<short-slug>/` for project-style work).
2. Fill in all six files — `ticket.md`, `inject.sh`, `walkthrough.md`,
   `rca-reference.md`, `interview.md`, `grade.sh`.
3. Symptoms only in `ticket.md`. The learner should never see the root cause
   before the walkthrough.
4. `inject.sh` must create a *real* fault in the running environment, and
   `grade.sh` must verify the *real* fix (not pod-deletion theater).
5. State the difficulty tier (L1–L4) and the interview questions it maps to.
6. Open a PR. The scenario CI matrix must be green.

See `docs/scenario-authoring.md` for the full guide.

## Contributing platform / app code

1. Fork, branch from `main`.
2. Match the existing structure (see §5.1 of the architecture doc).
3. Include tests: unit for services, Terratest for IaC, conftest for policies.
4. Run linters locally before pushing (`ci/` documents the exact gates).

## Code of conduct

Be excellent to each other. Blameless culture applies to contributors as much
as to postmortems.

## Security

Please report vulnerabilities privately — see [SECURITY.md](SECURITY.md).
