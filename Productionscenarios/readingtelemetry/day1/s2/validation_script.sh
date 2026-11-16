#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D1_2.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D1-102..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D1-102"
    echo " Orders Fail for One Product: Follow the Trace"
    echo "==================================================="
    echo "Observed Failure: Orders for promotional SKU 'PROD-7729' fail intermittently with generic 500 error screens. Aggregate service metrics report healthy throughput, masking isolated transaction failures."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D1_2.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D1-102"
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
    # Check 1: Trace ID identified and recorded
    if grep -q -i -F "4bf92f3577b34da6a3ce929d0e0e4736" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Trace ID identified and recorded"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Trace ID identified and recorded (missing pattern: 4bf92f3577b34da6a3ce929d0e0e4736)"
    fi
    # Check 2: Failing span operation identified
    if grep -q -i -F "inventory.reserveStock" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Failing span operation identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Failing span operation identified (missing pattern: inventory.reserveStock)"
    fi
    # Check 3: Target promotional SKU identified
    if grep -q -i -F "PROD-7729" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Target promotional SKU identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Target promotional SKU identified (missing pattern: PROD-7729)"
    fi
    # Check 4: Business exception captured from Loki
    if grep -q -i -F "StockReservationException" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Business exception captured from Loki"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Business exception captured from Loki (missing pattern: StockReservationException)"
    fi
    # Check 5: Root cause audit lock documented
    if grep -q -i -F "audit" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Root cause audit lock documented"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Root cause audit lock documented (missing pattern: audit)"
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
