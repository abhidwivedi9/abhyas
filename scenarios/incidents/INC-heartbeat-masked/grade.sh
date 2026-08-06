#!/usr/bin/env bash
# grade.sh — verifies the fix to INC-heartbeat-masked is REAL.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-masked"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# 1. Must genuinely be unmasked, not worked around some other way.
LOADSTATE=$(docker exec "$CONTAINER" systemctl show heartbeat -p LoadState --value)
[ "$LOADSTATE" = "loaded" ] || fail "heartbeat.service LoadState is '${LOADSTATE}', expected 'loaded'"

# 2. The unit file must be a real file again, not still (or newly) a symlink
#    to /dev/null wearing a different name — i.e. the actual fix, not a trick.
if docker exec "$CONTAINER" test -L /etc/systemd/system/heartbeat.service; then
    fail "/etc/systemd/system/heartbeat.service is still a symlink"
fi

HEALTH=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' \
    http://localhost:8080/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
[ "$STATE" = "active" ] || fail "heartbeat.service is '${STATE}', not active"

LAST_LINE=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log || true)
echo "$LAST_LINE" | grep -q "heartbeat ok" || fail "no recent heartbeat log entry found"

pass "heartbeat.service unmasked, restored, and healthy"
