#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
CONF="$STARTER/conf/server.xml"
CONF_BAK="$STARTER/conf/server.xml.bak"
EVIDENCE="$STARTER/evidence/evidence_D1_1.json"
STATE_F="/tmp/lab-state-D1-1.json"

get_listener_pid() {
    local port="$1"
    ss -tulpn 2>/dev/null | grep ":$port " | awk '{print $NF}' | sed -E 's/.*pid=([0-9]+).*/\1/' | head -n 1
}

invoke_reset() {
    pkill -f "rogue_daemon.py" 2>/dev/null || true
    pkill -f "catalog_app.py" 2>/dev/null || true
    rm -f "$STATE_F"
    echo "MIA-D1-101 reset complete."
}

invoke_start() {
    invoke_reset
    echo "Staging Scenario MIA-D1-101: Tomcat Port Collision..."
    sed -i 's/port="8080"/port="8082"/g' "$CONF"
    rm -f "$CONF_BAK"
    
    python3 "$STARTER/mock_services/rogue_daemon.py" >/dev/null 2>&1 &
    sleep 1
    local pid=$(get_listener_pid 8082)
    echo "{"daemonPid": "$pid"}" > "$STATE_F"
    echo "TICKET MIA-D1-101 [P2: Retail Catalog Down]"
    echo "Next: Inspect starter/logs/catalina.out and follow Participant_Guide_day1.md."
}

invoke_check() {
    echo "==================================================="
    echo " Validating MIA-D1-101: Tomcat Port Collision       "
    echo "==================================================="
    PASSED=0
    TOTAL=5

    # 1. Daemon untouched
    local d=$(get_listener_pid 8082)
    if [ -n "$d" ]; then
        echo "  [PASS] Legacy daemon still occupies port 8082"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Legacy daemon on port 8082 is missing"
    fi

    # 2. Config port 8080
    if grep -q 'port="8080"' "$CONF"; then
        echo "  [PASS] server.xml HTTP Connector configured to port 8080"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] server.xml does not contain port 8080"
    fi

    # 3. Backup file
    if [ -f "$CONF_BAK" ]; then
        echo "  [PASS] Production backup file server.xml.bak exists"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] server.xml.bak missing"
    fi

    # 4. Catalog endpoint responds 200
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/catalog || echo "000")
    if [ "$STATUS" -eq 200 ]; then
        echo "  [PASS] Catalog service responds HTTP 200 OK on port 8080"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Catalog endpoint returned HTTP $STATUS (expected 200)"
    fi

    # 5. Evidence file
    if [ -f "$EVIDENCE" ] && ! grep -q "<<FILL" "$EVIDENCE"; then
        echo "  [PASS] Incident evidence recorded in evidence_D1_1.json"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] evidence_D1_1.json incomplete or contains <<FILL>>"
    fi

    echo "==================================================="
    echo " Validation Results: $PASSED/$TOTAL passed"
    echo "==================================================="
    if [ "$PASSED" -eq "$TOTAL" ]; then
        echo " [PASS] MIA-D1-101 Validation Succeeded!"
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
