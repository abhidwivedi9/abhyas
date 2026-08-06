#!/usr/bin/env bash
# inject.sh - creates the REAL fault for INC-heartbeat-bad-dependency.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-bad-dependency"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating a maintenance window that decommissioned a dependency..."
docker exec "$CONTAINER" sed -i \
    '/^\[Unit\]$/a Requires=ghost-dependency.service\nAfter=ghost-dependency.service' \
    /etc/systemd/system/heartbeat.service
docker exec "$CONTAINER" systemctl daemon-reload

echo "[inject:${SCENARIO_ID}] taking heartbeat down for the maintenance window..."
# systemctl validates the dependency graph BEFORE tearing down a running
# instance, so a bare 'restart' against a broken Requires= would fail
# without ever stopping the currently-running process — not the down
# state a real maintenance-window restart would produce. Stop first, then
# start fresh, same as the real sequence of events.
docker exec "$CONTAINER" systemctl stop heartbeat

echo "[inject:${SCENARIO_ID}] confirming it fails to come back up..."
START_OUTPUT=$(docker exec "$CONTAINER" systemctl start heartbeat 2>&1 || true)
STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
if [ "$STATE" = "active" ]; then
    echo "error: heartbeat is active — injection did not take" >&2
    exit 1
fi
if ! echo "$START_OUTPUT" | grep -q "ghost-dependency.service not found"; then
    echo "error: expected dependency-not-found error not seen (got: ${START_OUTPUT})" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. Unit requires a dependency that no longer exists."
echo "[inject:${SCENARIO_ID}] pager firing: HeartbeatServiceDown"
