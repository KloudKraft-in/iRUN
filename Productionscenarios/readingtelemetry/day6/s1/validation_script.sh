#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D6_1.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D6-601..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D6-601"
    echo " Metric Anomaly to Root Cause in One Platform"
    echo "==================================================="
    echo "Observed Failure: At 09:12 UTC, checkout conversion drops by 35%. Engineers must correlate metric anomaly to application logs and distributed traces without tool switching."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D6_1.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D6-601"
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
    # Check 1: Anomaly timestamp identified
    if grep -q -i -F "09:12" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Anomaly timestamp identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Anomaly timestamp identified (missing pattern: 09:12)"
    fi
    # Check 2: Target service identified
    if grep -q -i -F "checkout-api" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Target service identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Target service identified (missing pattern: checkout-api)"
    fi
    # Check 3: Correlated Trace ID extracted
    if grep -q -i -F "6a71e29f8c12" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Correlated Trace ID extracted"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Correlated Trace ID extracted (missing pattern: 6a71e29f8c12)"
    fi
    # Check 4: Tempo trace tool referenced
    if grep -q -i -F "Tempo" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Tempo trace tool referenced"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Tempo trace tool referenced (missing pattern: Tempo)"
    fi
    # Check 5: Loki log error filter applied
    if grep -q -i -F "status="ERROR"" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Loki log error filter applied"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Loki log error filter applied (missing pattern: status="ERROR")"
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
