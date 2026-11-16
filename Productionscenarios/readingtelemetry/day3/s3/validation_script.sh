#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D3_3.json"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D3-303..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D3-303"
    echo " The p95 Latency Monitor That Never Fires"
    echo "==================================================="
    echo "Observed Failure: Critical checkout latency surges past 4 seconds during a promotion, yet the Datadog alert monitor remains completely green and silent."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D3_3.json"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D3-303"
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
    # Check 1: P95 aggregator used
    if grep -q -i -F "p95(last_5m)" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: P95 aggregator used"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: P95 aggregator used (missing pattern: p95(last_5m))"
    fi
    # Check 2: Production environment targeted
    if grep -q -i -F "env:prod" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Production environment targeted"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Production environment targeted (missing pattern: env:prod)"
    fi
    # Check 3: Correct metric targeted
    if grep -q -i -F "shopnow.checkout.duration" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Correct metric targeted"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Correct metric targeted (missing pattern: shopnow.checkout.duration)"
    fi
    # Check 4: Threshold set to 2.5s
    if grep -q -i -F "2.5" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: Threshold set to 2.5s"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: Threshold set to 2.5s (missing pattern: 2.5)"
    fi
    # Check 5: Composite alert logic configured
    if grep -q -i -F "composite" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Composite alert logic configured"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Composite alert logic configured (missing pattern: composite)"
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
