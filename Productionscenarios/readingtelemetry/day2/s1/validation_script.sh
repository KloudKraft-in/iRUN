#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D2_1.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D2-201..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D2-201"
    echo " Davis Opened a Problem: Find the Root Cause"
    echo "==================================================="
    echo "Observed Failure: Dynatrace Davis AI engine automatically opened Problem P-24101 indicating payment degradation. Navigating complex UI menus makes finding the root cause code span difficult."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D2_1.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D2-201"
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
    # Check 1: Dynatrace problem card ID identified
    if grep -q -i -F "P-24101" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Dynatrace problem card ID identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Dynatrace problem card ID identified (missing pattern: P-24101)"
    fi
    # Check 2: Failing topology service isolated
    if grep -q -i -F "PaymentService" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Failing topology service isolated"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Failing topology service isolated (missing pattern: PaymentService)"
    fi
    # Check 3: Code-level failing method captured
    if grep -q -i -F "StripeGatewayConnector.authorize" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Code-level failing method captured"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Code-level failing method captured (missing pattern: StripeGatewayConnector.authorize)"
    fi
    # Check 4: Underlying network timeout exception identified
    if grep -q -i -F "SocketTimeoutException" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Underlying network timeout exception identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Underlying network timeout exception identified (missing pattern: SocketTimeoutException)"
    fi
    # Check 5: Host infrastructure node identified
    if grep -q -i -F "prod-host-03" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Host infrastructure node identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Host infrastructure node identified (missing pattern: prod-host-03)"
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
