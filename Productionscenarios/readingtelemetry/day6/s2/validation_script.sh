#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D6_2.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D6-602..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D6-602"
    echo " Error Budget Burn and a Cardinality Bill"
    echo "==================================================="
    echo "Observed Failure: A sudden release introduces high-cardinality labels, causing Prometheus TSDB series count to explode and depleting the 30-day error budget in under 2 hours."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D6_2.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D6-602"
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
    # Check 1: High-cardinality label identified
    if grep -q -i -F "user_id" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: High-cardinality label identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: High-cardinality label identified (missing pattern: user_id)"
    fi
    # Check 2: Prometheus labeldrop action specified
    if grep -q -i -F "labeldrop" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Prometheus labeldrop action specified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Prometheus labeldrop action specified (missing pattern: labeldrop)"
    fi
    # Check 3: metric_relabel_configs block used
    if grep -q -i -F "metric_relabel_configs" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: metric_relabel_configs block used"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: metric_relabel_configs block used (missing pattern: metric_relabel_configs)"
    fi
    # Check 4: Error budget burn rate documented
    if grep -q -i -F "burn" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Error budget burn rate documented"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Error budget burn rate documented (missing pattern: burn)"
    fi
    # Check 5: Regex selector defined
    if grep -q -i -F "regex:" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Regex selector defined"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Regex selector defined (missing pattern: regex:)"
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
