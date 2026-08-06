#!/usr/bin/env bash
# grade.sh - verifies the fix to INC-cart-service-zombie-processes is REAL.
set -euo pipefail

SCENARIO_ID="INC-cart-service-zombie-processes"
CONTAINER="abhyas-cart-service"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# The real test: zombie count must be at (or near) zero AND stay there -
# not just a lucky snapshot between generator ticks.
Z1=$(docker exec "$CONTAINER" sh -c "ps -o stat | { grep -c Z || true; }" 2>/dev/null)
[ "$Z1" -le 1 ] || fail "still ${Z1} zombie processes present"

sleep 5
Z2=$(docker exec "$CONTAINER" sh -c "ps -o stat | { grep -c Z || true; }" 2>/dev/null)
[ "$Z2" -le 1 ] || fail "zombie count climbed again (${Z1} -> ${Z2}) — source not actually stopped"

HEALTH=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8001/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

pass "no zombie processes accumulating; cart-service stable and healthy"
