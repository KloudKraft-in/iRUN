TEL-D4-401: Slow-Transaction Report for the Ops Review
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Operations review requires a p95 transaction latency ranking for ShopNow-Production. Default APM overviews do not isolate top-5 slowest transactions.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. In New Relic Query Builder, formulate query: SELECT percentile(duration, 95) AS 'P95', average(duration), max(duration) FROM Transaction WHERE appName = 'ShopNow-Production' FACET name LIMIT 5 SINCE 1 day ago.
2. Isolate top slowest transaction 'processPayment' averaging ~4.2s p95.
3. Cross-check using Prometheus PromQL: topk(5, histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[1d])) by (le, handler))).
4. Record NRQL queries and Prometheus validation output in starter/evidence/evidence_D4_1.md.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D4_1.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
