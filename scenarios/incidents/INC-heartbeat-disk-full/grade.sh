#!/usr/bin/env bash
# grade.sh — verifies the fix to INC-heartbeat-disk-full is REAL.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-disk-full"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# 1. Disk must genuinely have free space — not just the log "looking" fine.
AVAIL_KB=$(docker exec "$CONTAINER" df --output=avail /var/log/heartbeat | tail -1 | tr -d ' ')
[ "$AVAIL_KB" -gt 0 ] || fail "no free space on /var/log/heartbeat (still full)"

# 2. Passing the naive health check alone is NOT enough — that's the whole
#    point of this scenario. The log must genuinely be advancing.
LINE1=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log || true)
sleep 4
LINE2=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log || true)
[ "$LINE1" != "$LINE2" ] || fail "heartbeat.log is still stale — logging thread not actually recovered"
echo "$LINE2" | grep -q "heartbeat ok" || fail "no valid heartbeat log entry found"

HEALTH=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' \
    http://localhost:8080/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

pass "disk has free space and heartbeat.log is genuinely advancing again"
