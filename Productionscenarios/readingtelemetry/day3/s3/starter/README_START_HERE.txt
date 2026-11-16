TEL-D3-303: The p95 Latency Monitor That Never Fires
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Critical checkout latency surges past 4 seconds during a promotion, yet the Datadog alert monitor remains completely green and silent.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Inspect the existing monitor query: avg(last_5m):avg:shopnow.checkout.duration{env:staging} > 2.0.
2. Identify two fatal defects: (1) average latency dilutes tail spikes, (2) query monitors env:staging instead of env:prod.
3. Rewrite query for 95th percentile on production: p95(last_5m):p95:shopnow.checkout.duration{env:prod} by {service} > 2.5.
4. Construct composite monitor combining latency (A) AND log error rate (B) using formula 'A && B'.
5. Complete starter/evidence/evidence_D3_3.json and execute validation.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D3_3.json
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
