#!/usr/bin/env bash
# grade.sh - verifies the fix to INC-heartbeat-missing-env-file is REAL.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-missing-env-file"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# Accept either legitimate fix: the EnvironmentFile= line was removed, OR
# the referenced file now actually exists. Either way the unit must load
# and start cleanly — don't prescribe which fix, verify the outcome.
ENV_LINE=$(docker exec "$CONTAINER" sh -c \
    "grep '^EnvironmentFile=' /etc/systemd/system/heartbeat.service || true")
if [ -n "$ENV_LINE" ]; then
    ENV_PATH=$(echo "$ENV_LINE" | cut -d= -f2)
    docker exec "$CONTAINER" test -f "$ENV_PATH" \
        || fail "unit still references EnvironmentFile=${ENV_PATH}, which doesn't exist"
fi

STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
[ "$STATE" = "active" ] || fail "heartbeat.service is '${STATE}', not active"

HEALTH=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' \
    http://localhost:8080/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

LAST_LINE=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log || true)
echo "$LAST_LINE" | grep -q "heartbeat ok" || fail "no recent heartbeat log entry found"

pass "unit loads cleanly (no dangling EnvironmentFile reference); service active and healthy"
