#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D2_3.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D2-203..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D2-203"
    echo " One Incident, Four Tools: Write the Escalation"
    echo "==================================================="
    echo "Observed Failure: Checkout experience is severely degraded across microservices. SREs receive contradictory signals across Grafana, Kibana, New Relic, and cloud consoles."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D2_3.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D2-203"
    echo "==================================================="
    
    if [ ! -f "$EVIDENCE" ]; then
        echo " [ERROR] Evidence file not found: $EVIDENCE"
        echo " Total Score: 0/5 (0%)"
        return 1
    fi
    
    if grep -q "<<FILL_" "$EVIDENCE" 2>/dev/null; then
        echo " [WARNING] Detected unfilled placeholder tokens (<<FILL_...>>) in evidence!"
    fi
    
    PASSED=0
    TOTAL=5
    # Check 1: Contended database identified
    if grep -q -i -F "orders_db" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Contended database identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Contended database identified (missing pattern: orders_db)"
    fi
    # Check 2: Lock contention root cause cited
    if grep -q -i -F "lock" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Lock contention root cause cited"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Lock contention root cause cited (missing pattern: lock)"
    fi
    # Check 3: Bottleneck controller identified
    if grep -q -i -F "CheckoutController" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Bottleneck controller identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Bottleneck controller identified (missing pattern: CheckoutController)"
    fi
    # Check 4: Grafana evidence referenced
    if grep -q -i -F "grafana" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Grafana evidence referenced"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Grafana evidence referenced (missing pattern: grafana)"
    fi
    # Check 5: Kibana log query included
    if grep -q -i -F "kibana" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Kibana log query included"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Kibana log query included (missing pattern: kibana)"
    fi
    SCORE=$((PASSED * 100 / TOTAL))
    echo "---------------------------------------------------"
    echo " Test Summary: $PASSED / $TOTAL checks passed ($SCORE%)"
    echo "---------------------------------------------------"
    if [ "$PASSED" -eq "$TOTAL" ]; then
        echo " [SUCCESS] All validation checks passed successfully!"
        return 0
    else
        echo " [INCOMPLETE] Please address failed checks and re-run."
        return 1
    fi
}

case "$ACTION" in
    start)
        invoke_start
        ;;
    check)
        invoke_check
        ;;
    reset)
        invoke_reset
        ;;
    help|*)
        echo "Usage: ./validation_script.sh {start|check|reset}"
        ;;
esac
