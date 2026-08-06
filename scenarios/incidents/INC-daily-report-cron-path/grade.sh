#!/usr/bin/env bash
# grade.sh — verifies the fix to INC-daily-report-cron-path is REAL.
set -euo pipefail

SCENARIO_ID="INC-daily-report-cron-path"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# The real test: run the job exactly the way cron would (its actual
# restricted default PATH, as the heartbeat user) — not via a normal shell,
# which would mask this exact class of bug.
docker exec "$CONTAINER" rm -f /var/log/heartbeat/report.log
if ! docker exec "$CONTAINER" su -s /bin/bash heartbeat -c \
        'env -i PATH=/usr/bin:/bin /opt/heartbeat/daily_report.sh'; then
    fail "daily_report.sh still fails under cron's real (restricted) PATH"
fi

docker exec "$CONTAINER" test -s /var/log/heartbeat/report.log \
    || fail "report.log was not written"
docker exec "$CONTAINER" tail -1 /var/log/heartbeat/report.log | grep -q "heartbeats logged" \
    || fail "report.log content looks wrong"

pass "daily_report.sh succeeds under cron's real environment, not just interactively"
