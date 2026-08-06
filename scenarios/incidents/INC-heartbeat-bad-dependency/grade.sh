#!/usr/bin/env bash
# grade.sh - verifies the fix to INC-heartbeat-bad-dependency is REAL.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-bad-dependency"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# The unit must genuinely no longer depend on the ghost unit — not just
# be running by some other trick.
if docker exec "$CONTAINER" sh -c "grep -q ghost-dependency /etc/systemd/system/heartbeat.service"; then
    fail "unit still references ghost-dependency.service"
fi

# Confirm systemd itself agrees the unit is clean: restarting it from a
# stopped state must succeed with no dependency errors.
docker exec "$CONTAINER" systemctl stop heartbeat 2>/dev/null || true
docker exec "$CONTAINER" systemctl start heartbeat \
    || fail "heartbeat.service still fails to start"
sleep 2  # give the HTTP server a moment to bind before probing it

STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
[ "$STATE" = "active" ] || fail "heartbeat.service is '${STATE}', not active"

HEALTH=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' \
    http://localhost:8080/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

pass "unit no longer depends on the removed service; starts cleanly and is healthy"
