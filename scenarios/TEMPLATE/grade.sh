#!/usr/bin/env bash
# grade.sh — verifies the learner's fix is REAL.
# Invoked by: abhyasctl scenario grade <scenario-id>  (and by the weekly CI matrix)
#
# Contract:
#   - Must fail if the fault is still present.
#   - Must fail on cosmetic "fixes" (e.g. the pod was deleted but the
#     underlying misconfiguration remains — re-check the config, not just
#     the symptom).
#   - Must pass within 5 minutes on a resource-trimmed kind profile.
#   - Exit 0 = pass, non-zero = fail, with a human-readable reason on stderr.
set -euo pipefail

SCENARIO_ID="TEMPLATE"
NAMESPACE="${ABHYAS_NAMESPACE:-scg}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# --- checks -------------------------------------------------------------------
# 1. Symptom is gone (e.g. SLI back in bounds, alert resolved):
#    kubectl/promtool/curl checks here
# 2. Root cause is actually fixed (config/state check, not just symptom):
#    e.g. verify the deployment's memory limit, the NetworkPolicy, the
#    Kafka consumer group lag — whatever inject.sh broke
# 3. No collateral damage (the "fix" didn't disable the feature/policy):
fail "TODO: implement grading checks"
# ------------------------------------------------------------------------------

pass "fault remediated and root cause verified"
