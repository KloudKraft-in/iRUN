#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D2_2.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D2-202..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D2-202"
    echo " Datadog Monitor Fires: Confirm It in Splunk"
    echo "==================================================="
    echo "Observed Failure: Datadog composite monitor triggers alert: CPU > 80% on prod-worker-02 AND Error Rate > 5%. Raw log evidence must be extracted from Splunk to confirm transaction failure."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D2_2.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D2-202"
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
    # Check 1: Transaction correlation ID verified
    if grep -q -i -F "TXN-88129-CORR" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Transaction correlation ID verified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Transaction correlation ID verified (missing pattern: TXN-88129-CORR)"
    fi
    # Check 2: Correct Splunk index targeted
    if grep -q -i -F "index=retail_prod" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Correct Splunk index targeted"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Correct Splunk index targeted (missing pattern: index=retail_prod)"
    fi
    # Check 3: Correct worker host identified
    if grep -q -i -F "prod-worker-02" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Correct worker host identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Correct worker host identified (missing pattern: prod-worker-02)"
    fi
    # Check 4: Splunk sourcetype specified
    if grep -q -i -F "sourcetype=" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Splunk sourcetype specified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Splunk sourcetype specified (missing pattern: sourcetype=)"
    fi
    # Check 5: Correct sourcetype formatted
    if grep -q -i -F "checkout:json" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Correct sourcetype formatted"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Correct sourcetype formatted (missing pattern: checkout:json)"
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
