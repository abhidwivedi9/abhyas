#!/usr/bin/env bash
# inject.sh — creates the REAL fault for INC-heartbeat-log-permission-denied.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-log-permission-denied"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating a security hardening pass breaking log ownership..."
# Chowning the directory alone is not enough - an already-open/existing
# file keeps writable for its owner regardless of the parent directory's
# ownership. The file itself has to be touched too, exactly like a real
# recursive ownership change would do.
docker exec "$CONTAINER" chown root:root /var/log/heartbeat/heartbeat.log
docker exec "$CONTAINER" chmod 644 /var/log/heartbeat/heartbeat.log

echo "[inject:${SCENARIO_ID}] restarting heartbeat..."
docker exec "$CONTAINER" systemctl restart heartbeat

echo "[inject:${SCENARIO_ID}] confirming the log has genuinely gone stale (while health stays green)..."
sleep 3
LINE1=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log 2>/dev/null || echo "")
sleep 4
LINE2=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log 2>/dev/null || echo "")
if [ "$LINE1" != "$LINE2" ]; then
    echo "error: heartbeat.log is still advancing — injection did not take" >&2
    exit 1
fi
if ! docker exec "$CONTAINER" journalctl -u heartbeat -n 20 --no-pager 2>/dev/null \
        | grep -q "PermissionError"; then
    echo "error: expected PermissionError signature not found in journal" >&2
    exit 1
fi
HEALTH=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' localhost:8080/health || true)
if [ "$HEALTH" != "200" ]; then
    echo "error: expected health to still be 200 (that's the whole point) but got '${HEALTH}'" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. heartbeat.log stale; /health still misleadingly returns 200."
echo "[inject:${SCENARIO_ID}] pager firing: HeartbeatLogStale"
