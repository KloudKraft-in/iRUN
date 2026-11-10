#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
CONF="$STARTER/conf.d/retail_promo.conf"
CONF_BAK="$STARTER/conf.d/retail_promo.conf.bak"
EVIDENCE="$STARTER/evidence/evidence_D1_2.md"
STATE_F="/tmp/lab-state-D1-2.json"

invoke_reset() {
    pkill -f "promo_backend.py" 2>/dev/null || true
    rm -f "$STATE_F"
    echo "MIA-D1-102 reset complete."
}

invoke_start() {
    invoke_reset
    echo "Staging Scenario MIA-D1-102: Nginx 502 Bad Gateway..."
    sed -i 's/127.0.0.1:8080/127.0.0.1:9090/g' "$CONF"
    python3 "$STARTER/mock_services/promo_backend.py" 8080 >/dev/null 2>&1 &
    sleep 1
    echo "{"started": true}" > "$STATE_F"
    echo "TICKET MIA-D1-102 [P2: Customer 502 Outage]"
    echo "Next: Inspect starter/logs/error.log and follow Participant_Guide_day1.md Ticket 2."
}

invoke_check() {
    echo "==================================================="
    echo " Validating MIA-D1-102: Nginx 502 Upstream Repair   "
    echo "==================================================="
    PASSED=0
    TOTAL=5

    # 1. Backend on 8080
    if ss -tulpn 2>/dev/null | grep -q ":8080 "; then
        echo "  [PASS] Promo backend microservice is listening on port 8080"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] No listener on port 8080"
    fi

    # 2. Config port 8080
    if grep -q 'proxy_pass http://127.0.0.1:8080' "$CONF"; then
        echo "  [PASS] Nginx virtual host configured to proxy_pass http://127.0.0.1:8080"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] proxy_pass does not point to 127.0.0.1:8080"
    fi

    # 3. Headers
    if grep -q 'X-Forwarded-For' "$CONF" && grep -q 'X-Real-IP' "$CONF"; then
        echo "  [PASS] Client IP forwarding headers (X-Real-IP, X-Forwarded-For) present"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Missing reverse proxy headers"
    fi

    # 4. HTTP 200
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/promo || echo "000")
    if [ "$STATUS" -eq 200 ]; then
        echo "  [PASS] Promotional endpoint returns HTTP 200 OK"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] HTTP status was $STATUS (expected 200)"
    fi

    # 5. Evidence
    if [ -f "$EVIDENCE" ] && ! grep -q "<<FILL" "$EVIDENCE"; then
        echo "  [PASS] Incident evidence recorded in evidence_D1_2.md"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] evidence_D1_2.md contains unfilled <<FILL>>"
    fi

    echo "==================================================="
    echo " Validation Results: $PASSED/$TOTAL passed"
    echo "==================================================="
    if [ "$PASSED" -eq "$TOTAL" ]; then
        echo " [PASS] MIA-D1-102 Validation Succeeded!"
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
