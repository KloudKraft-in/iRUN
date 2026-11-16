TEL-D2-202: Datadog Monitor Fires: Confirm It in Splunk
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Datadog composite monitor triggers alert: CPU > 80% on prod-worker-02 AND Error Rate > 5%. Raw log evidence must be extracted from Splunk to confirm transaction failure.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Review Datadog composite alert metadata and extract transaction correlation ID 'TXN-88129-CORR' at 11:32:14 UTC.
2. Access Splunk Enterprise (http://localhost:8000).
3. Construct search query: index=retail_prod host=prod-worker-02 sourcetype="checkout:json" "TXN-88129-CORR".
4. Confirm the matching error log signature and stack trace.
5. Complete starter/evidence/evidence_D2_2.md with queries and log evidence.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D2_2.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
