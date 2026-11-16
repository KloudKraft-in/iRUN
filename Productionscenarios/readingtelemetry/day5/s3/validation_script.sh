#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D5_3.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D5-503..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D5-503"
    echo " Pager Fatigue: Tune the Alerts and Rebuild the Dashboard"
    echo "==================================================="
    echo "Observed Failure: On-call engineers receive 80+ alerts per week due to transient 1-second CPU spikes and un-thresholded error fluctuations. Critical incidents get ignored due to alarm fatigue."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D5_3.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D5-503"
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
    # Check 1: Duration delay added to CPU alert
    if grep -q -i -F "for: 10m" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Duration delay added to CPU alert"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Duration delay added to CPU alert (missing pattern: for: 10m)"
    fi
    # Check 2: Duration delay added to error rate alert
    if grep -q -i -F "for: 3m" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Duration delay added to error rate alert"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Duration delay added to error rate alert (missing pattern: for: 3m)"
    fi
    # Check 3: Runbook URL annotations configured
    if grep -q -i -F "runbook_url" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Runbook URL annotations configured"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Runbook URL annotations configured (missing pattern: runbook_url)"
    fi
    # Check 4: Warning severity assigned
    if grep -q -i -F "severity: warning" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Warning severity assigned"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Warning severity assigned (missing pattern: severity: warning)"
    fi
    # Check 5: Critical severity assigned
    if grep -q -i -F "severity: critical" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Critical severity assigned"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Critical severity assigned (missing pattern: severity: critical)"
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
