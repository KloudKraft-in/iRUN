#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D1_3.md"
STATE_F="/tmp/lab-state-D1-3.json"

invoke_reset() {
    pkill -f "inventory_backend.py" 2>/dev/null || true
    pkill -f "kong_mock_gateway.py" 2>/dev/null || true
    rm -f "$STATE_F"
    echo "MIA-D1-103 reset complete."
}

invoke_start() {
    invoke_reset
    echo "Staging Scenario MIA-D1-103: Kong Gateway..."
    python3 "$STARTER/mock_services/inventory_backend.py" 8081 >/dev/null 2>&1 &
    python3 "$STARTER/mock_services/kong_mock_gateway.py" >/dev/null 2>&1 &
    sleep 1
    echo "{"started": true}" > "$STATE_F"
    echo "TICKET MIA-D1-103 [P3: Partner API 404 & Missing Rate Limit]"
    echo "Next: Inspect routes and follow Participant_Guide_day1.md Ticket 3."
}

invoke_check() {
    echo "==================================================="
    echo " Validating MIA-D1-103: Kong Gateway Enforcement   "
    echo "==================================================="
    PASSED=0
    TOTAL=5

    # 1. 401
    C401=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/v1/inventory || echo "000")
    if [ "$C401" -eq 401 ]; then
        echo "  [PASS] Unauthenticated request rejected with HTTP 401 Unauthorized"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Expected 401, got $C401"
    fi

    # 2. 403
    C403=$(curl -s -o /dev/null -w "%{http_code}" -H "apikey: wrong_key" http://localhost:8000/api/v1/inventory || echo "000")
    if [ "$C403" -eq 403 ]; then
        echo "  [PASS] Request with invalid API key rejected with HTTP 403 Forbidden"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Expected 403, got $C403"
    fi

    # 3. 200
    C200=$(curl -s -o /dev/null -w "%{http_code}" -H "apikey: LogisticsSecretKey2026" http://localhost:8000/api/v1/inventory || echo "000")
    if [ "$C200" -eq 200 ]; then
        echo "  [PASS] Valid request with LogisticsSecretKey2026 returns HTTP 200 OK"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Expected 200, got $C200"
    fi

    # 4. 429
    for i in {1..5}; do
        curl -s -o /dev/null -H "apikey: LogisticsSecretKey2026" http://localhost:8000/api/v1/inventory
    done
    C429=$(curl -s -o /dev/null -w "%{http_code}" -H "apikey: LogisticsSecretKey2026" http://localhost:8000/api/v1/inventory || echo "000")
    if [ "$C429" -eq 429 ]; then
        echo "  [PASS] Traffic flood triggers HTTP 429 Too Many Requests (Rate limit active)"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Expected 429, got $C429"
    fi

    # 5. Evidence
    if [ -f "$EVIDENCE" ] && ! grep -q "<<FILL" "$EVIDENCE"; then
        echo "  [PASS] Incident evidence and error matrix recorded in evidence_D1_3.md"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] evidence_D1_3.md contains unfilled <<FILL>>"
    fi

    echo "==================================================="
    echo " Validation Results: $PASSED/$TOTAL passed"
    echo "==================================================="
    if [ "$PASSED" -eq "$TOTAL" ]; then
        echo " [PASS] MIA-D1-103 Validation Succeeded!"
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
