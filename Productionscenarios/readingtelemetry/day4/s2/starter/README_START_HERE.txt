TEL-D4-402: Error Panel Shows Zero During an Outage
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     During an ongoing payment outage, the Grafana Error Rate panel displays 0 errors. SREs have zero visibility into failure rates.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Inspect the existing broken query: sum(count_over_time({app="payment-service"} |= "error" [1m])).
2. Identify why it returns 0: logs output JSON with uppercase 'level': 'ERROR', and string grep is case-sensitive and misses structured fields.
3. Refactor query using JSON parser and rate calculation: sum(rate({app="payment-service"} | json | level = "ERROR" [5m])).
4. Set panel thresholds (Warning > 1, Critical > 5) and export updated panel configuration.
5. Record findings and fixed query in starter/evidence/evidence_D4_2.json.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D4_2.json
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
