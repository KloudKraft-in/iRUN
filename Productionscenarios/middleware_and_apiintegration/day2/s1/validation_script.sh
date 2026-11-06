#!/usr/bin/env bash
ACTION="${1:-check}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER="$LAB_DIR/starter"
DLQ_F="$STARTER/orders_dlq.json"
QUEUE_F="$STARTER/orders_queue.json"
DB_F="$STARTER/processed_orders.json"
EVIDENCE="$STARTER/evidence/evidence_D2_1.json"

invoke_reset() {
    rm -f "$DB_F" "$QUEUE_F" "$DLQ_F"
    echo "MIA-D2-201 reset complete."
}

invoke_start() {
    invoke_reset
    echo "Staging Scenario MIA-D2-201: RabbitMQ DLQ Flood..."
    cd "$STARTER" && python3 seed_day2_dlq.py && cd "$LAB_DIR"
    echo "TICKET MIA-D2-201 [P2: Orders Stalled in DLQ]"
    echo "Next: Inspect starter/orders_dlq.json and follow Participant_Guide_day2.md Ticket 1."
}

invoke_check() {
    echo "==================================================="
    echo " Validating MIA-D2-201: Message Broker DLQ Recovery "
    echo "==================================================="
    PASSED=0
    TOTAL=4

    P_COUNT=$(python3 -c "import json, os; print(len(json.load(open('$DB_F')))) if os.path.exists('$DB_F') else print(0)")
    if [ "$P_COUNT" -eq 50 ]; then
        echo "  [PASS] Exactly 50 legitimate customer orders processed into database"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Processed count: $P_COUNT (expected 50)"
    fi

    D_COUNT=$(python3 -c "import json, os; print(len(json.load(open('$DLQ_F')))) if os.path.exists('$DLQ_F') else print(0)")
    if [ "$D_COUNT" -eq 10 ]; then
        echo "  [PASS] Exactly 10 malformed poison pills permanently quarantined in DLQ"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] DLQ count: $D_COUNT (expected 10)"
    fi

    Q_COUNT=$(python3 -c "import json, os; print(len(json.load(open('$QUEUE_F')))) if os.path.exists('$QUEUE_F') else print(0)")
    if [ "$Q_COUNT" -eq 0 ]; then
        echo "  [PASS] Primary orders.queue completely drained (0 pending)"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] Queue count: $Q_COUNT (expected 0)"
    fi

    if [ -f "$EVIDENCE" ] && ! grep -q "<<FILL" "$EVIDENCE"; then
        echo "  [PASS] Incident evidence and root cause recorded in evidence_D2_1.json"
        PASSED=$((PASSED+1))
    else
        echo "  [FAIL] evidence_D2_1.json contains unfilled <<FILL>> fields"
    fi

    echo "==================================================="
    echo " Validation Results: $PASSED/$TOTAL passed"
    echo "==================================================="
    if [ "$PASSED" -eq "$TOTAL" ]; then
        echo " [PASS] MIA-D2-201 Validation Succeeded!"
        exit 0
    else
        echo " [FAIL] Some checks failed."
        exit 1
    fi
}

case "$ACTION" in
    start) invoke_start ;;
    reset) invoke_reset ;;
    check) invoke_check ;;
    *)     invoke_check ;;
esac
