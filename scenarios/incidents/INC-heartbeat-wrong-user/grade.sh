#!/usr/bin/env bash
# grade.sh — verifies the fix to INC-heartbeat-wrong-user is REAL.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-wrong-user"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# 1. The unit must genuinely run as the correct, real service user again.
RUNUSER=$(docker exec "$CONTAINER" systemctl show heartbeat -p User --value)
[ "$RUNUSER" = "heartbeat" ] || fail "unit's User= is '${RUNUSER}', expected 'heartbeat'"

HEALTH=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' \
    http://localhost:8080/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
[ "$STATE" = "active" ] || fail "heartbeat.service is '${STATE}', not active"

LAST_LINE=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log || true)
echo "$LAST_LINE" | grep -q "heartbeat ok" || fail "no recent heartbeat log entry found"

pass "heartbeat.service running as the correct user; active and healthy"
