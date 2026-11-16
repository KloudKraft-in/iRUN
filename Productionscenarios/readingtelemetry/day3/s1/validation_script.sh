#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D3_1.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D3-301..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D3-301"
    echo " Error Spike on One Host After a Release"
    echo "==================================================="
    echo "Observed Failure: Post-deployment error rate surges to 8.4%. Standard log searches fail to extract unstructured error codes from application logs on host web-prod-04."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D3_1.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D3-301"
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
    # Check 1: Culprit host isolated
    if grep -q -i -F "web-prod-04" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Culprit host isolated"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Culprit host isolated (missing pattern: web-prod-04)"
    fi
    # Check 2: Regex extraction command used
    if grep -q -i -F "rex field=_raw" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Regex extraction command used"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Regex extraction command used (missing pattern: rex field=_raw)"
    fi
    # Check 3: Error code pattern matched
    if grep -q -i -F "ERR-[0-9]{4}" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Error code pattern matched"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Error code pattern matched (missing pattern: ERR-[0-9]{4})"
    fi
    # Check 4: Timechart aggregation present
    if grep -q -i -F "timechart" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Timechart aggregation present"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Timechart aggregation present (missing pattern: timechart)"
    fi
    # Check 5: Session transaction grouping implemented
    if grep -q -i -F "transaction session_id" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Session transaction grouping implemented"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Session transaction grouping implemented (missing pattern: transaction session_id)"
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
