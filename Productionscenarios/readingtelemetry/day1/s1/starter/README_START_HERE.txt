TEL-D1-101: Checkout Is Slow but the Dashboard Looks Green
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Grafana RED dashboard shows green status and average latency of ~185ms, while customers report 4.5s+ checkout timeouts. The panel query uses 'avg(payment_duration_seconds)' which flattens the bimodal distribution.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Open the Grafana RED Dashboard (http://localhost:3000) with credentials admin/admin.
2. Inspect the 'Payment Duration' panel query: notice it averages outliers instead of computing percentiles.
3. Replace arithmetic mean with p95 histogram quantile: histogram_quantile(0.95, sum(rate(payment_duration_seconds_bucket[5m])) by (le)) * 1000.
4. Add the missing RED 'Errors' panel calculating 5xx request percentage: sum(rate(http_requests_total{service="checkout-service", status=~"5.."}[5m])) / sum(rate(http_requests_total{service="checkout-service"}[5m])) * 100.
5. Complete starter/evidence/evidence_D1_1.json and run the validation harness.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D1_1.json
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
