TEL-D6-603: Integrated Production Incident Workshop
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Major production outage impacts all tiers of the ShopNow enterprise. Incident commander requires verified query evidence across all 7 observability platforms.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Execute Splunk (SPL): index=retail_checkout status=500 | stats count by error_code, host.
2. Execute Dynatrace (DQL): fetch logs | filter error.code == "INV_LOCK_TIMEOUT" | summarize count() by dt.entity.service.
3. Execute New Relic (NRQL): SELECT average(duration), max(duration) FROM Transaction WHERE appName='Inventory' FACET name SINCE 1 hour ago.
4. Execute Loki (LogQL): {app="payment-service"} | json | status="ERROR".
5. Execute Azure (KQL): dependencies | where success == false | summarize count() by target.
6. Execute Prometheus (PromQL): histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)).
7. Execute Datadog: p95(last_5m):p95:shopnow.checkout.duration{env:prod} by {service} > 2.5.
8. Compile post-mortem RCA with 5 Whys in starter/evidence/evidence_D6_3.md.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D6_3.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
