#!/usr/bin/env bash
# inject.sh - creates the REAL fault for INC-cart-service-zombie-processes.
set -euo pipefail

SCENARIO_ID="INC-cart-service-zombie-processes"
CONTAINER="abhyas-cart-service"

echo "[inject:${SCENARIO_ID}] checking cart-service is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating a leftover maintenance script that forks and never reaps..."
# Runs detached, forking a child every second and never wait()-ing on it.
# uvicorn (PID 1) never reaps unrelated children either, so each one
# becomes a permanent zombie once its immediate parent (this loop) is
# eventually gone - a real, common pattern: some one-off script left
# running, quietly leaking process-table entries.
docker exec -d "$CONTAINER" python3 -c "
import os, time
while True:
    pid = os.fork()
    if pid == 0:
        os._exit(0)
    time.sleep(1)
"

echo "[inject:${SCENARIO_ID}] confirming zombies are genuinely accumulating..."
Z1=$(docker exec "$CONTAINER" sh -c "ps -o stat | { grep -c Z || true; }")
sleep 4
Z2=$(docker exec "$CONTAINER" sh -c "ps -o stat | { grep -c Z || true; }")
if [ "$Z2" -le "$Z1" ]; then
    echo "error: zombie count did not climb (${Z1} -> ${Z2}) — injection did not take" >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] fault active. Zombie count ${Z1} -> ${Z2} and climbing."
echo "[inject:${SCENARIO_ID}] pager firing: CartServiceProcessCountHigh"
