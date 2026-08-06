#!/usr/bin/env bash
# grade.sh - verifies the fix to INC-heartbeat-port-conflict is REAL.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-port-conflict"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# 1. Port 8080 must genuinely be held by heartbeat's own process, not just
#    "some python3 process" — the rogue process is also python3, so
#    matching by process name alone wouldn't actually prove it's gone.
# Compare the PID actually bound to :8080 against heartbeat.service's own
# MainPID instead.
HOLDER_PID=$(docker exec "$CONTAINER" sh -c \
    "ss -ltnp 2>/dev/null | grep ':8080' | grep -oP 'pid=\K[0-9]+'" || true)
SERVICE_PID=$(docker exec "$CONTAINER" systemctl show heartbeat -p MainPID --value)
[ -n "$HOLDER_PID" ] || fail "nothing is listening on :8080"
[ "$HOLDER_PID" = "$SERVICE_PID" ] || fail "port 8080 is held by PID ${HOLDER_PID}, not heartbeat's own process (PID ${SERVICE_PID}) — rogue process still running?"

STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
[ "$STATE" = "active" ] || fail "heartbeat.service is '${STATE}', not active"

HEALTH=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' \
    http://localhost:8080/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

LAST_LINE=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log || true)
echo "$LAST_LINE" | grep -q "heartbeat ok" || fail "no recent heartbeat log entry found"

pass "port 8080 is held by heartbeat itself; service active and healthy"
