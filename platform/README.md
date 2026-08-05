# platform/
Infrastructure and cluster configuration as code.

- `terraform/` — live envs (dev/staging/prod) + reusable modules (Milestone 5)
- `ansible/` — VM-based labs: hardening, patching, legacy sim (Milestone 1)
- `kubernetes/` — Kustomize bases (Milestone 3)
- `helm/` — in-house charts + wrapped upstream charts (Milestone 6)
- `istio/` — mesh policy as code (Milestone 9)
- `policies/` — OPA/Gatekeeper, Kyverno constraints (Milestone 10)
