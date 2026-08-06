#!/usr/bin/env bash
# inject.sh — creates the REAL fault for INC-heartbeat-permission-denied.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-permission-denied"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating an overnight cleanup script stripping exec permission..."
docker exec "$CONTAINER" chmod 000 /opt/heartbeat/heartbeat.py

echo "[inject:${SCENARIO_ID}] restarting heartbeat to trigger the failure..."
docker exec "$CONTAINER" systemctl reset-failed heartbeat 2>/dev/null || true
docker exec "$CONTAINER" systemctl restart heartbeat || true
sleep 2

STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
if [ "$STATE" = "active" ]; then
    echo "error: heartbeat is still active — injection did not take" >&2
    exit 1
fi
if ! docker exec "$CONTAINER" journalctl -u heartbeat -n 20 --no-pager 2>/dev/null \
        | grep -qi "permission denied"; then
    echo "error: expected permission-denied signature not found in journal" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. heartbeat.service state: ${STATE}"
echo "[inject:${SCENARIO_ID}] pager firing: HeartbeatServiceDown"
