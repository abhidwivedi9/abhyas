#!/usr/bin/env bash
# inject.sh - creates the REAL fault for INC-daily-report-not-executable.
set -euo pipefail

SCENARIO_ID="INC-daily-report-not-executable"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating a permissions cleanup stripping exec bit..."
docker exec "$CONTAINER" chmod -x /opt/heartbeat/daily_report.sh

echo "[inject:${SCENARIO_ID}] confirming the job now fails exactly as cron would run it..."
docker exec "$CONTAINER" rm -f /var/log/heartbeat/report.log
if docker exec "$CONTAINER" su -s /bin/bash heartbeat -c \
        'env -i PATH=/usr/bin:/bin /opt/heartbeat/daily_report.sh' 2>/dev/null; then
    echo "error: job should fail now — injection did not take" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. daily_report.sh lost its execute bit."
echo "[inject:${SCENARIO_ID}] pager firing: DailyReportStale"
