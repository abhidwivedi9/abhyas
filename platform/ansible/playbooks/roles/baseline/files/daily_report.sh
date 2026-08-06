#!/usr/bin/env bash
# Cron job target for cron-related scenarios (silent failures, wrong PATH,
# missing permissions). Counts today's heartbeats — a stand-in for the kind
# of daily report job every real ops team has somewhere.
set -euo pipefail
COUNT=$(grep -c "heartbeat ok" /var/log/heartbeat/heartbeat.log 2>/dev/null || echo 0)
echo "$(date -Iseconds) daily_report: ${COUNT} heartbeats logged" >> /var/log/heartbeat/report.log
