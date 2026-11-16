TEL-D2-203: One Incident, Four Tools: Write the Escalation
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Checkout experience is severely degraded across microservices. SREs receive contradictory signals across Grafana, Kibana, New Relic, and cloud consoles.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Examine Grafana RED dashboard: locate latency jump on panel 2 (http://localhost:3000/d/red-checkout?viewPanel=2).
2. Inspect Kibana logs: query service.name:"order-service" AND log.level:ERROR.
3. Inspect New Relic APM: analyze CheckoutController#processOrder spending 7.6s in PostgreSQL pg_sleep.
4. Synthesize root cause: database table lock contention in orders_db.
5. Draft an executive escalation note in starter/evidence/evidence_D2_3.md linking all tools.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D2_3.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
