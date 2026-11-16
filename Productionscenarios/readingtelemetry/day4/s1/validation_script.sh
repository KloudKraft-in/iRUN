#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D4_1.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D4-401..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D4-401"
    echo " Slow-Transaction Report for the Ops Review"
    echo "==================================================="
    echo "Observed Failure: Operations review requires a p95 transaction latency ranking for ShopNow-Production. Default APM overviews do not isolate top-5 slowest transactions."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D4_1.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D4-401"
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
    # Check 1: NRQL percentile function used
    if grep -q -i -F "percentile(duration, 95)" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: NRQL percentile function used"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: NRQL percentile function used (missing pattern: percentile(duration, 95))"
    fi
    # Check 2: Target appName filtered
    if grep -q -i -F "ShopNow-Production" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Target appName filtered"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Target appName filtered (missing pattern: ShopNow-Production)"
    fi
    # Check 3: Facet grouping by transaction name
    if grep -q -i -F "FACET name" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Facet grouping by transaction name"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Facet grouping by transaction name (missing pattern: FACET name)"
    fi
    # Check 4: Top 5 limit applied
    if grep -q -i -F "LIMIT 5" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Top 5 limit applied"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Top 5 limit applied (missing pattern: LIMIT 5)"
    fi
    # Check 5: Slowest transaction identified
    if grep -q -i -F "processPayment" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Slowest transaction identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Slowest transaction identified (missing pattern: processPayment)"
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
