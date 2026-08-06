#!/usr/bin/env bash
# inject.sh - creates the REAL fault for INC-logrotate-misconfigured.
set -euo pipefail

SCENARIO_ID="INC-logrotate-misconfigured"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating a typo introduced during a prior edit..."
# logrotate is deliberately forgiving - it will not error out or refuse to
# run on a path that matches zero files, it just silently does nothing for
# that block. That's exactly what makes this bug realistic and dangerous:
# nothing about running logrotate looks broken unless you check carefully.
docker exec "$CONTAINER" sh -c \
    "printf '/var/log/heatbeat/*.log {\n    daily\n    rotate 3\n    size 5M\n    missingok\n    notifempty\n    copytruncate\n}\n' > /etc/logrotate.d/heartbeat"

echo "[inject:${SCENARIO_ID}] confirming the config no longer matches the real log files..."
OUTPUT=$(docker exec "$CONTAINER" logrotate -d /etc/logrotate.d/heartbeat 2>&1)
if echo "$OUTPUT" | grep -q "considering log /var/log/heartbeat/heartbeat.log"; then
    echo "error: config still matches the real heartbeat.log — injection did not take" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. Rotation policy no longer matches any real files."
echo "[inject:${SCENARIO_ID}] no pager fires for this one — it's an audit finding, not an outage yet."
