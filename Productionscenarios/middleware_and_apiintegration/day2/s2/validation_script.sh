#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
CONFIG="$STARTER/gateway_auth_config.json"
CERTS="$STARTER/certs/cert_metadata.json"
EVIDENCE="$STARTER/evidence/evidence_D2_2.md"

invoke_reset() {
    pkill -f "auth_gateway.py" 2>/dev/null || true
    echo "MIA-D2-202 reset complete."
}

invoke_start() {
    invoke_reset
    echo "Staging Scenario MIA-D2-202: JWT & SSL Repair..."
    cd "$STARTER"
    python3 generate_certs.py
    echo '{"allowed_audiences": ["mobile-app-v2"], "clock_skew": 0}' > gateway_auth_config.json
    python3 mock_services/auth_gateway.py 8443 >/dev/null 2>&1 &
    cd "$LAB_DIR"
    echo "TICKET MIA-D2-202 [P2: Mobile Login 401 & SSL Outage]"
    echo "Next: Inspect starter/client_simulator.py and follow Participant_Guide_day2.md Ticket 2."
}

invoke_check() {
    echo "==================================================="
    echo " Validating MIA-D2-202: JWT & SSL Handshake Repair  "
    echo "==================================================="
    PASSED=0
    TOTAL=4

    # 1. Allowed audience
    if grep -q "retail-web-client" "$CONFIG"; then
        echo "  [PASS] Gateway configured to accept retail-web-client audience"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Missing retail-web-client in allowed_audiences"
    fi

    # 2. SSL Cert
    STATUS=$(python3 -c "import json; print(json.load(open('$CERTS'))['active']['status'])")
    if [ "$STATUS" == "VALID" ]; then
        echo "  [PASS] Renewed SSL certificate bundle active and valid"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Active certificate still EXPIRED"
    fi

    # 3. HTTP 200
    TOKEN=$(python3 "$STARTER/client_simulator.py" | grep -A 1 "Generated token:" | tail -n 1)
    RES=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:8443 || echo "000")
    if [ "$RES" -eq 200 ]; then
        echo "  [PASS] Mobile client authenticated successfully with HTTP 200 OK"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] HTTP status was $RES (expected 200)"
    fi

    # 4. Evidence
    if [ -f "$EVIDENCE" ] && ! grep -q "<<FILL" "$EVIDENCE"; then
        echo "  [PASS] Incident evidence recorded in evidence_D2_2.md"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] evidence_D2_2.md contains unfilled <<FILL>>"
    fi

    echo "==================================================="
    echo " Validation Results: $PASSED/$TOTAL passed"
    echo "==================================================="
    if [ "$PASSED" -eq "$TOTAL" ]; then
        echo " [PASS] MIA-D2-202 Validation Succeeded!"
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
