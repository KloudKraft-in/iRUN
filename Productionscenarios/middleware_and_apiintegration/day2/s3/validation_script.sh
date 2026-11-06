#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
KONG_CONF="$STARTER/conf/kong_service.json"
NGX_CONF="$STARTER/conf/checkout_nginx.conf"
EVIDENCE="$STARTER/evidence/evidence_D2_3.md"

invoke_reset() {
    pkill -f "slow_checkout_backend.py" 2>/dev/null || true
    echo "MIA-D2-203 reset complete."
}

invoke_start() {
    invoke_reset
    echo "Staging Scenario MIA-D2-203: Distributed Timeout Inversion..."
    python3 "$STARTER/mock_services/slow_checkout_backend.py" 8085 >/dev/null 2>&1 &
    echo "TICKET MIA-D2-203 [P2: Intermittent 504 on Checkout & Ghost Orders]"
    echo "Next: Inspect starter/logs/multi_hop_trace.log and follow Participant_Guide_day2.md Ticket 3."
}

invoke_check() {
    echo "==================================================="
    echo " Validating MIA-D2-203: Distributed Timeout Chain   "
    echo "==================================================="
    PASSED=0
    TOTAL=3

    K_TO=$(python3 -c "import json; print(json.load(open('$KONG_CONF'))['read_timeout'])")
    if [ "$K_TO" -ge 12000 ]; then
        echo "  [PASS] Kong Gateway read_timeout aligned to >= 12000ms ($K_TO ms)"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Kong read_timeout ($K_TO ms) is dangerously low (< 12000ms)"
    fi

    if grep -q "proxy_read_timeout 12s" "$NGX_CONF"; then
        echo "  [PASS] Nginx proxy_read_timeout aligned to 12s"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Nginx proxy_read_timeout is not 12s"
    fi

    if [ -f "$EVIDENCE" ] && ! grep -q "<<FILL" "$EVIDENCE"; then
        echo "  [PASS] Incident Escalation and RCA evidence recorded in evidence_D2_3.md"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] evidence_D2_3.md contains unfilled <<FILL>> fields"
    fi

    echo "==================================================="
    echo " Validation Results: $PASSED/$TOTAL passed"
    echo "==================================================="
    if [ "$PASSED" -eq "$TOTAL" ]; then
        echo " [PASS] MIA-D2-203 Validation Succeeded!"
        exit 0
    else
        echo " [FAIL] Some checks failed."
        exit 1
    fi
}

case "$ACTION" in
    start) invoke_start ;;
    reset) invoke_reset ;;
    check) invoke_check ;;
    *)     invoke_check ;;
esac
