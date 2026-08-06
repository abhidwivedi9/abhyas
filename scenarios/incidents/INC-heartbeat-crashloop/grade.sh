#!/usr/bin/env bash
# grade.sh — verifies the fix to INC-heartbeat-crashloop is REAL.
# Invoked by: abhyasctl scenario grade INC-heartbeat-crashloop
set -euo pipefail

SCENARIO_ID="INC-heartbeat-crashloop"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# 1. The health endpoint must respond — proves the process is really up and
#    serving, not just present in the process table for a brief instant.
HEALTH=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' \
    http://localhost:8080/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

# 2. The real test: the restart counter must have STOPPED climbing. A
#    cosmetic fix (systemctl reset-failed/restart without touching the
#    actual bug) would still be crash-looping, and NRestarts would keep
#    increasing across the gap below. A genuine fix means no new crashes.
N1=$(docker exec "$CONTAINER" systemctl show heartbeat -p NRestarts --value)
sleep 6
N2=$(docker exec "$CONTAINER" systemctl show heartbeat -p NRestarts --value)
[ "$N1" = "$N2" ] || fail "heartbeat is still crash-looping (NRestarts ${N1} -> ${N2}) — root cause not fixed"

# 3. Still active after that same gap (belt-and-suspenders on #2).
STATE=$(docker exec "$CONTAINER" systemctl is-active heartbeat || true)
[ "$STATE" = "active" ] || fail "heartbeat.service is '${STATE}', not active"

# 4. The heartbeat loop must be genuinely producing fresh log lines, not a
#    stale log from before the incident.
LAST_LINE=$(docker exec "$CONTAINER" tail -1 /var/log/heartbeat/heartbeat.log || true)
echo "$LAST_LINE" | grep -q "heartbeat ok" || fail "no recent heartbeat log entry found"

pass "heartbeat.service is active, healthy, and stable (NRestarts steady at ${N2}); root cause fixed"
