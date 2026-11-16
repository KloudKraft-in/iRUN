#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D1_3.json"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D1-103..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D1-103"
    echo " Six Alerts at Shift Start, One Real Problem"
    echo "==================================================="
    echo "Observed Failure: Six simultaneous alerts fire in Alertmanager (CheckoutSlow, PaymentTimeout, ProfileQueryDegraded, OrderHistory504, DiskIOWaitHigh, DatabaseQueueSaturation), creating cognitive overload."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D1_3.json"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D1-103"
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
    # Check 1: Primary causal alert identified
    if grep -q -i -F "DatabaseQueueSaturation" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Primary causal alert identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Primary causal alert identified (missing pattern: DatabaseQueueSaturation)"
    fi
    # Check 2: Corroborating infrastructure alert recorded
    if grep -q -i -F "DiskIOWaitHigh" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Corroborating infrastructure alert recorded"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Corroborating infrastructure alert recorded (missing pattern: DiskIOWaitHigh)"
    fi
    # Check 3: Rogue query PID identified
    if grep -q -i -F "9182" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Rogue query PID identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Rogue query PID identified (missing pattern: 9182)"
    fi
    # Check 4: Target database resource identified
    if grep -q -i -F "PostgreSQL" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Target database resource identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Target database resource identified (missing pattern: PostgreSQL)"
    fi
    # Check 5: Remediation read replica routing proposed
    if grep -q -i -F "replica" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Remediation read replica routing proposed"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Remediation read replica routing proposed (missing pattern: replica)"
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
