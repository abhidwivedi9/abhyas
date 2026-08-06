#!/usr/bin/env bash
# inject.sh - creates the REAL fault for INC-heartbeat-port-conflict.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-port-conflict"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating another team's ad-hoc process grabbing :8080 first..."
docker exec "$CONTAINER" systemctl stop heartbeat
docker exec -d "$CONTAINER" python3 -c \
    "import socket,time; s=socket.socket(); s.bind(('0.0.0.0',8080)); s.listen(1); time.sleep(600)"
sleep 1

echo "[inject:${SCENARIO_ID}] restarting heartbeat into the now-occupied port..."
docker exec "$CONTAINER" systemctl reset-failed heartbeat 2>/dev/null || true
docker exec "$CONTAINER" systemctl restart heartbeat || true
sleep 2

STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
if [ "$STATE" = "active" ]; then
    echo "error: heartbeat is still active — injection did not take" >&2
    exit 1
fi
if ! docker exec "$CONTAINER" journalctl -u heartbeat -n 15 --no-pager 2>/dev/null \
        | grep -q "Address already in use"; then
    echo "error: expected port-conflict signature not found in journal" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. Port 8080 is held by an unrelated process; heartbeat can't bind."
echo "[inject:${SCENARIO_ID}] pager firing: HeartbeatServiceDown"
