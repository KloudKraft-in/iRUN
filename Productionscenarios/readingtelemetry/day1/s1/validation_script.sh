#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
EVIDENCE="$STARTER/evidence/evidence_D1_1.json"

invoke_reset() {
    echo "==================================================="
    echo " Resetting Scenario TEL-D1-101..."
    echo "==================================================="
    echo "Baseline state restored."
}

invoke_start() {
    invoke_reset
    echo "==================================================="
    echo " Initializing Incident: TEL-D1-101"
    echo " Checkout Is Slow but the Dashboard Looks Green"
    echo "==================================================="
    echo "Observed Failure: Grafana RED dashboard shows green status and average latency of ~185ms, while customers report 4.5s+ checkout timeouts. The panel query uses 'avg(payment_duration_seconds)' which flattens the bimodal distribution."
    echo ""
    echo "Your Mission: Follow guidelines in starter/README_START_HERE.txt"
    echo "Fill evidence template in: starter/evidence/evidence_D1_1.json"
    echo "Then validate with: ./validation_script.sh check"
}

invoke_check() {
    echo "==================================================="
    echo " Validating Solution for TEL-D1-101"
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
    # Check 1: p95 histogram_quantile query present
    if grep -q -i -F "histogram_quantile" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 1: p95 histogram_quantile query present"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 1: p95 histogram_quantile query present (missing pattern: histogram_quantile)"
    fi
    # Check 2: Correct bucket metric targeted
    if grep -q -i -F "payment_duration_seconds_bucket" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 2: Correct bucket metric targeted"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 2: Correct bucket metric targeted (missing pattern: payment_duration_seconds_bucket)"
    fi
    # Check 3: Rate aggregation applied inside bucket sum
    if grep -q -i -F "rate(" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 3: Rate aggregation applied inside bucket sum"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 3: Rate aggregation applied inside bucket sum (missing pattern: rate()"
    fi
    # Check 4: HTTP requests metric queried for errors
    if grep -q -i -F "http_requests_total" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 4: HTTP requests metric queried for errors"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 4: HTTP requests metric queried for errors (missing pattern: http_requests_total)"
    fi
    # Check 5: Regex filter applied for 5xx errors
    if grep -q -i -F "status=~" "$EVIDENCE" 2>/dev/null; then
        echo "  [PASS] Rule 5: Regex filter applied for 5xx errors"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] Rule 5: Regex filter applied for 5xx errors (missing pattern: status=~)"
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
