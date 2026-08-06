#!/usr/bin/env bash
# inject.sh - creates the REAL fault for INC-heartbeat-missing-env-file.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-missing-env-file"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating a partial config rollout..."
# Anchored to the real [Service] header only — a naive substring match
# would also hit the unrelated comment in [Unit] that happens to mention
# "[Service]" in passing (found this the hard way while building it).
docker exec "$CONTAINER" sed -i \
    '/^\[Service\]$/a EnvironmentFile=/etc/heartbeat/heartbeat.env' \
    /etc/systemd/system/heartbeat.service
docker exec "$CONTAINER" systemctl daemon-reload

echo "[inject:${SCENARIO_ID}] restarting to trigger the failure..."
docker exec "$CONTAINER" systemctl reset-failed heartbeat 2>/dev/null || true
docker exec "$CONTAINER" systemctl restart heartbeat || true
sleep 1

STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
if [ "$STATE" = "active" ]; then
    echo "error: heartbeat is still active — injection did not take" >&2
    exit 1
fi
if ! docker exec "$CONTAINER" journalctl -u heartbeat -n 15 --no-pager 2>/dev/null \
        | grep -q "Failed to load environment files"; then
    echo "error: expected EnvironmentFile failure signature not found in journal" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. Unit references a config file that was never shipped."
echo "[inject:${SCENARIO_ID}] pager firing: HeartbeatServiceDown"
