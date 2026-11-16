#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D3_2.md"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D3-302..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D3-302"
    echo " Which App Is Failing? Ask Grail"
    echo "==================================================="
    echo "Observed Failure: Multiple microservices log failures simultaneously across Kubernetes clusters. Traditional search fails to summarize error types by service entity."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D3_2.md"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D3-302"
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
    # Check 1: DQL fetch logs statement used
    if grep -q -i -F "fetch logs" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: DQL fetch logs statement used"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: DQL fetch logs statement used (missing pattern: fetch logs)"
    fi
    # Check 2: Error status filtered
    if grep -q -i -F "filter status == "ERROR"" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Error status filtered"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Error status filtered (missing pattern: filter status == "ERROR")"
    fi
    # Check 3: Dynatrace entity service grouped
    if grep -q -i -F "dt.entity.service" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Dynatrace entity service grouped"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Dynatrace entity service grouped (missing pattern: dt.entity.service)"
    fi
    # Check 4: Culprit service identified
    if grep -q -i -F "inventory-worker" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Culprit service identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Culprit service identified (missing pattern: inventory-worker)"
    fi
    # Check 5: Root cause deadlock exception identified
    if grep -q -i -F "DeadlockException" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Root cause deadlock exception identified"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Root cause deadlock exception identified (missing pattern: DeadlockException)"
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
