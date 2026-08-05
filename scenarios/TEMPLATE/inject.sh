#!/usr/bin/env bash
# inject.sh — creates the REAL fault for this scenario.
# Invoked by: abhyasctl scenario start <scenario-id>
#
# Contract:
#   - Must be idempotent (safe to run twice).
#   - Must only touch the scenario sandbox (the learner's kind cluster or
#     designated namespace) — never the learner's host beyond that.
#   - Must create a genuine fault observable through normal telemetry
#     (metrics/logs/traces), not a cosmetic one.
#   - Exit 0 on successful injection, non-zero otherwise.
set -euo pipefail

SCENARIO_ID="TEMPLATE"
NAMESPACE="${ABHYAS_NAMESPACE:-scg}"

echo "[inject:${SCENARIO_ID}] injecting fault into namespace ${NAMESPACE}..."

# --- fault injection goes here ------------------------------------------------
# Examples of legitimate injections:
#   kubectl -n "$NAMESPACE" patch deployment cart-service --type=json \
#     -p='[{"op":"replace","path":"/spec/template/spec/containers/0/resources/limits/memory","value":"64Mi"}]'
#   kubectl -n "$NAMESPACE" apply -f "$(dirname "$0")/assets/broken-networkpolicy.yaml"
#   istioctl ... fault injection VirtualService patch ...
echo "TODO: implement fault injection" >&2
exit 1
# ------------------------------------------------------------------------------

echo "[inject:${SCENARIO_ID}] fault active. Starting pager..."
