#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D5_2.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D5-502..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D5-502"
    echo " Lambda Timeouts: Logs Insights Meets X-Ray"
    echo "==================================================="
    echo "Observed Failure: Order invoice generation Lambdas terminate abruptly with 'Task timed out after 30.00 seconds'. CloudWatch logs show timeouts but do not reveal the stalled downstream call."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D5_2.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D5-502"
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
    # Check 1: Timeout message filtered
    if grep -q -i -F "Task timed out" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Timeout message filtered"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Timeout message filtered (missing pattern: Task timed out)"
    fi
    # Check 2: Hanging subsegment identified
    if grep -q -i -F "S3:PutObject" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Hanging subsegment identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Hanging subsegment identified (missing pattern: S3:PutObject)"
    fi
    # Check 3: Target S3 bucket captured
    if grep -q -i -F "shopnow-invoices-archive" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Target S3 bucket captured"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Target S3 bucket captured (missing pattern: shopnow-invoices-archive)"
    fi
    # Check 4: VPC routing / endpoint root cause cited
    if grep -q -i -F "VPC" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: VPC routing / endpoint root cause cited"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: VPC routing / endpoint root cause cited (missing pattern: VPC)"
    fi
    # Check 5: 30-second execution limit noted
    if grep -q -i -F "30" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: 30-second execution limit noted"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: 30-second execution limit noted (missing pattern: 30)"
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
