#!/usr/bin/env bash
# inject.sh — creates the REAL fault for INC-heartbeat-crashloop.
# Invoked by: abhyasctl scenario start INC-heartbeat-crashloop
#
# Target: the legacy-vm lab (platform/ansible/), not Kubernetes — this is a
# Milestone 1 (Linux/systemd) scenario. `abhyasctl up` must have already
# converged legacy-vm to baseline before this runs.
set -euo pipefail

SCENARIO_ID="INC-heartbeat-crashloop"
CONTAINER="${ABHYAS_LEGACY_VM_CONTAINER:-abhyas-legacy-vm}"

echo "[inject:${SCENARIO_ID}] checking legacy-vm is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating a bad deploy to heartbeat.py..."
# A one-character typo: "http.server" -> "http.serverx". This is what a real
# bad deploy looks like — the file is syntactically fine, it just references
# a module that doesn't exist, so the process dies on the very first import,
# every single time it's started. Restart=on-failure then puts it in an
# infinite crash loop — it never becomes healthy and never gives up on its
# own, exactly like a container stuck in CrashLoopBackOff.
docker exec "$CONTAINER" sed -i 's/import http\.server/import http.serverx/' \
    /opt/heartbeat/heartbeat.py

echo "[inject:${SCENARIO_ID}] restarting heartbeat to trigger the crash loop..."
docker exec "$CONTAINER" systemctl reset-failed heartbeat 2>/dev/null || true
docker exec "$CONTAINER" systemctl restart heartbeat || true

# Confirm the fault is real: the health endpoint must be consistently down
# (checked 3 times, 1s apart, to avoid the brief instant right after a
# restart attempt where the process is technically "active" before it
# crashes) and the crash signature must be in the journal.
echo "[inject:${SCENARIO_ID}] confirming health checks are failing..."
fails=0
for _ in 1 2 3; do
    CODE=$(docker exec "$CONTAINER" curl -s -o /dev/null -w '%{http_code}' \
        --max-time 1 http://localhost:8080/health 2>/dev/null || echo "000")
    [ "$CODE" != "200" ] && fails=$((fails + 1))
    sleep 1
done
if [ "$fails" -lt 3 ]; then
    echo "error: health endpoint is still responding — injection did not take" >&2
    exit 1
fi
if ! docker exec "$CONTAINER" journalctl -u heartbeat -n 20 --no-pager 2>/dev/null \
        | grep -q "ModuleNotFoundError"; then
    echo "error: expected crash signature not found in journal" >&2
    exit 1
fi

NRESTARTS=$(docker exec "$CONTAINER" systemctl show heartbeat -p NRestarts --value)
echo "[inject:${SCENARIO_ID}] fault active. heartbeat is crash-looping (NRestarts=${NRESTARTS} and climbing)."
echo "[inject:${SCENARIO_ID}] pager firing: HeartbeatServiceDown"
