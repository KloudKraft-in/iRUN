TEL-D6-601: Metric Anomaly to Root Cause in One Platform
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     At 09:12 UTC, checkout conversion drops by 35%. Engineers must correlate metric anomaly to application logs and distributed traces without tool switching.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. In Grafana Explore, detect metric anomaly on checkout throughput starting at 09:12 UTC.
2. Split view into Loki logs: query {service="checkout-api"} | json | status="ERROR".
3. Extract correlated Trace ID '6a71e29f8c12' directly from the log line.
4. Jump directly to Tempo trace waterfall for Trace ID 6a71e29f8c12.
5. Isolate root cause span and complete starter/evidence/evidence_D6_1.md.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D6_1.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
