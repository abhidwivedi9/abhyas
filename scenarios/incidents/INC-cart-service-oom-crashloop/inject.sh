#!/usr/bin/env bash
# inject.sh - creates the REAL fault for INC-cart-service-oom-crashloop.
set -euo pipefail

SCENARIO_ID="INC-cart-service-oom-crashloop"
CONTAINER="abhyas-cart-service"

echo "[inject:${SCENARIO_ID}] checking cart-service is up..."
if ! docker exec "$CONTAINER" true 2>/dev/null; then
    echo "error: ${CONTAINER} is not running. Run 'abhyasctl up' first." >&2
    exit 1
fi

echo "[inject:${SCENARIO_ID}] simulating a resource-rightsizing pass setting the memory limit too low..."
# 20m is below what the Python/uvicorn process itself needs just to start
# (observed idle usage is ~43MB) - every restart attempt will immediately
# OOM again, a genuine sustained crash loop, not a one-shot event.
docker update --memory 20m --memory-swap 20m "$CONTAINER" >/dev/null
docker restart "$CONTAINER" >/dev/null

echo "[inject:${SCENARIO_ID}] confirming a genuine sustained crash loop..."
N1=$(docker inspect "$CONTAINER" --format '{{.RestartCount}}')
sleep 6
N2=$(docker inspect "$CONTAINER" --format '{{.RestartCount}}')
if [ "$N2" -le "$N1" ]; then
    echo "error: RestartCount did not climb (${N1} -> ${N2}) — injection did not take" >&2
    exit 1
fi
OOMKILLED=$(docker inspect "$CONTAINER" --format '{{.State.OOMKilled}}')

echo "[inject:${SCENARIO_ID}] fault active. RestartCount ${N1} -> ${N2} and climbing (OOMKilled=${OOMKILLED})."
echo "[inject:${SCENARIO_ID}] pager firing: CartServiceRestartLoop"
