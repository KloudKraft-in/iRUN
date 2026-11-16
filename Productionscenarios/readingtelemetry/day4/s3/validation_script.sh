#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D4_3.json"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D4-403..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D4-403"
    echo " Latency Percentile and Service Variable Are Wrong"
    echo "==================================================="
    echo "Observed Failure: SRE dashboard latency percentiles show flat lines measuring cumulative stats since server reboot, and selecting a service in the variable dropdown causes panels to show 'No Data'."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D4_3.json"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D4-403"
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
    # Check 1: Quantile set to 0.95
    if grep -q -i -F "histogram_quantile(0.95" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Quantile set to 0.95"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Quantile set to 0.95 (missing pattern: histogram_quantile(0.95)"
    fi
    # Check 2: Rate wrapped around bucket counter
    if grep -q -i -F "rate(http_request_duration_seconds_bucket" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Rate wrapped around bucket counter"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Rate wrapped around bucket counter (missing pattern: rate(http_request_duration_seconds_bucket)"
    fi
    # Check 3: Aggregation includes le label
    if grep -q -i -F "by (le" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Aggregation includes le label"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Aggregation includes le label (missing pattern: by (le)"
    fi
    # Check 4: Non-capturing regex group implemented
    if grep -q -i -F "?:" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Non-capturing regex group implemented"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Non-capturing regex group implemented (missing pattern: ?:)"
    fi
    # Check 5: Variable interpolation preserved
    if grep -q -i -F "service=~"$service"" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Variable interpolation preserved"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Variable interpolation preserved (missing pattern: service=~"$service")"
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
