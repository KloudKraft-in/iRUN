TEL-D5-501: Top Failing Dependency in Application Insights
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Downstream third-party dependency failures cause checkout degradation. Engineers cannot determine which vendor is failing or correlate errors to application exceptions.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Open Azure Log Analytics / Application Insights KQL console.
2. Summarize failed calls: dependencies | where timestamp > ago(4h) | summarize TotalCalls = count(), FailedCalls = countif(success == false) by target | extend FailureRate = round(100.0 * FailedCalls / TotalCalls, 2) | sort by FailedCalls desc.
3. Identify failing target 'api.external-fraud.io' throwing 504 timeouts (42.4% failure rate).
4. Join dependencies with exceptions: dependencies | where timestamp > ago(4h) and success == false and target == "api.external-fraud.io" | join kind=inner (exceptions | where timestamp > ago(4h)) on operation_Id | project timestamp, operation_Id, target, resultCode, innermostMessage.
5. Record KQL queries and exception findings in starter/evidence/evidence_D5_1.md.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D5_1.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
