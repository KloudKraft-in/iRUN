TEL-D1-103: Six Alerts at Shift Start, One Real Problem
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Six simultaneous alerts fire in Alertmanager (CheckoutSlow, PaymentTimeout, ProfileQueryDegraded, OrderHistory504, DiskIOWaitHigh, DatabaseQueueSaturation), creating cognitive overload.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Access Alertmanager (http://localhost:9093) and Prometheus Alerts (http://localhost:9090/alerts).
2. Classify alerts into Symptomatic Application Alerts vs Infrastructure Causal Alerts using USE methodology.
3. Analyze database saturation metrics: observe Database Disk Queue Saturation = 38 (normal < 2) and I/O await = 280ms.
4. Correlate the saturation to unindexed batch analytics query PID 9182 on the primary database.
5. Formulate mitigation (terminate rogue query, route reporting to read replica) and complete starter/evidence/evidence_D1_3.json.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D1_3.json
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
