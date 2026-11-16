#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D6_3.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D6-603..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D6-603"
    echo " Integrated Production Incident Workshop"
    echo "==================================================="
    echo "Observed Failure: Major production outage impacts all tiers of the ShopNow enterprise. Incident commander requires verified query evidence across all 7 observability platforms."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D6_3.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D6-603"
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
    # Check 1: Splunk SPL query recorded
    if grep -q -i -F "Splunk" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: Splunk SPL query recorded"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: Splunk SPL query recorded (missing pattern: Splunk)"
    fi
    # Check 2: Dynatrace DQL query recorded
    if grep -q -i -F "Dynatrace" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Dynatrace DQL query recorded"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Dynatrace DQL query recorded (missing pattern: Dynatrace)"
    fi
    # Check 3: New Relic NRQL query recorded
    if grep -q -i -F "New Relic" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: New Relic NRQL query recorded"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: New Relic NRQL query recorded (missing pattern: New Relic)"
    fi
    # Check 4: Loki LogQL query recorded
    if grep -q -i -F "Loki" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Loki LogQL query recorded"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Loki LogQL query recorded (missing pattern: Loki)"
    fi
    # Check 5: Azure KQL query recorded
    if grep -q -i -F "Azure" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Azure KQL query recorded"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Azure KQL query recorded (missing pattern: Azure)"
    fi
    # Check 6: Prometheus PromQL query recorded
    if grep -q -i -F "Prometheus" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 6: Prometheus PromQL query recorded"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 6: Prometheus PromQL query recorded (missing pattern: Prometheus)"
    fi
    # Check 7: Datadog query recorded
    if grep -q -i -F "Datadog" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 7: Datadog query recorded"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 7: Datadog query recorded (missing pattern: Datadog)"
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
