# ADR-0005: AI Ops is read-only by default

- Status: Accepted
- Date: 2026-08-06

## Context

The `aiops/` subsystem (MCP server, incident copilot, deploy validator,
runbook generator, cost analyst, ChatOps bot) gives AI agents deep access to
the platform: alerts, PromQL, LogQL, traces, kubectl, Argo status, Terraform
plans. An agent that can also *mutate* the platform is a production hazard and
a terrible habit to teach.

## Decision

1. **Every MCP tool and agent capability is read-only by default.** The tool
   surface is explicitly enumerated (`get_alerts`, `query_promql`, `query_logs`,
   `get_traces`, `kubectl_read`, `argo_status`, `tf_plan_summary`,
   `runbook_search`) — no generic shell execution.
2. **Every write path goes through a PR or an explicit human approval.** The
   runbook generator drafts via PR; the cost analyst proposes rightsizing via
   PR; the deploy validator posts an assessment to a gate a human promotes.
3. Agent prompts and eval harnesses live in-repo and are versioned like code —
   building and evaluating the AI Ops layer is itself curriculum.
4. Model backends are pluggable: Gemini via Vertex AI on the GCP track, any
   Claude/OpenAI-compatible endpoint via config on the local track.

## Consequences

- Incident copilot can *recommend* commands but never run mutating ones; the
  learner stays the operator (pedagogically essential).
- Some automation convenience is sacrificed; the escape hatch is always a PR,
  which doubles as an audit trail.
- Scenario category "AI Ops build-and-extend" can safely hand learners real
  agent-extension tickets without a blast-radius problem.
- Any future exception must supersede this ADR explicitly.
