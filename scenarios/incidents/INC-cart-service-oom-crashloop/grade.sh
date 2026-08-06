#!/usr/bin/env bash
# grade.sh - verifies the fix to INC-cart-service-oom-crashloop is REAL.
set -euo pipefail

SCENARIO_ID="INC-cart-service-oom-crashloop"
CONTAINER="abhyas-cart-service"
fail() { echo "[grade:${SCENARIO_ID}] FAIL: $*" >&2; exit 1; }
pass() { echo "[grade:${SCENARIO_ID}] PASS: $*"; }

# 1. The memory limit must genuinely have been raised to something the
#    app can actually run inside — not just restarted and gotten lucky once.
MEM_BYTES=$(docker inspect "$CONTAINER" --format '{{.HostConfig.Memory}}')
MEM_MB=$((MEM_BYTES / 1024 / 1024))
[ "$MEM_MB" -ge 64 ] || fail "memory limit is only ${MEM_MB}MB — still too tight to be a real fix"

# 2. The real test: stability over time, not a lucky snapshot. A cosmetic
#    "fix" (just restarting again without raising the limit) would still
#    be climbing RestartCount right now.
N1=$(docker inspect "$CONTAINER" --format '{{.RestartCount}}')
sleep 6
N2=$(docker inspect "$CONTAINER" --format '{{.RestartCount}}')
[ "$N1" = "$N2" ] || fail "cart-service is still crash-looping (RestartCount ${N1} -> ${N2})"

HEALTH=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8001/health || true)
[ "$HEALTH" = "200" ] || fail "health endpoint returned '${HEALTH}', expected 200"

pass "memory limit restored to ${MEM_MB}MB; cart-service stable and healthy"
