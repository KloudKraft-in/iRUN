TEL-D1-102: Orders Fail for One Product: Follow the Trace
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Orders for promotional SKU 'PROD-7729' fail intermittently with generic 500 error screens. Aggregate service metrics report healthy throughput, masking isolated transaction failures.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Open Jaeger UI (http://localhost:16686) or Grafana Explore.
2. Filter traces for service 'checkout-service' with tag 'http.status_code=500'.
3. Locate failing trace '4bf92f3577b34da6a3ce929d0e0e4736' and examine the span waterfall.
4. Identify slowest failing span 'inventory.reserveStock' taking ~430ms with error=true.
5. Query Loki logs with LogQL: {app="inventory-service"} |= "4bf92f3577b34da6a3ce929d0e0e4736".
6. Extract the StockReservationException and document the audit lock root cause in starter/evidence/evidence_D1_2.md.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D1_2.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
