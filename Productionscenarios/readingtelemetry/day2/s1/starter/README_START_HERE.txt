TEL-D2-201: Davis Opened a Problem: Find the Root Cause
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Dynatrace Davis AI engine automatically opened Problem P-24101 indicating payment degradation. Navigating complex UI menus makes finding the root cause code span difficult.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Open Dynatrace Problem card P-24101 and review Smartscape topology.
2. Follow transaction flow from frontend -> checkout -> PaymentService on prod-host-03.
3. Open PurePaths filtered by failed requests.
4. Isolate failing method: StripeGatewayConnector.authorize() throwing SocketTimeoutException (5000ms).
5. Complete starter/evidence/evidence_D2_1.md and verify with the validation harness.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D2_1.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
