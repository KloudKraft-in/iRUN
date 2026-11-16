TEL-D4-403: Latency Percentile and Service Variable Are Wrong
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     SRE dashboard latency percentiles show flat lines measuring cumulative stats since server reboot, and selecting a service in the variable dropdown causes panels to show 'No Data'.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Fix PromQL histogram_quantile by wrapping bucket counts in rate(): histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{service=~"$service"}[5m])) by (le, service)).
2. Inspect the Grafana dashboard service template variable regex: /^(order|payment|inventory|notification).*$/.
3. Fix capturing group defect: replace with non-capturing group /^(?:order|payment|inventory|notification).*$/ so Grafana passes the full service name.
4. Complete starter/evidence/evidence_D4_3.json and run the validation script.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D4_3.json
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
