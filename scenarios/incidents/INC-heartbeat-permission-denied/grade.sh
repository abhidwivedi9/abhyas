#!/usr/bin/env bash
# grade.sh — verifies the fix to INC-heartbeat-permission-denied is REAL.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-permission-denied"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# 1. The file must actually be readable by its owner again — not just the
#    service restarted by some other means. python3 is invoked as
#    `python3 heartbeat.py` (interpreter runs the file as an argument), so
#    it's read permission that matters here, not execute.
PERMS=$(docker exec "$CONTAINER" stat -c '%a' /opt/heartbeat/heartbeat.py)
case "$PERMS" in
    [4-7]??) : ;;  # owner-readable (4xx and up)
    *) fail "/opt/heartbeat/heartbeat.py is mode ${PERMS} — not readable by owner" ;;
esac

HEALTH=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' \
    http://localhost:8080/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
[ "$STATE" = "active" ] || fail "heartbeat.service is '${STATE}', not active"

LAST_LINE=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log || true)
echo "$LAST_LINE" | grep -q "heartbeat ok" || fail "no recent heartbeat log entry found"

pass "heartbeat.py is readable again; service active and healthy"
