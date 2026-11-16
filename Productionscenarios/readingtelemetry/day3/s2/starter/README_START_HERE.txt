TEL-D3-302: Which App Is Failing? Ask Grail
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Multiple microservices log failures simultaneously across Kubernetes clusters. Traditional search fails to summarize error types by service entity.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Open Dynatrace Notebooks to execute Dynatrace Query Language (DQL).
2. Write Grail pipeline: fetch logs, from:now()-2h | filter status == "ERROR" | summarize ErrorCount = count(), by: {dt.entity.service, error.type} | sort ErrorCount desc.
3. Identify top failing service inventory-worker experiencing DeadlockException.
4. Verify count parity in Splunk: index=retail_inventory status="ERROR" error_type="DeadlockException" earliest=-2h | stats count.
5. Record findings and verified count in starter/evidence/evidence_D3_2.md.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D3_2.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
