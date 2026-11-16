#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D4_2.json"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D4-402..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D4-402"
    echo " Error Panel Shows Zero During an Outage"
    echo "==================================================="
    echo "Observed Failure: During an ongoing payment outage, the Grafana Error Rate panel displays 0 errors. SREs have zero visibility into failure rates."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D4_2.json"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D4-402"
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
    # Check 1: Loki JSON pipeline stage applied
    if grep -q -i -F "| json" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Loki JSON pipeline stage applied"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Loki JSON pipeline stage applied (missing pattern: | json)"
    fi
    # Check 2: Structured level field queried
    if grep -q -i -F "level" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Structured level field queried"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Structured level field queried (missing pattern: level)"
    fi
    # Check 3: Uppercase ERROR status matched
    if grep -q -i -F "ERROR" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Uppercase ERROR status matched"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Uppercase ERROR status matched (missing pattern: ERROR)"
    fi
    # Check 4: Rate aggregator used instead of count_over_time
    if grep -q -i -F "rate(" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Rate aggregator used instead of count_over_time"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Rate aggregator used instead of count_over_time (missing pattern: rate()"
    fi
    # Check 5: Payment service selector preserved
    if grep -q -i -F "payment-service" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Payment service selector preserved"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Payment service selector preserved (missing pattern: payment-service)"
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
