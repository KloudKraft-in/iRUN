#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D5_1.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D5-501..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D5-501"
    echo " Top Failing Dependency in Application Insights"
    echo "==================================================="
    echo "Observed Failure: Downstream third-party dependency failures cause checkout degradation. Engineers cannot determine which vendor is failing or correlate errors to application exceptions."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D5_1.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D5-501"
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
    # Check 1: Dependencies table queried
    if grep -q -i -F "dependencies" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Dependencies table queried"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Dependencies table queried (missing pattern: dependencies)"
    fi
    # Check 2: Failing dependency target identified
    if grep -q -i -F "api.external-fraud.io" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Failing dependency target identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Failing dependency target identified (missing pattern: api.external-fraud.io)"
    fi
    # Check 3: Inner join with exceptions table performed
    if grep -q -i -F "join kind=inner" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Inner join with exceptions table performed"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Inner join with exceptions table performed (missing pattern: join kind=inner)"
    fi
    # Check 4: Correlated on operation_Id
    if grep -q -i -F "operation_Id" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Correlated on operation_Id"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Correlated on operation_Id (missing pattern: operation_Id)"
    fi
    # Check 5: Gateway timeout error code recorded
    if grep -q -i -F "504" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Gateway timeout error code recorded"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Gateway timeout error code recorded (missing pattern: 504)"
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
