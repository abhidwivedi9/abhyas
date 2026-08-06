#!/usr/bin/env bash
# grade.sh - verifies the fix to INC-logrotate-misconfigured is REAL.
set -euo pipefail

SCENARIO_ID="INC-logrotate-misconfigured"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# The real test: does logrotate's own dry-run actually consider the real
# log files, not just "does the config file exist / have valid syntax."
OUTPUT=$(docker exec "$CONTAINER" logrotate -d /etc/logrotate.d/heartbeat 2>&1)
echo "$OUTPUT" | grep -q "considering log /var/log/heartbeat/heartbeat.log" \
    || fail "logrotate -d does not consider the real heartbeat.log path"
echo "$OUTPUT" | grep -q "considering log /var/log/heartbeat/report.log" \
    || fail "logrotate -d does not consider the real report.log path"

pass "logrotate policy genuinely covers heartbeat's real log files"
