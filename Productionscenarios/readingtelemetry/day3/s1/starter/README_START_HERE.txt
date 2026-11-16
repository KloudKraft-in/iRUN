TEL-D3-301: Error Spike on One Host After a Release
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Post-deployment error rate surges to 8.4%. Standard log searches fail to extract unstructured error codes from application logs on host web-prod-04.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Execute host breakdown search in Splunk: (index=retail_web OR index=retail_checkout) earliest=-4h | stats count by host, sourcetype | sort -count.
2. Isolate culprit host web-prod-04 producing 92% of errors.
3. Extract error codes with regex: rex field=_raw "status_code=(?<err_code>ERR-[0-9]{4})".
4. Generate 15m timechart: timechart span=15m count by err_code.
5. Group user sessions: index=retail_checkout earliest=-4h | transaction session_id maxspan=30m | where duration > 10 | table session_id, duration, eventcount.
6. Complete starter/evidence/evidence_D3_1.md and validate.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D3_1.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
