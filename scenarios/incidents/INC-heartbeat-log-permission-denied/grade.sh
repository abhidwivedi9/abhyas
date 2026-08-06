#!/usr/bin/env bash
# grade.sh — verifies the fix to INC-heartbeat-log-permission-denied is REAL.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-log-permission-denied"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# 1. The log file must genuinely be owned by heartbeat again.
OWNER=$(docker exec "$CONTAINER" stat -c '%U' /var/log/heartbeat/heartbeat.log)
[ "$OWNER" = "heartbeat" ] || fail "heartbeat.log is owned by '${OWNER}', expected 'heartbeat'"

# 2. Passing the naive health check alone is NOT enough. The log must
#    genuinely be advancing.
LINE1=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log || true)
sleep 4
LINE2=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log || true)
[ "$LINE1" != "$LINE2" ] || fail "heartbeat.log is still stale — logging thread not actually recovered"
echo "$LINE2" | grep -q "heartbeat ok" || fail "no valid heartbeat log entry found"

HEALTH=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' \
    http://localhost:8080/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

pass "heartbeat.log ownership restored and genuinely advancing again"
