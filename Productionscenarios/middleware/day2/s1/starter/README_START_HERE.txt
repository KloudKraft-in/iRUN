MIA-D2-201: Message Broker DLQ Flood Recovery & Defensive Consumer
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Inspect orders_dlq.json:
     cat starter/orders_dlq.json
3. OBSERVED FAILURE:
     60 orders are stuck in the DLQ. Running the unpatched consumer crashes on
     poison pills with missing order_id or negative amounts.

YOUR MISSION (Guidelines & Solve):
1. Review naive logic in starter/order_consumer.py.
2. Implement defensive schema validation:
     - Check: order_id is present and total_amount > 0.
     - Poison pills -> Log warning & isolate in orders_dlq.json.
     - Legitimate orders -> Process into processed_orders.json.
3. Replay messages so:
     - exactly 50 orders are in processed_orders.json
     - exactly 10 poison pills are in orders_dlq.json
     - orders_queue.json is 0.
4. Fill in starter/evidence/evidence_D2_1.json.
5. Run validation:
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================
