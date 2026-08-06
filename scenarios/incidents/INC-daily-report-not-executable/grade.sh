#!/usr/bin/env bash
# grade.sh - verifies the fix to INC-daily-report-not-executable is REAL.
set -euo pipefail

SCENARIO_ID="INC-daily-report-not-executable"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

PERMS=$(docker exec "$CONTAINER" stat -c '%a' /opt/heartbeat/daily_report.sh)
case "$PERMS" in
    [1357][0-7][0-7]) : ;;  # owner-executable (odd first digit = x bit set)
    *) fail "daily_report.sh is mode ${PERMS} — not executable by owner" ;;
esac

docker exec "$CONTAINER" rm -f /var/log/heartbeat/report.log
docker exec "$CONTAINER" su -s /bin/bash heartbeat -c \
    'env -i PATH=/usr/bin:/bin /opt/heartbeat/daily_report.sh' \
    || fail "job still fails when run the way cron actually runs it"

docker exec "$CONTAINER" test -s /var/log/heartbeat/report.log \
    || fail "report.log was not written"

pass "daily_report.sh is executable and succeeds under cron's real environment"
