#!/usr/bin/env bash
# inject.sh — creates the REAL fault for INC-heartbeat-masked.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-masked"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating a fat-fingered 'decommission the wrong service' mistake..."
# This is what `systemctl mask` produces under the hood. We replicate it
# directly because systemctl itself safely refuses to mask over a real,
# existing unit file without deleting it first — same as a careless human
# would have to do to cause this for real.
docker exec "$CONTAINER" systemctl stop heartbeat
docker exec "$CONTAINER" rm -f /etc/systemd/system/heartbeat.service
docker exec "$CONTAINER" ln -sf /dev/null /etc/systemd/system/heartbeat.service
docker exec "$CONTAINER" systemctl daemon-reload

echo "[inject:${SCENARIO_ID}] confirming the unit is masked and down..."
LOADSTATE=$(docker exec "$CONTAINER" systemctl show heartbeat -p LoadState --value)
if [ "$LOADSTATE" != "masked" ]; then
    echo "error: heartbeat.service LoadState is '${LOADSTATE}', expected 'masked'" >&2
    exit 1
fi
STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
if [ "$STATE" = "active" ]; then
    echo "error: heartbeat is still active — injection did not take" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. heartbeat.service is masked and down."
echo "[inject:${SCENARIO_ID}] pager firing: HeartbeatServiceDown"
