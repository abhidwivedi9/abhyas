#!/usr/bin/env bash
# inject.sh — creates the REAL fault for INC-daily-report-cron-path.
set -euo pipefail

SCENARIO_ID="INC-daily-report-cron-path"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] installing a convenience helper under /usr/local/bin..."
# /usr/local/bin is on a normal interactive shell's PATH by default on
# Ubuntu, which is exactly why this bug survives manual testing — but
# cron's own default PATH (/usr/bin:/bin) does not include it.
docker exec "$CONTAINER" sh -c 'cat > /usr/local/bin/heartbeat-counter <<SCRIPT
#!/usr/bin/env bash
grep -c "heartbeat ok" "\$1" 2>/dev/null || echo 0
SCRIPT
chmod +x /usr/local/bin/heartbeat-counter'

echo "[inject:${SCENARIO_ID}] simulating the 'simplify the report script' change..."
docker exec "$CONTAINER" sh -c 'cat > /opt/heartbeat/daily_report.sh <<SCRIPT
#!/usr/bin/env bash
set -euo pipefail
COUNT=\$(heartbeat-counter /var/log/heartbeat/heartbeat.log)
echo "\$(date -Iseconds) daily_report: \${COUNT} heartbeats logged" >> /var/log/heartbeat/report.log
SCRIPT
chown heartbeat:heartbeat /opt/heartbeat/daily_report.sh
chmod +x /opt/heartbeat/daily_report.sh'

echo "[inject:${SCENARIO_ID}] confirming: works interactively, fails under cron's real PATH..."
if ! docker exec "$CONTAINER" su -s /bin/bash heartbeat -c '/opt/heartbeat/daily_report.sh' >/dev/null 2>&1; then
    echo "error: script should still succeed with a normal interactive PATH" >&2
    exit 1
fi
docker exec "$CONTAINER" rm -f /var/log/heartbeat/report.log  # reset what the interactive test above just wrote

if docker exec "$CONTAINER" su -s /bin/bash heartbeat -c 'env -i PATH=/usr/bin:/bin /opt/heartbeat/daily_report.sh' 2>/dev/null; then
    echo "error: script should fail under cron's restricted PATH — injection did not take" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. Runs fine interactively; fails under cron's real PATH."
echo "[inject:${SCENARIO_ID}] pager firing: DailyReportStale"
