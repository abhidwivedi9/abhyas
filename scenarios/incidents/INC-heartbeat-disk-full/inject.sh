#!/usr/bin/env bash
# inject.sh — creates the REAL fault for INC-heartbeat-disk-full.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-disk-full"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] stopping heartbeat before filling its disk..."
# heartbeat.log already has slack in its last allocated filesystem block
# from normal operation — appends that fit within an already-allocated
# block succeed even when df reports 0 available (true on any filesystem,
# not just tmpfs). Stopping the service and clearing its log first means
# the very next write after restart needs a brand-new block, which is
# guaranteed to fail once the filesystem is genuinely full.
docker exec "$CONTAINER" systemctl stop heartbeat
docker exec "$CONTAINER" rm -f /var/log/heartbeat/heartbeat.log

echo "[inject:${SCENARIO_ID}] filling /var/log/heartbeat to genuinely 100%..."
# Two passes: bs=1k gets the bulk quickly, bs=1 mops up the last few bytes
# a 1k-block write can't fit into — without this, up to ~1KB of slack can
# remain, enough for many small heartbeat writes before real exhaustion.
docker exec "$CONTAINER" sh -c \
    'dd if=/dev/zero of=/var/log/heartbeat/.filler bs=1k 2>/dev/null; \
     dd if=/dev/zero of=/var/log/heartbeat/.filler2 bs=1 2>/dev/null; true'

echo "[inject:${SCENARIO_ID}] restarting heartbeat against the full disk..."
docker exec "$CONTAINER" systemctl restart heartbeat

echo "[inject:${SCENARIO_ID}] confirming the log has genuinely gone stale..."
sleep 3
LINE1=$(docker exec "$CONTAINER" cat /var/log/heartbeat/heartbeat.log 2>/dev/null || echo "")
sleep 4
LINE2=$(docker exec "$CONTAINER" cat /var/log/heartbeat/heartbeat.log 2>/dev/null || echo "")
if [ "$LINE1" != "$LINE2" ] || [ -n "$LINE2" ]; then
    echo "error: heartbeat.log has content or is still advancing — injection did not take" >&2
    exit 1
fi
if ! docker exec "$CONTAINER" journalctl -u heartbeat -n 30 --no-pager 2>/dev/null \
        | grep -q "No space left on device"; then
    echo "error: expected ENOSPC signature not found in journal" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. Disk full; heartbeat.log stale; /health still returns 200."
echo "[inject:${SCENARIO_ID}] pager firing: HeartbeatLogStale"
